# SIMD Assessment for Target Hardware - 2025-11-17

## Target Hardware Platforms

### Platform 1: Apple M1 Pro (Development/Primary)
- **Architecture**: ARM64 (AArch64)
- **CPU Cores**: 10 cores (8 performance + 2 efficiency)
- **SIMD Instruction Set**: ARM NEON (128-bit vectors)
- **Vector Width**: 128-bit (4x float32 or 2x float64)
- **Cache**: 
  - L1: 128KB per P-core, 64KB per E-core
  - L2: 12MB shared
  - Memory bandwidth: ~200 GB/s unified memory

### Platform 2: AMD EPYC 7543P (Production VM)
- **Architecture**: x86_64 (Zen 3)
- **Available Cores**: 2 cores (in VM)
- **SIMD Instruction Sets**: 
  - AVX2 (256-bit vectors) - highly likely
  - AVX-512 (512-bit vectors) - not available on Zen 3
- **Vector Width**: 256-bit (8x float32 or 4x float64)
- **Cache**: 
  - L1: 32KB per core
  - L2: 512KB per core
  - L3: Shared (depends on VM allocation)

## SIMD Capabilities Analysis

### ARM NEON (M1 Pro)
```
Float32: 4 elements per operation (128-bit / 32-bit)
Float64: 2 elements per operation (128-bit / 64-bit)

Theoretical Speedup:
- Single-precision: 4x
- Double-precision: 2x
- Actual (accounting for overhead): 2-3x typical
```

### AVX2 (AMD EPYC)
```
Float32: 8 elements per operation (256-bit / 32-bit)
Float64: 4 elements per operation (256-bit / 64-bit)

Theoretical Speedup:
- Single-precision: 8x
- Double-precision: 4x
- Actual (accounting for overhead): 3-6x typical
```

## Expected Performance Improvements by Operation

### Phase 1: Matrix Operations (IMPLEMENTED ✅)

**M1 Pro (NEON)**:
- Matrix sum/mean: 2-3x faster
- Min/max: 2-3x faster
- Element-wise ops: 2.5-3.5x faster

**AMD EPYC (AVX2)**:
- Matrix sum/mean: 4-6x faster
- Min/max: 3-5x faster
- Element-wise ops: 4-7x faster

**Why Better on AMD**: Wider vectors (256-bit vs 128-bit), more elements per operation.

### Phase 2: Data Conversion & Sound Processing (PARTIAL ✅)

**M1 Pro (NEON)**:
- Data type conversion: 2-3x faster
- Scaling operations: 2.5-3x faster
- Sound mixing: 2-3x faster

**AMD EPYC (AVX2)**:
- Data type conversion: 4-5x faster
- Scaling operations: 4-6x faster
- Sound mixing: 4-6x faster

**Critical Note**: Memory bandwidth matters more here. M1 Pro's unified memory architecture (200 GB/s) may partially offset narrower SIMD width vs AMD's discrete memory.

### Phase 3: DSP Operations (NOT YET IMPLEMENTED)

#### FFT/Spectrogram
**M1 Pro (NEON)**:
- FFT butterfly operations: 2-3x faster
- Complex multiplication: 2x faster
- Window functions: 2.5-3x faster

**AMD EPYC (AVX2)**:
- FFT butterfly operations: 3-5x faster
- Complex multiplication: 3-4x faster
- Window functions: 4-6x faster

#### Autocorrelation (Pitch, LPC)
**M1 Pro (NEON)**:
- Dot products: 3-4x faster
- Lag calculations: 2.5-3x faster

**AMD EPYC (AVX2)**:
- Dot products: 5-7x faster
- Lag calculations: 4-6x faster

**Why These Are Best**: Autocorrelation is dominated by dot products, which are ideal for SIMD (multiply-add sequences).

## RcppXsimd Cross-Platform Strategy

### Current Implementation Status
```cpp
#ifdef RCPPXSIMD_XSIMD_HPP
  // SIMD path - automatically selects:
  //   - NEON on ARM (M1 Pro)
  //   - AVX2 on x86_64 (AMD EPYC)
  xsimd::batch<double> operations...
#else
  // Scalar fallback
  for loop operations...
#endif
```

### Benefits of xsimd Library
1. **Single codebase** for both platforms
2. **Automatic ISA detection** at compile time
3. **Optimal instruction selection**:
   - M1 Pro → NEON automatically
   - AMD EPYC → AVX2 automatically
4. **Compile-time fallback** if no SIMD available

## Realistic Performance Expectations

### Conservative Estimates (Accounting for Real-World Overhead)

| Operation Type | M1 Pro (NEON) | AMD EPYC (AVX2) |
|----------------|---------------|-----------------|
| Matrix operations | 2.0-2.5x | 3.5-4.5x |
| Data conversion | 1.8-2.3x | 3.0-4.0x |
| Tone generation | 2.2-2.8x | 4.0-5.0x |
| Sound mixing | 2.0-2.5x | 3.5-4.5x |
| FFT operations | 1.8-2.5x | 2.5-3.5x |
| Autocorrelation | 2.5-3.5x | 4.5-6.0x |
| Formant (LPC) | 2.2-3.0x | 3.5-5.0x |
| Pitch detection | 2.5-3.2x | 4.0-5.5x |

### Why Conservative?
1. **Cache effects**: Not all data fits in L1/L2
2. **Memory latency**: SIMD can't hide all latency
3. **Loop overhead**: Startup/cleanup code
4. **Branch misprediction**: Some conditional logic remains
5. **Data alignment**: Unaligned loads are slower

## VM Considerations (AMD EPYC in 2-core VM)

### Potential Limitations
1. **Reduced cache allocation**: L3 cache may be limited
2. **Memory bandwidth contention**: Shared with other VMs
3. **CPU pinning**: May not get full turbo boost
4. **NUMA effects**: Memory locality issues

### Recommended Optimizations
```cpp
// Use smaller working sets to fit in L2 cache
constexpr size_t CACHE_FRIENDLY_SIZE = 256 * 1024; // 256KB chunks

// Prefer sequential access patterns
// SIMD works best with contiguous memory

// Minimize memory allocations in hot paths
// Reuse buffers where possible
```

## Implementation Priority for Your Hardware

### High Impact (Do First) ⭐⭐⭐
1. **Autocorrelation** (Pitch, LPC)
   - Best SIMD gains (4-6x on EPYC, 2.5-3.5x on M1)
   - Core DSP operation
   - Used in multiple analysis pipelines

2. **Matrix operations** (Already done ✅)
   - Foundation for many operations
   - Consistent gains across platforms

3. **Sound mixing/scaling**
   - Frequently used
   - Simple SIMD patterns
   - Good gains (3-5x on EPYC, 2-3x on M1)

### Medium Impact (Do Next) ⭐⭐
4. **Data conversion** (Partially done ✅)
   - Used in every I/O operation
   - Moderate gains (3-4x on EPYC, 2x on M1)

5. **Window functions**
   - Used in FFT/spectrogram
   - Simple vectorization
   - Good gains (4-5x on EPYC, 2.5-3x on M1)

6. **FFT butterflies**
   - Complex but high impact
   - Moderate gains due to complexity

### Lower Impact (Do Last) ⭐
7. **Min/max search** (Already done ✅)
   - Already quite fast
   - Limited by reduction overhead

8. **Intensity calculations**
   - Similar to matrix ops
   - Incremental benefit

## Benchmarking Strategy

### What to Measure
1. **Baseline (scalar)**: Current performance
2. **SIMD enabled**: With RcppXsimd
3. **Platform comparison**: M1 vs EPYC results

### Test Workloads
```r
# Small (fits in L1): 0.1s audio @ 16kHz = 1,600 samples
# Medium (fits in L2): 1.0s audio @ 44.1kHz = 44,100 samples  
# Large (exceeds L2): 60s audio @ 44.1kHz = 2,646,000 samples
```

### Expected Results

**M1 Pro**:
- Small workloads: ~2.5x average speedup
- Medium workloads: ~2.2x average speedup
- Large workloads: ~2.0x average speedup (memory bound)

**AMD EPYC (2-core VM)**:
- Small workloads: ~4.5x average speedup
- Medium workloads: ~4.0x average speedup
- Large workloads: ~3.0x average speedup (memory bound)

## Real-World Impact Example

### Vowel Formant Tracking Pipeline
```r
# Typical workflow
sound <- Sound$new("vowel.wav")  # 1s @ 44.1kHz
formant <- sound$to_formant_burg()  # LPC autocorrelation
f1 <- formant$get_value_at_time(1, 0.5)
f2 <- formant$get_value_at_time(2, 0.5)
```

**Performance Breakdown**:

| Step | Time (scalar) | M1 SIMD | EPYC SIMD |
|------|---------------|---------|-----------|
| Load sound | 200μs | 200μs | 200μs |
| to_formant_burg | 15ms | 6ms (2.5x) | 4ms (3.8x) |
| get_value (×2) | 100μs | 100μs | 100μs |
| **Total** | **15.3ms** | **6.3ms** | **4.3ms** |

**Speedup**: 2.4x (M1), 3.6x (EPYC)

### Batch Processing (100 files)
- **Scalar**: 1,530ms (1.53s)
- **M1 SIMD**: 630ms (0.63s) - saves 900ms
- **EPYC SIMD**: 430ms (0.43s) - saves 1,100ms

## Recommendations

### For M1 Pro Development
1. **Enable NEON optimizations** - 2-3x gains are significant
2. **Focus on autocorrelation** - highest impact operations
3. **Test with realistic workloads** - 1-60s audio files
4. **Monitor memory bandwidth** - may be bottleneck for large files

### For AMD EPYC Production
1. **Ensure AVX2 is available** - check VM settings
2. **Use cache-friendly chunk sizes** - 256KB working sets
3. **Batch process when possible** - amortize overhead
4. **Monitor VM resource limits** - may need dedicated cores

### General Strategy
1. ✅ **Phase 1 complete**: Matrix operations baseline
2. ✅ **Phase 2 partial**: Data conversion started
3. ⏭️ **Phase 3 priority**: Autocorrelation (LPC, Pitch)
4. ⏭️ **Phase 4**: FFT and spectrogram
5. ⏭️ **Phase 5**: End-to-end optimization

## Conclusion

**SIMD optimization is highly worthwhile for both platforms:**

- **M1 Pro**: Expect 2-3x improvements with NEON
- **AMD EPYC**: Expect 3-6x improvements with AVX2
- **RcppXsimd**: Provides zero-cost abstraction for both

**Highest ROI operations** (implement first):
1. Autocorrelation (pitch detection, LPC)
2. Sound mixing and scaling
3. Window functions
4. FFT butterfly operations

**Current progress**: ~40% complete (Phases 1-2)
**Remaining effort**: ~3-4 weeks for full SIMD coverage
**Expected overall speedup**: 2-3x on M1, 3-5x on EPYC

The effort is justified given the performance-critical nature of audio DSP operations and the frequency of batch processing workflows.
