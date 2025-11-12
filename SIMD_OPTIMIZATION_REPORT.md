# SIMD Optimization Assessment Report for speaker Package
## Using RcppXsimd for Performance Enhancement

**Date**: 2025-11-12
**Package Version**: 0.4.1
**Analysis Scope**: Full C++ codebase (~16,000 lines)
**Target**: RcppXsimd integration for vectorized computation

---

## Executive Summary

The **speaker** package is an R wrapper for Praat's phonetic analysis functionality, performing computationally intensive operations on audio signals, spectral analysis, and acoustic feature extraction. This assessment identifies high-value opportunities for SIMD (Single Instruction Multiple Data) vectorization using the RcppXsimd package.

### Key Findings

- ✅ **Excellent SIMD potential**: Multiple hot paths with array-based double precision operations
- ✅ **High impact targets**: FFT, spectral analysis, matrix operations, signal processing
- ✅ **Estimated speedup**: 2-8x for individual operations, 2-4x for end-to-end pipelines
- ✅ **Low risk**: RcppXsimd provides CPU capability detection and automatic fallbacks
- ⚠️ **Moderate complexity**: Some optimizations require careful handling of Praat's memory layout

### Recommended Action

**Start with Phase 1** (matrix operations and data conversions) to validate approach and measure real-world gains before proceeding to more complex spectral analysis optimizations.

**Estimated Development Effort**: 6-10 weeks for comprehensive SIMD integration
**Estimated Performance Gain**: 2-4x for typical phonetic analysis pipelines

---

## Top 10 SIMD Optimization Opportunities

### Tier 1: Critical Hot Paths (Highest Impact)

#### 1. **Spectrogram Generation (FFT-based)** ⭐⭐⭐⭐⭐
**Location**: `src/sound_wrappers.cpp:420-469`, Praat's FFT in `src/praat/dwsys/NUMFourier.cpp`

**Current Implementation**:
```cpp
autoSpectrogram spectrogram = Sound_to_Spectrogram_e(
    sound, window_length, max_frequency, time_step,
    frequency_step, shape, 8.0, 8.0
);
```

**Gemini Analysis**:
> "The core of this function involves a Fast Fourier Transform (FFT) calculation within a loop over sound frames. The inner loops performing windowing and the FFT butterfly calculations are highly parallelizable."

**Manual Analysis Findings**:
- FFT is called repeatedly for overlapping windows
- Pre/post-processing involves array element shuffling (lines 64-87 in NUMFourier.cpp)
- Window function application (Hamming, Hanning, etc.) uses scalar `cos()` operations

**SIMD Opportunities**:
- ✅ **Window function generation**: Vectorize `w[i] = 0.54 - 0.46 * cos(2*pi*i/N)` using `xsimd::cos()`
- ✅ **FFT butterfly operations**: Replace Praat's scalar FFT with SIMD-optimized implementation
- ✅ **Data reordering**: Use `xsimd::shuffle()` for efficient array element permutation
- ⚠️ **Consider FFTW**: If license permits, FFTW has mature SIMD support (SSE2, AVX, AVX2, AVX512)

**Estimated Speedup**:
- Gemini: 2-4x
- Manual analysis: 3-5x (with SIMD-optimized FFT library)

**Impact**: **VERY HIGH** - Spectrogram generation is core to phonetic analysis

**Implementation Priority**: Phase 2-3 (requires FFT library evaluation)

---

#### 2. **Formant Extraction (LPC/Burg Algorithm)** ⭐⭐⭐⭐⭐
**Location**: `src/formant_wrappers.cpp:27-50`, Praat's `Sound_to_Formant_burg()`

**Current Implementation**:
```cpp
autoFormant formant = Sound_to_Formant_burg(
    sound.get(), time_step, max_number_of_formants,
    maximum_formant, window_length, pre_emphasis_from
);
```

**Gemini Analysis**:
> "The LPC algorithm relies heavily on autocorrelation calculations, which are essentially dot products over windowed segments of the sound data. These dot products are ideal for SIMD."

**SIMD Opportunities**:
- ✅ **Autocorrelation computation**: Vectorize sum-of-products: `sum(x[i] * x[i+lag])`
- ✅ **Pre-emphasis filter**: Apply `x[i] - k*x[i-1]` in SIMD blocks
- ✅ **Covariance matrix operations**: Matrix multiplication with SIMD

**Estimated Speedup**: 2-4x

**Impact**: **VERY HIGH** - Formant tracking is fundamental to vowel analysis

**Implementation Priority**: Phase 2

---

#### 3. **Pitch Detection (Autocorrelation Method)** ⭐⭐⭐⭐⭐
**Location**: `src/sound_wrappers.cpp:268-291`, Praat's `Sound_to_Pitch()`

**Gemini Analysis**:
> "Pitch detection via autocorrelation involves numerous loops calculating the correlation of the signal with itself at different lags. This is another instance of repeated dot-product-like operations on large arrays."

**SIMD Opportunities**:
- ✅ **Lag correlation loops**: `sum(x[i] * x[i+k])` for multiple lag values
- ✅ **Peak detection**: Vectorized comparison operations
- ✅ **Normalization**: Batch division operations

**Estimated Speedup**: 2-4x

**Impact**: **VERY HIGH** - F0 tracking is used in most analyses

**Implementation Priority**: Phase 2

---

#### 4. **Intensity Calculation** ⭐⭐⭐⭐⭐
**Location**: `src/intensity_wrappers.cpp`, `src/sound_wrappers.cpp:180-202`

**Current Implementation**:
```cpp
double sound_get_rms(XPtr<structSound> xptr, double from_time, double to_time) {
    double rms = 0.0;
    for (int ch = 1; ch <= sound->ny; ch++) {
        double channel_rms = Sound_getRootMeanSquare(sound, from_time, to_time);
        rms += channel_rms * channel_rms;
    }
    return sqrt(rms / sound->ny);
}
```

**Gemini Analysis**:
> "This function calculates the intensity (energy) of a sound over time. It involves squaring and summing sample values within sliding windows. The loop that squares and accumulates values is easily vectorizable."

**SIMD Opportunities**:
- ✅ **Sum of squares**: Use `xsimd::fma(x, x, accumulator)` for `sum(x^2)`
- ✅ **Sliding window**: Process 4-8 samples per iteration
- ✅ **RMS computation**: Vectorized sqrt operation

**Estimated Speedup**:
- Gemini: 3-5x
- Manual: 3-5x

**Impact**: **VERY HIGH** - Used in normalization, loudness analysis

**Implementation Priority**: Phase 1 (relatively straightforward)

---

### Tier 2: High-Frequency Operations

#### 5. **Matrix Statistical Operations** ⭐⭐⭐⭐⭐
**Location**: `src/matrix_wrappers.cpp:184-244`

**Current Implementation**:
```cpp
// Sum
double matrix_get_sum(SEXP xptr) {
    double sum = 0.0;
    for (integer i = 1; i <= matrix->ny; i++) {
        for (integer j = 1; j <= matrix->nx; j++) {
            sum += matrix->z[i][j];
        }
    }
    return sum;
}

// Min/Max - similar nested loops
```

**SIMD Opportunities**:
- ✅ **Horizontal reduction**: `xsimd::reduce_add()`, `xsimd::reduce_min()`, `xsimd::reduce_max()`
- ✅ **Single-pass multi-stat**: Compute sum, min, max, mean in one vectorized loop
- ✅ **Cache-friendly access**: Process rows in SIMD-sized chunks

**Example SIMD Implementation**:
```cpp
double matrix_get_sum_simd(SEXP xptr) {
    Matrix matrix = GET_PRAAT_OBJECT(Matrix, xptr);
    using batch = xsimd::batch<double>;
    constexpr size_t batch_size = batch::size;  // 4 for AVX2, 2 for SSE2

    double sum = 0.0;
    for (integer i = 1; i <= matrix->ny; i++) {
        double* row = &matrix->z[i][1];
        integer nx = matrix->nx;

        // Vectorized loop (process 4 doubles at once)
        batch acc(0.0);
        integer j = 0;
        for (; j + batch_size <= nx; j += batch_size) {
            batch b = xsimd::load_unaligned(&row[j]);
            acc += b;
        }
        sum += xsimd::reduce_add(acc);

        // Scalar remainder
        for (; j < nx; ++j) {
            sum += row[j];
        }
    }
    return sum;
}
```

**Estimated Speedup**: 4-8x

**Impact**: **VERY HIGH** - Used extensively in spectral analysis

**Implementation Priority**: Phase 1 (easiest high-impact win)

---

#### 6. **Data Conversion (Praat ↔ R)** ⭐⭐⭐⭐⭐
**Location**: `src/sound_wrappers.cpp:72-76, 489-497, 509-521`, `src/matrix_wrappers.cpp:140-152, 156-170`, `src/spectrogram_wrappers.cpp:138-152`

**Current Implementation**:
```cpp
// Sound creation from R matrix
for (int ch = 1; ch <= n_channels; ch++) {
    for (int i = 1; i <= n_samples; i++) {
        sound->z[ch][i] = values(ch - 1, i - 1);  // Scalar copy
    }
}

// Sound export to R matrix
for (int ch = 1; ch <= sound->ny; ch++) {
    for (int i = 1; i <= sound->nx; i++) {
        mat(ch - 1, i - 1) = sound->z[ch][i];  // Scalar copy
    }
}
```

**SIMD Opportunities**:
- ✅ **Bulk memory transfer**: Use `xsimd::load()/store()` for 4-8 element transfers
- ✅ **Memory prefetching**: Improve cache utilization
- ✅ **Alignment handling**: Use `xsimd::load_unaligned()` if needed

**Estimated Speedup**: 4-8x

**Impact**: **VERY HIGH** - Called on every Sound/Matrix object creation and export

**Implementation Priority**: Phase 1

---

#### 7. **Tone/Signal Generation** ⭐⭐⭐⭐
**Location**: `src/sound_wrappers.cpp:88-110`

**Current Implementation**:
```cpp
// Generate tone
for (int i = 1; i <= sound->nx; i++) {
    double t = sound->x1 + (i - 1) * sound->dx;
    sound->z[1][i] = amplitude * sin(2.0 * M_PI * frequency * t);
}
```

**SIMD Opportunities**:
- ✅ **Vectorized sine**: Use `xsimd::sin()` (leverages SVML on Intel)
- ✅ **Time vector**: Compute `t = x1 + (i-1)*dx` in SIMD blocks
- ✅ **Batch processing**: 4-8 samples per iteration

**Example SIMD Implementation**:
```cpp
using batch = xsimd::batch<double>;
constexpr size_t simd_size = batch::size;

batch t_base(sound->x1);
batch dt(sound->dx);
batch indices = xsimd::arange<double>(0.0, simd_size);  // [0, 1, 2, 3]
batch two_pi_f(2.0 * M_PI * frequency);
batch amp(amplitude);

for (int i = 1; i <= sound->nx; i += simd_size) {
    batch t = t_base + (indices + batch(i-1)) * dt;
    batch values = amp * xsimd::sin(two_pi_f * t);
    xsimd::store_unaligned(&sound->z[1][i], values);
    indices = indices + batch(simd_size);
}
```

**Estimated Speedup**: 4-6x (SVML provides excellent sine performance)

**Impact**: **HIGH** - Fundamental for signal synthesis

**Implementation Priority**: Phase 1

---

#### 8. **LTAS (Long-Term Average Spectrum)** ⭐⭐⭐⭐
**Location**: `src/sound_wrappers.cpp:399-416`

**Gemini Analysis**:
> "Creating a Long-Term Average Spectrum (LTAS) involves averaging multiple FFTs. The loops for performing individual FFTs and the final loop for averaging the spectral bins can both be vectorized."

**SIMD Opportunities**:
- ✅ **Spectral averaging**: Vectorize bin-wise averaging across multiple spectra
- ✅ **Power spectral density**: `sum(|FFT|^2)` with SIMD complex arithmetic
- ✅ **Log scale conversion**: Batch `10*log10(x)` operations

**Estimated Speedup**: 2-4x

**Impact**: **MEDIUM-HIGH** - Used in voice quality assessment

**Implementation Priority**: Phase 2

---

#### 9. **Audio Filtering** ⭐⭐⭐⭐
**Location**: Praat sound filtering functions (called from `sound_wrappers.cpp`)

**Gemini Analysis**:
> "These filtering operations apply a filter kernel to the sound data, which is a convolution operation. Convolution involves sliding window multiplications and additions, a perfect candidate for Fused Multiply-Add (FMA) instructions available through SIMD."

**SIMD Opportunities**:
- ✅ **FIR filtering**: Vectorize `y[n] = sum(h[k] * x[n-k])`
- ✅ **FMA operations**: Use `xsimd::fma(a, b, c)` for `a*b + c`
- ✅ **Batch processing**: Process multiple output samples simultaneously

**Estimated Speedup**: 2-4x

**Impact**: **MEDIUM** - Used in preprocessing pipelines

**Implementation Priority**: Phase 3

---

#### 10. **Sound Mixing and Scaling** ⭐⭐⭐⭐
**Location**: `src/sound_wrappers.cpp:705-737, 849-935`

**Current Implementation**:
```cpp
// Scale intensity
void sound_scale_intensity(XPtr<structSound> xptr, double new_intensity_db) {
    Sound_scaleIntensity(sound, new_intensity_db);
}

// Mix sounds with balance
for (integer i = 1; i <= nx; i++) {
    // ... extract val1, val2 ...
    mixed->z[ich][i] = (val1 + balance * val2) / (1.0 + balance);
}
```

**Gemini Analysis**:
> "These functions perform simple element-wise multiplication of the sound's samples by a constant factor. This is one of the most basic and effective SIMD operations."

**SIMD Opportunities**:
- ✅ **Scalar multiplication**: `x * scale_factor` for entire array
- ✅ **Weighted sum**: `(a + k*b) / (1+k)` vectorized
- ✅ **FMA for mixing**: Use `xsimd::fma()` for efficient `k*b` computation

**Estimated Speedup**:
- Gemini: 4-8x (for amplify/multiply)
- Manual: 4-6x (for mixing)

**Impact**: **MEDIUM** - Used in audio composition and normalization

**Implementation Priority**: Phase 1-2

---

## Additional Optimization Opportunities

### 11. **LPC Coefficient Conversion**
**Location**: `src/lpc_wrappers.cpp`

**Gemini Analysis**:
> "This function converts LPC coefficients to reflection coefficients. The conversion involves loops with arithmetic operations that can be vectorized. While the algorithm (Schur recursion) has some dependencies, parts of the inner loops are often parallelizable."

**Estimated Speedup**: 2-3x
**Priority**: Phase 3 (lower frequency operation)

---

### 12. **Matrix Multiplication**
**Location**: `src/matrix_wrappers.cpp` (if implemented)

**Gemini Analysis**:
> "Standard matrix multiplication is computationally intensive and a classic example where SIMD can provide substantial speedups by vectorizing the inner loop's dot product calculation."

**Estimated Speedup**: 3-6x
**Priority**: Phase 2-3 (depends on usage frequency)

---

### 13. **DataFrame Assembly**
**Location**: `src/sound_wrappers.cpp:478-504`

**Current Implementation**:
```cpp
int row = 0;
for (int ch = 1; ch <= n_channels; ch++) {
    for (int i = 1; i <= n_samples; i++) {
        time[row] = sound->x1 + (i - 1) * sound->dx;
        channel[row] = ch;
        value[row] = sound->z[ch][i];
        row++;
    }
}
```

**SIMD Opportunities**:
- ✅ **Time vector generation**: Vectorize `x1 + (i-1)*dx`
- ✅ **Broadcast operations**: Use `xsimd::broadcast()` for channel assignment
- ⚠️ **Scatter stores**: Non-contiguous writes may limit gains

**Estimated Speedup**: 2-4x

**Priority**: Phase 2

---

## Implementation Strategy

### Phase 1: Foundation (Weeks 1-2) - Low-Hanging Fruit
**Goal**: Establish SIMD infrastructure and validate approach with high-impact, low-complexity targets

#### Tasks:
1. **Add RcppXsimd dependency**
   - Update `DESCRIPTION`: Add `LinkingTo: RcppXsimd`
   - Update `src/Makevars`: Add C++14 requirement (minimum for xsimd)
   - Create test suite for SIMD vs scalar validation

2. **Implement matrix operations** (`matrix_wrappers.cpp`)
   - `matrix_get_sum()` → SIMD version
   - `matrix_get_mean()` → SIMD version
   - `matrix_get_minimum()` → SIMD version
   - `matrix_get_maximum()` → SIMD version
   - Single-pass combined statistics function

3. **Implement data conversion** (`sound_wrappers.cpp`, `matrix_wrappers.cpp`)
   - `sound_create_from_values()` → SIMD bulk copy
   - `sound_as_matrix()` → SIMD bulk copy
   - `matrix_to_r_matrix()` → SIMD bulk copy
   - `matrix_from_r_matrix()` → SIMD bulk copy

4. **Implement tone generation** (`sound_wrappers.cpp`)
   - `sound_create_tone()` → Vectorized sine function

5. **Benchmarking**
   - Create microbenchmarks using `Rcpp::benchmark()`
   - Test with various matrix/sound sizes
   - Measure speedup across different CPUs

**Deliverables**:
- Working SIMD implementations for 3-4 key functions
- Benchmark suite demonstrating 3-5x speedups
- Documentation of SIMD patterns for future use

**Estimated Effort**: 1-2 weeks
**Expected Speedup**: 3-5x for targeted operations

---

### Phase 2: Medium Complexity (Weeks 3-5)
**Goal**: Extend SIMD to signal processing and acoustic analysis functions

#### Tasks:
1. **Intensity calculations**
   - Implement SIMD RMS computation
   - Replace Praat's `Sound_getRootMeanSquare()` with vectorized version
   - Vectorize `Sound_getEnergy()` and `Sound_getPower()`

2. **Sound mixing and scaling**
   - `sound_scale_peak()` → SIMD scalar multiplication
   - `sound_mix()` → SIMD weighted sum
   - `sound_concatenate()` → Optimize memory operations

3. **Spectrogram export**
   - `spectrogram_as_matrix()` → SIMD data reorganization
   - Consider transpose optimization

4. **DataFrame assembly**
   - Vectorize time vector generation
   - Optimize multi-column assembly

5. **LPC/Formant preprocessing**
   - Identify vectorizable components in autocorrelation
   - Implement SIMD pre-emphasis filter

**Deliverables**:
- 6-8 additional SIMD-optimized functions
- Benchmark suite for signal processing operations
- Integration tests with real phonetic analysis workflows

**Estimated Effort**: 2-3 weeks
**Expected Speedup**: 2-4x for signal processing operations

---

### Phase 3: Advanced (Weeks 6-10) - Complex Algorithms
**Goal**: Tackle FFT, formant extraction, and pitch detection

#### Tasks:
1. **FFT evaluation**
   - Evaluate Praat's built-in FFT performance
   - Consider FFTW integration (license permitting)
   - Implement SIMD window functions (Hamming, Hanning, etc.)
   - Optimize FFT pre/post-processing (data shuffling)

2. **Formant extraction**
   - Vectorize LPC autocorrelation loops
   - Optimize Burg's algorithm inner loops
   - Benchmark against current implementation

3. **Pitch detection**
   - Vectorize autocorrelation method
   - Optimize lag computation loops
   - Implement SIMD peak detection

4. **Filtering operations**
   - Vectorize FIR filtering with FMA
   - Implement SIMD convolution kernels

5. **LTAS generation**
   - Vectorize spectral averaging
   - Optimize power spectral density computation

**Deliverables**:
- Complete SIMD coverage of core phonetic analysis functions
- End-to-end pipeline benchmarks
- Performance comparison report vs Python Parselmouth

**Estimated Effort**: 3-5 weeks
**Expected Speedup**: 2-4x for complete analysis pipelines

---

## Technical Implementation Details

### Integration with RcppXsimd

#### 1. Package Setup

**DESCRIPTION**:
```r
Package: speaker
LinkingTo: Rcpp, RcppXsimd
Imports: Rcpp
SystemRequirements: C++14
```

**src/Makevars**:
```makefile
CXX_STD = CXX14
PKG_CXXFLAGS = $(SHLIB_OPENMP_CXXFLAGS)
PKG_LIBS = $(SHLIB_OPENMP_CXXFLAGS)
```

**src/Makevars.win**:
```makefile
CXX_STD = CXX14
```

---

#### 2. SIMD Pattern Examples

**Pattern A: Horizontal Reduction (Sum, Min, Max)**

```cpp
#include <xsimd/xsimd.hpp>

// [[Rcpp::export]]
double matrix_sum_simd(Rcpp::NumericMatrix mat) {
    using batch = xsimd::batch<double>;
    constexpr size_t simd_size = batch::size;

    double sum = 0.0;
    const int nrow = mat.nrow();
    const int ncol = mat.ncol();

    for (int i = 0; i < nrow; ++i) {
        const double* row_data = &mat(i, 0);

        // SIMD accumulation
        batch acc(0.0);
        int j = 0;
        for (; j + simd_size <= ncol; j += simd_size) {
            batch b = xsimd::load_unaligned(&row_data[j]);
            acc += b;
        }
        sum += xsimd::reduce_add(acc);

        // Remainder loop
        for (; j < ncol; ++j) {
            sum += row_data[j];
        }
    }
    return sum;
}
```

**Pattern B: Element-wise Operations (Map)**

```cpp
// [[Rcpp::export]]
Rcpp::NumericVector vector_scale_simd(Rcpp::NumericVector x, double scale) {
    using batch = xsimd::batch<double>;
    constexpr size_t simd_size = batch::size;

    const int n = x.size();
    Rcpp::NumericVector result(n);

    batch scale_batch(scale);

    int i = 0;
    for (; i + simd_size <= n; i += simd_size) {
        batch x_batch = xsimd::load_unaligned(&x[i]);
        batch result_batch = x_batch * scale_batch;
        xsimd::store_unaligned(&result[i], result_batch);
    }

    // Remainder
    for (; i < n; ++i) {
        result[i] = x[i] * scale;
    }

    return result;
}
```

**Pattern C: Transcendental Functions (Sin, Cos, Exp, Log)**

```cpp
// [[Rcpp::export]]
Rcpp::NumericVector vectorized_sin(Rcpp::NumericVector x) {
    using batch = xsimd::batch<double>;
    constexpr size_t simd_size = batch::size;

    const int n = x.size();
    Rcpp::NumericVector result(n);

    int i = 0;
    for (; i + simd_size <= n; i += simd_size) {
        batch x_batch = xsimd::load_unaligned(&x[i]);
        batch result_batch = xsimd::sin(x_batch);  // Uses SVML on Intel
        xsimd::store_unaligned(&result[i], result_batch);
    }

    // Remainder
    for (; i < n; ++i) {
        result[i] = std::sin(x[i]);
    }

    return result;
}
```

**Pattern D: Fused Multiply-Add (FMA)**

```cpp
// [[Rcpp::export]]
double dot_product_simd(Rcpp::NumericVector x, Rcpp::NumericVector y) {
    using batch = xsimd::batch<double>;
    constexpr size_t simd_size = batch::size;

    const int n = std::min(x.size(), y.size());

    batch acc(0.0);
    int i = 0;
    for (; i + simd_size <= n; i += simd_size) {
        batch x_batch = xsimd::load_unaligned(&x[i]);
        batch y_batch = xsimd::load_unaligned(&y[i]);
        acc = xsimd::fma(x_batch, y_batch, acc);  // acc += x * y
    }

    double result = xsimd::reduce_add(acc);

    // Remainder
    for (; i < n; ++i) {
        result += x[i] * y[i];
    }

    return result;
}
```

---

### 3. Memory Alignment Considerations

**Issue**: Praat's memory allocation may not guarantee 16/32-byte alignment required for optimal SIMD performance.

**Solution 1**: Use `xsimd::load_unaligned()` / `xsimd::store_unaligned()`
- **Pros**: Works with any memory layout, safe
- **Cons**: ~10% performance penalty vs aligned loads

**Solution 2**: Check alignment and branch
```cpp
bool is_aligned = (reinterpret_cast<uintptr_t>(ptr) % sizeof(batch) == 0);
if (is_aligned) {
    batch b = xsimd::load_aligned(ptr);
} else {
    batch b = xsimd::load_unaligned(ptr);
}
```

**Recommendation**: Start with unaligned operations, profile, then optimize hot paths with alignment checks.

---

### 4. CPU Capability Detection

RcppXsimd automatically detects CPU capabilities at compile time:
- **SSE2**: 2 doubles per vector (baseline, available on all x86-64)
- **AVX**: 4 doubles per vector (Intel Sandy Bridge+, AMD Bulldozer+)
- **AVX2**: 4 doubles + FMA (Intel Haswell+, AMD Excavator+)
- **AVX512**: 8 doubles per vector (Intel Skylake-X+, AMD Zen 4+)

**No runtime detection needed** - xsimd selects best instruction set at compile time.

For **cross-platform packages**, compile with `-march=native` on user's machine:
```makefile
PKG_CXXFLAGS = -march=native
```

---

## Benchmarking Strategy

### Test Suite Design

#### 1. Microbenchmarks (Operation-Level)

**Purpose**: Measure speedup for individual SIMD functions

**Test Cases**:
```r
# Matrix operations
bench::mark(
  scalar = matrix_sum_scalar(mat_1000x1000),
  simd   = matrix_sum_simd(mat_1000x1000),
  check = TRUE,
  iterations = 1000
)

# Sound operations
bench::mark(
  scalar = sound_create_tone_scalar(1.0, 44100, 440, 1.0),
  simd   = sound_create_tone_simd(1.0, 44100, 440, 1.0),
  check = TRUE
)
```

**Metrics**:
- Median execution time
- Speedup ratio (scalar / simd)
- Memory bandwidth utilization
- CPU cache hit rates (via `perf`)

---

#### 2. Integration Tests (Pipeline-Level)

**Purpose**: Measure real-world performance gains in complete workflows

**Test Scenarios**:

**Scenario 1: Formant Extraction Pipeline**
```r
# Load 10-minute speech recording
sound <- Sound$new("speech_10min.wav")

bench::mark(
  baseline = {
    formants <- sound$to_formant_burg(0.01, 5, 5500, 0.025, 50)
    df <- formants$as_data_frame()
  },
  simd_optimized = {
    formants <- sound$to_formant_burg_simd(0.01, 5, 5500, 0.025, 50)
    df <- formants$as_data_frame_simd()
  },
  iterations = 10
)
```

**Scenario 2: Spectrogram Analysis**
```r
bench::mark(
  baseline = {
    spec <- sound$to_spectrogram(0.005, 5000, 0.002, 20, "Gaussian")
    mat <- spec$as_matrix()
    power_mean <- mean(mat, na.rm = TRUE)
  },
  simd_optimized = {
    spec <- sound$to_spectrogram(0.005, 5000, 0.002, 20, "Gaussian")
    mat <- spec$as_matrix_simd()
    power_mean <- matrix_mean_simd(mat)
  }
)
```

**Scenario 3: Batch Processing**
```r
# Process 100 audio files
files <- list.files("corpus/", pattern = "*.wav", full.names = TRUE)

system.time({
  results <- lapply(files, function(f) {
    sound <- Sound$new(f)
    pitch <- sound$to_pitch()
    pitch$get_mean()
  })
})
```

---

#### 3. Validation Tests (Numerical Accuracy)

**Purpose**: Ensure SIMD operations produce identical results to scalar versions

**Test Pattern**:
```r
test_that("SIMD matrix sum matches scalar", {
  mat <- matrix(rnorm(1000*1000), 1000, 1000)

  scalar_result <- matrix_sum_scalar(mat)
  simd_result <- matrix_sum_simd(mat)

  expect_equal(scalar_result, simd_result, tolerance = 1e-12)
})

test_that("SIMD formant extraction matches Praat", {
  sound <- Sound$new("test_audio.wav")

  # Compare against known Praat output
  praat_output <- read.table("test_audio_formants.txt")

  formants <- sound$to_formant_burg_simd(...)
  r_output <- formants$as_data_frame()

  expect_equal(r_output$F1, praat_output$F1, tolerance = 1e-6)
  expect_equal(r_output$F2, praat_output$F2, tolerance = 1e-6)
})
```

---

### Benchmark Environment

**Hardware Requirements**:
- **Intel CPU**: For AVX2/AVX512 testing
- **AMD CPU**: For platform compatibility validation
- **Apple Silicon (M1/M2)**: For ARM NEON testing

**Software**:
- R 4.0+
- RcppXsimd 0.1.2+
- bench package for accurate timing
- perf (Linux) or Instruments (macOS) for profiling

---

### Expected Results

#### Microbenchmark Results (Projected)

| Operation | Scalar Time | SIMD Time | Speedup | Impact |
|-----------|-------------|-----------|---------|--------|
| Matrix sum (1000x1000) | 2.5 ms | 0.4 ms | **6.2x** | Very High |
| Matrix min/max | 2.3 ms | 0.5 ms | **4.6x** | Very High |
| Tone generation (1s @ 44.1kHz) | 8.2 ms | 1.8 ms | **4.6x** | High |
| Data conversion (1M samples) | 12.0 ms | 2.1 ms | **5.7x** | Very High |
| RMS calculation (1M samples) | 15.0 ms | 3.5 ms | **4.3x** | High |
| Sound mixing (1M samples) | 18.0 ms | 3.8 ms | **4.7x** | Medium |

---

#### End-to-End Pipeline Results (Projected)

| Workflow | Baseline | SIMD-Optimized | Speedup | Notes |
|----------|----------|----------------|---------|-------|
| 10-min formant extraction | 45 s | 18 s | **2.5x** | Dominated by LPC |
| Spectrogram (10-min audio) | 32 s | 11 s | **2.9x** | FFT-heavy |
| Intensity analysis (100 files) | 28 s | 9 s | **3.1x** | Simple operations |
| Full acoustic analysis | 120 s | 45 s | **2.7x** | Mixed workload |

**Note**: End-to-end speedups are lower than microbenchmarks due to Amdahl's Law (non-parallelizable overhead).

---

## Risk Assessment and Mitigation

### Risk 1: Memory Alignment Issues ⚠️

**Issue**: Praat's memory allocation may not align to 16/32-byte boundaries required for optimal SIMD performance.

**Impact**:
- Aligned loads/stores: Best performance
- Unaligned loads/stores: ~10% slower but still faster than scalar

**Mitigation**:
✅ Use `xsimd::load_unaligned()` / `xsimd::store_unaligned()` by default
✅ Profile hot paths and add alignment checks if needed
✅ Document alignment requirements for future Praat updates

**Severity**: LOW (unaligned SIMD still provides 3-4x speedup)

---

### Risk 2: Praat Source Code Modifications ⚠️⚠️

**Issue**: Some optimizations require modifying Praat's C++ code, complicating upgrades.

**Impact**:
- Harder to sync with upstream Praat updates
- Potential merge conflicts
- Maintenance burden

**Mitigation**:
✅ **Preferred**: Create wrapper functions without modifying Praat source
✅ **If needed**: Minimize changes, document clearly, submit patches upstream
✅ Track Praat version in `inst/include/praat/VERSION.txt`
⚠️ **Avoid**: Deep modifications to Praat algorithms

**Severity**: MEDIUM

---

### Risk 3: Platform Compatibility 🔧

**Issue**: SIMD instruction sets vary by CPU (SSE2, AVX, AVX2, AVX512, NEON).

**Impact**:
- Code compiled for AVX2 won't run on older CPUs
- ARM CPUs (Apple Silicon) use NEON, not AVX

**Mitigation**:
✅ RcppXsimd **automatically handles** ISA detection at compile time
✅ Provides fallback to scalar code on unsupported platforms
✅ Test on multiple architectures:
  - Intel x86-64 (SSE2, AVX, AVX2)
  - AMD x86-64 (SSE2, AVX, AVX2)
  - ARM64 (NEON) - Apple M1/M2, AWS Graviton

**Severity**: LOW (RcppXsimd handles automatically)

---

### Risk 4: Numerical Precision Differences 🔬

**Issue**: SIMD operations may produce slightly different results due to:
- Different order of operations (IEEE 754 non-associativity)
- Compiler optimizations
- FMA (fused multiply-add) vs separate operations

**Example**:
```cpp
// Scalar: (a * b) + c → rounding after multiply, then after add
double result = a * b + c;

// FMA: (a * b) + c → single rounding step
double result_fma = fma(a, b, c);  // Slightly different result
```

**Impact**: Differences typically < 1e-12 (machine epsilon)

**Mitigation**:
✅ Add comprehensive unit tests with tolerance checks
✅ Use `expect_equal(..., tolerance = 1e-10)` in tests
✅ Document known differences in vignettes
✅ Validate against Praat desktop output

**Severity**: LOW (acceptable for phonetic analysis)

---

### Risk 5: Compilation Complexity 🛠️

**Issue**: C++14 requirement and SIMD intrinsics may cause compilation issues on some systems.

**Impact**:
- Windows users with old Rtools
- Legacy Linux systems with GCC < 5.0
- Exotic platforms

**Mitigation**:
✅ Require R 4.0+ (ensures modern compiler)
✅ Provide clear error messages in `configure` script
✅ Document system requirements in README
✅ Test on CRAN build systems before submission

**Severity**: MEDIUM (may exclude some users)

---

### Risk 6: Development and Maintenance Effort 👨‍💻

**Issue**: SIMD optimization adds code complexity and maintenance burden.

**Impact**:
- Longer development time (6-10 weeks)
- Harder to debug SIMD code
- Need to maintain both scalar and SIMD paths

**Mitigation**:
✅ Follow phased approach (start with easy wins)
✅ Create SIMD pattern library for reuse
✅ Comprehensive test coverage (>90%)
✅ Document SIMD implementations thoroughly
✅ Use profiling tools (perf, valgrind) for validation

**Severity**: MEDIUM (manageable with good planning)

---

## Comparison with Other Approaches

### Alternative 1: Parallelization with OpenMP

**Approach**: Use `#pragma omp parallel for` to parallelize loops across CPU cores.

**Pros**:
- Easier to implement than SIMD
- Can utilize multiple cores
- Good for embarrassingly parallel tasks

**Cons**:
- Higher overhead (thread creation/synchronization)
- Less effective for small arrays
- Doesn't leverage within-core parallelism

**Performance**:
- Best for: Batch processing of multiple files
- Speedup: 2-4x on quad-core, 4-8x on octa-core
- **Complements SIMD**: Can combine both approaches

**Recommendation**: Consider OpenMP for batch operations, SIMD for inner loops.

---

### Alternative 2: GPU Acceleration (CUDA/OpenCL)

**Approach**: Offload computations to GPU via CUDA or OpenCL.

**Pros**:
- Massive parallelism (1000s of cores)
- Excellent for large-scale matrix operations
- Potential 10-100x speedup for suitable workloads

**Cons**:
- Requires GPU hardware
- High memory transfer overhead (CPU ↔ GPU)
- Complex setup and debugging
- Not available on all systems (e.g., headless servers)
- Overkill for phonetic analysis workloads

**Performance**:
- Best for: Massive matrix operations (>10,000 x 10,000)
- Speedup: 10-100x (if memory transfer is not bottleneck)

**Recommendation**: Not recommended for speaker package (overhead outweighs benefits).

---

### Alternative 3: Call External Optimized Libraries

**Approach**: Replace Praat implementations with highly optimized libraries:
- **FFTW**: Fastest FFT library (supports SIMD, multi-threading)
- **Intel MKL**: Optimized BLAS/LAPACK operations
- **Eigen**: C++ matrix library with SIMD support

**Pros**:
- Mature, battle-tested implementations
- Often hand-optimized in assembly
- Excellent performance

**Cons**:
- Licensing issues (MKL is proprietary, FFTW is GPL)
- Large dependencies (MKL is ~500 MB)
- May break compatibility with Praat

**Performance**:
- FFTW: 20-50% faster than Praat's FFT
- MKL: 2-5x faster for matrix operations

**Recommendation**:
- ✅ Consider FFTW for FFT operations (if GPL-compatible)
- ⚠️ Avoid MKL (proprietary, large dependency)
- ⚠️ Avoid Eigen (unnecessary complexity, Praat works well)

---

### Recommended Hybrid Approach

**Optimal Strategy**: Combine multiple techniques

1. **SIMD (RcppXsimd)**: For inner loops and array operations ← **Primary focus**
2. **OpenMP**: For batch file processing (optional Phase 4)
3. **FFTW**: Replace Praat's FFT if license permits (Phase 3)
4. **GPU**: Not recommended for this use case

---

## Licensing Considerations

### RcppXsimd License
- **License**: MIT
- **Compatibility**: ✅ Compatible with GPL-3 (Praat's license)
- **Distribution**: No restrictions

### FFTW License (if considered)
- **License**: GPL-2 or GPL-3
- **Compatibility**: ✅ Compatible with GPL-3
- **Concern**: GPL is viral (entire package becomes GPL)
- **Current Status**: speaker package is GPL-3 (Praat requirement)
- **Conclusion**: ✅ FFTW is compatible

### Intel MKL License
- **License**: Proprietary (Intel Simplified Software License)
- **Compatibility**: ❌ Not compatible with GPL-3
- **Conclusion**: Cannot use without relicensing entire package

---

## Deliverables and Documentation

### Code Deliverables

1. **SIMD-optimized functions**
   - `src/simd/` directory with implementations
   - Clear separation from Praat source code

2. **Test suite**
   - `tests/testthat/test-simd-*.R`
   - Validation against scalar versions
   - Benchmark suite

3. **Build configuration**
   - Updated `DESCRIPTION`, `Makevars`, `configure`
   - Cross-platform compilation support

---

### Documentation Deliverables

1. **Technical vignette**: "SIMD Optimization in speaker" (`vignettes/simd-optimization.Rmd`)
   - How SIMD works
   - Performance benchmarks
   - When to expect speedups

2. **Developer guide**: "Adding SIMD to New Functions" (`SIMD_PATTERNS.md`)
   - Code patterns and examples
   - Common pitfalls
   - Testing strategies

3. **Benchmark report**: `SIMD_BENCHMARKS.md`
   - Microbenchmark results
   - End-to-end pipeline comparisons
   - Hardware-specific results

4. **Migration notes**: For future Praat updates
   - Which files were modified
   - How to resolve conflicts
   - Testing checklist

---

## Conclusion and Recommendations

### Summary of Findings

The **speaker** package presents **excellent opportunities** for SIMD optimization with RcppXsimd:

✅ **High-impact targets identified**: Matrix operations, data conversion, signal generation, intensity calculations
✅ **Significant speedup potential**: 2-8x for individual operations, 2-4x for end-to-end pipelines
✅ **Low implementation risk**: RcppXsimd handles platform compatibility automatically
✅ **Clear development path**: Phased approach from easy wins to complex optimizations

---

### Recommendations

#### Immediate Actions (Next 1-2 weeks)

1. ✅ **Add RcppXsimd to package dependencies**
2. ✅ **Implement Phase 1 optimizations** (matrix ops, data conversion, tone generation)
3. ✅ **Create benchmark suite** to validate speedups
4. ✅ **Test on multiple platforms** (Intel, AMD, ARM)

#### Short-term Goals (Months 1-2)

1. ✅ **Complete Phase 2 optimizations** (intensity, mixing, spectrogram export)
2. ✅ **Write technical vignette** documenting SIMD performance
3. ✅ **Expand test coverage** to >90% for SIMD functions

#### Long-term Goals (Months 3-6)

1. ⚠️ **Evaluate Phase 3 optimizations** (FFT, formant extraction, pitch detection)
2. ⚠️ **Consider FFTW integration** for FFT operations
3. ⚠️ **Add OpenMP support** for batch processing (optional)
4. ✅ **Publish performance comparison** vs Python Parselmouth

---

### Success Metrics

**Target Performance Gains**:
- ✅ Matrix operations: **4-8x faster**
- ✅ Data conversion: **4-8x faster**
- ✅ Signal generation: **4-6x faster**
- ✅ Intensity calculations: **3-5x faster**
- ✅ End-to-end pipelines: **2-4x faster**

**Quality Metrics**:
- ✅ All tests pass with <1e-10 tolerance
- ✅ No memory leaks (valgrind clean)
- ✅ Compilation succeeds on Windows, macOS, Linux
- ✅ CRAN checks pass

---

### Final Verdict

**Proceed with SIMD optimization using RcppXsimd.** The expected performance gains (2-4x for complete workflows) justify the development effort (6-10 weeks). Start with Phase 1 to validate the approach and build momentum before tackling more complex optimizations.

---

## Appendix: Reference Materials

### A. RcppXsimd Resources

- **GitHub**: https://github.com/OHDSI/RcppXsimd
- **Documentation**: https://ohdsi.github.io/RcppXsimd/
- **xsimd library**: https://github.com/xtensor-stack/xsimd

### B. SIMD Intrinsics References

- **Intel Intrinsics Guide**: https://www.intel.com/content/www/us/en/docs/intrinsics-guide/
- **ARM NEON Guide**: https://developer.arm.com/architectures/instruction-sets/simd-isas/neon

### C. Profiling Tools

- **Linux perf**: `perf record -g ./Rscript benchmark.R`
- **macOS Instruments**: Xcode → Open Developer Tool → Instruments
- **Valgrind**: `R -d valgrind --tool=callgrind -f benchmark.R`
- **Oprofile**: System-wide profiler for Linux

### D. Benchmark Tools

- R packages: `bench`, `microbenchmark`, `rbenchmark`
- External: Google Benchmark, Catch2 Benchmark

---

**Report prepared by**: Claude (Anthropic)
**Date**: 2025-11-12
**Contact**: File issues at https://github.com/humlab-speech/speaker
