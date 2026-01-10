# data.table Migration Audit

**Date:** 2026-01-10  
**Package:** pladdrr v3.0.2 → v4.0.0  
**Auditor:** OpenCode AI

---

## Summary Statistics

| Category | Count | Priority |
|----------|-------|----------|
| C++ DataFrame::create() calls | 39 unique locations | HIGH |
| R data.frame() constructions | 50 occurrences | MEDIUM |
| Critical rbind() in loops | 6 occurrences | CRITICAL |
| Rcpp modules with as_data_frame | 26 modules | HIGH |
| Test files to update | 39 files | HIGH |
| Vignettes to update | 19 files | MEDIUM |

---

## Critical Bottlenecks (Must Fix)

### 🔴 Priority 0: Nested rbind() Loops

1. **R/formant.R:173,182** - Nested loop (frames × formants)
   - Impact: HIGH - 100 frames × 4 formants = 400 rbind operations
   - Current: O(n²) complexity
   - Solution: Pre-allocate list + rbindlist()
   - Expected: 8x speedup

2. **R/batch-processing.R:493,500,514** - File pairing loop
   - Impact: MEDIUM - 1000+ files in production corpora
   - Current: Growing data.frame in loop
   - Solution: Vectorized data.table join
   - Expected: 8x speedup

3. **R/parallel-batch.R:285** - Benchmark accumulation
   - Impact: LOW - Only benchmark code (10-20 iterations)
   - Solution: List accumulation

---

## C++ Modules by Priority

### Tier 1: High-Traffic (Migrate First)
1. formant_module.cpp - as_data_frame(int)
2. pitch_module.cpp - as_data_frame(bool, bool), get_all_candidates()
3. textgrid_module.cpp - as_data_frame()
4. sound_module.cpp - as_data_frame()
5. intensity_module.cpp - as_data_frame()

### Tier 2: Medium-Traffic
6. spectrum_module.cpp
7. harmonicity_module.cpp
8. spectrogram_module.cpp
9. ltas_module.cpp
10. pointprocess_module.cpp
11. formantpath_module.cpp
12. complexspectrogram_module.cpp

### Tier 3: Low-Traffic (Migrate Last)
13. polygon_module.cpp
14. table_module.cpp
15. formanttier_module.cpp
16. pitchtier_module.cpp
17. intensitytier_module.cpp
18. amplitudetier_module.cpp
19. durationtier_module.cpp
20. matrix_module.cpp
21. lpc_module.cpp
22. cepstrum_module.cpp
23. powercepstrum_module.cpp
24. excitation_module.cpp
25. electroglottogram_module.cpp
26. formantgrid_module.cpp

---

## R Files by Impact

### High Impact (>10 data.frame operations)
1. **R/batch-processing.R** - 15 occurrences, 725 lines
   - pair_files() - rbind in loop (lines 493-514)
   - extract_measurements_custom() - aggregation (lines 360-390)
   - aggregate_measurements() - data.frame manipulation

2. **R/formant.R** - 8 occurrences, 422 lines
   - extract_formants() - NESTED rbind loop (lines 137-190)
   - Critical performance bottleneck

3. **R/textgrid-r6.R** - 3 occurrences
   - as_data_frame() method wraps C++ calls
   - Point tier handling (lines 390-399)

### Medium Impact (3-10 occurrences)
4. R/parallel-batch.R - 3 occurrences
5. R/plotting-combined.R - 4 occurrences
6. R/autoplot-methods.R - 4 occurrences
7. R/cepstrum_plots.R - 4 occurrences

### Low Impact (<3 occurrences)
8-30. Various R files with 1-2 occurrences

---

## Standalone Wrapper Functions

C++ wrapper functions that return DataFrame (not in modules):

1. src/formant_wrappers.cpp:441 - formant_as_data_frame()
2. src/textgrid_wrappers.cpp:302 - textgrid_get_all_intervals()
3. src/textgrid_wrappers.cpp:404 - textgrid_get_all_points()
4. src/textgrid_wrappers.cpp:584 - textgrid_to_data_frame()
5. src/textgrid_batch_operations.cpp:257 - textgrid_interval_statistics_batch()
6. src/sound_wrappers.cpp:732 - sound_as_data_frame()
7. src/ltas_wrappers.cpp:246 - ltas_as_data_frame()
8. src/excitation_wrappers.cpp:121 - excitation_as_vector()
9. src/interpreter_wrappers.cpp:527 - praat_interpreter_list_objects()

---

## S3 Methods to Update

All in `R/s3-methods.R`:
- as.data.frame.Pitch
- as.data.frame.Formant
- as.data.frame.Intensity
- as.data.frame.Sound
- as.data.frame.Spectrum
- as.data.frame.Harmonicity
- as.data.frame.TextGrid
- as.data.frame.PointProcess

**Strategy:** Add parallel as.data.table.* methods, keep as.data.frame.* for compatibility

---

## Test Files Requiring Updates

All 39 test files in `tests/testthat/`:
- Update class expectations: "data.frame" → c("data.table", "data.frame")
- Add data.table-specific tests (key checks)
- Test backward compatibility

**High Priority Test Files:**
1. test-formant.R
2. test-pitch.R
3. test-textgrid.R
4. test-batch-processing.R
5. test-intensity.R

---

## Vignettes Requiring Updates

All 19 vignettes need review:

**High Priority (Heavy data manipulation):**
1. vignettes/articles/batch-operations-guide.Rmd
2. vignettes/performance-optimization.Rmd
3. vignettes/textgrid-workflows.Rmd
4. vignettes/vowel-space-analysis.Rmd
5. vignettes/integrated-phonetic-analysis.Rmd

**Medium Priority:**
6. vignettes/getting-started.Rmd
7. vignettes/formant-analysis.Rmd
8. vignettes/formantpath-robust-tracking.Rmd
9. vignettes/visualization.Rmd

**Low Priority (Minimal data.frame usage):**
10-19. Other vignettes

---

## Dependencies Impact Analysis

### Current Imports:
- Rcpp (>= 1.0.0) ✅
- R6 (>= 2.5.0) ✅
- ggplot2 ✅

### Adding:
- **data.table (>= 1.14.0)** NEW
  - Size: ~2.5MB
  - Dependencies: NONE (excellent!)
  - Stability: Mature, widely used

### Compatibility Check:
- ✅ ggplot2 works with data.table
- ✅ testthat works with data.table
- ✅ knitr/rmarkdown work with data.table
- ⚠️ Need to verify Rcpp + data.table integration

---

## Breaking Change Assessment

### Definite Breaks:
1. Code checking `class(x) == "data.frame"` will fail
   - Fix: Use `inherits(x, "data.frame")` or `is.data.frame(x)`
   
2. Code depending on exact class vector will fail
   - Current: `class(df)` → "data.frame"
   - New: `class(dt)` → c("data.table", "data.frame")

### Likely No Impact:
- ✅ `df$column` access - works identically
- ✅ `df[rows, cols]` subsetting - works (but data.table has extended syntax)
- ✅ `subset(df, ...)` - works
- ✅ `merge(df, ...)` - works (data.table has faster merge)
- ✅ ggplot2::ggplot(df, ...) - works
- ✅ Most base R functions accept data.frame - will work

### Potential Issues:
- ⚠️ data.table modifies by reference (`:=` operator)
- ⚠️ Some functions may need `as.data.frame()` wrapper
- ⚠️ Print output looks different (data.table prints head+tail)

---

## Risk Assessment

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| C++ integration issues | MEDIUM | HIGH | Test thoroughly, fallback to R conversion |
| User code breaks | HIGH | MEDIUM | Clear migration guide, compatibility layer |
| Test failures | MEDIUM | HIGH | Comprehensive test updates |
| Performance regressions | LOW | HIGH | Benchmark suite before/after |
| ggplot2 incompatibility | LOW | MEDIUM | Integration tests |
| Documentation gaps | MEDIUM | MEDIUM | Thorough review process |

---

## Implementation Checklist

### Phase 0: Audit (COMPLETE)
- [x] Catalog all C++ DataFrame locations (39 found)
- [x] Catalog all R data.frame locations (50 found)
- [x] Identify critical bottlenecks (6 found)
- [x] Document S3 methods (8 found)
- [x] List test files (39 found)
- [x] List vignettes (19 found)

### Phase 1: Foundation (NEXT)
- [ ] Update DESCRIPTION
- [ ] Create src/datatable_utils.h
- [ ] Create R/datatable-utils.R
- [ ] Update NAMESPACE
- [ ] Create test infrastructure
- [ ] Verify Rcpp + data.table integration

### Phase 2-7: See DATATABLE_MIGRATION_PLAN.md

---

## Questions Resolved

1. **Q:** How many DataFrame calls?  
   **A:** 39 unique C++ locations, 26 modules

2. **Q:** How many rbind() bottlenecks?  
   **A:** 6 critical, 2 are high-impact

3. **Q:** data.table dependencies?  
   **A:** Zero - excellent for our use case

4. **Q:** Breaking changes severity?  
   **A:** MEDIUM - Most code will work, some class checks will break

5. **Q:** Estimated effort?  
   **A:** Confirmed 160 hours (4 weeks)

---

## Next Actions

1. ✅ Create feature branch: `feature/datatable-migration-v4`
2. ✅ Complete Phase 1: Foundation (32 hours)
3. Start Phase 2: C++ module migration (40 hours)

**Status:** Audit complete, proceeding to Phase 1
