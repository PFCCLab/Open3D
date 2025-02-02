// ----------------------------------------------------------------------------
// -                        Open3D: www.open3d.org                            -
// ----------------------------------------------------------------------------
// Copyright (c) 2018-2024 www.open3d.org
// SPDX-License-Identifier: MIT
// ----------------------------------------------------------------------------

#pragma once

#include "pybind/open3d_pybind.h"

namespace open3d {
namespace t {
namespace pipelines {
namespace registration {

void pybind_feature(py::module &m);
void pybind_registration(py::module &m);
void pybind_robust_kernels(py::module &m);

}  // namespace registration
}  // namespace pipelines
}  // namespace t
}  // namespace open3d
