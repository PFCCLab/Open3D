// ----------------------------------------------------------------------------
// -                        Open3D: www.open3d.org                            -
// ----------------------------------------------------------------------------
// Copyright (c) 2018-2023 www.open3d.org
// SPDX-License-Identifier: MIT
// ----------------------------------------------------------------------------
//

#include <vector>

#include "open3d/ml/impl/continuous_conv/ContinuousConvBackpropFilter.h"
#include "open3d/ml/paddle/PaddleHelper.h"

using namespace open3d::ml::impl;

template <class TFeat, class TOut, class TReal, class TIndex>
void ContinuousConvBackpropFilterCPU(
        const paddle::Tensor& filters,
        const paddle::Tensor& out_positions,
        const paddle::Tensor& extents,
        const paddle::Tensor& offset,
        const paddle::Tensor& inp_positions,
        const paddle::Tensor& inp_features,
        const paddle::Tensor& inp_importance,
        const paddle::Tensor& neighbors_index,
        const paddle::Tensor& neighbors_importance,
        const paddle::Tensor& neighbors_row_splits,
        const paddle::Tensor& out_features_gradient,
        const bool align_corners,
        const open3d::ml::impl::CoordinateMapping coordinate_mapping,
        const bool normalize,
        const open3d::ml::impl::InterpolationMode interpolation,
        const int64_t max_temp_mem_MB,
        paddle::Tensor& filter_backprop) {
    const bool individual_extents = extents.shape()[0] > 1;
    const bool isotropic_extents = extents.shape()[1] == 1;
    std::vector<int> filter_dims;
    for (auto d : filters.shape()) {
        filter_dims.push_back(static_cast<int>(d));
    }
    CConvBackpropFilterCPU<TFeat, TOut, TReal, TIndex>(
            filter_backprop.data<TOut>(), filter_dims, out_positions.shape()[0],
            out_positions.data<TReal>(), inp_positions.shape()[0],
            inp_positions.data<TReal>(), inp_features.data<TFeat>(),
            inp_importance.shape()[0] ? inp_importance.data<TFeat>() : nullptr,
            neighbors_index.shape()[0], neighbors_index.data<TIndex>(),
            neighbors_importance.shape()[0] ? neighbors_importance.data<TFeat>()
                                            : nullptr,
            neighbors_row_splits.data<int64_t>(), extents.data<TReal>(),
            offset.data<TReal>(), out_features_gradient.data<TFeat>(),
            interpolation, coordinate_mapping, align_corners,
            individual_extents, isotropic_extents, normalize);
}
#define INSTANTIATE(TFeat, TOut, TReal, TIndex)                                \
    template void ContinuousConvBackpropFilterCPU<TFeat, TOut, TReal, TIndex>( \
            const paddle::Tensor& filters,                                     \
            const paddle::Tensor& out_positions,                               \
            const paddle::Tensor& extents, const paddle::Tensor& offset,       \
            const paddle::Tensor& inp_positions,                               \
            const paddle::Tensor& inp_features,                                \
            const paddle::Tensor& inp_importance,                              \
            const paddle::Tensor& neighbors_index,                             \
            const paddle::Tensor& neighbors_importance,                        \
            const paddle::Tensor& neighbors_row_splits,                        \
            const paddle::Tensor& out_features_gradient,                       \
            const bool align_corners,                                          \
            const open3d::ml::impl::CoordinateMapping coordinate_mapping,      \
            const bool normalize,                                              \
            const open3d::ml::impl::InterpolationMode interpolation,           \
            const int64_t max_temp_mem_MB, paddle::Tensor& filter_backprop);

INSTANTIATE(float, float, float, int32_t)
