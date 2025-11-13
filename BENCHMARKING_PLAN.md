# Benchmarking Implementation Plan
**Date**: 2025-11-13  
**Package Version**: 0.4.1  
**Status**: Ready to Execute

## Overview

This document outlines the comprehensive benchmarking strategy for the speaker package, including:
1. Performance comparison against Parselmouth (Python)
2. Baseline performance metrics for SIMD optimization
3. Validation of converted Praat scripts from superassp

## Goals

### Primary Goals
1. **Establish speaker performance advantage** over Parselmouth
2. **Validate that direct C++ binding** is faster than Python overhead
3. **Create baseline metrics** for potential SIMD optimizations
4. **Document performance characteristics** across operations

### Success Criteria
- speaker shows ≥1.5x speedup over Parselmouth for individual operations
- Full workflow speedups of ≥1.5x demonstrate practical advantage
- Benchmark suite runs successfully on macOS, Linux, and Windows
- Results are reproducible and well-documented

## Benchmark Categories

### Category 1: SIMD Baseline (Benchmarks 01-03)
**Purpose**: Establish baseline before potential SIMD optimizations

#### Benchmark 01: Matrix Operations
- **Operations**: sum, mean, min, max
- **Sizes**: 100×100, 500×500, 1000×1000, 2000×2000
- **Iterations**: 50 per operation
- **Expected SIMD improvement**: 4-8x (future)

#### Benchmark 02: Data Conversion
- **Operations**: Sound creation, matrix/dataframe export
- **Durations**: 1s, 10s, 60s (mono/stereo)
- **Sample rate**: 44.1 kHz
- **Iterations**: 20 per operation
- **Expected SIMD improvement**: 4-8x (future)

#### Benchmark 03: Tone Generation
- **Operations**: Sine wave synthesis
- **Durations**: 0.1s, 1s, 10s
- **Frequencies**: 220 Hz, 440 Hz, 880 Hz
- **Iterations**: 50 per operation
- **Expected SIMD improvement**: 4-6x (future)

### Category 2: Parselmouth Comparison (Benchmarks 04-05)
**Purpose**: Demonstrate speaker's performance advantage

#### Benchmark 04: Individual Operations
Compares core analysis functions between speaker and Parselmouth:

| Operation | speaker Method | Parselmouth Method | Expected Speedup |
|-----------|----------------|-------------------|------------------|
| Pitch | `Sound$to_pitch()` | `snd.to_pitch()` | 1.5-2.5x |
| Formant | `Sound$to_formant()` | `snd.to_formant_burg()` | 1.5-2.5x |
| Intensity | `Sound$to_intensity()` | `snd.to_intensity()` | 1.5-2.5x |
| Spectrogram | `Sound$to_spectrogram()` | `snd.to_spectrogram()` | 1.5-2.5x |
| Harmonicity | `Sound$to_harmonicity()` | `snd.to_harmonicity_cc()` | 1.5-2.5x |

**Why speaker should be faster**:
- Direct C++ binding (no Python interpreter overhead)
- No object serialization/deserialization
- Optimized memory management
- Native R integration

#### Benchmark 05: Full Workflows
Compares complete analysis pipelines:

| Workflow | Operations | Expected Speedup |
|----------|-----------|------------------|
| Voice Quality | Pitch + PointProcess + jitter/shimmer + HNR | 1.5-3x |
| Formant Analysis | Formant tracking + statistics (mean, SD) | 1.5-3x |
| Spectral Analysis | Spectrum + moments (CoG, SD, skewness, kurtosis) | 1.5-3x |
| PSOLA Manipulation | Manipulation + PitchTier + resynthesis | 1.5-3x |

**Real-world relevance**:
- These workflows mirror actual superassp Python scripts
- Tests complete analysis pipelines, not just individual calls
- Includes overhead from object creation and method chaining

## Implementation Status

### Completed
- ✅ Benchmark 01: Matrix operations (SIMD baseline)
- ✅ Benchmark 02: Data conversion (SIMD baseline)
- ✅ Benchmark 03: Tone generation (SIMD baseline)
- ✅ Benchmark 04: Parselmouth comparison (operations)
- ✅ Benchmark 05: Parselmouth comparison (workflows)
- ✅ Master runner script (`00_run_all_benchmarks.R`)
- ✅ Comparison report generator (`compare_results.R`)
- ✅ Documentation (`README.md`)

### Pending
- ⬜ Run benchmarks and collect results
- ⬜ Generate comparison plots
- ⬜ Document findings
- ⬜ Update package documentation with performance notes

## Execution Plan

### Phase 1: Setup (Completed)
- [x] Create benchmark scripts
- [x] Set up results directory structure
- [x] Write master runner script
- [x] Write comparison report generator
- [x] Update documentation

### Phase 2: Baseline Execution (Next)
```r
# 1. Build and install package
R CMD INSTALL --preclean .

# 2. Run all benchmarks
source("inst/benchmarks/00_run_all_benchmarks.R")

# 3. Generate comparison report
source("inst/benchmarks/compare_results.R")
```

**Expected duration**: 15-20 minutes

### Phase 3: Analysis and Documentation
1. Review benchmark results
2. Analyze speedup ratios
3. Identify any slower operations
4. Document findings in:
   - `inst/benchmarks/RESULTS.md`
   - Package README
   - Vignettes

### Phase 4: Publication
1. Create performance comparison vignette
2. Add badges to README showing speedup
3. Include plots in documentation
4. Prepare blog post/announcement

## Expected Outcomes

### Best Case
- Mean speedup across all operations: 2-3x
- No operations slower than Parselmouth
- Clear performance advantage demonstrated
- SIMD optimization shows additional 4-8x potential

### Realistic Case
- Mean speedup across all operations: 1.5-2.5x
- Most operations faster, a few comparable
- Clear advantage for typical workflows
- SIMD optimization shows 3-6x potential

### Worst Case
- Mean speedup: 1.0-1.5x
- Performance comparable to Parselmouth
- Some operations slower due to R overhead
- Re-evaluate SIMD priority

## Platform Coverage

### Tier 1 (Primary)
- ✅ macOS (Intel x86-64)
- ✅ macOS (Apple Silicon ARM64)
- ✅ Linux (x86-64, AMD64)

### Tier 2 (Secondary)
- ⚠️ Windows (x86-64) - not yet tested

## Risk Mitigation

### Risk 1: Python/Parselmouth Not Available
**Impact**: Cannot run benchmarks 04-05  
**Mitigation**: Benchmarks automatically skipped, focus on SIMD baselines

### Risk 2: Package Build Failures
**Impact**: Cannot run any benchmarks  
**Mitigation**: Resolve build issues before benchmarking

### Risk 3: Slower Than Parselmouth
**Impact**: Questions about package value proposition  
**Mitigation**: 
- Focus on R integration advantages (autocomplete, type safety)
- Implement SIMD optimizations
- Profile and optimize slow operations

### Risk 4: Inconsistent Results
**Impact**: Unreliable performance claims  
**Mitigation**:
- Use bench package (more reliable than microbenchmark)
- Run sufficient iterations (20-50)
- Report median times (more stable)
- Document system configuration

## Future Enhancements

### Additional Benchmarks
1. **Batch processing**: Compare processing 100 files
2. **Memory usage**: Track peak memory consumption
3. **Parallel processing**: Test multi-core scaling
4. **Large files**: Test with 1+ hour audio files
5. **TextGrid parsing**: Compare annotation handling

### SIMD Implementation
After baseline established:
1. Integrate RcppXsimd
2. Implement SIMD for identified bottlenecks
3. Re-run benchmarks
4. Document speedups

### Cross-Language Comparison
Beyond Parselmouth:
1. Compare to pure Praat (via shell execution)
2. Compare to phonTools (R)
3. Compare to librosa (Python)
4. Compare to Kaldi (C++)

## Success Metrics

### Technical Metrics
- [ ] Benchmarks run without errors
- [ ] Results saved in `.rds` format
- [ ] Plots generated successfully
- [ ] Documentation complete

### Performance Metrics
- [ ] Mean speedup ≥ 1.5x (target: 2.0x)
- [ ] Zero operations with speedup < 0.8x
- [ ] Full workflow speedup ≥ 1.5x (target: 2.5x)

### Quality Metrics
- [ ] Reproducible results (CV < 10%)
- [ ] Clear documentation
- [ ] Plots suitable for publication
- [ ] Code well-commented

## References

### Internal
- `inst/benchmarks/README.md` - Detailed benchmark documentation
- `SIMD_INTEGRATION_PLAN.md` - SIMD optimization roadmap
- `SESSION_STATUS_2025-11-13.md` - Current package status

### External
- [Parselmouth](https://github.com/YannickJadoul/Parselmouth) - Python Praat bindings
- [bench package](https://bench.r-lib.org/) - Accurate R benchmarking
- [RcppXsimd](https://github.com/OHDSI/RcppXsimd) - SIMD for R/C++

## Contact

For questions or issues:
- GitHub: https://github.com/humlab-speech/speaker/issues
- Maintainer: Fredrik Nylén <fredrik.nylen@umu.se>

---

**Last Updated**: 2025-11-13  
**Status**: Ready to execute Phase 2 (baseline execution)  
**Next Action**: Build package and run benchmarks
