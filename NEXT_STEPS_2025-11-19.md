# Next Steps - 2025-11-19

## Current Status: v0.5.3

### What's Working ✅
- **All core functionality**: Sound generation, Pitch extraction, Formant analysis, Intensity, etc.
- **TextGrid operations**: Create, edit, query, save (just not load from files)
- **SIMD optimizations**: 2-4x performance improvements implemented
- **R6 object system**: Full OOP interface with methods and properties
- **Package builds cleanly**: No errors, only warnings (about MSVC ABI - not relevant for macOS/Linux)

### Known Limitation ⚠️
- **File I/O disabled**: Cannot read TextGrid or Sound files from disk
- **Reason**: Praat's `Data_readFromFile()` requires additional initialization that causes segfaults
- **Workaround**: Use programmatic creation (`TextGrid$create()`, `Sound$create_tone()`)
- **Documented in**: SESSION_SUMMARY_2025-11-19.md

## Immediate Next Steps (Priority Order)

### 1. Fix File I/O (HIGH PRIORITY for v0.6.0) 🔴

**Investigation paths**:

a) **Missing Data_recognizeFileType() calls**:
```cpp
// In praat_initialize(), add:
Data_recognizeFileType(soundFileRecognizer);
Data_recognizeFileType(textGridRecognizer);
// etc...
```

b) **Call full praat_init()**:
   - Currently: We call `praat_initialize()` (custom)
   - Praat expects: `praat_init(title, version, ...)`
   - May need to stub out GUI components

c) **Use class-specific readers**:
   - Instead of `Data_readFromFile()`
   - Try `Sound_readFromSoundFile()` directly
   - May bypass initialization issues

d) **Custom parser** (last resort):
   - Implement TextGrid text format parser in C++
   - Avoids Praat's complex initialization
   - More maintainable long-term

**Estimated effort**: 4-8 hours
**Target**: v0.6.0 (Dec 2025)

### 2. Update Examples to Use Programmatic Creation

**Files to update**:
- `inst/examples/06_textgrid_analysis.R` ✓ Already using create()
- `inst/examples/textgrid_editing_demo.R` ✓ Already using create()
- Any vignettes that load files

**Action**: Verify all examples work without file I/O

### 3. Complete SIMD Benchmarking Suite

**Status**: Partially complete
- Phase 1-3 benchmarks: Working
- Parselmouth comparison: Requires test files (blocked by file I/O)

**Action**:
- Run complete benchmark suite with generated data
- Document SIMD performance gains
- Create SIMD_BENCHMARKS.md report

### 4. Unit Testing for SIMD

**Create test files** (as outlined in SIMD_COMPLETION_ASSESSMENT):
- `tests/testthat/test-simd-matrix.R`
- `tests/testthat/test-simd-sound-conversion.R`  
- `tests/testthat/test-simd-autocorrelation.R`
- etc.

**Test criteria**:
- Numerical accuracy (tolerance < 1e-12)
- Performance gains (>1.5x speedup)
- Edge cases (empty, single element, odd sizes)

### 5. Documentation Updates

**Files needing updates**:
- README.md: Add file I/O limitation note
- SIMD_PATTERNS.md: Create developer guide
- Vignettes: Update to use programmatic creation

## Medium-Term Goals (v0.6.0 - v1.0.0)

### v0.6.0 (Target: December 2025)
- ✅ **Resolve file I/O completely**
- Add file-based examples
- Complete SIMD testing
- Documentation polish

### v0.7.0 (Target: January 2026)
- Cross-platform testing (Windows, Linux, macOS)
- R CMD check --as-cran compliance
- Performance optimization based on benchmarks

### v1.0.0 (Target: February 2026)
- Production-ready release
- Complete documentation
- Comprehensive test coverage (>90%)
- CRAN submission

## Development Workflow

### Building and Testing
```r
# Build to local library
R CMD INSTALL --library=~/R_libs .

# Test basic functionality
.libPaths(c("~/R_libs", .libPaths()))
library(speaker)

# Create objects programmatically
sound <- Sound$create_tone(1.0, 440, 44100, 0.5)
pitch <- sound$to_pitch()
tg <- TextGrid$create(0, 5, "phones words")
```

### Running Benchmarks
```bash
# SIMD vs Scalar comparison
Rscript inst/benchmarks/run_scalar_baseline.R
Rscript inst/benchmarks/run_simd_optimized.R
Rscript inst/benchmarks/compare_results.R
```

### Running Tests
```bash
# All tests
R CMD check --as-cran .

# Specific test file
testthat::test_file("tests/testthat/test-sound.R")
```

## Technical Debt

1. **File I/O initialization** (CRITICAL)
2. **SIMD test coverage** (HIGH)
3. **Documentation completeness** (MEDIUM)
4. **Windows compatibility testing** (MEDIUM)
5. **Memory leak detection** (LOW - XPtr should handle this)

## Questions to Investigate

1. Does `Sound_readFromSoundFile()` work if called directly?
2. What exact Praat initialization sequence is needed?
3. Can we use rPraat to parse TextGrids, then convert?
4. Should we implement custom TextGrid parser?

## Resources

- **Praat source**: `src/praat.github.io/`
- **Investigation log**: `SESSION_SUMMARY_2025-11-19.md`
- **SIMD status**: `SIMD_COMPLETION_ASSESSMENT_2025-11-17.md`
- **Architecture**: `AMENDMENT_COMPLETE.md`

## Success Metrics for v1.0.0

- [ ] All file I/O working
- [ ] 90%+ test coverage
- [ ] R CMD check --as-cran passes
- [ ] SIMD performance documented
- [ ] 5+ comprehensive examples
- [ ] Complete vignettes
- [ ] Windows/Linux/macOS verified

---

**Last Updated**: 2025-11-19
**Current Version**: 0.5.3
**Next Milestone**: v0.6.0 (File I/O fixed)
