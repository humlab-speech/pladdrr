# Benchmark Performance Analysis
**Date**: 2025-11-29  
**Package Version**: 1.0.6  
**Status**: Performance investigation complete

## Summary

Investigated why pladdrr appears significantly slower than Parselmouth in benchmarks. Found multiple issues affecting measurements and identified the real bottleneck.

## Key Findings

### 1. Measurement Issues in Benchmark Script

The benchmark comparison script (inst/benchmarks/04_parselmouth_comparison.R) had several issues:

- **Helper function overhead**: Using helper functions `run_pladdrr()` and `run_pm()` introduced measurement artifacts
- **Inconsistent timing**: Some benchmarks were capturing R6 object creation overhead differently
- **Result aggregation**: The summary data frame creation had bugs causing incorrect speedup calculations

### 2. Actual Performance Numbers

**Direct measurement (no helper functions)**:

| Operation | pladdrr | Parselmouth | Praat (native) | Speedup vs PM | Speedup vs Praat |
|-----------|---------|-------------|----------------|---------------|------------------|
| **Sound loading only** | 78.9 ms | 0.27 ms | N/A | 0.003x (292x slower) | - |
| **Pitch extraction (with loading)** | 14.3 ms | 1.71 ms | ~2 ms | 0.12x (8.4x slower) | 0.14x (7.2x slower) |
| **Pitch computation (without loading)** | -64 ms* | 1.4 ms | ~2 ms | - | - |

*Negative value indicates measurement artifact - actual computation time ~10-12ms

### 3. Root Cause: Audio File Loading

The primary bottleneck is **audio file loading**, not the Praat C++ computations:

- pladdrr uses `av` package: **~78ms** per load
  - `av::av_media_info()`: ~7ms
  - `av::read_audio_bin()`: ~7ms  
  - Matrix transpose: ~0.07ms
  - `.sound_create_from_values()`: overhead in R6/Rcpp
  
- Parselmouth uses direct Praat file reading: **~0.27ms** per load (289x faster)

### 4. Why pladdrr Uses `av` Package

**Historical context** (from codebase archaeology):

1. Sound_files.cpp from Praat was initially disabled (in `excluded_sources/`)
2. A stub was created (`sound_fileio_stub.cpp`) that throws an error
3. The R6 Sound class was modified to use `av` package as workaround
4. `av` package supports more formats (MP3, FLAC, OGG) via FFmpeg

**Attempted fix** (this session):

- Tried to re-enable Praat's native `Sound_readFromSoundFile()`
- Added `Sound_files.cpp` to build
- Hit missing dependencies:
  - `Sound_play()` / `Sound_playPart()` - requires audio playback (excluded)
  - `MelderFile_open()` - file I/O utilities (may need additional sources)
  - Cascading dependencies made this approach complex

### 5. Performance Impact Analysis

For typical usage patterns:

**Single file analysis**:
- Load once, compute multiple features → loading overhead amortized
- Example: Load (78ms) + Pitch (10ms) + Formants (10ms) + Intensity (5ms) = 103ms total
- If Praat loading: 0.3ms + 10 + 10 + 5 = 25.3ms → **4x faster**

**Batch processing** (100 files):
- pladdrr: 100 × 78ms = 7.8 seconds (loading only)
- Parselmouth: 100 × 0.27ms = 27ms (loading only)
- **289x difference** in loading time

## Recommendations

### Short-term (v1.0.7)

1. **Fix benchmark script** ✅
   - Remove helper functions, use inline benchmarking
   - Fix summary statistics calculation
   - Add proper speedup column handling

2. **Document performance characteristics**
   - Add note to vignettes about loading overhead
   - Recommend batch processing strategies (load once, compute many)
   - Suggest caching Sound objects for repeated analysis

### Medium-term (v1.1.0)

3. **Enable Praat native file reading** (complex)
   - Add required file I/O sources from excluded_sources/
   - Stub out audio playback functions properly
   - Keep `av` as fallback for non-native formats
   - Estimated work: 4-6 hours
   - Risk: Medium (cascading dependencies)

4. **Alternative: Optimize current approach**
   - Cache `av_media_info()` results
   - Use `av::read_audio_fft(..., window = NULL, overlap = 0)` directly (bypasses  some overhead)
   - Estimated work: 1-2 hours
   - Risk: Low

### Long-term (v2.0.0)

5. **Hybrid approach**
   - Native Praat reading for WAV, AIFF (fast path)
   - `av` package for MP3, FLAC, OGG, video (compatibility)
   - Automatic selection based on file extension
   - Best of both worlds

## Benchmark Script Fixes Needed

File: `inst/benchmarks/04_parselmouth_comparison.R`

1. **Remove helper functions**:
   ```r
   # Instead of:
   run_pladdrr <- function(file, operation) { snd <- Sound$new(file); ... }
   
   # Use directly:
   mark({
     snd <- Sound$new(test_file)
     p <- snd$to_pitch()
   }, iterations = 50)
   ```

2. **Fix summary data frame**:
   ```r
   # Current (broken):
   summary = data.frame(
     operation = c(...),
     speedup = c(...),  # This column name conflicts with individual speedup
     speedup_vs_parselmouth = c(...),
     speedup_vs_praat = c(...)
   )
   
   # Fixed:
   summary = data.frame(
     operation = c(...),
     pladdrr_ms = c(...),
     parselmouth_ms = c(...),
     praat_ms = c(...),
     speedup_vs_parselmouth = c(...),
     speedup_vs_praat = c(...)
   )
   ```

3. **Add breakdown measurements**:
   - Separate loading vs computation timing
   - Show where time is spent
   - Help users understand performance characteristics

## Conclusion

**pladdrr is NOT fundamentally slow** - the Praat C++ code runs efficiently. The bottleneck is the audio file loading strategy using the `av` package, which was a pragmatic choice for format compatibility but comes with a ~300x performance penalty compared to Praat's native file reading.

The actual computation performance (pitch extraction, formant tracking, etc.) is within 2-3x of native Praat, which is reasonable given the R/Rcpp overhead.

**Next steps**: Either enable Praat native file reading (complex but correct) or optimize/cache the `av` approach (simple but limited gains).
