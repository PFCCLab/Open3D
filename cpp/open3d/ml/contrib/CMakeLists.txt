add_library(ml_contrib OBJECT)

target_sources(ml_contrib PRIVATE
    Cloud.cpp
    GridSubsampling.cpp
    IoU.cpp
)

if(BUILD_CUDA_MODULE)
    target_sources(ml_contrib PRIVATE
        IoU.cu
    )
endif()

if (WITH_ROCM)
    include(Hipify)

    get_target_property(SOURCE_LIST ml_contrib SOURCES)
    get_hipified_list("${SOURCE_LIST}" HIPIFIED_SOURCE_LIST)

    foreach(src IN LISTS HIPIFIED_SOURCE_LIST)
        get_filename_component(ext ${src} EXT)
        if(ext STREQUAL ".cu")
            set_source_files_properties(${src} PROPERTIES LANGUAGE HIP)
        endif()
    endforeach()

    set_property(TARGET ml_contrib PROPERTY SOURCES ${HIPIFIED_SOURCE_LIST})
endif()

open3d_show_and_abort_on_warning(ml_contrib)
open3d_set_global_properties(ml_contrib)
open3d_set_open3d_lib_properties(ml_contrib)
open3d_link_3rdparty_libraries(ml_contrib)

if(BUILD_CUDA_MODULE)
    target_include_directories(ml_contrib SYSTEM PRIVATE ${CMAKE_CUDA_TOOLKIT_INCLUDE_DIRECTORIES})
endif()
