// ----------------------------------------------------------------------------
// -                        Open3D: www.open3d.org                            -
// ----------------------------------------------------------------------------
// Copyright (c) 2018-2023 www.open3d.org
// SPDX-License-Identifier: MIT
// ----------------------------------------------------------------------------
//

#include <vector>

#include "open3d/ml/impl/continuous_conv/ContinuousConvTranspose.h"
#include "open3d/ml/paddle/PaddleHelper.h"

using namespace open3d::ml::impl;

template <class TFeat, class TOut, class TReal, class TIndex>
void ContinuousConvTransposeCPU(
        const paddle::Tensor& filters,
        const paddle::Tensor& out_positions,
        const paddle::Tensor& out_importance,
        const paddle::Tensor& extents,
        const paddle::Tensor& offset,
        const paddle::Tensor& inp_positions,
        const paddle::Tensor& inp_features,
        const paddle::Tensor& inp_neighbors_index,
        const paddle::Tensor& inp_neighbors_importance_sum,
        const paddle::Tensor& inp_neighbors_row_splits,
        const paddle::Tensor& neighbors_index,
        const paddle::Tensor& neighbors_importance,
        const paddle::Tensor& neighbors_row_splits,
        const bool align_corners,
        const CoordinateMapping coordinate_mapping,
        const bool normalize,
        const InterpolationMode interpolation,
        const int64_t max_temp_mem_MB,
        paddle::Tensor& out_features) {
    const bool individual_extents = extents.shape()[0] > 1;
    const bool isotropic_extents = extents.shape()[1] == 1;
    std::vector<int> filter_dims;
    for (auto d : filters.shape()) {
        filter_dims.push_back(static_cast<int>(d));
    }

    CConvTransposeComputeFeaturesCPU<TFeat, TOut, TReal, TIndex>(
            out_features.data<TOut>(), filter_dims, filters.data<TFeat>(),
            out_positions.shape()[0], out_positions.data<TReal>(),
            out_importance.shape()[0] ? out_importance.data<TFeat>() : nullptr,
            inp_positions.shape()[0], inp_positions.data<TReal>(),
            inp_features.data<TFeat>(),
            inp_neighbors_importance_sum.shape()[0]
                    ? inp_neighbors_importance_sum.data<TFeat>()
                    : nullptr,
            inp_neighbors_row_splits.data<int64_t>(),
            neighbors_index.shape()[0], neighbors_index.data<TIndex>(),
            neighbors_importance.shape()[0] ? neighbors_importance.data<TFeat>()
                                            : nullptr,
            neighbors_row_splits.data<int64_t>(), extents.data<TReal>(),
            offset.data<TReal>(), interpolation, coordinate_mapping,
            align_corners, individual_extents, isotropic_extents, normalize);
}
#define INSTANTIATE(TFeat, TOut, TReal, TIndex)                               \
    template void ContinuousConvTransposeCPU<TFeat, TOut, TReal, TIndex>(     \
            const paddle::Tensor& filters,                                    \
            const paddle::Tensor& out_positions,                              \
            const paddle::Tensor& out_importance,                             \
            const paddle::Tensor& extents, const paddle::Tensor& offset,      \
            const paddle::Tensor& inp_positions,                              \
            const paddle::Tensor& inp_features,                               \
            const paddle::Tensor& inp_neighbors_index,                        \
            const paddle::Tensor& inp_neighbors_importance_sum,               \
            const paddle::Tensor& inp_neighbors_row_splits,                   \
            const paddle::Tensor& neighbors_index,                            \
            const paddle::Tensor& neighbors_importance,                       \
            const paddle::Tensor& neighbors_row_splits,                       \
            const bool align_corners,                                         \
            const CoordinateMapping coordinate_mapping, const bool normalize, \
            const InterpolationMode interpolation,                            \
            const int64_t max_temp_mem_MB, paddle::Tensor& out_features);

INSTANTIATE(float, float, float, int32_t)
