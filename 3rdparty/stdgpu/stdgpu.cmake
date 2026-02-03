# Exports: ${STDGPU_INCLUDE_DIRS}
# Exports: ${STDGPU_LIB_DIR}
# Exports: ${STDGPU_LIBRARIES}

include(ExternalProject)

if (WITH_CUDA)
ExternalProject_Add(
    ext_stdgpu
    PREFIX stdgpu
    URL https://github.com/stotko/stdgpu/archive/c25d4bd9d7cb61ab3c3fed179c393916372e6034.tar.gz
    URL_HASH SHA256=5f2accdab5776920d33d4d3601f26e10e50fa6786ae1503e6e9d2d9280c0f4d2
    DOWNLOAD_DIR "${OPEN3D_THIRD_PARTY_DOWNLOAD_DIR}/stdgpu"
    UPDATE_COMMAND ""
    CMAKE_ARGS
        -DCMAKE_INSTALL_PREFIX=<INSTALL_DIR>
        -DCMAKE_BUILD_TYPE=Release
        -DSTDGPU_BUILD_SHARED_LIBS=OFF
        -DSTDGPU_BUILD_EXAMPLES=OFF
        -DSTDGPU_BUILD_TESTS=OFF
        -DSTDGPU_BUILD_BENCHMARKS=OFF
        -DSTDGPU_ENABLE_CONTRACT_CHECKS=OFF
        ${ExternalProject_CMAKE_ARGS_hidden}
    CMAKE_CACHE_ARGS    # Lists must be passed via CMAKE_CACHE_ARGS
        -DCMAKE_CUDA_ARCHITECTURES:STRING=${CMAKE_CUDA_ARCHITECTURES}
    BUILD_BYPRODUCTS
        <INSTALL_DIR>/lib/${CMAKE_STATIC_LIBRARY_PREFIX}stdgpu${CMAKE_STATIC_LIBRARY_SUFFIX}
)
elseif(WITH_ROCM)
ExternalProject_Add(
    ext_stdgpu
    PREFIX stdgpu
    # NOTE: Fix make install error on ROCm. PR: https://github.com/stotko/stdgpu/pull/473
    URL https://github.com/stotko/stdgpu/archive/6a8be3eafb485866afa488714b6120adc5140f10.tar.gz
    URL_HASH SHA256=267551bb482e2971c9cb3b3a23324891fb173295ef5ecc3cc3a520d03e76bddd
    DOWNLOAD_DIR "${OPEN3D_THIRD_PARTY_DOWNLOAD_DIR}/stdgpu"
    UPDATE_COMMAND ""
    CMAKE_ARGS
        -DCMAKE_INSTALL_PREFIX=<INSTALL_DIR>
        -DCMAKE_BUILD_TYPE=Release
        -DSTDGPU_BUILD_SHARED_LIBS=OFF
        -DSTDGPU_BUILD_EXAMPLES=OFF
        -DSTDGPU_BUILD_TESTS=OFF
        -DSTDGPU_BUILD_BENCHMARKS=OFF
        -DSTDGPU_ENABLE_CONTRACT_CHECKS=OFF
        -DSTDGPU_BACKEND=STDGPU_BACKEND_HIP
        ${ExternalProject_CMAKE_ARGS_hidden}
        # NOTE: Place this line before ExternalProject_CMAKE_ARGS_hidden to override the CMAKE_CXX_COMPILER.
        -DCMAKE_CXX_COMPILER=$ENV{ROCM_PATH}/llvm/bin/clang++
    CMAKE_CACHE_ARGS    # Lists must be passed via CMAKE_CACHE_ARGS
        # FIXME(beinggod): The CMAKE_HIP_ARCHITECTURES not work because of unknown issue
        -DCMAKE_HIP_ARCHITECTURES:STRING=${CMAKE_HIP_ARCHITECTURES}
    BUILD_BYPRODUCTS
        <INSTALL_DIR>/lib/${CMAKE_STATIC_LIBRARY_PREFIX}stdgpu${CMAKE_STATIC_LIBRARY_SUFFIX}
)
endif()

ExternalProject_Get_Property(ext_stdgpu INSTALL_DIR)
set(STDGPU_INCLUDE_DIRS ${INSTALL_DIR}/include/) # "/" is critical.
# set(STDGPU_LIB_DIR ${INSTALL_DIR}/lib)
set(STDGPU_LIB_DIR ${INSTALL_DIR}/${Open3D_INSTALL_LIB_DIR})
set(STDGPU_LIBRARIES stdgpu)
