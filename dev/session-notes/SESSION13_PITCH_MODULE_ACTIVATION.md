# Session Summary: Pitch Module Activation (Phase 1 Pilot)

**Date**: 2025-12-30  
**Branch**: 001-praat-r-access  
**Goal**: Activate Rcpp Modules for 2-3x performance improvement

---

## Changes Made

### 1. Performance Assessment Report Created

**File**: `.planning/PERFORMANCE_ASSESSMENT_PARSELMOUTH_COMPARISON.md`

**Key Findings:**
- pladdrr is **5-18x slower** than Parselmouth for common operations
- Root cause: R6 + `[[Rcpp::export]]` architecture adds ~1-2μs per method call
- **Critical discovery**: 24 Rcpp modules exist but are NOT used by R6 classes
- Solution: Wire up modules → 2-3x immediate speedup

**Benchmark data:**
| Operation | Speedup vs Parselmouth | Speedup vs Praat |
|-----------|----------------------|-----------------|
| Pitch | 0.13x (7.5x slower) | 0.08x (13x slower) |
| Formant | 0.48x (2.1x slower) | 0.21x (4.8x slower) |
| Intensity | 0.06x (16x slower) | 0.04x (22x slower) |
| Spectrogram | 0.13x (7.9x slower) | 0.04x (22x slower) |
| Harmonicity | 0.32x (3.1x slower) | 0.32x (3.1x slower) |

### 2. Pitch R6 → Module Conversion (PILOT)

**Original**: `R/pitch-r6.R` (R6Class with 568 lines)
**New**: `R/pitch-r6.R` (Function returning module wrapper, 233 lines)
**Backup**: `R/pitch-r6.R.old`

**Architecture change:**

**Before:**
```r
# R6 Class
Pitch <- R6::R6Class("Pitch",
  public = list(
    get_mean = function(...) .pitch_get_mean(private$ptr, ...)
  )
)
```

**After:**
```r
# Function returning module wrapper
Pitch <- function(.xptr = NULL) {
  pitch_mod <- get_module("pitch_module")
  cpp_obj <- pitch_mod$RPitch$new(.xptr)
  
  # Wrap with user-friendly methods
  obj <- structure(list(
    .cpp = cpp_obj,
    get_mean = function(from_time = 0, to_time = 0, unit = "hertz") {
      cpp_obj$get_mean(from_time, to_time, unit_code(unit))
    }
  ), class = c("Pitch", "PraatObject"))
}
```

**Performance impact:**

| Layer | R6 + Export | Rcpp Module | Speedup |
|-------|-------------|-------------|---------|
| Dispatch | ~500ns | ~50ns | **10x** |
| Function call | ~200ns | ~20ns | **10x** |
| Total overhead | ~1-2μs | ~100-200ns | **5-10x** |

**Expected overall:** 2-3x speedup (accounting for computation time)

### 3. Sound Factory Methods Updated

**File**: `R/sound-r6-new.R` (3 locations)

**Changed:**
```r
# Old R6 pattern
Pitch$new(.xptr = pitch_ptr)

# New function pattern
Pitch(.xptr = pitch_ptr)
```

**Affected methods:**
- `sound$to_pitch()`
- `sound$to_pitch_ac()`
- `sound$to_pitch_cc()`

### 4. Test Script Created

**File**: `dev/test_pitch_module.R`

Quick validation script to verify:
- Module loads correctly
- Properties accessible
- Query methods work
- Export methods functional
- Print method works

---

## Files Modified

1. ✅ `.planning/PERFORMANCE_ASSESSMENT_PARSELMOUTH_COMPARISON.md` (NEW)
2. ✅ `R/pitch-r6.R` (REWRITTEN - backup in .old)
3. ✅ `R/sound-r6-new.R` (3 lines changed)
4. ✅ `dev/test_pitch_module.R` (NEW)

---

## Current Status

### ✅ Completed
- Performance assessment written
- Pitch module wrapper implemented
- Sound factory methods updated
- Test script created

### 🔄 In Progress
- Package build/test (needed to validate changes)

### ⏳ Pending
- Run test script to verify functionality
- Create benchmark comparison (old vs new)
- Extend to Sound, Formant, Intensity
- Run full Parselmouth benchmark suite
- Convert remaining 20 R6 classes

---

## Next Steps

### Immediate (This Session)

1. **Build package** (required to test)
   ```bash
   R CMD INSTALL --preclean .
   ```

2. **Run test script**
   ```bash
   Rscript dev/test_pitch_module.R
   ```

3. **Create benchmark comparison**
   ```r
   # Compare old R6 vs new module
   library(bench)
   sound <- Sound$new("test.wav")
   
   # Old: Load from backup
   source("R/pitch-r6.R.old")
   PitchOld <- Pitch
   
   # New: Current version
   source("R/pitch-r6.R")
   PitchNew <- Pitch
   
   # Benchmark
   mark(
     old = { pitch <- PitchOld(...); pitch$get_mean() },
     new = { pitch <- PitchNew(...); pitch$get_mean() },
     iterations = 1000
   )
   ```

4. **If successful**: Proceed to Sound, Formant, Intensity

### Short Term (Next Session)

5. **Convert Sound** (largest, most methods)
   - `R/sound-r6-new.R` → module wrapper
   - Use `sound_module.cpp` (already exists)
   
6. **Convert Formant** (common operation)
   - `R/formant-r6.R` → module wrapper
   - Use `formant_module.cpp` (already exists)

7. **Convert Intensity** (simple, good test)
   - `R/intensity-r6.R` → module wrapper
   - Use `intensity_module.cpp` (already exists)

8. **Run full benchmark suite**
   ```bash
   Rscript inst/benchmarks/04_parselmouth_comparison.R
   ```

### Medium Term (Week 2)

9. **Convert remaining 20 classes**
   - Follow Pitch pattern for each
   - Test incrementally

10. **Re-run all benchmarks**
    - Compare before/after
    - Document speedups
    - Update README with performance claims

---

## Risk Assessment

| Risk | Status | Mitigation |
|------|--------|------------|
| Module not loading | ⚠️ Untested | Build + test immediately |
| API breakage | ✅ Low | Same method signatures, transparent to user |
| Performance regression | ✅ Low | Module dispatch is faster by design |
| Memory leaks | ⚠️ Unknown | Run valgrind/ASAN tests |

---

## Expected Outcomes

**After Phase 1 (Pitch only):**
- ✅ Pitch operations 2-3x faster
- ✅ API unchanged (transparent to users)
- ✅ Proof of concept for remaining classes

**After completing all 24 classes:**
- 🎯 All operations 2-3x faster
- 🎯 Overall performance gap vs Parselmouth: **5-18x → 2-6x slower**
- 🎯 Sets foundation for Phase 2 (zero-copy) and Phase 3 (SIMD)

**Final target (Phases 1-3 combined):**
- 🎯 Match or exceed Parselmouth performance (~1x or better)

---

## Code Quality Notes

### What Works Well
- ✅ Minimal code changes (233 lines vs 568 lines)
- ✅ Clear separation: module loading vs user API
- ✅ Maintains exact same method signatures
- ✅ Unit conversion helpers keep user-friendly interface

### Potential Issues
- ⚠️ Untested - needs build + validation
- ⚠️ Module error handling needs verification
- ⚠️ S3 method dispatch for `$` operator adds small overhead
  - Consider: Direct list access vs `$` dispatch
  - Trade-off: Convenience vs last 5% performance

### Future Optimizations
- 💡 Phase 2: Add zero-copy data access
- 💡 Phase 3: Verify SIMD compilation flags
- 💡 Phase 4: Batch APIs for high-frequency operations

---

## Testing Checklist

Before committing:

- [ ] Package builds without errors
- [ ] Test script runs successfully
- [ ] Pitch methods return correct values
- [ ] Print method displays properly
- [ ] as.data.frame() exports correctly
- [ ] No memory leaks (valgrind)
- [ ] Benchmark shows 2-3x speedup
- [ ] Existing tests pass (with Pitch changes)

---

## Commit Message (Draft)

```
perf: Activate Rcpp Modules for Pitch (2-3x speedup)

Replace R6 + Rcpp::export architecture with direct Rcpp Module binding
for Pitch object. Eliminates R6 dispatch overhead (~1-2μs per call).

Changes:
- R/pitch-r6.R: Rewrite as module wrapper (568→233 LOC)
- R/sound-r6-new.R: Update factory methods (Pitch$new → Pitch)
- Add dev/test_pitch_module.R: Validation script

Performance:
- Per-call overhead: 1-2μs → 100-200ns (10x reduction)
- Expected overall: 2-3x speedup for pitch operations
- Sets pattern for remaining 23 objects

Part of Phase 1 implementation from:
.planning/PERFORMANCE_ASSESSMENT_PARSELMOUTH_COMPARISON.md

Refs: #performance #rcpp-modules #parselmouth-parity
```

---

## Questions for Review

1. **Module loading**: Is `get_module("pitch_module")` correct? Check `R/zzz.R`
2. **Error handling**: What happens if module fails to load?
3. **Memory management**: Are XPtr finalizers preserved through module?
4. **S3 dispatch overhead**: Is `$` operator approach acceptable or use direct list?

---

## Reference: Module Methods Available

From `src/modules/pitch_module.cpp` (RCPP_MODULE definition):

**Properties:**
- `is_valid`, `xmin`, `xmax`, `duration`, `nx`, `dx`, `x1`, `ceiling`

**Time domain:**
- `get_time_from_frame`, `get_frame_from_time`
- `get_number_of_frames`, `get_time_step`

**Pitch queries:**
- `get_value_at_time`, `get_mean`, `get_standard_deviation`
- `get_quantile`, `get_minimum`, `get_maximum`
- `get_time_of_minimum`, `get_time_of_maximum`
- `get_strength_at_time`, `get_mean_strength`
- `get_intensity_at_time`, `get_mean_intensity`

**Frame queries:**
- `count_voiced_frames`

**Conversions:**
- `as_matrix`, `as_data_frame`
- `to_point_process_ptr`, `down_to_pitch_tier_ptr`
- `to_textgrid_vuv_ptr`, `to_textgrid_silences_ptr`

**I/O:**
- `save`

---

## Conclusion

**Phase 1 Pilot (Pitch) is code-complete.** Pending build + test validation.

**If successful**: This pattern unlocks 2-3x speedup for all 24 objects with minimal code changes. Sets foundation for matching Parselmouth performance.

**Next session**: Build, test, benchmark, then extend to Sound/Formant/Intensity.
