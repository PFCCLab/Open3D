# open3d_show_and_abort_on_warning(target)
#
# Enables warnings when compiling <target> and enables treating warnings as errors.
function(open3d_show_and_abort_on_warning target)

    set(DISABLE_MSVC_WARNINGS
        /Wv:18         # ignore warnings introduced in Visual Studio 2015 and later.
        /wd4201        # non-standard extension nameless struct (filament includes)
        /wd4310        # cast truncates const value (filament)
        /wd4505        # unreferenced local function has been removed (dirent)
        /wd4127        # conditional expression is const (Eigen)
        /wd4146        # unary minus operator applied to unsigned type, result still unsigned (UnaryEWCPU)
        /wd4189        # local variable is initialized but not referenced (PoissonRecon)
        /wd4324        # structure was padded due to alignment specifier (qhull)
        /wd4706        # assignment within conditional expression (fileIO, ...)
        /wd4100        # unreferenced parameter (many places in Open3D code)
        /wd4702        # unreachable code (many places in Open3D code)
        /wd4244        # implicit data type conversion (many places in Open3D code)
        /wd4245        # signed/unsigned mismatch (visualization, PoissonRecon, ...)
        /wd4267        # conversion from size_t to smaller type (FixedRadiusSearchCUDA, tests)
        /wd4305        # conversion to smaller type in initialization or constructor argument (examples, tests)
        /wd4819        # suppress vs2019+ compiler build error C2220 (Windows)
    )
    set(DISABLE_GNU_CLANG_INTEL_WARNINGS
        -Wno-unused-parameter               # (many places in Open3D code)
    )

    if (WITH_ROCM)
        # Add HIP compiler flags to suppress warnings
        set(HIP_FLAGS "")

        string(APPEND HIP_FLAGS " -Wno-macro-redefined")
        string(APPEND HIP_FLAGS " -Wno-inconsistent-missing-override")
        string(APPEND HIP_FLAGS " -Wno-exceptions")
        string(APPEND HIP_FLAGS " -Wno-shift-count-negative")
        string(APPEND HIP_FLAGS " -Wno-shift-count-overflow")
        string(APPEND HIP_FLAGS " -Wno-unused-command-line-argument")
        string(APPEND HIP_FLAGS " -Wno-duplicate-decl-specifier")
        string(APPEND HIP_FLAGS " -Wno-implicit-int-float-conversion")
        string(APPEND HIP_FLAGS " -Wno-pass-failed")
        string(APPEND HIP_FLAGS " -Wno-unused-result")
        string(APPEND HIP_FLAGS " -Wno-deprecated-declarations")
        string(APPEND HIP_FLAGS " -Wno-format")
        string(APPEND HIP_FLAGS " -Wno-dangling-gsl")
        string(APPEND HIP_FLAGS " -Wno-unused-value")
        string(APPEND HIP_FLAGS " -Wno-braced-scalar-init")
        string(APPEND HIP_FLAGS " -Wno-return-type")
        string(APPEND HIP_FLAGS " -Wno-pragma-once-outside-header")
        string(APPEND HIP_FLAGS " -Wno-deprecated-builtins")
        string(APPEND HIP_FLAGS " -Wno-switch")
        string(APPEND HIP_FLAGS " -Wno-literal-conversion")
        string(APPEND HIP_FLAGS " -Wno-constant-conversion")
        string(APPEND HIP_FLAGS " -Wno-defaulted-function-deleted")
        string(APPEND HIP_FLAGS " -Wno-sign-compare")
        string(APPEND HIP_FLAGS " -Wno-bitwise-instead-of-logical")
        string(APPEND HIP_FLAGS " -Wno-unknown-warning-option")
        string(APPEND HIP_FLAGS " -Wno-unused-lambda-capture")
        string(APPEND HIP_FLAGS " -Wno-unused-variable")
        string(APPEND HIP_FLAGS " -Wno-unused-but-set-variable")
        string(APPEND HIP_FLAGS " -Wno-reorder-ctor")
        string(APPEND HIP_FLAGS " -Wno-deprecated-copy-with-user-provided-copy")
        string(APPEND HIP_FLAGS " -Wno-unused-local-typedef")
        string(APPEND HIP_FLAGS " -Wno-missing-braces")
        string(APPEND HIP_FLAGS " -Wno-sometimes-uninitialized")
        string(APPEND HIP_FLAGS " -Wno-deprecated-copy")
        string(APPEND HIP_FLAGS " -Wno-pessimizing-move")
        string(APPEND HIP_FLAGS " -Wunused-command-line-argument")

        # Add CXX compiler flags to suppress warnings
        list(APPEND DISABLE_GNU_CLANG_INTEL_WARNINGS -Wno-return-type)
        list(APPEND DISABLE_GNU_CLANG_INTEL_WARNINGS -Wno-unused-result)
    else()
        set(HIP_FLAGS "")
    endif()

    if (WITH_CUDA)
        # General NVCC flags
        set(DISABLE_NVCC_WARNINGS
            2809           # ignoring return value from routine declared with "nodiscard" attribute (cub)
        )
        string(REPLACE ";" "," DISABLE_NVCC_WARNINGS "${DISABLE_NVCC_WARNINGS}")

        set(CUDA_FLAGS "--Werror cross-execution-space-call,deprecated-declarations")
        string(APPEND CUDA_FLAGS " --Werror all-warnings")
        string(APPEND CUDA_FLAGS " --Werror ext-lambda-captures-this")
        string(APPEND CUDA_FLAGS " --expt-relaxed-constexpr")
        string(APPEND CUDA_FLAGS " --diag-suppress ${DISABLE_NVCC_WARNINGS}")

        # Host compiler flags
        if (MSVC)
            set(CUDA_DISABLE_MSVC_WARNINGS ${DISABLE_MSVC_WARNINGS})
            string(REPLACE ";" "," CUDA_DISABLE_MSVC_WARNINGS "${CUDA_DISABLE_MSVC_WARNINGS}")

            string(APPEND CUDA_FLAGS " -Xcompiler /W4,/WX,${CUDA_DISABLE_MSVC_WARNINGS}")
        else()
            # reorder breaks builds on Windows, so only enable for other platforms
            string(APPEND CUDA_FLAGS " --Werror reorder")

            set(CUDA_DISABLE_GNU_CLANG_INTEL_WARNINGS ${DISABLE_GNU_CLANG_INTEL_WARNINGS})
            string(REPLACE ";" "," CUDA_DISABLE_GNU_CLANG_INTEL_WARNINGS "${CUDA_DISABLE_GNU_CLANG_INTEL_WARNINGS}")

            string(APPEND CUDA_FLAGS " -Xcompiler -Wall,-Wextra,-Werror,${CUDA_DISABLE_GNU_CLANG_INTEL_WARNINGS}")
        endif()
    else()
        set(CUDA_FLAGS "")
    endif()

    target_compile_options(${target} PRIVATE
        $<$<COMPILE_LANG_AND_ID:C,MSVC>:/W4 /WX ${DISABLE_MSVC_WARNINGS}>
        $<$<COMPILE_LANG_AND_ID:C,GNU,Clang,AppleClang,Intel>:-Wall -Wextra -Werror ${DISABLE_GNU_CLANG_INTEL_WARNINGS}>
        $<$<COMPILE_LANG_AND_ID:CXX,MSVC>:/W4 /WX ${DISABLE_MSVC_WARNINGS}>
        $<$<COMPILE_LANG_AND_ID:CXX,GNU,Clang,AppleClang,Intel>:-Wall -Wextra -Werror ${DISABLE_GNU_CLANG_INTEL_WARNINGS}>
        $<$<COMPILE_LANGUAGE:CUDA>:SHELL:${CUDA_FLAGS}>
        $<$<COMPILE_LANGUAGE:HIP>:SHELL:${HIP_FLAGS}>
        $<$<COMPILE_LANGUAGE:ISPC>:--werror>
    )
endfunction()
