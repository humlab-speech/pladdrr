# SIMD Optimization Plan: Advanced Algorithms & Pipelines

**Date**: 2025-11-23
**Package Version**: 0.9.9 → 1.1.0
**Status**: Planning Phase
**Focus**: Algorithmic optimizations and pipeline acceleration

---

## 1. Executive Summary

This document outlines the next phase of SIMD optimizations for the `speaker` package, building upon the foundational work completed in `SIMD_EXTENDED_IMPLEMENTATION_2025-11-22.md`. The previous phases successfully optimized many of Praat's core C++ functions. This plan addresses opportunities that were deferred or not considered, focusing on **entire analysis pipelines** and the integration of **best-in-class third-party libraries** for cornerstone algorithms.

The key opportunities identified are:
1.  **High-Performance FFT Engine**: Replace or augment Praat's native FFT with a dedicated, highly-optimized library like PFFFT to accelerate all frequency-domain analysis.
2.  **Complete MFCC Pipeline Acceleration**: Implement a fully-vectorized pipeline for Mel-Frequency Cepstral Coefficients (MFCCs), a critical feature for machine learning applications.
3.  **Dynamic Time Warping (DTW) Acceleration**: Optimize the core distance calculations within DTW to dramatically speed up sequence alignment tasks.

Implementing these will provide substantial speedups (5-15x) for advanced phonetic analysis and machine learning workflows, positioning `speaker` as a top-tier performance leader.

---

## 2. New SIMD Optimization Opportunities

### Priority 1: High-Performance FFT Engine

**Justification**: The Fast Fourier Transform (FFT) is the computational backbone of spectrograms, cepstrums, and formant analysis. The `SIMD_EXTENDED_IMPLEMENTATION` report notes that `sound_convolution_simd.cpp` has a scalar fallback. Praat's native FFT implementation is not optimized for modern SIMD architectures. Integrating a specialized library would provide a massive, widespread performance boost.

**Proposal**: Integrate the **PFFFT library**. It is a public-domain, SIMD-accelerated FFT library that supports SSE, AVX, and NEON, making it a perfect fit for this project without introducing licensing complexities like FFTW (GPL).

**Affected Praat Functions**:
- `Sound: To Spectrogram...`
- `Sound: To Spectrum...`
- `Sound: To Cepstrum...`
- `Sound: To LPC (autocorrelation)...` (which uses FFT for fast correlation)
- All FFT-based filtering operations.

**SIMD Strategy**:
- **Integration**: Add PFFFT source code or as a submodule.
- **Wrapper**: Create a C++ wrapper (`fft_engine_simd.cpp`) that provides a simple interface over PFFFT.
- **Dispatch**: Modify existing Praat functions (`Spectrogram_create`, etc.) to conditionally call the PFFFT wrapper instead of Praat's internal FFT functions (`fastFourierTransform`, `realFastFourierTransform`).
- **Windowing**: Ensure the existing `window_functions_simd.cpp` is used to prepare the input signal before passing it to PFFFT.

**Dependencies**: PFFFT library source.

**Expected Speedup**: **5-10x** for FFT operations, leading to a **2-4x** speedup for a full spectrogram or cepstrum analysis.

---

### Priority 2: Complete MFCC Pipeline Acceleration

**Justification**: MFCCs are the most widely used features for speech recognition, speaker identification, and other audio-based machine learning. The previous plan deferred DCT implementation, which is only one part of the pipeline. A fully-optimized MFCC workflow is a high-value feature for researchers and developers.

**Proposal**: Create a new, dedicated `mfcc_simd.cpp` module that implements the entire pipeline using vectorized operations.

**MFCC Pipeline Steps & SIMD Strategy**:
1.  **Framing & Windowing**: Already optimized via `window_functions_simd.cpp`.
2.  **Periodogram (FFT)**: Leverage the new **High-Performance FFT Engine** (Priority 1).
3.  **Mel Filterbank Application**: This is a matrix-vector multiplication. The Mel filterbank matrix is sparse.
    - **Strategy**: Implement a SIMD-optimized sparse matrix-vector product. Vectorize the accumulation of FFT bin energies for each filter.
4.  **Logarithm of Filterbank Energies**: The `log()` function is scalar.
    - **Strategy**: Integrate the **SLEEF library** (Boost Software License), which provides SIMD-vectorized versions of `log()` (`xsimd::log()`). This was noted as a dependency for other deferred tasks and should be prioritized.
5.  **Discrete Cosine Transform (DCT)**:
    - **Strategy**: Implement a SIMD-accelerated DCT-II. This can be done efficiently using FFTs (via the new engine) or by direct vectorization of the DCT formula using SLEEF for the `cos()` function.

**Affected Praat Functions**: This would be a **new feature**, exposed as `Sound$to_mfcc()`, analogous to libraries like Python's `librosa`.

**Dependencies**: PFFFT (from Priority 1), SLEEF library source.

**Expected Speedup**: **10-15x** for the entire MFCC calculation compared to a scalar R or C++ implementation.

---

### Priority 3: Dynamic Time Warping (DTW) Acceleration

**Justification**: DTW is an essential algorithm for aligning and comparing two temporal sequences of different lengths. It is fundamental to template-based speech recognition and for comparing pitch contours or formant tracks. The calculation is computationally intensive (O(N*M)), and the inner loop is a prime candidate for optimization.

**Proposal**: Create a `dtw_simd.cpp` module to provide a fast DTW implementation.

**SIMD Strategy**:
- **Core Task**: The DTW algorithm fills a cost matrix `C`, where `C[i, j]` is the distance between the `i`-th element of sequence 1 and the `j`-th element of sequence 2, plus the minimum of neighboring costs.
- **Optimization Target**: The calculation of the distance `d(vec1[i], vec2[j])` is the bottleneck. The `num_distance_simd.cpp` module already provides the `euclidean_distance_simd()` function.
- **Implementation**:
    1.  The outer loops of the DTW algorithm will remain serial due to data dependencies.
    2.  Inside the loop, when calculating the cost for a new cell, the distance between the two feature vectors (e.g., MFCC vectors) will be calculated using the already-optimized `euclidean_distance_simd()` or `cosine_similarity_simd()`.
    3.  This avoids redundant work and leverages existing SIMD modules for a significant boost.

**Affected Praat Functions**: This would be a **new, high-level feature**, exposed as `Matrix$dtw(Matrix other)` or `speaker::dtw(matrix1, matrix2)`, allowing alignment of any two feature matrices (MFCCs, formant tracks, etc.).

**Dependencies**: None (leverages existing `num_distance_simd.cpp`).

**Expected Speedup**: **3-5x** for typical DTW tasks, where the vector size is large enough (e.g., 13-39 dimensional MFCCs) for the distance calculation to be the dominant factor.

---

## 3. Implementation Roadmap

### Phase 1: Infrastructure (1-2 days)
- **Task**: Integrate PFFFT and SLEEF libraries into the build system.
- **Goal**: Ensure both libraries compile correctly within the R package structure. Create `configure` script logic to detect their availability and set preprocessor flags.

### Phase 2: FFT Engine & MFCCs (3-4 days)
- **Task**: Implement the **High-Performance FFT Engine** (Priority 1).
- **Task**: Implement the **Complete MFCC Pipeline** (Priority 2), leveraging the new FFT engine and SLEEF.
- **Goal**: Expose a new `Sound$to_mfcc()` method and see significant speedups in `Sound$to_spectrogram()`.

### Phase 3: DTW & Benchmarking (2-3 days)
- **Task**: Implement **DTW Acceleration** (Priority 3).
- **Task**: Create a new vignette (`vignettes/advanced-analysis.Rmd`) benchmarking the new MFCC and DTW features against other R packages (e.g., `dtw`, `tuneR`) and Python libraries (`librosa`).
- **Goal**: Demonstrate performance leadership in these advanced domains.

---

## 4. Conclusion

The previous SIMD work has laid an excellent foundation. By targeting these three high-impact, algorithmic opportunities, the `speaker` package can evolve from being a "fast Praat wrapper" to a "high-performance phonetic analysis engine" that surpasses the capabilities of many contemporary tools. This plan directly addresses the needs of users in machine learning and advanced phonetic research, where MFCCs, FFT-speed, and DTW are daily requirements.
