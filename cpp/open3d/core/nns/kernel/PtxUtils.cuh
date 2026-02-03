// ----------------------------------------------------------------------------
// -                        Open3D: www.open3d.org                            -
// ----------------------------------------------------------------------------
// Copyright (c) 2018-2024 www.open3d.org
// SPDX-License-Identifier: MIT
// ----------------------------------------------------------------------------
// MIT License
//
// Copyright (c) Facebook, Inc. and its affiliates.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
// ----------------------------------------------------------------------------
// original path: faiss/faiss/gpu/utils/PtxUtils.cuh
// ----------------------------------------------------------------------------

#pragma once

#if __HIP_PLATFORM_AMD__
#include <hip/hip_runtime.h>
#else
#include <cuda.h>
#endif

namespace open3d {
namespace core {

// ROCm/HIP does not support inline PTX, but provides similar functionality via
// builtins. We'll use conditional compilation to provide ROCm/HIP-compatible
// versions for relevant functions/macros.

#if __HIP_PLATFORM_AMD__

// There are no direct equivalents of `bfe.u32`, `bfe.u64`, or `bfi.b32` PTX in
// HIP C++ builtins, but bit-field extract/insert can be implemented in pure C++
// as follows: defines to simplify the SASS assembly structure file/line in the
// profiler

template <typename T>
static inline T bfe(T val, unsigned pos, unsigned len) {
    static_assert(std::is_unsigned<T>::value, "bfe requires unsigned type");
    constexpr unsigned BITS = sizeof(T) * 8;

    if (len == 0) return 0;
    if (len >= BITS) return val >> pos;
    return (val >> pos) & ((T(1) << len) - 1);
}

#define GET_BITFIELD_U32(OUT, VAL, POS, LEN) \
    (OUT = bfe<uint32_t>(VAL, POS, LEN));

#define GET_BITFIELD_U64(OUT, VAL, POS, LEN) \
    (OUT = bfe<uint64_t>(VAL, POS, LEN));

__device__ __forceinline__ unsigned int getBitfield(unsigned int val,
                                                    int pos,
                                                    int len) {
    // Extract `len` bits from `val`, starting at bit `pos`.
    if (len == 0) return 0;
    return (val >> pos) & ((1u << len) - 1);
}

__device__ __forceinline__ uint64_t getBitfield(uint64_t val,
                                                int pos,
                                                int len) {
    if (len == 0) return 0;
    return (val >> pos) & ((1ull << len) - 1);
}

__device__ __forceinline__ unsigned int setBitfield(unsigned int val,
                                                    unsigned int toInsert,
                                                    int pos,
                                                    int len) {
    // Clear the target bitfield and insert the new bits.
    if (len == 0) return val;
    unsigned int mask = ((1u << len) - 1) << pos;
    return (val & ~mask) | ((toInsert << pos) & mask);
}

__device__ __forceinline__ int getLaneId() { return __lane_id(); }

__device__ __forceinline__ unsigned getLaneMaskLt() {
    // No direct HIP equivalent. Use __ballot()/__ballot_sync.
    unsigned lane_id = getLaneId();
    return (1u << lane_id) - 1;
}

__device__ __forceinline__ unsigned getLaneMaskLe() {
    unsigned lane_id = getLaneId();
    return (1u << (lane_id + 1)) - 1;
}

__device__ __forceinline__ unsigned getLaneMaskGt() {
    unsigned lane_id = getLaneId();
    return 0xffffffffu << (lane_id + 1);
}

__device__ __forceinline__ unsigned getLaneMaskGe() {
    unsigned lane_id = getLaneId();
    return 0xffffffffu << lane_id;
}

__device__ __forceinline__ void namedBarrierWait(int name, int numThreads) {
    // NOTE: hip does not support bar.sync with num threads, so we use a trap to
    // indicate an error. Keep this function to compact the code.
    __builtin_trap();
}

__device__ __forceinline__ void namedBarrierArrived(int name, int numThreads) {
    // NOTE: hip does not support bar.arrived with num threads, so we use a trap
    // to indicate an error. Keep this function to compact the code.
    __builtin_trap();
}

#else  // __HIP_PLATFORM_AMD__

// defines to simplify the SASS assembly structure file/line in the profiler
#define GET_BITFIELD_U32(OUT, VAL, POS, LEN) \
    asm("bfe.u32 %0, %1, %2, %3;" : "=r"(OUT) : "r"(VAL), "r"(POS), "r"(LEN));

#define GET_BITFIELD_U64(OUT, VAL, POS, LEN) \
    asm("bfe.u64 %0, %1, %2, %3;" : "=l"(OUT) : "l"(VAL), "r"(POS), "r"(LEN));

__device__ __forceinline__ unsigned int getBitfield(unsigned int val,
                                                    int pos,
                                                    int len) {
    unsigned int ret;
    asm("bfe.u32 %0, %1, %2, %3;" : "=r"(ret) : "r"(val), "r"(pos), "r"(len));
    return ret;
}

__device__ __forceinline__ uint64_t getBitfield(uint64_t val,
                                                int pos,
                                                int len) {
    uint64_t ret;
    asm("bfe.u64 %0, %1, %2, %3;" : "=l"(ret) : "l"(val), "r"(pos), "r"(len));
    return ret;
}

__device__ __forceinline__ unsigned int setBitfield(unsigned int val,
                                                    unsigned int toInsert,
                                                    int pos,
                                                    int len) {
    unsigned int ret;
    asm("bfi.b32 %0, %1, %2, %3, %4;"
        : "=r"(ret)
        : "r"(toInsert), "r"(val), "r"(pos), "r"(len));
    return ret;
}

__device__ __forceinline__ int getLaneId() {
    int laneId;
    asm("mov.u32 %0, %%laneid;" : "=r"(laneId));
    return laneId;
}

__device__ __forceinline__ unsigned getLaneMaskLt() {
    unsigned mask;
    asm("mov.u32 %0, %%lanemask_lt;" : "=r"(mask));
    return mask;
}

__device__ __forceinline__ unsigned getLaneMaskLe() {
    unsigned mask;
    asm("mov.u32 %0, %%lanemask_le;" : "=r"(mask));
    return mask;
}

__device__ __forceinline__ unsigned getLaneMaskGt() {
    unsigned mask;
    asm("mov.u32 %0, %%lanemask_gt;" : "=r"(mask));
    return mask;
}

__device__ __forceinline__ unsigned getLaneMaskGe() {
    unsigned mask;
    asm("mov.u32 %0, %%lanemask_ge;" : "=r"(mask));
    return mask;
}

__device__ __forceinline__ void namedBarrierWait(int name, int numThreads) {
    asm volatile("bar.sync %0, %1;" : : "r"(name), "r"(numThreads) : "memory");
}

__device__ __forceinline__ void namedBarrierArrived(int name, int numThreads) {
    asm volatile("bar.arrive %0, %1;"
                 :
                 : "r"(name), "r"(numThreads)
                 : "memory");
}

#endif

}  // namespace core
}  // namespace open3d
