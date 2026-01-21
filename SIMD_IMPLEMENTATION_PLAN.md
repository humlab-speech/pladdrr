# SIMD Implementation Plan for pladdrr
**Comprehensive optimization roadmap for DSP/audio processing**

Version: 1.0  
Date: 2026-01-20  
Package: pladdrr v4.4.0

---

## Executive Summary

This plan outlines a phased approach to integrate and extend SIMD optimizations in pladdrr. Current analysis shows:
- **15 SIMD modules** already implemented but not fully integrated
- **Expected gains**: 2-4x on core operations, 30-100% on full workflows
- **Timeline**: 12-16 weeks for complete implementation
- **Priority**: Integration first (quick wins), then new implementations

---

## Phase 1: SIMD Integration (Weeks 1-4)
**Goal**: Integrate existing SIMD code into main DSP paths  
**Expected gain**: 30-50% speedup on typical phonetic workflows  
**Risk**: Low - code already exists and tested

### Task 1.1: Pitch Extraction Integration (Week 1)
**Target**: `Sound_to_Pitch_ac`, `Sound_to_Pitch_cc`  
**File**: `src/praat.github.io/fon/Sound_to_Pitch.cpp`

#### Subtasks:
1. **Identify autocorrelation call sites**
   - Search for `NUMautocorrelation` calls in `Sound_to_Pitch.cpp`
   - Map to corresponding SIMD functions in `autocorrelation_simd.cpp`

2. **Create bridge functions**
   ```cpp
   // In sound_wrappers.cpp or new file: pitch_simd_bridge.cpp
   #include "autocorrelation_simd.cpp"
   
   void NUMautocorrelation_simd_bridge(
       constVEC const& signal,
       VEC const& autocorr,
       integer lag_min,
       integer lag_max
   ) {
       // Call autocorrelation_simd and adapt to Praat VEC format
   }
   ```

3. **Modify Sound_to_Pitch.cpp**
   - Add `#ifdef HAVE_XSIMD` blocks
   - Replace scalar autocorrelation with SIMD version
   - Fallback to scalar if SIMD unavailable

4. **Testing**
   - Compare results: SIMD vs scalar (should be identical within FP tolerance)
   - Benchmark on various pitch ranges (75-600 Hz)
   - Test edge cases: very short/long signals, silence

#### Files to modify:
- `src/praat.github.io/fon/Sound_to_Pitch.cpp` (add SIMD calls)
- `src/sound_wrappers.cpp` (expose SIMD functions to Praat)
- New: `src/pitch_simd_bridge.cpp` (adapter functions)

#### Success criteria:
- [ ] Pitch extraction uses SIMD when available
- [ ] Results match scalar implementation (max diff < 1e-10)
- [ ] 1.5-2.5x speedup on pitch extraction benchmarks

---

### Task 1.2: Intensity Calculation Integration (Week 1-2)
**Target**: `Sound_to_Intensity`  
**File**: `src/praat.github.io/fon/Sound_to_Intensity.cpp`

#### Subtasks:
1. **Analyze Intensity computation**
   - Identify windowed RMS calculations
   - Map to `sound_get_rms_simd`, `sound_get_energy_simd`

2. **Modify Sound_to_Intensity**
   ```cpp
   // In Sound_to_Intensity.cpp
   #ifdef HAVE_XSIMD
   #include "../sound_statistics_simd.cpp"
   #endif
   
   // Replace frame RMS computation with SIMD version
   for (integer iframe = 1; iframe <= thy nx; iframe++) {
       #ifdef HAVE_XSIMD
           thy z[1][iframe] = compute_frame_rms_simd(windowedSignal);
       #else
           thy z[1][iframe] = compute_frame_rms_scalar(windowedSignal);
       #endif
   }
   ```

3. **Integrate windowing**
   - Use `apply_hamming_window_simd` from `window_functions_simd.cpp`
   - Batch window multiple frames

4. **Testing**
   - Compare intensity contours (SIMD vs scalar)
   - Test different window sizes (0.01s - 0.1s)
   - Verify time alignment

#### Files to modify:
- `src/praat.github.io/fon/Sound_to_Intensity.cpp`
- New: `src/intensity_simd_bridge.cpp`

#### Success criteria:
- [ ] Intensity calculation uses SIMD RMS
- [ ] Results identical to scalar (max diff < 1e-10)
- [ ] 1.5-2x speedup

---

### Task 1.3: Formant Extraction Integration (Week 2-3)
**Target**: `Sound_to_Formant_burg`  
**File**: `src/praat.github.io/fon/Sound_to_Formant.cpp`

#### Subtasks:
1. **Integrate LPC Burg SIMD**
   - Replace scalar Burg algorithm with `lpc_burg_simd`
   - Adapt Praat's LPC structure to SIMD input/output

2. **SIMD polynomial root finding**
   ```cpp
   // New function in formant_lpc_simd.cpp
   void find_formant_frequencies_simd(
       const double* lpc_coeffs,
       int order,
       double* formant_freqs,
       double* bandwidths,
       int* n_formants,
       double sampling_rate
   );
   ```

3. **Integration points**
   - Pre-emphasis: use SIMD filter
   - Window application: use `window_functions_simd`
   - Autocorrelation: use `lpc_autocorrelation_simd`
   - Root finding: new SIMD implementation

4. **Testing**
   - Compare formant tracks (F1, F2, F3)
   - Test various formant ceilings (4000-8000 Hz)
   - Vowel formant accuracy

#### Files to modify:
- `src/praat.github.io/fon/Sound_to_Formant.cpp`
- `src/formant_lpc_simd.cpp` (extend with root finding)
- New: `src/formant_simd_bridge.cpp`

#### Success criteria:
- [ ] Formant extraction uses SIMD Burg algorithm
- [ ] Formants match scalar within 5 Hz
- [ ] 2-4x speedup on formant extraction

---

### Task 1.4: Window Function Integration (Week 3)
**Target**: All windowing operations  
**Files**: Multiple (Spectrogram, Intensity, Pitch, etc.)

#### Subtasks:
1. **Create unified windowing interface**
   ```cpp
   // In window_functions_simd.cpp - add generic interface
   void apply_window_simd(
       double* data,
       int n,
       WindowType type,
       double parameter = 0.0
   );
   ```

2. **Find all window application sites**
   - Search for `hamming`, `hanning`, `gaussian` in Praat code
   - Replace with SIMD versions

3. **Batch windowing**
   - Process multiple frames simultaneously
   - Reuse window coefficients

#### Files to modify:
- `src/window_functions_simd.cpp` (extend)
- `src/praat.github.io/fon/Sound_and_Spectrogram.cpp`
- `src/praat.github.io/fon/Sound_to_Pitch.cpp`
- `src/praat.github.io/fon/Sound_to_Intensity.cpp`

#### Success criteria:
- [ ] All major windowing uses SIMD
- [ ] 1.5-2x speedup on windowing operations

---

### Task 1.5: Testing & Benchmarking (Week 4)
**Goal**: Validate Phase 1 integrations

#### Subtasks:
1. **Create comprehensive test suite**
   ```r
   # tests/testthat/test-simd-integration.R
   test_that("SIMD pitch matches scalar", {
       sound <- Sound$create_tone(440, duration = 1.0)
       
       # Force scalar
       options(speaker.use_simd = FALSE)
       pitch_scalar <- sound$to_pitch()
       
       # Force SIMD
       options(speaker.use_simd = TRUE)
       pitch_simd <- sound$to_pitch()
       
       expect_equal(pitch_scalar$get_mean(), 
                    pitch_simd$get_mean(), 
                    tolerance = 1e-6)
   })
   ```

2. **Benchmark suite**
   ```r
   # benchmarks/phase1_integration.R
   library(pladdrr)
   library(microbenchmark)
   
   sound <- Sound$new("test_audio.wav")
   
   microbenchmark(
       pitch = sound$to_pitch(),
       formant = sound$to_formant_burg(),
       intensity = sound$to_intensity(),
       times = 100
   )
   ```

3. **Create comparison reports**
   - Document speedup for each operation
   - Memory usage comparison
   - Accuracy validation

#### Deliverables:
- [ ] Test suite with 20+ tests
- [ ] Benchmark report showing speedups
- [ ] Documentation updates

---

## Phase 2: Spectrogram & Filtering (Weeks 5-8)
**Goal**: SIMD-optimize spectrogram generation and filtering  
**Expected gain**: 40-60% on spectral analysis

### Task 2.1: Spectrogram SIMD (Week 5-6)
**Target**: `Sound_to_Spectrogram`  
**File**: `src/praat.github.io/fon/Sound_and_Spectrogram.cpp`

#### Subtasks:
1. **SIMD frame extraction**
   ```cpp
   // New file: src/spectrogram_simd.cpp
   
   void extract_frames_simd(
       const double* signal,
       int signal_len,
       double** frames,
       int n_frames,
       int frame_length,
       int hop_size
   ) {
       using batch = xsimd::batch<double>;
       constexpr size_t simd_size = batch::size;
       
       // Extract multiple frames with SIMD
       for (int frame = 0; frame < n_frames; frame++) {
           int offset = frame * hop_size;
           double* frame_data = frames[frame];
           
           int i = 0;
           for (; i + simd_size <= frame_length; i += simd_size) {
               batch data = xsimd::load_unaligned(&signal[offset + i]);
               data.store_unaligned(&frame_data[i]);
           }
           
           // Scalar remainder
           for (; i < frame_length; i++) {
               frame_data[i] = signal[offset + i];
           }
       }
   }
   ```

2. **SIMD windowing + FFT preparation**
   - Apply window to multiple frames in parallel
   - Batch FFT input preparation

3. **SIMD power spectrum calculation**
   - Use `fft_simd.cpp` functions
   - Vectorize magnitude computation

4. **Integration into Sound_to_Spectrogram**

#### Files to create/modify:
- New: `src/spectrogram_simd.cpp`
- Modify: `src/praat.github.io/fon/Sound_and_Spectrogram.cpp`

#### Success criteria:
- [ ] Spectrogram generation uses SIMD
- [ ] Results match scalar spectrogram
- [ ] 2-3x speedup

---

### Task 2.2: Pre-emphasis Filter SIMD (Week 6)
**Target**: All pre-emphasis filtering  
**Files**: Multiple (Formant, LPC, MFCC pipelines)

#### Subtasks:
1. **Implement SIMD pre-emphasis**
   ```cpp
   // In src/num_filtering_simd.cpp
   
   void apply_preemphasis_simd(
       const double* input,
       double* output,
       int n,
       double alpha = 0.97
   ) {
       using batch = xsimd::batch<double>;
       constexpr size_t simd_size = batch::size;
       
       // First sample (no pre-emphasis)
       output[0] = input[0];
       
       // Process in SIMD blocks
       // Note: Loop-carried dependency - use look-ahead
       batch alpha_batch(alpha);
       
       for (int i = 1; i + simd_size < n; i += simd_size) {
           batch curr = xsimd::load_unaligned(&input[i]);
           batch prev = xsimd::load_unaligned(&input[i-1]);
           batch result = curr - alpha_batch * prev;
           result.store_unaligned(&output[i]);
       }
       
       // Scalar remainder
       for (int i = n - (n-1) % simd_size; i < n; i++) {
           output[i] = input[i] - alpha * input[i-1];
       }
   }
   ```

2. **Integration points**
   - `Sound_to_Formant_burg` (before LPC)
   - `Sound_to_MFCC` (before mel-filterbank)
   - `Sound_to_LPC` (preprocessing)

#### Files to modify:
- `src/num_filtering_simd.cpp` (add function)
- `src/praat.github.io/fon/Sound_to_Formant.cpp`
- `src/praat.github.io/dwtools/Sound_to_MFCC.cpp`

#### Success criteria:
- [ ] Pre-emphasis uses SIMD
- [ ] 1.5-2x speedup on filtered operations

---

### Task 2.3: Bandpass Filter SIMD (Week 7)
**Target**: Pitch extraction filtering  
**File**: `src/praat.github.io/fon/Sound_to_Pitch.cpp`

#### Subtasks:
1. **Implement SIMD IIR/FIR filters**
   - Extend `num_filtering_simd.cpp`
   - Implement second-order sections (SOS) with SIMD

2. **Optimize pitch bandpass**
   - Filter signal before autocorrelation
   - Use SIMD for coefficient application

3. **Integration**

#### Files to modify:
- `src/num_filtering_simd.cpp`
- `src/praat.github.io/fon/Sound_to_Pitch.cpp`

#### Success criteria:
- [ ] Bandpass filtering uses SIMD
- [ ] 2-3x speedup on filtered pitch extraction

---

### Task 2.4: Testing Phase 2 (Week 8)

#### Deliverables:
- [ ] Spectrogram tests (10+ test cases)
- [ ] Filter tests (pre-emphasis, bandpass)
- [ ] Benchmark report for Phase 2
- [ ] Updated documentation

---

## Phase 3: Batch & MFCC Operations (Weeks 9-11)
**Goal**: Optimize batch processing and MFCC  
**Expected gain**: 50-100% on batch workflows

### Task 3.1: MFCC SIMD Implementation (Week 9-10)
**Target**: `Sound_to_MFCC`  
**File**: `src/praat.github.io/dwtools/Sound_to_MFCC.cpp`

#### Subtasks:
1. **SIMD Mel-scale conversion**
   ```cpp
   // New file: src/mfcc_simd.cpp
   
   void hz_to_mel_simd(
       const double* hz,
       double* mel,
       int n
   ) {
       using batch = xsimd::batch<double>;
       constexpr size_t simd_size = batch::size;
       
       batch c(1127.0);
       batch scale(1.0 / 700.0);
       
       int i = 0;
       for (; i + simd_size <= n; i += simd_size) {
           batch freq = xsimd::load_unaligned(&hz[i]);
           batch result = c * xsimd::log(batch(1.0) + freq * scale);
           result.store_unaligned(&mel[i]);
       }
       
       // Scalar remainder
       for (; i < n; i++) {
           mel[i] = 1127.0 * log(1.0 + hz[i] / 700.0);
       }
   }
   ```

2. **SIMD Mel filterbank**
   - Triangular filters with SIMD
   - Batch processing across frequency bins

3. **SIMD DCT (Discrete Cosine Transform)**
   - Type-II DCT for cepstral coefficients
   - SIMD cosine computation

4. **SIMD log energy**
   - Already available in `sound_statistics_simd.cpp`

#### Files to create:
- New: `src/mfcc_simd.cpp`

#### Files to modify:
- `src/praat.github.io/dwtools/Sound_to_MFCC.cpp`

#### Success criteria:
- [ ] MFCC computation uses SIMD
- [ ] 2-4x speedup on MFCC extraction
- [ ] Results match scalar MFCC

---

### Task 3.2: Batch Query Optimization (Week 10-11)
**Target**: `batch_queries.cpp`  
**File**: `src/batch_queries.cpp`

#### Subtasks:
1. **SIMD across time points**
   - Process multiple time points simultaneously
   - Vectorize formant/pitch queries

2. **Parallel frame processing**
   - Process multiple frames with SIMD
   - Reduce memory allocations

3. **Optimize data structure access**

#### Files to modify:
- `src/batch_queries.cpp`

#### Success criteria:
- [ ] Batch queries use SIMD
- [ ] 1.5-2.5x speedup on batch operations

---

### Task 3.3: TextGrid Batch Operations (Week 11)
**Target**: `textgrid_batch_operations.cpp`  
**File**: `src/textgrid_batch_operations.cpp`

#### Subtasks:
1. **SIMD interval extraction**
2. **Batch feature extraction**
3. **Vectorize across intervals**

#### Success criteria:
- [ ] TextGrid operations use SIMD
- [ ] 1.5-2x speedup

---

## Phase 4: Advanced Features (Weeks 12-16)
**Goal**: Optimize advanced features  
**Expected gain**: 30-50% on advanced operations

### Task 4.1: FormantPath SIMD (Week 12-13)
**Target**: `Sound_to_Formant_path`  
**File**: `src/praat.github.io/LPC/FormantPath.cpp`

#### Subtasks:
1. **SIMD multi-ceiling extraction**
   - Process multiple formant ceilings in parallel
   - Vectorize across ceiling candidates

2. **SIMD dynamic programming**
   - Vectorize cost matrix computation
   - SIMD backtracking

3. **Integration**

#### Files to modify:
- `src/praat.github.io/LPC/FormantPath.cpp`
- `src/formant_lpc_simd.cpp` (extend)

#### Success criteria:
- [ ] FormantPath uses SIMD
- [ ] 2-3x speedup

---

### Task 4.2: Harmonicity SIMD (Week 13)
**Target**: `Sound_to_Harmonicity`  
**File**: `src/praat.github.io/fon/Sound_to_Harmonicity.cpp`

#### Subtasks:
1. **Use SIMD autocorrelation**
2. **SIMD HNR calculation**

#### Success criteria:
- [ ] Harmonicity uses SIMD
- [ ] 1.5-2x speedup

---

### Task 4.3: ComplexSpectrogram SIMD (Week 14)
**Target**: `ComplexSpectrogram`  
**File**: `src/praat.github.io/dwtools/ComplexSpectrogram.cpp`

#### Subtasks:
1. **SIMD complex arithmetic**
2. **SIMD phase unwrapping**

#### Success criteria:
- [ ] ComplexSpectrogram uses SIMD
- [ ] 1.5-2x speedup

---

### Task 4.4: KlattGrid SIMD (Week 15)
**Target**: KlattGrid synthesis  
**File**: `src/praat.github.io/dwtools/KlattGrid.cpp`

#### Subtasks:
1. **SIMD oscillator banks**
2. **SIMD formant filters**

#### Success criteria:
- [ ] KlattGrid synthesis uses SIMD
- [ ] 1.5-2x speedup

---

### Task 4.5: Final Testing & Documentation (Week 16)

#### Deliverables:
- [ ] Complete test suite (100+ tests)
- [ ] Full benchmark report
- [ ] User documentation
- [ ] Developer documentation
- [ ] Performance tuning guide

---

## Implementation Guidelines

### Code Style
```cpp
// Always provide scalar fallback
#ifdef HAVE_XSIMD
    result = compute_simd(data, n);
#else
    result = compute_scalar(data, n);
#endif

// Use consistent SIMD patterns
using batch = xsimd::batch<double>;
constexpr size_t simd_size = batch::size;

// Process main loop
int i = 0;
for (; i + simd_size <= n; i += simd_size) {
    batch data = xsimd::load_unaligned(&input[i]);
    // SIMD operations
    result.store_unaligned(&output[i]);
}

// Handle remainder
for (; i < n; i++) {
    // Scalar operations
}
```

### Testing Requirements
- **Accuracy**: Results must match scalar within `1e-10` for deterministic operations
- **Performance**: Minimum 1.3x speedup to justify SIMD complexity
- **Memory**: No significant memory increase
- **Portability**: Must work on x86_64 (SSE4.2, AVX2) and ARM (NEON)

### Benchmarking
- Use `microbenchmark` package in R
- Test with realistic audio files (10s - 5min)
- Various sampling rates (16kHz, 22.05kHz, 44.1kHz)
- Report median, mean, and std dev of execution times

### Documentation
Each SIMD function must have:
1. Algorithm description
2. Expected speedup
3. Accuracy notes
4. Usage examples

---

## Risk Mitigation

### Technical Risks
1. **Numerical accuracy**: Use FMA (fused multiply-add) for better precision
2. **Memory alignment**: Use `load_unaligned` for safety
3. **Platform differences**: Test on multiple architectures

### Project Risks
1. **Timeline slippage**: Phases 1-2 are critical; 3-4 are optional enhancements
2. **CRAN compatibility**: Keep `-march=native` for local, provide portable fallback
3. **Maintenance burden**: Document all SIMD code extensively

---

## Success Metrics

### Performance Targets
- **Phase 1**: 30-50% speedup on typical workflows
- **Phase 2**: Additional 20-30% on spectral analysis
- **Phase 3**: 50-100% on batch operations
- **Phase 4**: 20-30% on advanced features
- **Overall**: 2-4x speedup on DSP-intensive operations

### Quality Metrics
- Zero regression in accuracy (max diff < 1e-10)
- 100% test coverage for SIMD paths
- All SIMD functions have scalar fallbacks
- Documentation for all new functions

---

## Appendix A: File Organization

```
src/
├── *_simd.cpp              # SIMD implementations (15 existing)
├── *_simd_bridge.cpp       # NEW: Bridge functions to Praat code
├── simd_utils.h            # SIMD utilities
├── praat.github.io/        # Praat source (modify carefully)
│   ├── fon/
│   │   ├── Sound_to_Pitch.cpp      # Modify for Task 1.1
│   │   ├── Sound_to_Formant.cpp    # Modify for Task 1.3
│   │   ├── Sound_to_Intensity.cpp  # Modify for Task 1.2
│   │   └── Sound_and_Spectrogram.cpp # Modify for Task 2.1
│   ├── dwtools/
│   │   └── Sound_to_MFCC.cpp       # Modify for Task 3.1
│   └── LPC/
│       └── FormantPath.cpp         # Modify for Task 4.1
└── tests/
    └── simd_tests.cpp      # NEW: SIMD-specific tests
```

---

## Appendix B: Benchmark Template

```r
# benchmarks/simd_benchmark_template.R

library(pladdrr)
library(microbenchmark)

# Load test audio
sound <- Sound$new("test_audio_10s_44100.wav")

# Benchmark function
benchmark_operation <- function(op_name, op_func, times = 100) {
  # Scalar
  options(speaker.use_simd = FALSE)
  result_scalar <- microbenchmark(op_func(), times = times, unit = "ms")
  
  # SIMD
  options(speaker.use_simd = TRUE)
  result_simd <- microbenchmark(op_func(), times = times, unit = "ms")
  
  speedup <- median(result_scalar$time) / median(result_simd$time)
  
  cat(sprintf("%s: %.2fx speedup\n", op_name, speedup))
  
  list(
    operation = op_name,
    scalar_median = median(result_scalar$time),
    simd_median = median(result_simd$time),
    speedup = speedup
  )
}

# Run benchmarks
results <- list(
  benchmark_operation("Pitch extraction", 
                      function() sound$to_pitch()),
  benchmark_operation("Formant extraction", 
                      function() sound$to_formant_burg()),
  benchmark_operation("Intensity contour", 
                      function() sound$to_intensity())
)

# Save results
saveRDS(results, "benchmark_results.rds")
```

---

## Appendix C: Integration Checklist

For each SIMD integration:
- [ ] Identify scalar code location
- [ ] Create/locate corresponding SIMD function
- [ ] Write bridge/adapter function if needed
- [ ] Add `#ifdef HAVE_XSIMD` guards
- [ ] Test accuracy (compare scalar vs SIMD)
- [ ] Benchmark performance
- [ ] Update documentation
- [ ] Add unit tests
- [ ] Code review
- [ ] Merge to main branch

---

## Contact & Support

For questions about this implementation plan:
- Review existing SIMD code in `src/*_simd.cpp`
- Check RcppXsimd documentation: https://github.com/OHDSI/RcppXsimd
- Praat algorithms: https://www.fon.hum.uva.nl/praat/

**Plan maintained by**: pladdrr development team  
**Last updated**: 2026-01-20
