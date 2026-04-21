open3d_ispc_add_library(tpipelines_kernel OBJECT)

target_sources(tpipelines_kernel PRIVATE
    Registration.cpp
    RegistrationCPU.cpp
    FillInLinearSystem.cpp
    FillInLinearSystemCPU.cpp
    RGBDOdometry.cpp
    RGBDOdometryCPU.cpp
    TransformationConverter.cpp
    Feature.cpp
    FeatureCPU.cpp
)

if (BUILD_CUDA_MODULE)
    target_sources(tpipelines_kernel PRIVATE
        RegistrationCUDA.cu
        FillInLinearSystemCUDA.cu
        RGBDOdometryCUDA.cu
        TransformationConverter.cu
        FeatureCUDA.cu
    )
endif()

if (WITH_ROCM)
    include(Hipify)

    get_target_property(SOURCE_LIST tpipelines_kernel SOURCES)
    get_hipified_list("${SOURCE_LIST}" HIPIFIED_SOURCE_LIST)

    foreach(src IN LISTS HIPIFIED_SOURCE_LIST)
        get_filename_component(ext ${src} EXT)
        if(ext STREQUAL ".cu")
            set_source_files_properties(${src} PROPERTIES LANGUAGE HIP)
        endif()
    endforeach()

    set_property(TARGET tpipelines_kernel PROPERTY SOURCES ${HIPIFIED_SOURCE_LIST})
endif()

open3d_show_and_abort_on_warning(tpipelines_kernel)
open3d_set_global_properties(tpipelines_kernel)
# The kernels are used in the unit tests, so they cannot be hidden for now.
open3d_set_open3d_lib_properties(tpipelines_kernel)
#open3d_set_open3d_lib_properties(tpipelines_kernel HIDDEN)
open3d_link_3rdparty_libraries(tpipelines_kernel)

if(BUILD_CUDA_MODULE)
    target_include_directories(tpipelines_kernel SYSTEM PRIVATE ${CMAKE_CUDA_TOOLKIT_INCLUDE_DIRECTORIES})
endif()
