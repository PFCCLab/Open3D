include(FetchContent)

FetchContent_Declare(
    ext_hipify_torch
    prefix hipify_torch
    URL https://github.com/ROCm/hipify_torch/archive/ee928d80eb49a74be5d556465e04c6a40de7e3bc.tar.gz
    URL_HASH SHA256=6446fc51f849c8f6fce37aa71e23f9b0a4715d15a5ab75ba69e635f89b6a9d6c
    DOWNLOAD_DIR "${OPEN3D_THIRD_PARTY_DOWNLOAD_DIR}/hipify_torch"
)

message(STATUS "Fetching hipify_torch")

FetchContent_MakeAvailable(ext_hipify_torch)

list(APPEND CMAKE_MODULE_PATH "${ext_hipify_torch_SOURCE_DIR}/cmake")