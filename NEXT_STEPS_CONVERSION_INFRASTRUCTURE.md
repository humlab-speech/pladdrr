# Next Steps After Conversion Infrastructure Implementation

**Date**: 2025-11-19  
**Current Version**: 0.5.8  
**Branch**: 001-praat-r-access  
**Status**: Conversion infrastructure complete, ready for C++ implementation and testing

---

## Immediate Priorities (Current Session)

### 1. Add PowerCepstrum C++ Stubs
**File**: `src/powercepstrum_wrappers.cpp` (to create)

Required C++ functions matching R6 method calls:

```cpp
// Sound → PowerCepstrum conversion
// [[Rcpp::export]]
SEXP praat_sound_to_powercepstrum(SEXP xptr, double pitch_floor, double time_step);

// Sound → PowerCepstrogram conversion
// [[Rcpp::export]]
SEXP praat_sound_to_powercepstrogram(SEXP xptr, double pitch_floor, double time_step, 
                                     double max_frequency, double pre_emphasis_from);

// PowerCepstrum methods
// [[Rcpp::export]]
double praat_powercepstrum_get_peak_prominence(SEXP xptr, std::string interpolation,
                                                double qmin, double qmax,
                                                std::string fit_method, double tolerance);

// [[Rcpp::export]]
double praat_powercepstrum_get_quefrency_of_peak(SEXP xptr, std::string interpolation,
                                                  double qmin, double qmax);

// [[Rcpp::export]]
double praat_powercepstrum_get_value_at_quefrency(SEXP xptr, double quefrency,
                                                   std::string interpolation, std::string unit);

// [[Rcpp::export]]
SEXP praat_powercepstrum_smooth(SEXP xptr, double averaging_window, int nsamples);

// [[Rcpp::export]]
SEXP praat_powercepstrum_to_matrix(SEXP xptr);

// [[Rcpp::export]]
Rcpp::NumericMatrix praat_powercepstrum_as_matrix(SEXP xptr);

// PowerCepstrogram methods
// [[Rcpp::export]]
double praat_powercepstrogram_get_cpp_at_time(SEXP xptr, double time, std::string interpolation,
                                               double qmin, double qmax, std::string fit_method, 
                                               double tolerance);

// [[Rcpp::export]]
double praat_powercepstrogram_get_mean_cpp(SEXP xptr, double from_time, double to_time,
                                           double qmin, double qmax, std::string fit_method,
                                           double tolerance);

// [[Rcpp::export]]
SEXP praat_powercepstrogram_to_powercepstrum_slice(SEXP xptr, double time);

// [[Rcpp::export]]
SEXP praat_powercepstrogram_smooth(SEXP xptr, double time_averaging_window,
                                   double quefrency_averaging_window);

// [[Rcpp::export]]
SEXP praat_powercepstrogram_to_matrix(SEXP xptr);

// [[Rcpp::export]]
Rcpp::NumericMatrix praat_powercepstrogram_as_matrix(SEXP xptr);
```

**Implementation approach**:
1. Check if Praat source has PowerCepstrum classes
2. If yes: wrap existing Praat functions
3. If no: implement using Praat's Sound_to_PowerCepstrum algorithm
4. Use XPtr with finalizer for memory management

**Praat source files to check**:
- `fon/Sound_and_Cepstrum.cpp`
- `fon/PowerCepstrum.cpp`
- `fon/PowerCepstrogram.cpp`

### 2. Update NAMESPACE
Add exports for new functions:

```r
# Batch processing utilities
export(batch_process)
export(pair_files)
export(extract_measurements)
export(aggregate_measurements)

# PowerCepstrum classes
export(PowerCepstrum)
export(PowerCepstrogram)
```

### 3. Add Sound Methods
**File**: `R/sound.R` or `R/sound-r6-new.R`

Add methods to Sound class:

```r
#' Convert Sound to PowerCepstrum
to_powercepstrum = function(pitch_floor = 60.0, time_step = 0.01) {
  xptr <- praat_sound_to_powercepstrum(self$.xptr, pitch_floor, time_step)
  PowerCepstrum$new(xptr)
}

#' Convert Sound to PowerCepstrogram
to_powercepstrogram = function(pitch_floor = 60.0, time_step = 0.002,
                               max_frequency = 5000.0, pre_emphasis_from = 50.0) {
  xptr <- praat_sound_to_powercepstrogram(self$.xptr, pitch_floor, time_step,
                                          max_frequency, pre_emphasis_from)
  PowerCepstrogram$new(xptr)
}
```

### 4. Test Batch Processing
Create test file: `tests/testthat/test-batch-processing.R`

```r
test_that("batch_process works with simple function", {
  # Create test audio files or use inst/extdata files
  results <- batch_process(
    directory = testthat::test_path("fixtures"),
    pattern = "\\.wav$",
    func = function(sound) {
      data.frame(duration = sound$get_total_duration())
    }
  )
  
  expect_s3_class(results, "data.frame")
  expect_true("duration" %in% names(results))
})

test_that("pair_files matches Sound and TextGrid files", {
  pairs <- pair_files(
    sound_dir = testthat::test_path("fixtures/sounds"),
    textgrid_dir = testthat::test_path("fixtures/textgrids")
  )
  
  expect_s3_class(pairs, "data.frame")
  expect_equal(names(pairs), c("sound_file", "textgrid_file", "basename"))
})

test_that("extract_measurements returns proper data.frame", {
  sound <- Sound$new(testthat::test_path("fixtures/test.wav"))
  textgrid <- TextGrid$new(testthat::test_path("fixtures/test.TextGrid"))
  
  results <- extract_measurements(
    sound = sound,
    textgrid = textgrid,
    tier = 1,
    measurements = c("pitch", "intensity"),
    time_point = "midpoint"
  )
  
  expect_s3_class(results, "data.frame")
  expect_true("label" %in% names(results))
  expect_true("f0" %in% names(results))
  expect_true("intensity" %in% names(results))
})
```

---

## Short-term Priorities (Next Session)

### 5. Sound/av Integration
**Objective**: Ensure all Sound file I/O uses av package (humlab-speech/av fork)

**Tasks**:
1. Review `Sound$new()` constructor
2. Ensure it uses `av::av_audio_read()` for loading
3. Add `Sound$save()` method using `av::av_audio_convert()`
4. Document av dependency in DESCRIPTION
5. Add av to Imports in DESCRIPTION
6. Create vignette: "Sound File I/O with av Package"

**Example implementation**:
```r
Sound <- R6::R6Class(
  "Sound",
  public = list(
    initialize = function(path) {
      # Use av package for file reading
      audio_info <- av::av_media_info(path)
      audio_data <- av::av_audio_read(path)
      
      # Convert to Praat Sound object
      self$.xptr <- praat_sound_from_audio_data(
        audio_data$samples,
        audio_data$sample_rate,
        audio_data$channels
      )
    },
    
    save = function(path, format = "wav", sample_rate = NULL) {
      # Extract data from Praat object
      data <- self$as_matrix()
      
      # Use av package for writing
      av::av_audio_convert(
        audio = data,
        output = path,
        format = format,
        sample_rate = sample_rate %||% self$get_sampling_frequency()
      )
    }
  )
)
```

### 6. Extend Existing Classes

#### Ltas Class Extensions
**File**: `R/ltas-r6.R` (find or create)

Add missing query methods:

```r
#' Get minimum value
get_minimum = function(from_frequency = 0, to_frequency = 0, 
                      unit = c("dB", "Pa2/Hz"), interpolation = c("none", "parabolic")) {
  unit <- match.arg(unit)
  interpolation <- match.arg(interpolation)
  praat_ltas_get_minimum(self$.xptr, from_frequency, to_frequency, unit, interpolation)
}

#' Get maximum value
get_maximum = function(from_frequency = 0, to_frequency = 0,
                      unit = c("dB", "Pa2/Hz"), interpolation = c("none", "parabolic")) {
  unit <- match.arg(unit)
  interpolation <- match.arg(interpolation)
  praat_ltas_get_maximum(self$.xptr, from_frequency, to_frequency, unit, interpolation)
}

#' Get spectral slope
get_slope = function(from_frequency, to_frequency, 
                    unit = c("dB", "Pa2/Hz"), method = c("linear", "robust")) {
  unit <- match.arg(unit)
  method <- match.arg(method)
  praat_ltas_get_slope(self$.xptr, from_frequency, to_frequency, unit, method)
}
```

#### Matrix Class Extensions
Document R matrix conversion clearly:

```r
#' Convert Praat Matrix to R matrix
#' 
#' @description
#' Exports the Praat Matrix object as an R matrix.
#' Note: R's matrix operations are generally more efficient than
#' operating on the Praat Matrix object directly.
#' 
#' @return Numeric matrix
#' 
#' @examples
#' \dontrun{
#' sound <- Sound$new("audio.wav")
#' spectrogram <- sound$to_spectrogram()
#' mat <- spectrogram$to_matrix()$as_matrix()
#' 
#' # Now use R's matrix operations
#' log_mat <- log(mat + 1e-10)
#' smoothed <- apply(mat, 2, function(x) filter(x, rep(1/3, 3)))
#' }
as_matrix = function() {
  praat_matrix_as_matrix(self$.xptr)
}
```

### 7. Create Vignettes

#### Vignette 1: "Migrating from Praat Scripts"
**File**: `vignettes/migrating-from-praat.Rmd`

**Outline**:
1. Introduction
   - Why migrate to speaker?
   - Advantages over Praat scripts
   - Advantages over Parselmouth

2. Core Concepts
   - OOP vs procedural
   - No global selection
   - R data structures

3. Pattern-by-Pattern Translation
   - Reading files
   - Object creation
   - Queries
   - Loops and batch processing
   - Data export

4. Complete Examples
   - Batch pitch analysis
   - Formant extraction with TextGrid
   - Voice quality assessment

5. Troubleshooting
   - Common errors
   - Performance tips
   - Where to get help

#### Vignette 2: "Batch Processing Workflows"
**File**: `vignettes/batch-processing.Rmd`

**Outline**:
1. Introduction to batch processing
2. Using `batch_process()`
3. File pairing with `pair_files()`
4. Extracting measurements with `extract_measurements()`
5. Aggregating results
6. Parallel processing
7. Error handling
8. Complete workflows
9. Best practices

---

## Medium-term Priorities (v0.6.0)

### 8. FormantPath Class
Modern formant tracking algorithm (Praat 6.1+).

**Check availability**:
```cpp
// Check if Praat source has FormantPath
// Likely in: fon/FormantPath.cpp
```

**If available, implement**:
```r
FormantPath <- R6::R6Class(
  "FormantPath",
  public = list(
    .xptr = NULL,
    initialize = function(.xptr) {
      self$.xptr <- .xptr
    },
    
    # Methods based on Praat's FormantPath API
    get_formant_at_time = function(...) { ... },
    extract_formant = function(...) { ... },
    to_formant = function(...) { ... }
  )
)
```

### 9. Additional Batch Utilities

```r
#' Batch convert audio format
batch_convert_format = function(directory, output_dir, from_format, to_format, ...) {
  # Use av package for conversion
}

#' Batch resample audio
batch_resample = function(directory, output_dir, new_sample_rate, ...) {
  # Use av package for resampling
}

#' Batch normalize intensity
batch_normalize = function(directory, output_dir, target_intensity = 70, ...) {
  # Use Sound$scale_intensity()
}
```

### 10. Export Helpers

```r
#' Export data.frame to Praat Table format
export_to_praat_table = function(df, path) {
  # Write in Praat Table text format
  # Header: "File type = \"ooTextFile\""
  # "Object class = \"Table 1\""
  # etc.
}

#' Export multiple objects to Praat Collection
export_to_praat_collection = function(object_list, path) {
  # Write Collection format
}
```

---

## Long-term Priorities (v1.0.0)

### 11. Comprehensive Vignette Suite (8 total)

1. ✅ "Introduction to speaker" (exists)
2. ✅ "Basic Sound Analysis" (exists)
3. ⏳ "Migrating from Praat Scripts" (planned)
4. ⏳ "Batch Processing Workflows" (planned)
5. ⏳ "TextGrid-Aligned Analysis"
6. ⏳ "Voice Quality Measurement"
7. ⏳ "PSOLA Manipulation"
8. ⏳ "Advanced Spectral Analysis"

### 12. Migration Tools

#### Script Converter (Shiny App?)
Interactive tool to convert Praat scripts to speaker R code:
- Paste Praat script
- Get R equivalent
- Explanation of changes
- Best practices suggestions

#### Pattern Matcher
Analyze Praat script and identify:
- Which speaker functions to use
- Which workflows are applicable
- Potential issues

### 13. Performance Benchmarking

Compare speaker vs Praat for common tasks:
- Batch pitch extraction
- Formant tracking
- Voice quality measures
- Large file processing

Document in vignette or technical report.

### 14. CRAN Preparation

- [ ] All examples run without errors
- [ ] All tests pass
- [ ] R CMD check --as-cran clean
- [ ] Documentation complete
- [ ] Vignettes built successfully
- [ ] NEWS.md updated
- [ ] cran-comments.md created
- [ ] Reverse dependency checks
- [ ] License clarified (GPL-3 for Praat compatibility)

---

## Technical Debt Tracker

### High Priority
- [ ] PowerCepstrum C++ implementation
- [ ] Sound/av integration
- [ ] Batch processing tests
- [ ] NAMESPACE updates

### Medium Priority
- [ ] Ltas method extensions
- [ ] Matrix documentation
- [ ] FormantPath class
- [ ] Vignettes for new features

### Low Priority
- [ ] Additional batch utilities
- [ ] Export helpers
- [ ] Migration tools
- [ ] Performance benchmarks

---

## Dependencies to Add

### Required
- `R6` (already present)
- `Rcpp` (already present)
- `av` (humlab-speech/av fork) - **ADD THIS**

### Suggested
- `progress` - for progress bars
- `parallel` - for parallel processing (base R)

### Optional (for vignettes)
- `ggplot2` - for plotting examples
- `dplyr` - for data manipulation examples
- `knitr` - for vignette building
- `rmarkdown` - for vignette building

**Update DESCRIPTION**:
```
Imports:
    R6,
    Rcpp,
    av (>= 0.8.0)
Suggests:
    progress,
    ggplot2,
    dplyr,
    testthat (>= 3.0.0),
    knitr,
    rmarkdown
```

---

## Success Metrics

### v0.5.8 (Current)
- [x] Conversion guide complete
- [x] Batch processing utilities complete
- [x] PowerCepstrum classes complete (R6 only)
- [ ] C++ implementation
- [ ] Tests passing

### v0.6.0 (Next Release)
- [ ] PowerCepstrum C++ working
- [ ] Sound/av integration complete
- [ ] Batch utilities tested and documented
- [ ] 2 new vignettes (migration + batch processing)
- [ ] Ltas/Matrix extensions

### v0.7.0
- [ ] FormantPath class
- [ ] Additional batch utilities
- [ ] Export helpers
- [ ] 2 more vignettes

### v1.0.0 (CRAN Release)
- [ ] 8 comprehensive vignettes
- [ ] All object classes complete (23/23)
- [ ] 95%+ test coverage
- [ ] R CMD check clean
- [ ] Performance benchmarks
- [ ] Migration tools
- [ ] Production-ready documentation

---

## Questions to Resolve

1. **av package**: Confirm using humlab-speech/av fork specifically?
2. **FormantPath**: Available in Praat source we're using?
3. **Table class**: Implement minimal wrapper or just use data.frame?
4. **Parallel backend**: Use `parallel`, `future`, or both?
5. **Progress bars**: Make `progress` package required or suggested?

---

## Conclusion

The speaker package now has **complete conversion infrastructure** for systematic Praat script migration. Next steps focus on:

1. **C++ implementation** (PowerCepstrum, Sound/av)
2. **Testing** (batch utilities, integration tests)
3. **Documentation** (vignettes, migration guides)
4. **Refinement** (class extensions, additional utilities)

**Timeline to v1.0.0**: ~8-10 weeks if full-time development.

---

**Next Session**: Start with PowerCepstrum C++ stubs and Sound/av integration.
