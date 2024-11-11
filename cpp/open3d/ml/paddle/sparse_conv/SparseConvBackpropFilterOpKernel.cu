// ----------------------------------------------------------------------------
// -                        Open3D: www.open3d.org                            -
// ----------------------------------------------------------------------------
// Copyright (c) 2018-2023 www.open3d.org
// SPDX-License-Identifier: MIT
// ----------------------------------------------------------------------------
//

#include <bits/stdint-intn.h>

#include <sstream>
#include <vector>

#include "open3d/ml/impl/sparse_conv/SparseConvBackpropFilter.cuh"
#include "open3d/ml/paddle/PaddleHelper.h"

using namespace open3d::ml::impl;

template <class TFeat, class TOut, class TIndex, class TKernelIndex>
void SparseConvBackpropFilterCUDA(const paddle::Tensor& filters,
                                  const paddle::Tensor& inp_features,
                                  const paddle::Tensor& inp_importance,
                                  const paddle::Tensor& neighbors_index,
                                  const paddle::Tensor& neighbors_kernel_index,
                                  const paddle::Tensor& neighbors_importance,
                                  const paddle::Tensor& neighbors_row_splits,
                                  const paddle::Tensor& out_features_gradient,
                                  const bool normalize,
                                  const int64_t max_temp_mem_MB,
                                  paddle::Tensor& filter_backprop) {
    std::vector<int> filter_dims;
    for (auto d : filters.shape()) {
        filter_dims.push_back(static_cast<int>(d));
    }

    auto stream = filters.stream();
    // -1 means current global place
    auto cuda_device_props = phi::backends::gpu::GetDeviceProperties(-1);
    const int texture_alignment = cuda_device_props.textureAlignment;

    auto place = filters.place();

    void* temp_ptr = nullptr;
    size_t temp_size = 0;
    size_t max_temp_size = 0;

    // determine temp_size
    SparseConvBackpropFilterCUDA<TFeat, TOut, TIndex, TKernelIndex>(
            stream, temp_ptr, temp_size, max_temp_size, texture_alignment,
            filter_backprop.data<TOut>(), filter_dims,
            neighbors_row_splits.shape()[0] - 1, inp_features.shape()[0],
            inp_features.data<TFeat>(),
            inp_importance.shape()[0] ? inp_importance.data<TFeat>() : nullptr,
            neighbors_index.shape()[0], neighbors_index.data<TIndex>(),
            neighbors_kernel_index.data<TKernelIndex>(),
            neighbors_importance.shape()[0] ? neighbors_importance.data<TFeat>()
                                            : nullptr,
            neighbors_row_splits.data<int64_t>(),
            out_features_gradient.data<TFeat>(), normalize);

    temp_size = std::max(
            std::min(static_cast<size_t>(max_temp_mem_MB) * 1024 * 1024,
                     max_temp_size),
            temp_size);

    auto temp_tensor = CreateTempTensor(temp_size, place, &temp_ptr);

    // actually run the operation
    SparseConvBackpropFilterCUDA<TFeat, TOut, TIndex, TKernelIndex>(
            stream, temp_ptr, temp_size, max_temp_size, texture_alignment,
            filter_backprop.data<TOut>(), filter_dims,
            neighbors_row_splits.shape()[0] - 1, inp_features.shape()[0],
            inp_features.data<TFeat>(),
            inp_importance.shape()[0] ? inp_importance.data<TFeat>() : nullptr,
            neighbors_index.shape()[0], neighbors_index.data<TIndex>(),
            neighbors_kernel_index.data<TKernelIndex>(),
            neighbors_importance.shape()[0] ? neighbors_importance.data<TFeat>()
                                            : nullptr,
            neighbors_row_splits.data<int64_t>(),
            out_features_gradient.data<TFeat>(), normalize);
}
#define INSTANTIATE(TFeat, TOut, TIndex, TKernelIndex)                         \
    template void                                                              \
    SparseConvBackpropFilterCUDA<TFeat, TOut, TIndex, TKernelIndex>(           \
            const paddle::Tensor& filters, const paddle::Tensor& inp_features, \
            const paddle::Tensor& inp_importance,                              \
            const paddle::Tensor& neighbors_index,                             \
            const paddle::Tensor& neighbors_kernel_index,                      \
            const paddle::Tensor& neighbors_importance,                        \
            const paddle::Tensor& neighbors_row_splits,                        \
            const paddle::Tensor& out_features_gradient, const bool normalize, \
            const int64_t max_temp_mem_MB, paddle::Tensor& filter_backprop);

INSTANTIATE(float, float, int32_t, uint8_t)
