# Session 10: CRAN Check Issues - Priority Fix List

**Date**: 2025-12-21  
**Package**: pladdrr v1.3.0  
**Status**: 9 WARNINGS, 8 NOTES - needs cleanup before CRAN submission

## Critical Issues (Must Fix for CRAN)

### 1. Object Files in Source Package ⚠️ HIGH PRIORITY
**Issue**: `.o` files and compiled libraries left in src/

**Fix Required**:
```bash
# Clean all object files
cd /Users/frkkan96/Documents/src/pladdrr
make clean
rm -f src/*.o src/*.so
find src/praat.github.io -name "*.o" -delete
find src/gsl-2.8 -name "*.o" -delete
find src/gsl-2.8 -name "*.la" -delete
```

**Files Affected**: 60+ object files listed in check output

### 2. Executable Files Included ⚠️ HIGH PRIORITY
**Issue**: Binary executables in source (sendpraat, spit)

**Fix Required**:
```bash
# Remove executables from praat.github.io subdirs
rm -f src/praat.github.io/docs/sendpraat-*
rm -f src/praat.github.io/docs/silipa93.exe
rm -rf src/praat.github.io/test/manually/spit/
```

**Files**: 10+ executables in docs/ and test/ dirs

### 3. Hidden Files (.git, .DS_Store) ⚠️ HIGH PRIORITY
**Issue**: Git repos, build artifacts, macOS files included

**Fix Required**:
```bash
# Remove all git submodules and hidden files
rm -rf src/clapack/.git
rm -rf src/pffft/.git
rm -rf src/praat.github.io/.git
find . -name ".DS_Store" -delete
rm -rf .git .github .serena .specify .claude
rm -rf ..Rcheck
```

**Files**: 100+ hidden files/dirs

### 4. Non-portable File Names ⚠️ MEDIUM PRIORITY
**Issue**: Unicode chars, spaces in filenames (praat test files)

**Fix Required**:
```bash
# Remove problematic test files from praat source
rm -rf "src/praat.github.io/test/fon ExperimentMFC/"
rm -rf "src/praat.github.io/test/sys/large PDF/"
rm -rf "src/praat.github.io/test/manually/external/Chris Darwin/"
# Or: exclude test/ dir entirely from package
```

**Files**: 20+ non-portable paths in praat test files

### 5. Top-Level Documentation Files ⚠️ MEDIUM PRIORITY
**Issue**: Session notes, dev docs should not be in package root

**Fix Required**:
```bash
# Move to dev/ or remove from package
mkdir -p dev/session-notes
mv CLAUDE.md SESSION*.md TEXTGRID*.md PRAAT*.md QUICK*.md dev/session-notes/
mv DEBUG*.md NEXT*.md DOCUMENTATION*.md PLADDRR*.md dev/session-notes/
mv *.log test_*.R verify_*.R final_*.R dev/
mv *.tar.gz dev/
mv specs/ dev/ docs/ dev/
```

**Files**: 30+ markdown/log files in root

### 6. Missing GitHub Repo ⚠️ LOW PRIORITY
**Issue**: URLs point to non-existent repo

**Fix Required**:
Edit `DESCRIPTION`:
```r
# Change from:
URL: https://github.com/humlab-speech/pladdrr
BugReports: https://github.com/humlab-speech/pladdrr/issues

# To actual working repo, or remove if not public yet
```

## Package Size Warning

**Issue**: 71.9 MB installed size (CRAN prefers <5MB)

**Breakdown**:
- `inst/extdata`: 50.2 MB (audio files)
- `libs`: 13.9 MB (compiled code)
- `inst/signalfiles`: 3.2 MB

**Options**:
1. Remove large test audio files from `inst/extdata`
2. Use download-on-demand for benchmarks
3. Compress audio files more aggressively
4. Move benchmarks to separate package

## NAMESPACE Fixes Required

**Issue**: Missing imports for base R functions

**Fix**: Add to `NAMESPACE`:
```r
importFrom("stats", "aggregate", "approx", "fitted", "lm", "median",
           "predict", "quantile", "rnorm", "sd", "time")
importFrom("utils", "head")
```

**Or better**: Add to R files using these functions:
```r
#' @importFrom stats sd median aggregate
#' @importFrom utils head
```

## Makevars Issues

**Issues**:
1. Non-portable compiler flags (`-march=armv8-a+simd`)
2. Both `Makevars` and `Makevars.in` present
3. GNU extensions (`+=`, `wildcard`, etc.)
4. `$(BLAS_LIBS)` not followed by `$(FLIBS)`

**Fix Strategy**:
1. Remove platform-specific flags from Makevars.in
2. Delete `src/Makevars` (generated file)
3. Use portable Makefile syntax
4. Fix BLAS/LAPACK linking order

## Minor Fixes

### LazyData Without data/
**Fix**: Remove `LazyData: true` from DESCRIPTION (no data/ dir)

### CRLF Line Endings
**Fix**: Convert GSL headers to LF
```bash
dos2unix src/gsl-2.8/gsl/gsl_sf_hermite.h
dos2unix src/gsl-2.8/specfunc/gsl_sf_hermite.h
```

### Documentation \usage Mismatches
**Fix**: Update Rd files for:
- `batch_process.Rd` - remove 'cores' arg
- `extract_measurements.Rd` - fix arg list

### Unknown DESCRIPTION Fields
**Fix**: Remove `Remotes:` field (CRAN ignores it)

## Recommended Fix Order

### Phase 1: Clean Build Artifacts (10 min)
```bash
make clean
find . -name "*.o" -delete
find . -name "*.so" -delete  
find . -name "*.la" -delete
find . -name ".DS_Store" -delete
rm -rf ..Rcheck
```

### Phase 2: Remove Non-Source Files (15 min)
```bash
# Git repos
rm -rf src/{clapack,pffft,praat.github.io}/.git

# Executables
rm -f src/praat.github.io/docs/{sendpraat-*,silipa93.exe}
rm -rf src/praat.github.io/test/manually/spit/

# Hidden dirs
rm -rf .git .github .serena .specify .claude

# Non-portable test files
rm -rf "src/praat.github.io/test/fon ExperimentMFC/"
# ... etc
```

### Phase 3: Reorganize Top-Level Files (10 min)
```bash
mkdir -p dev/session-notes
mv CLAUDE.md SESSION*.md dev/session-notes/
# ... move all non-essential files to dev/
```

### Phase 4: Fix Code Issues (30 min)
1. Add missing imports to NAMESPACE
2. Fix Makevars portability
3. Update documentation files
4. Fix line endings

### Phase 5: Reduce Package Size (optional, 1 hour)
1. Remove large audio files
2. Compress remaining test data
3. Consider splitting benchmarks to separate package

### Phase 6: Re-check (5 min)
```bash
R CMD build --no-manual .
R CMD check --as-cran pladdrr_1.3.0.tar.gz
```

## Expected Final Status

**Goal**: 0 ERRORS, 0 WARNINGS, 2-3 NOTES acceptable

**Acceptable NOTES**:
- "New submission" (first CRAN submission)
- "Installed size is XMb" (if <20MB)
- "C++17 not fully portable" (document in submission notes)

**Blockers for CRAN**:
- ❌ Object files (must remove)
- ❌ Executables (must remove)
- ❌ Git repos (must remove)
- ❌ Non-portable filenames (must fix/remove)
- ⚠️ Size >50MB (should reduce)

## Next Steps

Start with Phase 1 (clean) and work through systematically. After Phase 4, re-run check to verify fixes.

---

**Estimated Total Time**: 2-3 hours for full CRAN compliance
