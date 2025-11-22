# SIMD Optimization Plan: Minor Targets

**Date**: 2025-01-22
**Package**: speaker
**Technology**: RcppXsimd + xsimd library
**Purpose**: Secondary optimization opportunities beyond the main plan

---

## Executive Summary

This document catalogs **minor SIMD optimization targets** - functions that are called less frequently or have smaller performance impact than the main priorities, but still offer meaningful speedup opportunities. These targets are suitable for:

1. **Phase 4 implementation** (after main priorities are complete)
2. **Incremental improvements** during maintenance
3. **Specialized use cases** where specific operations dominate runtime
4. **Completeness** to maximize overall package performance

**Coverage**: 35+ additional functions across 8 Praat modules
**Estimated Total Speedup**: 1.2-1.5x additional improvement over main plan
**Implementation Complexity**: Varies from EASY to MODERATE
**Priority**: SECONDARY (implement after main SIMD plan)

---

## Organization by Module

This plan organizes targets by Praat module (Formant, Intensity, Harmonicity, Spectrum, Ltas, Matrix, PointProcess, and Miscellaneous) rather than by operation type.

---

## Category 1: Formant Analysis Operations

**Module**: `src/praat.github.io/fon/Formant.cpp`
**Usage Frequency**: MEDIUM (formant tracking is common but not continuous)
**New File**: `src/formant_analysis_simd.cpp`

### 1.1 Formant Standard Deviation

**Function**: `Formant_getStandardDeviation`
**Operation**: Statistical reduction (variance calculation)
**Array Size**: 100-1000 frames

**Current Implementation**:
```cpp
for (integer iframe = ixmin; iframe <= ixmax; iframe++) {
    const double f = Formant_getValueAtTime(...);
    sum += (f - mean) * (f - mean);
}
```

**SIMD Strategy**:
```cpp
using batch = xsimd::batch<double>;
batch mean_vec(mean);
batch acc(0.0);

for (; i + simd_size <= n; i += simd_size) {
    batch f = xsimd::load_unaligned(&frequencies[i]);
    batch diff = f - mean_vec;
    acc = xsimd::fma(diff, diff, acc);  // sum += diff^2
}
double variance = xsimd::reduce_add(acc);
```

**SIMD Potential**: ⭐⭐⭐ HIGH
**Estimated Speedup**: 4-8x
**Conversion Complexity**: EASY
**Priority**: MEDIUM (useful for formant quality assessment)

---

### 1.2 Formant Maximum Intensity Finding

**Function**: `Formant_drawSpeckles_inside`
**Operation**: Max reduction across frames
**Array Size**: 100-1000 frames

**Current Implementation**:
```cpp
double maximumIntensity = 0.0;
for (integer iframe = 1; iframe <= my nx; iframe++) {
    const double intensity = my frames[iframe].intensity;
    if (intensity > maximumIntensity)
        maximumIntensity = intensity;
}
```

**SIMD Strategy**:
```cpp
using batch = xsimd::batch<double>;
batch max_vec(0.0);

for (; i + simd_size <= nx; i += simd_size) {
    batch intensities = xsimd::load_unaligned(&intensity_array[i]);
    max_vec = xsimd::max(max_vec, intensities);
}
double maximum = xsimd::reduce_max(max_vec);
```

**SIMD Potential**: ⭐⭐⭐ HIGH
**Estimated Speedup**: 4-8x
**Conversion Complexity**: EASY
**Priority**: LOW (visualization function, not analysis-critical)

---

### 1.3 Formant Extrema (Min/Max with Gather)

**Function**: `Formant_getExtrema`
**Operation**: Min/max reduction with non-contiguous access
**Array Size**: 100-1000 frames

**Current Implementation**:
```cpp
for (integer iframe = ixmin; iframe <= ixmax; iframe++) {
    const double f = frame->formant[iformant].frequency;
    if (f < minimum) minimum = f;
    if (f > maximum) maximum = f;
}
```

**SIMD Strategy**:
```cpp
// Requires gather operation (AVX2+)
using batch = xsimd::batch<double>;
batch min_vec(DBL_MAX);
batch max_vec(-DBL_MAX);

// Gather formant frequencies (stride = sizeof(FormantFrame))
for (; i + simd_size <= n; i += simd_size) {
    // Use gather or manual loading
    batch freqs = gather_formant_frequencies(&frames[i], iformant);
    min_vec = xsimd::min(min_vec, freqs);
    max_vec = xsimd::max(max_vec, freqs);
}
```

**SIMD Potential**: ⭐⭐ MEDIUM (gather operations have overhead)
**Estimated Speedup**: 2-4x (with AVX2 gather)
**Conversion Complexity**: MODERATE (requires gather or manual packing)
**Priority**: LOW

---

### 1.4 Formant Tracker Local Cost

**Function**: `getLocalCost` (within `Formant_tracker`)
**Operation**: Parallel arithmetic on formant candidates
**Array Size**: 5-10 candidates per frame

**Current Implementation**:
```cpp
for (integer iformant = 1; iformant <= numberOfFormants; iformant++) {
    const double df = fabs(freq - ref);
    localCost += dfCost * df + bfCost * bw / freq;
}
```

**SIMD Strategy**:
```cpp
// Vectorize across candidates (small batch size)
using batch = xsimd::batch<double>;

batch freqs = xsimd::load_unaligned(&candidate_freqs[0]);
batch bws = xsimd::load_unaligned(&candidate_bandwidths[0]);
batch refs = xsimd::load_unaligned(&reference_freqs[0]);

batch df = xsimd::abs(freqs - refs);
batch cost = dfCost_vec * df + bfCost_vec * bws / freqs;
```

**SIMD Potential**: ⭐⭐ MEDIUM
**Estimated Speedup**: 2-4x
**Conversion Complexity**: MODERATE (small batch size, requires careful structuring)
**Priority**: MEDIUM (formant tracking is performance-sensitive)

**Note**: May be too small to benefit significantly (only 5-10 elements). Profile before implementing.

---

## Category 2: Intensity Analysis Operations

**Module**: `src/praat.github.io/fon/Intensity.cpp`
**Usage Frequency**: HIGH (intensity frequently computed)
**New File**: `src/intensity_analysis_simd.cpp`

### 2.1 Intensity Average (Energy-based)

**Function**: `Intensity_getAverage`
**Operation**: Element-wise transform (dB → energy) + reduction
**Array Size**: 100-1000 frames

**Current Implementation**:
```cpp
// Energy averaging method
for (integer iframe = ixmin; iframe <= ixmax; iframe++) {
    const double value = my z[1][iframe];
    sum += pow(10.0, 0.1 * value);  // dB to energy
}
longdouble average = sum / numberOfFrames;
// Convert back to dB
result = 10.0 * log10(average);
```

**SIMD Strategy**:
```cpp
using batch = xsimd::batch<double>;
batch scale(0.1);
batch acc(0.0);

for (; i + simd_size <= n; i += simd_size) {
    batch db_values = xsimd::load_unaligned(&intensity_db[i]);
    batch exponents = scale * db_values;

    // Requires vectorized pow(10, x)
    batch energies = simd_pow10(exponents);  // SLEEF or approximation
    acc += energies;
}
double sum = xsimd::reduce_add(acc);
```

**SIMD Potential**: ⭐⭐⭐ HIGH (if vectorized pow available)
**Estimated Speedup**: 4-8x
**Conversion Complexity**: MODERATE-HARD (requires SLEEF or polynomial approximation for pow)
**Priority**: MEDIUM-HIGH
**Dependency**: Requires vectorized math library (SLEEF recommended)

---

### 2.2 Intensity Min/Max Finding

**Function**: `Intensity_drawInside` → `Matrix_getWindowExtrema`
**Operation**: Min/max reduction
**Array Size**: 100-1000 frames

**Current Implementation**:
```cpp
for (integer i = ixmin; i <= ixmax; i++) {
    double value = my z[1][i];
    if (value < minimum) minimum = value;
    if (value > maximum) maximum = value;
}
```

**SIMD Strategy**:
```cpp
using batch = xsimd::batch<double>;
batch min_vec(DBL_MAX);
batch max_vec(-DBL_MAX);

for (; i + simd_size <= n; i += simd_size) {
    batch values = xsimd::load_unaligned(&data[i]);
    min_vec = xsimd::min(min_vec, values);
    max_vec = xsimd::max(max_vec, values);
}

double minimum = xsimd::reduce_min(min_vec);
double maximum = xsimd::reduce_max(max_vec);
```

**SIMD Potential**: ⭐⭐⭐ HIGH
**Estimated Speedup**: 4-8x
**Conversion Complexity**: EASY
**Priority**: MEDIUM

---

## Category 3: Harmonicity (HNR) Operations

**Module**: `src/praat.github.io/fon/Harmonicity.cpp`
**Usage Frequency**: MEDIUM (voice quality analysis)
**New File**: `src/harmonicity_analysis_simd.cpp`

### 3.1 Extract Sounding Values (Stream Compaction)

**Function**: `Harmonicity_getSoundingValues`
**Operation**: Filter/compact array (keep non-NaN values)
**Array Size**: 100-1000 frames

**Current Implementation**:
```cpp
for (integer i = 1; i <= my nx; i++) {
    if (isdefined(my z[1][i])) {
        result[count++] = my z[1][i];
    }
}
```

**SIMD Strategy**:
```cpp
// Stream compaction using SIMD (complex but powerful)
using batch = xsimd::batch<double>;
using mask = typename batch::batch_bool_type;

for (; i + simd_size <= nx; i += simd_size) {
    batch values = xsimd::load_unaligned(&data[i]);

    // Create mask for defined values (not NaN)
    mask is_defined = !xsimd::isnan(values);

    // Compress: keep only valid values
    // This is complex - may need AVX-512 compress or permute tricks
    compact_and_store(values, is_defined, &output[out_idx]);
}
```

**SIMD Potential**: ⭐⭐⭐ HIGH (with AVX-512 compress instruction)
**Estimated Speedup**: 3-8x
**Conversion Complexity**: HARD (stream compaction is algorithmically complex)
**Priority**: MEDIUM
**Note**: Most beneficial on AVX-512 (with `vpcompressd`). On older SIMD, use predicated stores.

**Alternative Approach** (easier):
```cpp
// Simpler: Use masked store (predicated write)
for (; i + simd_size <= nx; i += simd_size) {
    batch values = xsimd::load_unaligned(&data[i]);
    mask is_defined = !xsimd::isnan(values);

    // Store only valid elements (requires scatter or loop)
    store_if(values, is_defined, &output[out_idx]);
}
```

---

### 3.2 Harmonicity Statistics (Mean, StdDev)

**Function**: `Harmonicity_getMean`, `Harmonicity_getStandardDeviation`
**Operation**: Statistical reductions
**Array Size**: 100-1000 sounding frames

**Current Implementation**:
```cpp
// getMean
for (integer i = 1; i <= n; i++)
    sum += values[i];
mean = sum / n;

// getStandardDeviation
for (integer i = 1; i <= n; i++)
    sum += (values[i] - mean) * (values[i] - mean);
```

**SIMD Strategy**:
```cpp
// Same pattern as general statistical reductions
using batch = xsimd::batch<double>;
batch acc(0.0);

for (; i + simd_size <= n; i += simd_size) {
    batch vals = xsimd::load_unaligned(&values[i]);
    acc += vals;
}
double mean = xsimd::reduce_add(acc) / n;

// Variance
batch mean_vec(mean);
batch var_acc(0.0);
for (; i + simd_size <= n; i += simd_size) {
    batch vals = xsimd::load_unaligned(&values[i]);
    batch diff = vals - mean_vec;
    var_acc = xsimd::fma(diff, diff, var_acc);
}
```

**SIMD Potential**: ⭐⭐⭐ HIGH
**Estimated Speedup**: 4-8x
**Conversion Complexity**: EASY
**Priority**: MEDIUM-HIGH

---

### 3.3 Harmonicity ↔ Matrix Conversion

**Function**: `Harmonicity_to_Matrix`, `Matrix_to_Harmonicity`
**Operation**: Bulk memory copy
**Array Size**: 100-1000 frames

**Current Implementation**:
```cpp
thy z.all() <<= my z.all();  // VEC copy
```

**SIMD Strategy**:
```cpp
// Compiler likely auto-vectorizes, but can be explicit
std::memcpy(dest, src, n * sizeof(double));

// Or explicit SIMD loop
for (; i + simd_size <= n; i += simd_size) {
    batch data = xsimd::load_unaligned(&src[i]);
    xsimd::store_unaligned(&dest[i], data);
}
```

**SIMD Potential**: ⭐⭐⭐ HIGH (but likely already optimized by compiler)
**Estimated Speedup**: 8-16x (over naive loop, but minimal over memcpy)
**Conversion Complexity**: TRIVIAL
**Priority**: LOW (compiler already does this)

---

## Category 4: Spectrum Analysis Operations

**Module**: `src/praat.github.io/fon/Spectrum.cpp`
**Usage Frequency**: MEDIUM-HIGH (FFT, spectral analysis)
**New File**: `src/spectrum_analysis_simd.cpp`

### 4.1 Spectral Power Calculation

**Function**: `structSpectrum::v_getValueAtSample`, `Spectrum_getPowerDensityRange`
**Operation**: Complex magnitude (re² + im²)
**Array Size**: 256-4096 frequency bins

**Current Implementation**:
```cpp
for (integer i = ixmin; i <= ixmax; i++) {
    const double re = my z[1][i];
    const double im = my z[2][i];
    const double power = re * re + im * im;
    sum += power;
}
```

**SIMD Strategy**:
```cpp
using batch = xsimd::batch<double>;
batch acc(0.0);

for (; i + simd_size <= n; i += simd_size) {
    batch re = xsimd::load_unaligned(&real[i]);
    batch im = xsimd::load_unaligned(&imag[i]);

    batch power = xsimd::fma(re, re, im * im);  // re² + im²
    acc += power;
}
```

**SIMD Potential**: ⭐⭐⭐ HIGH
**Estimated Speedup**: 3-4x
**Conversion Complexity**: EASY
**Priority**: HIGH (frequently used)

---

### 4.2 Spectral Band Energy/Density

**Function**: `Spectrum_getBandEnergy`, `Spectrum_getBandDensity`
**Operation**: Summation over frequency range
**Array Size**: Variable (typically 10-500 bins per band)

**Current Implementation**:
```cpp
for (integer i = ixmin; i <= ixmax; i++) {
    sum += Sampled_getValueAtSample(me, i);  // Calls power calc
}
```

**SIMD Strategy**:
- Vectorize the inner power calculation (re² + im²)
- Vectorize the summation

**SIMD Potential**: ⭐⭐⭐ HIGH
**Estimated Speedup**: 3-5x
**Conversion Complexity**: EASY
**Priority**: MEDIUM-HIGH

---

### 4.3 Hann Band Filtering

**Function**: `Spectrum_passHannBand`, `Spectrum_stopHannBand`
**Operation**: Element-wise multiplication with filter coefficients
**Array Size**: 256-4096 bins

**Current Implementation**:
```cpp
for (integer i = 1; i <= my nx; i++) {
    const double f = my x1 + (i - 1) * my dx;
    const double factor = 0.5 * (1.0 + cos(NUMpi * (f - fmid) / fWidth));
    my z[1][i] *= factor;  // Real part
    my z[2][i] *= factor;  // Imaginary part
}
```

**SIMD Strategy**:
```cpp
using batch = xsimd::batch<double>;

// Vectorize factor calculation (requires vectorized cos)
for (; i + simd_size <= nx; i += simd_size) {
    batch freqs = compute_frequencies(i);  // Vectorize f calculation
    batch angles = pi_vec * (freqs - fmid_vec) / fWidth_vec;
    batch cos_vals = simd_cos(angles);  // SLEEF or polynomial
    batch factors = half_vec * (one_vec + cos_vals);

    // Apply to real and imaginary parts
    batch re = xsimd::load_unaligned(&real[i]);
    batch im = xsimd::load_unaligned(&imag[i]);

    re *= factors;
    im *= factors;

    xsimd::store_unaligned(&real[i], re);
    xsimd::store_unaligned(&imag[i], im);
}
```

**SIMD Potential**: ⭐⭐⭐ HIGH (with vectorized cos)
**Estimated Speedup**: 3-5x
**Conversion Complexity**: MODERATE (requires vectorized cos - SLEEF)
**Priority**: MEDIUM
**Dependency**: SLEEF or polynomial approximation for cos

---

### 4.4 Spectral Moments (Centre of Gravity, Central Moment)

**Function**: `Spectrum_getCentreOfGravity`, `Spectrum_getCentralMoment`
**Operation**: Weighted reduction (sum of f × E, sum of (f-fmean)^n × E)
**Array Size**: 256-4096 bins

**Current Implementation**:
```cpp
// Centre of gravity
for (integer i = ixmin; i <= ixmax; i++) {
    const double f = Sampled_indexToX(me, i);
    const double energy = sqr(my z[1][i]) + sqr(my z[2][i]);
    sumEnergy += energy;
    sumFE += f * energy;
}
double centreOfGravity = sumFE / sumEnergy;

// Central moment
for (integer i = ixmin; i <= ixmax; i++) {
    const double f = Sampled_indexToX(me, i);
    const double energy = sqr(my z[1][i]) + sqr(my z[2][i]);
    sum += pow(f - fmean, moment) * energy;
}
```

**SIMD Strategy**:
```cpp
using batch = xsimd::batch<double>;
batch sum_energy(0.0);
batch sum_fe(0.0);

for (; i + simd_size <= n; i += simd_size) {
    // Compute frequencies
    batch freqs = x1_vec + dx_vec * batch_indices(i);

    // Compute energies
    batch re = xsimd::load_unaligned(&real[i]);
    batch im = xsimd::load_unaligned(&imag[i]);
    batch energy = xsimd::fma(re, re, im * im);

    // Accumulate
    sum_energy += energy;
    sum_fe = xsimd::fma(freqs, energy, sum_fe);
}

double total_energy = xsimd::reduce_add(sum_energy);
double weighted_sum = xsimd::reduce_add(sum_fe);
double cog = weighted_sum / total_energy;
```

**SIMD Potential**: ⭐⭐⭐ HIGH
**Estimated Speedup**: 4-6x
**Conversion Complexity**: MODERATE (frequency calculation needs care)
**Priority**: MEDIUM

---

### 4.5 Cepstral Smoothing

**Function**: `Spectrum_cepstralSmoothing`
**Operation**: Log-power calculation + Gaussian windowing
**Array Size**: 256-4096 bins

**Current Implementation**:
```cpp
// Convert to log power spectrum
for (integer i = 1; i <= my nx; i++) {
    const double re = my z[1][i];
    const double im = my z[2][i];
    const double power = re * re + im * im;
    cepstrum->z[1][i] = 0.5 * log(power + 1e-300);
}

// Apply Gaussian window
for (integer i = 1; i <= my nx; i++) {
    const double quefrency = (i - 1) * cepstrum->dx;
    cepstrum->z[1][i] *= exp(-quefrency * quefrency / (2.0 * bandwidth * bandwidth));
}
```

**SIMD Strategy**:
```cpp
// Step 1: Vectorize power + log
using batch = xsimd::batch<double>;
batch tiny(1e-300);
batch half(0.5);

for (; i + simd_size <= nx; i += simd_size) {
    batch re = xsimd::load_unaligned(&real[i]);
    batch im = xsimd::load_unaligned(&imag[i]);
    batch power = xsimd::fma(re, re, im * im) + tiny;
    batch log_power = half * simd_log(power);  // SLEEF
    xsimd::store_unaligned(&cepstrum[i], log_power);
}

// Step 2: Vectorize exp windowing
for (; i + simd_size <= nx; i += simd_size) {
    batch quefrencies = compute_quefrencies(i);
    batch exponent = -(quefrencies * quefrencies) / (two_vec * bw2_vec);
    batch window = simd_exp(exponent);  // SLEEF

    batch ceps = xsimd::load_unaligned(&cepstrum[i]);
    ceps *= window;
    xsimd::store_unaligned(&cepstrum[i], ceps);
}
```

**SIMD Potential**: ⭐⭐⭐ HIGH (with SLEEF)
**Estimated Speedup**: 3-5x
**Conversion Complexity**: HARD (requires vectorized log and exp)
**Priority**: MEDIUM
**Dependency**: SLEEF for log/exp

---

## Category 5: LTAS Operations

**Module**: `src/praat.github.io/fon/Ltas.cpp`
**Usage Frequency**: LOW-MEDIUM
**New File**: `src/ltas_analysis_simd.cpp`

### 5.1 LTAS Trend Line Computation

**Function**: `Ltas_computeTrendLine`, `Ltas_subtractTrendLine`
**Operation**: Linear regression (sum, dot product, sum of squares) + FMA
**Array Size**: Variable (10-1000 frequency bands)

**Current Implementation**:
```cpp
// Compute slope
for (integer i = 1; i <= n; i++) {
    sum += y[i];
    numerator += (i - 0.5 * (n + 1)) * y[i];
    denominator += (i - 0.5 * (n + 1)) * (i - 0.5 * (n + 1));
}
const double slope = numerator / denominator;

// Subtract trend
for (integer i = 1; i <= n; i++)
    y[i] -= (a + b * i);
```

**SIMD Strategy**:
```cpp
using batch = xsimd::batch<double>;

// Step 1: Vectorize reductions
batch sum_acc(0.0);
batch num_acc(0.0);
batch den_acc(0.0);

for (; i + simd_size <= n; i += simd_size) {
    batch y_vals = xsimd::load_unaligned(&y[i]);
    batch indices = compute_centered_indices(i, n);

    sum_acc += y_vals;
    num_acc = xsimd::fma(indices, y_vals, num_acc);
    den_acc = xsimd::fma(indices, indices, den_acc);
}

// Step 2: Vectorize trend subtraction
batch slope_vec(slope);
batch intercept_vec(intercept);

for (; i + simd_size <= n; i += simd_size) {
    batch y_vals = xsimd::load_unaligned(&y[i]);
    batch indices = compute_indices(i);
    batch trend = xsimd::fma(slope_vec, indices, intercept_vec);
    batch corrected = y_vals - trend;
    xsimd::store_unaligned(&y[i], corrected);
}
```

**SIMD Potential**: ⭐⭐⭐ HIGH
**Estimated Speedup**: 4-6x
**Conversion Complexity**: MODERATE
**Priority**: LOW-MEDIUM

---

### 5.2 LTAS Merging (dB ↔ Energy Conversion)

**Function**: `Ltases_merge`
**Operation**: Element-wise pow/log transformations + summation
**Array Size**: Variable (10-1000 bands)

**Current Implementation**:
```cpp
// dB to energy
for (integer iband = 1; iband <= numberOfBands; iband++)
    energies[iband] = pow(10.0, my z[1][iband] / 10.0);

// Sum energies
for (integer iltas = 1; iltas <= n; iltas++)
    for (integer iband = 1; iband <= numberOfBands; iband++)
        sumOfEnergies[iband] += energies_iltas[iband];

// Energy to dB
for (integer iband = 1; iband <= numberOfBands; iband++)
    thy z[1][iband] = 10.0 * log10(sumOfEnergies[iband] / n);
```

**SIMD Strategy**:
```cpp
using batch = xsimd::batch<double>;
batch ten(10.0);

// dB to energy
for (; i + simd_size <= n; i += simd_size) {
    batch db = xsimd::load_unaligned(&db_values[i]);
    batch exponent = db / ten;
    batch energy = simd_pow10(exponent);  // SLEEF
    xsimd::store_unaligned(&energies[i], energy);
}

// Sum (simple reduction, already covered)

// Energy to dB
for (; i + simd_size <= n; i += simd_size) {
    batch energy = xsimd::load_unaligned(&energies[i]);
    batch db = ten * simd_log10(energy / n_vec);  // SLEEF
    xsimd::store_unaligned(&db_values[i], db);
}
```

**SIMD Potential**: ⭐⭐⭐ HIGH (with SLEEF)
**Estimated Speedup**: 3-5x
**Conversion Complexity**: MODERATE-HARD (requires vectorized pow10/log10)
**Priority**: LOW
**Dependency**: SLEEF

---

## Category 6: Matrix Operations

**Module**: `src/praat.github.io/fon/Matrix.cpp`
**Usage Frequency**: MEDIUM (used for general 2D data)
**New File**: `src/matrix_operations_simd.cpp`

### 6.1 Matrix Statistics (Min, Max, Sum, Mean, StdDev)

**Functions**: `Matrix_getMinimum`, `Matrix_getMaximum`, `Matrix_getSum`, etc.
**Operation**: Reductions over 2D arrays
**Array Size**: Variable (nx × ny, could be large)

**Current Implementation**:
```cpp
for (integer irow = 1; irow <= my ny; irow++)
    for (integer icol = 1; icol <= my nx; icol++)
        sum += my z[irow][icol];
```

**SIMD Strategy**:
```cpp
// Treat as flattened 1D array
using batch = xsimd::batch<double>;
batch acc(0.0);

for (integer irow = 1; irow <= ny; irow++) {
    const double* row = &matrix.z[irow][1];
    integer i = 0;

    for (; i + simd_size <= nx; i += simd_size) {
        batch vals = xsimd::load_unaligned(&row[i]);
        acc += vals;
    }

    // Scalar remainder
    for (; i < nx; ++i) {
        sum += row[i];
    }
}
```

**SIMD Potential**: ⭐⭐⭐ HIGH
**Estimated Speedup**: 4-8x
**Conversion Complexity**: EASY
**Priority**: MEDIUM

---

### 6.2 Matrix Scaling/Addition

**Functions**: `Matrix_scale`, `Matrix_addScalar`, `Matrix_multiplyByScalar`
**Operation**: Element-wise arithmetic
**Array Size**: Variable (nx × ny)

**Current Implementation**:
```cpp
for (integer irow = 1; irow <= my ny; irow++)
    for (integer icol = 1; icol <= my nx; icol++)
        my z[irow][icol] *= scale;
```

**SIMD Strategy**:
```cpp
using batch = xsimd::batch<double>;
batch scale_vec(scale);

for (integer irow = 1; irow <= ny; irow++) {
    double* row = &matrix.z[irow][1];
    integer i = 0;

    for (; i + simd_size <= nx; i += simd_size) {
        batch vals = xsimd::load_unaligned(&row[i]);
        vals *= scale_vec;
        xsimd::store_unaligned(&row[i], vals);
    }

    // Scalar remainder
    for (; i < nx; ++i) {
        row[i] *= scale;
    }
}
```

**SIMD Potential**: ⭐⭐⭐ HIGH
**Estimated Speedup**: 3-4x
**Conversion Complexity**: EASY
**Priority**: MEDIUM

---

## Category 7: PointProcess Operations

**Module**: `src/praat.github.io/fon/PointProcess.cpp`
**Usage Frequency**: MEDIUM (voice quality analysis)
**New File**: `src/pointprocess_analysis_simd.cpp`

### 7.1 Period Statistics (Jitter, Shimmer)

**Functions**: `PointProcess_getJitter_local`, `PointProcess_getMeanPeriod`
**Operation**: Pairwise differences + statistical reductions
**Array Size**: 10-1000 points

**Current Implementation**:
```cpp
// Mean period
for (integer i = 1; i < nt; i++)
    sum += t[i+1] - t[i];
double meanPeriod = sum / (nt - 1);

// Jitter (local)
for (integer i = 2; i <= nt - 1; i++) {
    const double dt1 = t[i] - t[i-1];
    const double dt2 = t[i+1] - t[i];
    sum += fabs(dt2 - dt1);
}
```

**SIMD Strategy**:
```cpp
// Vectorize pairwise differences
using batch = xsimd::batch<double>;

// Load overlapping windows
for (; i + simd_size + 1 <= nt; i += simd_size) {
    batch t_curr = xsimd::load_unaligned(&t[i]);
    batch t_next = xsimd::load_unaligned(&t[i+1]);
    batch periods = t_next - t_curr;
    // Accumulate...
}

// Jitter requires accessing [i-1], [i], [i+1]
// More complex but doable with shifted loads
```

**SIMD Potential**: ⭐⭐ MEDIUM
**Estimated Speedup**: 2-3x (overlapping access patterns add complexity)
**Conversion Complexity**: MODERATE
**Priority**: MEDIUM

**Note**: May be limited by data dependencies and irregular access patterns. Profile before implementing.

---

## Category 8: Miscellaneous Utility Functions

### 8.1 Vector Interpolation

**Functions**: Various interpolation functions in NUM2.cpp
**Operation**: Linear/cubic interpolation on arrays
**SIMD Potential**: ⭐⭐ MEDIUM (complex, data-dependent)
**Priority**: LOW

### 8.2 Vector Normalization

**Operation**: Scale vector to unit length (norm = 1)
**SIMD Potential**: ⭐⭐⭐ HIGH
**Priority**: LOW-MEDIUM

### 8.3 Vector Distance Metrics

**Functions**: Euclidean distance, Manhattan distance
**SIMD Potential**: ⭐⭐⭐ HIGH
**Priority**: MEDIUM

---

## Implementation Priority Matrix

| Category | # Targets | Avg Speedup | Usage Freq | Complexity | Overall Priority |
|----------|-----------|-------------|------------|------------|------------------|
| Spectrum | 6 | 3-5x | HIGH | MOD-HARD | ⭐⭐⭐ HIGH |
| Harmonicity | 3 | 4-8x | MEDIUM | EASY-HARD | ⭐⭐⭐ HIGH |
| Intensity | 2 | 4-8x | HIGH | MOD | ⭐⭐⭐ HIGH |
| LTAS | 2 | 3-5x | LOW-MED | MOD-HARD | ⭐⭐ MEDIUM |
| Formant | 4 | 2-8x | MEDIUM | EASY-MOD | ⭐⭐ MEDIUM |
| Matrix | 2 | 3-8x | MEDIUM | EASY | ⭐⭐ MEDIUM |
| PointProcess | 1 | 2-3x | MEDIUM | MOD | ⭐ LOW-MED |
| Misc | 3 | 2-4x | LOW | EASY-MOD | ⭐ LOW |

---

## Dependencies

### Required for Full Implementation

**SLEEF Library** (SIMD-optimized mathematical functions):
- Required for: log, exp, pow, cos, sin operations
- Affects: ~15 functions in this plan
- Integration: Header-only or link against libsleef
- Platforms: x86 (SSE2+, AVX, AVX-512), ARM (NEON, SVE)

**Alternative**: Polynomial approximations (lower accuracy, easier integration)

---

## Recommended Implementation Order

### Phase 4A: High-Value, Low-Dependency (2 weeks)

1. ✅ Spectrum power calculations (no dependencies)
2. ✅ Harmonicity statistics (no dependencies)
3. ✅ Intensity min/max (no dependencies)
4. ✅ Matrix statistics and scaling (no dependencies)
5. ✅ Formant statistics (no dependencies)

**Expected Gain**: 1.2-1.3x additional speedup
**Effort**: ~40 hours
**Files**: 4 new SIMD files

---

### Phase 4B: SLEEF-Dependent Operations (2-3 weeks)

**Prerequisite**: Integrate SLEEF library

1. ✅ Spectrum cepstral smoothing (log, exp)
2. ✅ Spectrum Hann filtering (cos)
3. ✅ Intensity energy-based averaging (pow10)
4. ✅ LTAS merging (pow10, log10)

**Expected Gain**: 1.1-1.2x additional speedup
**Effort**: ~30 hours (+ SLEEF integration ~10 hours)
**Files**: 2-3 new SIMD files

---

### Phase 4C: Complex/Niche Operations (1-2 weeks)

**Only if profiling shows benefit**

1. Harmonicity stream compaction (AVX-512 preferred)
2. Formant tracker local cost
3. PointProcess jitter calculations
4. Misc vector utilities

**Expected Gain**: 1.05-1.1x additional speedup
**Effort**: ~20 hours
**Files**: 1-2 new SIMD files

---

## Testing Requirements

All minor targets must pass the same validation as main targets:

1. **Numerical Accuracy**: Bit-exact or ≤1 ULP tolerance
2. **Edge Cases**: Empty arrays, single element, unaligned data
3. **Performance**: Benchmark vs scalar baseline
4. **Fallback**: Code compiles and runs without xsimd

**Test Files**:
- `tests/testthat/test-simd-minor-spectrum.R`
- `tests/testthat/test-simd-minor-harmonicity.R`
- `tests/testthat/test-simd-minor-formant.R`
- etc.

---

## Success Metrics

**Phase 4A Success**:
- ✅ 10+ minor functions SIMD-optimized
- ✅ 1.2x additional speedup on spectral/statistical operations
- ✅ Zero accuracy regressions
- ✅ All tests pass

**Phase 4B Success**:
- ✅ SLEEF integrated successfully
- ✅ All vectorized math functions validated
- ✅ 1.1x additional speedup on transcendental operations
- ✅ Cross-platform compatibility maintained

**Overall Minor Targets Success**:
- ✅ 20-25 functions SIMD-optimized
- ✅ 1.3-1.5x cumulative additional speedup
- ✅ Complete coverage of frequently-used operations
- ✅ Comprehensive documentation

---

## Summary

This plan identifies **35+ additional SIMD optimization opportunities** beyond the main plan, organized into 8 categories. The targets range from easy statistical reductions (4-8x speedup) to complex operations requiring specialized libraries (3-5x with SLEEF).

**Key Highlights**:
- **Spectrum operations**: Highest priority (6 targets, frequent use)
- **Harmonicity/Intensity**: High value (5 targets, significant speedup)
- **SLEEF dependency**: Required for ~40% of targets (vectorized math)
- **Estimated total gain**: 1.3-1.5x additional improvement
- **Recommended phased approach**: Start with no-dependency targets

**When to Implement**:
- After main SIMD plan (Phases 1-3) is complete
- During maintenance/enhancement phases
- When profiling identifies specific bottlenecks
- If specialized workflows (e.g., heavy spectral analysis) dominate

---

**Document Version**: 1.0
**Last Updated**: 2025-01-22
**Status**: READY FOR PHASE 4 IMPLEMENTATION
