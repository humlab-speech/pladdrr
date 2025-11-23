# Package Rename Documentation: speaker → pladdrr

**Date**: 2025-01-22
**Renaming**: speaker → pladdrr

This document catalogs ALL instances where "speaker" appears as the package name that need to be changed to "pladdrr" during the rename operation.

## Summary Statistics

- **Total files requiring changes**: 50+ files
- **Critical areas**: DESCRIPTION, NAMESPACE, R code, vignettes, documentation, C++ exports
- **GitHub URLs**: 26+ instances requiring update
- **C++ symbols**: 2000+ auto-generated symbols with `_speaker_` prefix

## 1. Package Definition Files

### DESCRIPTION (3 instances)
**File**: `DESCRIPTION`

```
Line 1:   Package: speaker
Line 42:  URL: https://github.com/humlab-speech/speaker
Line 43:  BugReports: https://github.com/humlab-speech/speaker/issues
```

**Action**:
- Change package name to "pladdrr"
- Update URLs to humlab-speech/pladdrr

### NAMESPACE (1 instance)
**File**: `NAMESPACE`

```
Line 103: useDynLib(speaker, .registration = TRUE)
```

**Action**: Change to `useDynLib(pladdrr, .registration = TRUE)`

## 2. Package Documentation

### R/speaker-package.R (14+ instances)
**File**: `R/speaker-package.R`

This is the main package documentation file. Contains:

```r
Line 1:   #' speaker: Direct Access to Praat C Functionality from R
Line 3:   #' The speaker package provides direct access to Praat's C phonetic analysis
Line 44:  #' The speaker package follows these core principles:
Line 80:  #' See \code{vignette("basic-usage", package = "speaker")} for an introduction
Line 102: #' @name speaker-package
Line 103: #' @aliases speaker
Line 104: #' @useDynLib speaker, .registration = TRUE
Line 121: "speaker: Direct access to Praat C functionality\n",
Line 122: "See ?speaker for an overview and citation information.\n",
Line 123: "Use citation('speaker') for citing this package in publications."
```

**Action**:
- Replace all "speaker" with "pladdrr"
- Update package title and description
- Change @name to `pladdrr-package`
- Change @aliases to `pladdrr`
- Update .onAttach message

### man/speaker-package.Rd (10+ instances)
**File**: `man/speaker-package.Rd` (auto-generated from speaker-package.R)

```
Line 2:   % Please edit documentation in R/speaker-package.R
Line 4:   \name{speaker-package}
Line 5:   \alias{speaker-package}
Line 6:   \alias{speaker}
Line 7:   \title{speaker: Direct Access to Praat C Functionality from R}
Line 9:   The speaker package provides direct access to Praat's C phonetic analysis
Line 53:  The speaker package follows these core principles:
Line 95:  See \code{vignette("basic-usage", package = "speaker")} for an introduction
Line 122: \item \url{https://github.com/humlab-speech/speaker}
Line 123: \item Report bugs at \url{https://github.com/humlab-speech/speaker/issues}
```

**Action**: Will be auto-regenerated from R/pladdrr-package.R via roxygen2

## 3. Citation Files

### inst/CITATION (6 instances)
**Files**:
- `inst/CITATION`
- `speaker/inst/CITATION` (duplicate)
- `speaker_1/inst/CITATION` (duplicate)

```
Line 3:  title    = "speaker: Object-Oriented Interface to Praat Phonetic Analysis",
Line 7:  url      = "https://github.com/humlab-speech/speaker",
Line 10: "speaker: Object-Oriented Interface to Praat Phonetic Analysis.",
Line 12: "https://github.com/humlab-speech/speaker"
```

**Action**:
- Update package title
- Update URL to humlab-speech/pladdrr
- Update textVersion

## 4. README and Documentation

### README.md (15+ instances)
**File**: `README.md`

```
Line 1:   # speaker
Line 7:   The `speaker` package provides direct, efficient access...
Line 37:  # Install speaker from GitHub
Line 38:  devtools::install_github("humlab-speech/speaker")
Line 55:  The `speaker` package uses the [humlab-speech/av]...
Line 110: library(speaker)
Line 184: library(speaker)
Line 296: |  | **speaker** (R) | **Parselmouth** (Python) |
Line 310: **speaker** provides the best of both worlds...
Line 320: vignette("integrated-phonetic-analysis", package = "speaker")
Line 323: vignette("vowel-space-analysis", package = "speaker")
Line 326: vignette("textgrid-workflows", package = "speaker")
Line 346: file.show(system.file("examples", "07_comprehensive_phonetic_analysis.R", package = "speaker"))
Line 348: # Run example (after installing speaker)
Line 349: source(system.file("examples", "07_comprehensive_phonetic_analysis.R", package = "speaker"))
```

**Action**: Replace all instances of "speaker" package name with "pladdrr"

### CLAUDE.md (Extensive references)
**File**: `CLAUDE.md`

This file contains extensive package documentation and references to "speaker". Major sections include:

- Package name throughout development history
- Installation instructions
- Example code with `library(speaker)`
- Architectural decisions
- Object implementation status

**Action**:
- Update all package name references
- Update library() calls
- Keep historical context but note rename

## 5. Vignettes

### Vignette Files Requiring Updates:

#### getting-started.Rmd (4 instances)
**File**: `vignettes/getting-started.Rmd`

```r
Line 29:  install.packages("speaker", type = "source")
Line 36:  library(speaker)
Line 360: packageVersion("speaker")
Line 369: - Package documentation: `help(package = "speaker")`
```

#### integrated-phonetic-analysis.Rmd (1 instance)
**File**: `vignettes/integrated-phonetic-analysis.Rmd`

```r
Line 68: library(speaker)
```

#### vowel-space-analysis.Rmd (1 instance)
**File**: `vignettes/vowel-space-analysis.Rmd`

```r
Line 79: library(speaker)
```

#### textgrid-workflows.Rmd (3 instances)
**File**: `vignettes/textgrid-workflows.Rmd`

```r
Line 72:  library(speaker)
Line 131: tg_file <- system.file("extdata", "benchmarkdata1min.TextGrid", package = "speaker")
Line 297: tg_file <- system.file("extdata", "benchmarkdata10min.TextGrid", package = "speaker")
```

#### visualization.Rmd (2 instances)
**File**: `vignettes/visualization.Rmd`

```r
Line 20: library(speaker)
Line 47: sound <- Sound$new(system.file("extdata", "voice_sample.wav", package = "speaker"))
```

**Action**: Update all `library(speaker)` and `package = "speaker"` references

## 6. C++ Exported Functions

### RcppExports.cpp and RcppExports.R (2000+ instances)
**Files**:
- `src/RcppExports.cpp`
- `R/RcppExports.R`

All C++ exported functions use the prefix `_speaker_`:

```cpp
// Examples from src/RcppExports.cpp
RcppExport SEXP _speaker_amplitude_tier_create_cpp(...)
RcppExport SEXP _speaker_amplitude_tier_add_point_cpp(...)
RcppExport SEXP _speaker_intensity_tier_to_amplitude_tier_cpp(...)
RcppExport SEXP _speaker_autocorrelation_simd(...)
RcppExport SEXP _speaker_matrix_multiply_rows_inplace(...)
// ... 2000+ more functions
```

**Action**:
- These will be **auto-regenerated** by running `Rcpp::compileAttributes()`
- After renaming package to "pladdrr", run compileAttributes() to regenerate with `_pladdrr_` prefix
- DO NOT manually edit these files

## 7. R Documentation Files (.Rd)

### man/*.Rd files (50+ files)
**Files**: All .Rd files in man/ directory

Many .Rd files contain references like:

```
\code{\link[speaker:PraatObject]{speaker::PraatObject}}
<a href='../../speaker/html/PraatObject.html'>
```

**Examples**:
- `man/TextGrid.Rd`
- `man/LPC.Rd`
- `man/IntensityTier.Rd`
- `man/Table.Rd`
- etc.

**Action**: Will be auto-regenerated by `devtools::document()` after updating R source files

## 8. Test Files

### tests/testthat/*.R (Multiple files)
**Files**: Test files in tests/testthat/

```r
// From test-simd-matrix.R and test-simd-autocorrelation.R
skip_if_not_installed("speaker")
library(speaker)
if (exists(".autocorrelation_simd", where = asNamespace("speaker"), inherits = FALSE))
```

**Action**:
- Update `skip_if_not_installed("pladdrr")`
- Update `library(pladdrr)`
- Update `asNamespace("pladdrr")`

## 9. Other R Source Files

### R/sound.R
**File**: `R/sound.R`

```r
Line 3: # This file implements the primary sound object interface for the speaker package.
```

### R/ltas-r6.R
**File**: `R/ltas-r6.R`

```r
Line 8: #' analysis and speaker characterization.
```

**Note**: This "speaker" refers to "person speaking", not the package name. May want to review context.

**Action**: Update package reference comment, keep "speaker" if referring to person

## 10. Documentation Markdown Files (300+ files)

### Major Documentation Files Requiring Updates:

Files with extensive "speaker" package references:

1. **AMENDMENT_COMPLETE.md** - Multiple references to package capabilities
2. **AV_INTEGRATION_COMPLETE.md** - av package integration documentation
3. **AV_INTEGRATION_STATUS.md** - Integration status
4. **AVQI_DSI_ANALYSIS_SUMMARY.md** - Voice quality analysis
5. **AVQI_DSI_COMPARISON_TABLE.md** - Feature comparison table
6. **AVQI_DSI_COMPLETE_STATUS.md** - Implementation status with code examples
7. **AVQI_DSI_GAP_ANALYSIS.md** - Gap analysis with code examples
8. **AVQI_DSI_IMPLEMENTATION_ANALYSIS.md** - Implementation details
9. **AVQI_DSI_IMPLEMENTATION_PLAN_OLD.md** - Old implementation plan

Plus 300+ other .md files in the repository.

**Action**:
- Update package name references throughout
- Update code examples with `library(pladdrr)`
- Update comparison tables
- Keep historical context where appropriate

## 11. GitHub URLs

### All Files with GitHub URLs (26+ instances)

All references to:
- `https://github.com/humlab-speech/speaker`
- `https://github.com/humlab-speech/speaker/issues`

Need to be updated to:
- `https://github.com/humlab-speech/pladdrr`
- `https://github.com/humlab-speech/pladdrr/issues`

**Files affected**:
- DESCRIPTION
- README.md
- inst/CITATION
- man/speaker-package.Rd
- Various .md documentation files

## 12. Files That Can Be IGNORED

### Praat Source Code
**Directory**: `src/praat.github.io/`

This is the upstream Praat source code. Contains many occurrences of "speaker" referring to:
- Speaker (person) in phonetics context
- Speaker identification algorithms
- Speaker normalization

**Action**: ⚠️ **DO NOT CHANGE** - This is external Praat source code

### Generated Binary/Build Files
- `*.o` files (compiled objects)
- `*.so` / `*.dll` files (shared libraries)
- Build artifacts

**Action**: Will be regenerated during package rebuild

## Rename Procedure Checklist

### Phase 1: Preparation
- [ ] Create git branch for rename operation
- [ ] Back up current package state
- [ ] Document current version number
- [ ] Test that package builds successfully before rename

### Phase 2: Core Package Files
- [ ] Update DESCRIPTION (Package, URL, BugReports)
- [ ] Rename R/speaker-package.R → R/pladdrr-package.R
- [ ] Update content of pladdrr-package.R
- [ ] Update NAMESPACE (useDynLib)
- [ ] Update inst/CITATION

### Phase 3: Documentation
- [ ] Update README.md
- [ ] Update CLAUDE.md
- [ ] Update all vignettes (.Rmd files)
- [ ] Update major .md documentation files

### Phase 4: Code Updates
- [ ] Update library() calls in vignettes
- [ ] Update package= arguments in vignettes
- [ ] Update test files (skip_if_not_installed, library, asNamespace)
- [ ] Review and update R source file comments

### Phase 5: Regeneration
- [ ] Run `Rcpp::compileAttributes()` to regenerate RcppExports with new prefix
- [ ] Run `devtools::document()` to regenerate all .Rd files
- [ ] Verify NAMESPACE is correct

### Phase 6: Validation
- [ ] R CMD check --as-cran
- [ ] Build package successfully
- [ ] Run all tests
- [ ] Build all vignettes
- [ ] Verify GitHub URLs are correct

### Phase 7: Repository Updates
- [ ] Update GitHub repository name (if applicable)
- [ ] Update .github workflows (if any)
- [ ] Update any CI/CD configurations
- [ ] Create new CRAN submission (if applicable)

## Search Commands for Manual Verification

After automated replacement, verify with:

```bash
# Search for any remaining "speaker" references (excluding Praat source)
grep -r "speaker" --exclude-dir=praat.github.io \
                 --exclude-dir=.git \
                 --exclude="*.o" \
                 --exclude="*.so" \
                 /path/to/package/

# Search for old GitHub URLs
grep -r "humlab-speech/speaker" /path/to/package/

# Verify new package name is present
grep -r "pladdrr" /path/to/package/ | wc -l
```

## Potential Issues to Watch For

1. **Circular dependencies**: Ensure no files reference old package name after rename
2. **C++ symbol mismatches**: Verify RcppExports regeneration completes successfully
3. **Vignette builds**: Test all vignettes build without errors
4. **External documentation**: Update any external wikis, websites, or papers
5. **User migration**: Consider providing a migration guide for existing users

## Notes

- The package currently uses Rcpp infrastructure extensively
- All `_speaker_` C++ symbols will automatically become `_pladdrr_` after running Rcpp::compileAttributes()
- Man pages (.Rd files) will regenerate automatically via devtools::document()
- Vignettes must be manually updated but will rebuild successfully once updated

---

**Status**: Documentation complete, ready for rename operation
**Estimated manual edit locations**: 50+ files
**Estimated auto-regenerated files**: 100+ files (.Rd, RcppExports)
