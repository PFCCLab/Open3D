// ----------------------------------------------------------------------------
// -                        Open3D: www.open3d.org                            -
// ----------------------------------------------------------------------------
// Copyright (c) 2018-2024 www.open3d.org
// SPDX-License-Identifier: MIT
// ----------------------------------------------------------------------------

#include <thrust/execution_policy.h>
#include <thrust/sequence.h>

#include "open3d/core/CUDAUtils.h"
#include "open3d/core/hashmap/HashBackendBuffer.h"

namespace open3d {
namespace core {
void CUDAResetHeap(Tensor &heap) {
    uint32_t *heap_ptr = heap.GetDataPtr<uint32_t>();
    thrust::sequence(thrust::device, heap_ptr, heap_ptr + heap.GetLength(), 0);
#if __HIP_PLATFORM_AMD__
    OPEN3D_CUDA_CHECK(hipGetLastError());
#else
    OPEN3D_CUDA_CHECK(cudaGetLastError());
#endif
}
}  // namespace core
}  // namespace open3d
