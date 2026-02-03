// ----------------------------------------------------------------------------
// -                        Open3D: www.open3d.org                            -
// ----------------------------------------------------------------------------
// Copyright (c) 2018-2024 www.open3d.org
// SPDX-License-Identifier: MIT
// ----------------------------------------------------------------------------

// This file contains headers for BLAS/LAPACK implementations for CUDA.
//
// For developers, please make sure that this file is not ultimately included in
// Open3D.h.

#pragma once

#if BUILD_CUDA_MODULE

#if __HIP_PLATFORM_AMD__
#include <hipblas/hipblas.h>
#include <hipsolver/hipsolver.h>
#else
#include <cublas_v2.h>
#include <cusolverDn.h>
#include <cusolver_common.h>
#endif

#endif
