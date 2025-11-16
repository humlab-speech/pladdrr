# TODO: Parselmouth Comparison Benchmarks

**Status**: Deferred for later implementation  
**Priority**: Medium  
**Date Added**: 2025-11-16  

## Objective

Add optional Parselmouth comparison benchmarks to validate that speaker's R 
implementation performs comparably or better than Python's Parselmouth library.

## Current State

- ✅ Benchmarking infrastructure in place (`inst/benchmarks/`)
- ✅ Comparison script ready (`compare_results.R`)
- ✅ SIMD baseline tracking implemented
- ⏸️ Parselmouth comparison section exists but marked optional

## Requirements

1. **Python Environment**
   - Install Python 3.8+
   - Install Parselmouth: `pip install praat-parselmouth`
   - Verify installation

2. **Benchmark Scripts**
   - Create `inst/benchmarks/04_parselmouth_comparison.R`
   - Implement reticulate-based Python calls
   - Compare equivalent operations:
     * Sound loading and manipulation
     * Pitch extraction
     * Formant tracking
     * Spectrogram generation
     * Intensity analysis

3. **Metrics to Compare**
   - Execution time (median, mean)
   - Memory usage
   - Result accuracy (validate outputs match)
   - API ergonomics (lines of code, clarity)

## Implementation Steps

1. Set up Python/Parselmouth environment
2. Create benchmark script with reticulate
3. Define equivalent operations in both libraries
4. Run benchmarks and save results
5. Update `compare_results.R` to process Parselmouth data
6. Generate comparison plots and tables

## Expected Outcome

Documentation showing:
- **Performance**: speaker vs Parselmouth execution times
- **Usability**: R6 methods vs `praat.call()` string dispatcher
- **Dependencies**: Native R+C++ vs Python+C++ binding
- **Platform**: Cross-platform comparison

## Benefits

- Validates speaker's competitive performance
- Demonstrates R6 API advantages over generic dispatcher
- Provides migration guide for Parselmouth users
- Marketing material for package adoption

## Notes

- Not blocking SIMD implementation
- Can be added incrementally
- May require Python environment setup documentation
- Consider optional dependency (reticulate) for testing only

---

**Related Files**:
- `inst/benchmarks/compare_results.R` (has Parselmouth section stub)
- `inst/benchmarks/04_parselmouth_comparison.R` (to be created)

**Dependencies**:
- reticulate (R package)
- praat-parselmouth (Python package)
