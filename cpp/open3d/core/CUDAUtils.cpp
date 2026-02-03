// ----------------------------------------------------------------------------
// -                        Open3D: www.open3d.org                            -
// ----------------------------------------------------------------------------
// Copyright (c) 2018-2024 www.open3d.org
// SPDX-License-Identifier: MIT
// ----------------------------------------------------------------------------

#include "open3d/core/CUDAUtils.h"

#include "open3d/Macro.h"
#include "open3d/utility/Logging.h"

#ifdef BUILD_CUDA_MODULE
#include "open3d/core/MemoryManager.h"
#endif

namespace open3d {
namespace core {
namespace cuda {

int DeviceCount() {
#ifdef BUILD_CUDA_MODULE
#if __HIP_PLATFORM_AMD__
    try {
        int num_devices;
        OPEN3D_CUDA_CHECK(hipGetDeviceCount(&num_devices));
        return num_devices;
    } catch (const std::runtime_error&) {
        return 0;
    }
#else
    try {
        int num_devices;
        OPEN3D_CUDA_CHECK(cudaGetDeviceCount(&num_devices));
        return num_devices;
    }
    // This function is also used to detect CUDA support in our Python code.
    // Thus, catch any errors if no GPU is available.
    catch (const std::runtime_error&) {
        return 0;
    }
#endif
#else
    return 0;
#endif
}

bool IsAvailable() { return cuda::DeviceCount() > 0; }

void ReleaseCache() {
#ifdef BUILD_CUDA_MODULE
#ifdef ENABLE_CACHED_CUDA_MANAGER
    // Release cache from all devices. Since only memory from MemoryManagerCUDA
    // is cached at the moment, this works as expected. In the future, the logic
    // could become more fine-grained.
    MemoryManagerCached::ReleaseCache();
#else
    utility::LogWarning(
            "Built without cached CUDA memory manager, cuda::ReleaseCache() "
            "has no effect.");
#endif

#else
    utility::LogWarning("Built without CUDA module, cuda::ReleaseCache().");
#endif
}

void Synchronize() {
#ifdef BUILD_CUDA_MODULE
    for (int i = 0; i < DeviceCount(); ++i) {
        Synchronize(Device(Device::DeviceType::CUDA, i));
    }
#endif
}

void Synchronize(const Device& device) {
#ifdef BUILD_CUDA_MODULE
    if (device.IsCUDA()) {
        CUDAScopedDevice scoped_device(device);
#if __HIP_PLATFORM_AMD__
        OPEN3D_CUDA_CHECK(hipDeviceSynchronize());
#else
        OPEN3D_CUDA_CHECK(cudaDeviceSynchronize());
#endif
    }
#endif
}

void AssertCUDADeviceAvailable(int device_id) {
#ifdef BUILD_CUDA_MODULE
    int num_devices = cuda::DeviceCount();
    if (num_devices == 0) {
        utility::LogError(
                "Invalid device 'CUDA:{}'. -DBUILD_CUDA_MODULE=ON, but no "
                "CUDA device available.",
                device_id);
    } else if (num_devices == 1 && device_id != 0) {
        utility::LogError(
                "Invalid CUDA Device 'CUDA:{}'. Device ID expected to "
                "be 0, but got {}.",
                device_id, device_id);
    } else if (device_id < 0 || device_id >= num_devices) {
        utility::LogError(
                "Invalid CUDA Device 'CUDA:{}'. Device ID expected to "
                "be between 0 to {}, but got {}.",
                device_id, num_devices - 1, device_id);
    }
#else
    utility::LogError(
            "-DBUILD_CUDA_MODULE=OFF. Please build with -DBUILD_CUDA_MODULE=ON "
            "to use CUDA device.");
#endif
}

void AssertCUDADeviceAvailable(const Device& device) {
    if (device.IsCUDA()) {
        AssertCUDADeviceAvailable(device.GetID());
    } else {
        utility::LogError(
                "Expected device-type to be CUDA, but got device '{}'",
                device.ToString());
    }
}

bool SupportsMemoryPools(const Device& device) {
#if defined(BUILD_CUDA_MODULE) && (CUDART_VERSION >= 11020)
    if (device.IsCUDA()) {
        int driverVersion = 0;
        int deviceSupportsMemoryPools = 0;
        OPEN3D_CUDA_CHECK(cudaDriverGetVersion(&driverVersion));
        if (driverVersion >=
            11020) {  // avoid invalid value error in cudaDeviceGetAttribute
            OPEN3D_CUDA_CHECK(cudaDeviceGetAttribute(
                    &deviceSupportsMemoryPools, cudaDevAttrMemoryPoolsSupported,
                    device.GetID()));
        }
        return !!deviceSupportsMemoryPools;
    } else {
        return false;
    }
#else
    return false;
#endif
}

#ifdef BUILD_CUDA_MODULE
int GetDevice() {
    int device;
#if __HIP_PLATFORM_AMD__
    OPEN3D_CUDA_CHECK(hipGetDevice(&device));
#else
    OPEN3D_CUDA_CHECK(cudaGetDevice(&device));
#endif
    return device;
}

static void SetDevice(int device_id) {
    AssertCUDADeviceAvailable(device_id);
#if __HIP_PLATFORM_AMD__
    OPEN3D_CUDA_CHECK(hipSetDevice(device_id));
#else
    OPEN3D_CUDA_CHECK(cudaSetDevice(device_id));
#endif
}

class CUDAStream {
public:
    static CUDAStream& GetInstance() {
        // The global stream state is given per thread like CUDA's internal
        // device state.
        static thread_local CUDAStream instance;
        return instance;
    }
#if __HIP_PLATFORM_AMD__
    hipStream_t Get() { return stream_; }
    void Set(hipStream_t stream) { stream_ = stream; }

    static hipStream_t Default() { return static_cast<hipStream_t>(0); }
#else
    cudaStream_t Get() { return stream_; }
    void Set(cudaStream_t stream) { stream_ = stream; }

    static cudaStream_t Default() { return static_cast<cudaStream_t>(0); }
#endif

private:
    CUDAStream() = default;
    CUDAStream(const CUDAStream&) = delete;
    CUDAStream& operator=(const CUDAStream&) = delete;

#if __HIP_PLATFORM_AMD__
    hipStream_t stream_ = Default();
#else
    cudaStream_t stream_ = Default();
#endif
};

#if __HIP_PLATFORM_AMD__
hipStream_t GetStream() { return CUDAStream::GetInstance().Get(); }

void SetStream(hipStream_t stream) { CUDAStream::GetInstance().Set(stream); }

hipStream_t GetDefaultStream() { return CUDAStream::Default(); }
#else
cudaStream_t GetStream() { return CUDAStream::GetInstance().Get(); }

static void SetStream(cudaStream_t stream) {
    CUDAStream::GetInstance().Set(stream);
}

cudaStream_t GetDefaultStream() { return CUDAStream::Default(); }
#endif

#endif

}  // namespace cuda

#ifdef BUILD_CUDA_MODULE

CUDAScopedDevice::CUDAScopedDevice(int device_id)
    : prev_device_id_(cuda::GetDevice()) {
    cuda::SetDevice(device_id);
}

CUDAScopedDevice::CUDAScopedDevice(const Device& device)
    : CUDAScopedDevice(device.GetID()) {
    cuda::AssertCUDADeviceAvailable(device);
}

CUDAScopedDevice::~CUDAScopedDevice() { cuda::SetDevice(prev_device_id_); }

constexpr CUDAScopedStream::CreateNewStreamTag
        CUDAScopedStream::CreateNewStream;

CUDAScopedStream::CUDAScopedStream(const CreateNewStreamTag&)
    : prev_stream_(cuda::GetStream()), owns_new_stream_(true) {
#if __HIP_PLATFORM_AMD__
    OPEN3D_CUDA_CHECK(hipStreamCreate(&new_stream_));
#else
    OPEN3D_CUDA_CHECK(cudaStreamCreate(&new_stream_));
#endif
    cuda::SetStream(new_stream_);
}

#if __HIP_PLATFORM_AMD__
CUDAScopedStream::CUDAScopedStream(hipStream_t stream)
#else
CUDAScopedStream::CUDAScopedStream(cudaStream_t stream)
#endif
    : prev_stream_(cuda::GetStream()),
      new_stream_(stream),
      owns_new_stream_(false) {
    cuda::SetStream(stream);
}

CUDAScopedStream::~CUDAScopedStream() {
    if (owns_new_stream_) {
#if __HIP_PLATFORM_AMD__
        OPEN3D_CUDA_CHECK(hipStreamDestroy(new_stream_));
#else
        OPEN3D_CUDA_CHECK(cudaStreamDestroy(new_stream_));
#endif
    }
    cuda::SetStream(prev_stream_);
}

CUDAState& CUDAState::GetInstance() {
    static CUDAState instance;
    return instance;
}

bool CUDAState::IsP2PEnabled(int src_id, int tar_id) const {
    cuda::AssertCUDADeviceAvailable(src_id);
    cuda::AssertCUDADeviceAvailable(tar_id);
    return p2p_enabled_[src_id][tar_id];
}

bool CUDAState::IsP2PEnabled(const Device& src, const Device& tar) const {
    cuda::AssertCUDADeviceAvailable(src);
    cuda::AssertCUDADeviceAvailable(tar);
    return p2p_enabled_[src.GetID()][tar.GetID()];
}

void CUDAState::ForceDisableP2PForTesting() {
    for (int src_id = 0; src_id < cuda::DeviceCount(); ++src_id) {
        for (int tar_id = 0; tar_id < cuda::DeviceCount(); ++tar_id) {
            if (src_id != tar_id && p2p_enabled_[src_id][tar_id]) {
                p2p_enabled_[src_id][tar_id] = false;
            }
        }
    }
}

CUDAState::CUDAState() {
    // Check and enable all possible peer to peer access.
    p2p_enabled_ = std::vector<std::vector<bool>>(
            cuda::DeviceCount(), std::vector<bool>(cuda::DeviceCount(), false));

    for (int src_id = 0; src_id < cuda::DeviceCount(); ++src_id) {
        for (int tar_id = 0; tar_id < cuda::DeviceCount(); ++tar_id) {
            if (src_id == tar_id) {
                p2p_enabled_[src_id][tar_id] = true;
            } else {
                CUDAScopedDevice scoped_device(src_id);

                // Check access.
                int can_access = 0;
#if __HIP_PLATFORM_AMD__
                OPEN3D_CUDA_CHECK(
                        hipDeviceCanAccessPeer(&can_access, src_id, tar_id));
#else
                OPEN3D_CUDA_CHECK(
                        cudaDeviceCanAccessPeer(&can_access, src_id, tar_id));
#endif
                // Enable access.
                if (can_access) {
                    p2p_enabled_[src_id][tar_id] = true;
#if __HIP_PLATFORM_AMD__
                    hipError_t err = hipDeviceEnablePeerAccess(tar_id, 0);
                    if (err == hipErrorPeerAccessAlreadyEnabled) {
                        // Ignore error since P2P is already enabled.
                        // Add void to suppress unused variable warning.
                        (void)hipGetLastError();
                    } else {
                        OPEN3D_CUDA_CHECK(err);
                    }
#else
                    cudaError_t err = cudaDeviceEnablePeerAccess(tar_id, 0);
                    if (err == cudaErrorPeerAccessAlreadyEnabled) {
                        // Ignore error since P2P is already enabled.
                        cudaGetLastError();
                    } else {
                        OPEN3D_CUDA_CHECK(err);
                    }
#endif
                } else {
                    p2p_enabled_[src_id][tar_id] = false;
                }
            }
        }
    }
}

int GetCUDACurrentDeviceTextureAlignment() {
    int value;
#if __HIP_PLATFORM_AMD__
    OPEN3D_CUDA_CHECK(hipDeviceGetAttribute(
            &value, hipDeviceAttributeTextureAlignment, cuda::GetDevice()));
#else
    OPEN3D_CUDA_CHECK(cudaDeviceGetAttribute(
            &value, cudaDevAttrTextureAlignment, cuda::GetDevice()));
#endif
    return value;
}

int GetCUDACurrentWarpSize() {
    int value;
#if __HIP_PLATFORM_AMD__
    OPEN3D_CUDA_CHECK(hipDeviceGetAttribute(&value, hipDeviceAttributeWarpSize,
                                            cuda::GetDevice()));
#else
    OPEN3D_CUDA_CHECK(cudaDeviceGetAttribute(&value, cudaDevAttrWarpSize,
                                             cuda::GetDevice()));
#endif
    return value;
}

size_t GetCUDACurrentTotalMemSize() {
    size_t free;
    size_t total;
#if __HIP_PLATFORM_AMD__
    OPEN3D_CUDA_CHECK(hipMemGetInfo(&free, &total));
#else
    OPEN3D_CUDA_CHECK(cudaMemGetInfo(&free, &total));
#endif
    return total;
}

#endif

}  // namespace core
}  // namespace open3d

#ifdef BUILD_CUDA_MODULE

namespace open3d {
namespace core {

#if __HIP_PLATFORM_AMD__
void __OPEN3D_CUDA_CHECK(hipError_t err, const char* file, const int line) {
    if (err != hipSuccess) {
        utility::LogError("{}:{} CUDA runtime error: {}", file, line,
                          hipGetErrorString(err));
    }
}
#else
void __OPEN3D_CUDA_CHECK(cudaError_t err, const char* file, const int line) {
    if (err != cudaSuccess) {
        utility::LogError("{}:{} CUDA runtime error: {}", file, line,
                          cudaGetErrorString(err));
    }
}
#endif

void __OPEN3D_GET_LAST_CUDA_ERROR(const char* message,
                                  const char* file,
                                  const int line) {
#if __HIP_PLATFORM_AMD__
    hipError_t err = hipGetLastError();
    if (err != hipSuccess) {
        utility::LogError("{}:{} {}: OPEN3D_GET_LAST_CUDA_ERROR(): {}", file,
                          line, message, hipGetErrorString(err));
    }
#else
    cudaError_t err = cudaGetLastError();
    if (err != cudaSuccess) {
        utility::LogError("{}:{} {}: OPEN3D_GET_LAST_CUDA_ERROR(): {}", file,
                          line, message, cudaGetErrorString(err));
    }
#endif
}

}  // namespace core
}  // namespace open3d

#endif

// C interface to provide un-mangled function to Python ctypes
extern "C" OPEN3D_DLL_EXPORT int open3d_core_cuda_device_count() {
    return open3d::core::cuda::DeviceCount();
}
