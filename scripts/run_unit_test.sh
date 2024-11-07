#!/bin/bash
set -x

SCRIPT_HOME=$(cd $(dirname $0); pwd)
LOG_FILE="/tmp/open3d_paddle_ut.log"

PADDLE_UT=(
    "test_fixed_radius_search"
    "test_knn_search" 
    "test_ragged_tensor_paddle" 
    "test_radius_search"
    "test_ragged_to_dense" 
    "test_nms"
    "test_invert_neighbors_list"
    "test_voxelize"
    "test_reduce_subarrays_sum"
    "test_roi_pool"
    "test_query_pts"
    # "test_three_nn"
    # "test_three_interp"
    # "test_sampling"
    # "test_voxel_pooling"
    # "test_cconv"
    # "test_sparseconv"
    # "test_general_sparseconv"
)

rm -rf $LOG_FILE

for UT in "${PADDLE_UT[@]}"; do
    pytest "${SCRIPT_HOME}/../python/test/ml_ops/${UT}.py" | tee -a $LOG_FILE
done

FAILED_CASE=$(cat $LOG_FILE | grep "failed" | wc -l)

if [[ $FAILED_CASE -eq 0 ]]; then
    echo "PASS all unit tests!"
else
    echo "FAILED. Please check $LOG_FILE..."
fi