# open3d_make_rocm_architectures(rocm_archs)
#
# Sets up ROCM architectures based on the following precedence rules
# and stores them into the <rocm_archs> variable.
#   1. All common architectures if BUILD_COMMON_ROCM_ARCHS=ON
#   2. User-defined architectures
#   3. Architectures detected on the current machine
function(open3d_make_rocm_architectures rocm_archs)
    unset(${rocm_archs})

    find_package(HIP REQUIRED)

    if(BUILD_COMMON_ROCM_ARCHS)
        # split by semicolon
        set(${rocm_archs} "gfx906;gfx926;gfx928;gfx936")
    else()
        file(WRITE
            "${CMAKE_CURRENT_BINARY_DIR}/rocm_architectures.sh"
            "
            #!/bin/bash
            set -e

            ARCH=$(rocminfo | grep -E '^\\s*Name:\\s+gfx[0-9]+' | awk '{print $2}' | sort -u)

            if [ -z "$ARCH" ]; then
                echo -n "Unknown"
                exit 1
            else
                echo -n "$ARCH"
                exit 0
            fi
            ")

        execute_process(
            COMMAND bash ${CMAKE_CURRENT_BINARY_DIR}/rocm_architectures.sh
            WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
            RESULT_VARIABLE RET
            OUTPUT_VARIABLE DETECTED_ARCHITECTURES
            ERROR_VARIABLE ERROR
        )

        if(RET EQUAL 0)
            message(STATUS "Building with detected architectures")
            set(${rocm_archs} ${DETECTED_ARCHITECTURES})
        else()
            message(FATAL_ERROR "Failed to detect ROCM architectures")
        endif()
    endif()

    set(${rocm_archs} ${${rocm_archs}} PARENT_SCOPE)

endfunction()
