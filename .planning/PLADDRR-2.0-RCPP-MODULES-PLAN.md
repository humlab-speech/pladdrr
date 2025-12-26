# pladdrr 2.0: Rcpp Modules Conversion Plan

## Executive Summary

Convert pladdrr from R6 + `[[Rcpp::export]]` architecture to Rcpp Modules, eliminating ~40% of glue code while maintaining API compatibility.

**Scope**: 24 wrapper files → 24 module files, 24 R6 files → thin compatibility shims

---

## Phase 0: Preparation (Foundation)

### 0.1 Create Module Infrastructure

**New files to create:**

```
src/
├── modules/                      # NEW directory
│   └── module_common.h           # Shared module utilities
├── traits/                       # NEW directory
│   ├── praat_object_traits.h     # Base object behavior
│   └── sampled_object_traits.h   # Time-domain behavior
└── pladdrr_modules.cpp           # Module registration entry point
```

**`src/modules/module_common.h`:**
```cpp
#ifndef PLADDRR_MODULE_COMMON_H
#define PLADDRR_MODULE_COMMON_H

#include <Rcpp.h>
#include "../praat_xptr_utils.h"
#include "../praat_types.h"
#include "../praat_error_handling.h"

// Macro for consistent pointer validation
#define VALIDATE_PTR(ptr, type) \
    if (!ptr || ptr.get() == nullptr) \
        Rcpp::stop("Invalid " #type " pointer")

// Common property getters for time-domain objects
#define TIME_DOMAIN_PROPERTIES(T) \
    double get_xmin() const { return ptr ? ptr->xmin : NA_REAL; } \
    double get_xmax() const { return ptr ? ptr->xmax : NA_REAL; } \
    double get_duration() const { return ptr ? (ptr->xmax - ptr->xmin) : NA_REAL; }

// Common property getters for sampled objects
#define SAMPLED_PROPERTIES(T) \
    TIME_DOMAIN_PROPERTIES(T) \
    int get_nx() const { return ptr ? ptr->nx : NA_INTEGER; } \
    double get_dx() const { return ptr ? ptr->dx : NA_REAL; } \
    double get_x1() const { return ptr ? ptr->x1 : NA_REAL; }

#endif
```

### 0.2 Create Test Harness for Parallel Testing

**New file: `tests/testthat/helper-module-compat.R`**
```r
# Helper to run same tests against R6 and Module implementations
test_both_implementations <- function(desc, r6_code, module_code) {
  test_that(paste(desc, "(R6)"), r6_code)
  test_that(paste(desc, "(Module)"), module_code)
}
```

### 0.3 Version Branch Strategy

```bash
# Create 2.0 development branch
git checkout -b v2.0-rcpp-modules
git push -u origin v2.0-rcpp-modules
```

---

## Phase 1: Pilot Module - Pitch (Simplest Complete Object)

### 1.1 Create Pitch Module

**File: `src/modules/pitch_module.cpp`**

Convert from current `pitch_wrappers.cpp` (24 exported functions) to single module class.

**Current pattern (pitch_wrappers.cpp):**
```cpp
// [[Rcpp::export(.pitch_get_time_from_frame)]]
double pitch_get_time_from_frame(XPtr<structPitch> pitch, int frame_number) {
    if (!pitch) Rcpp::stop("Invalid Pitch pointer");
    return Sampled_indexToX(pitch.get(), frame_number);
}
```

**New pattern (pitch_module.cpp):**
```cpp
#include "module_common.h"
#include "praat.github.io/fon/Pitch.h"
#include "praat.github.io/fon/Sound_to_Pitch.h"

class RPitch {
public:
    Rcpp::XPtr<structPitch> ptr;

    // Default constructor (for Rcpp)
    RPitch() : ptr(R_NilValue) {}

    // Constructor from pointer
    RPitch(Rcpp::XPtr<structPitch> p) : ptr(p) {}

    // ============================================================
    // Properties (read-only)
    // ============================================================

    bool is_valid() const {
        return ptr && ptr.get() != nullptr;
    }

    double get_xmin() const {
        VALIDATE_PTR(ptr, Pitch);
        return ptr->xmin;
    }

    double get_xmax() const {
        VALIDATE_PTR(ptr, Pitch);
        return ptr->xmax;
    }

    double get_duration() const {
        return get_xmax() - get_xmin();
    }

    int get_nx() const {
        VALIDATE_PTR(ptr, Pitch);
        return ptr->nx;
    }

    double get_dx() const {
        VALIDATE_PTR(ptr, Pitch);
        return ptr->dx;
    }

    // ============================================================
    // Query methods - Time domain
    // ============================================================

    double get_time_from_frame(int frame_number) {
        VALIDATE_PTR(ptr, Pitch);
        if (frame_number < 1 || frame_number > ptr->nx)
            Rcpp::stop("Frame number out of range");
        return Sampled_indexToX(ptr.get(), frame_number);
    }

    int get_frame_from_time(double time) {
        VALIDATE_PTR(ptr, Pitch);
        return (int)Sampled_xToNearestIndex(ptr.get(), time);
    }

    int get_number_of_frames() {
        VALIDATE_PTR(ptr, Pitch);
        return ptr->nx;
    }

    double get_time_step() {
        VALIDATE_PTR(ptr, Pitch);
        return ptr->dx;
    }

    // ============================================================
    // Query methods - Pitch values
    // ============================================================

    double get_value_at_time(double time, int unit, bool interpolate) {
        VALIDATE_PTR(ptr, Pitch);
        // Convert unit code to Praat enum
        kPitch_unit praat_unit = static_cast<kPitch_unit>(unit);
        return Pitch_getValueAtTime(ptr.get(), time, praat_unit, interpolate);
    }

    double get_mean(double from_time, double to_time, int unit) {
        VALIDATE_PTR(ptr, Pitch);
        kPitch_unit praat_unit = static_cast<kPitch_unit>(unit);
        return Pitch_getMean(ptr.get(), from_time, to_time, praat_unit);
    }

    double get_standard_deviation(double from_time, double to_time, int unit) {
        VALIDATE_PTR(ptr, Pitch);
        kPitch_unit praat_unit = static_cast<kPitch_unit>(unit);
        return Pitch_getStandardDeviation(ptr.get(), from_time, to_time, praat_unit);
    }

    double get_quantile(double quantile, double from_time, double to_time, int unit) {
        VALIDATE_PTR(ptr, Pitch);
        kPitch_unit praat_unit = static_cast<kPitch_unit>(unit);
        return Pitch_getQuantile(ptr.get(), from_time, to_time, quantile, praat_unit);
    }

    double get_minimum(double from_time, double to_time, int unit, bool interpolate) {
        VALIDATE_PTR(ptr, Pitch);
        kPitch_unit praat_unit = static_cast<kPitch_unit>(unit);
        return Pitch_getMinimum(ptr.get(), from_time, to_time, praat_unit, interpolate);
    }

    double get_maximum(double from_time, double to_time, int unit, bool interpolate) {
        VALIDATE_PTR(ptr, Pitch);
        kPitch_unit praat_unit = static_cast<kPitch_unit>(unit);
        return Pitch_getMaximum(ptr.get(), from_time, to_time, praat_unit, interpolate);
    }

    // ============================================================
    // Frame queries
    // ============================================================

    int count_voiced_frames() {
        VALIDATE_PTR(ptr, Pitch);
        return Pitch_countVoicedFrames(ptr.get());
    }

    bool is_frame_voiced(int frame_number) {
        VALIDATE_PTR(ptr, Pitch);
        if (frame_number < 1 || frame_number > ptr->nx)
            Rcpp::stop("Frame number out of range");
        return Pitch_isVoiced_i(ptr.get(), frame_number);
    }

    double get_value_in_frame(int frame_number, int unit) {
        VALIDATE_PTR(ptr, Pitch);
        if (frame_number < 1 || frame_number > ptr->nx)
            Rcpp::stop("Frame number out of range");
        kPitch_unit praat_unit = static_cast<kPitch_unit>(unit);
        return Pitch_getValueInFrame(ptr.get(), frame_number, praat_unit);
    }

    // ============================================================
    // Conversions
    // ============================================================

    Rcpp::NumericVector to_vector() {
        VALIDATE_PTR(ptr, Pitch);
        int n = ptr->nx;
        Rcpp::NumericVector result(n);
        for (int i = 1; i <= n; i++) {
            result[i-1] = Pitch_getValueInFrame(ptr.get(), i, kPitch_unit::HERTZ);
        }
        return result;
    }

    Rcpp::DataFrame to_data_frame() {
        VALIDATE_PTR(ptr, Pitch);
        int n = ptr->nx;
        Rcpp::NumericVector times(n), values(n);
        Rcpp::LogicalVector voiced(n);

        for (int i = 1; i <= n; i++) {
            times[i-1] = Sampled_indexToX(ptr.get(), i);
            values[i-1] = Pitch_getValueInFrame(ptr.get(), i, kPitch_unit::HERTZ);
            voiced[i-1] = Pitch_isVoiced_i(ptr.get(), i);
        }

        return Rcpp::DataFrame::create(
            Rcpp::Named("time") = times,
            Rcpp::Named("f0") = values,
            Rcpp::Named("voiced") = voiced
        );
    }
};

// Module definition
RCPP_MODULE(pitch_module) {
    using namespace Rcpp;

    class_<RPitch>("Pitch")
        .constructor()
        .constructor<XPtr<structPitch>>()

        // Properties
        .property("is_valid", &RPitch::is_valid)
        .property("xmin", &RPitch::get_xmin)
        .property("xmax", &RPitch::get_xmax)
        .property("duration", &RPitch::get_duration)
        .property("nx", &RPitch::get_nx)
        .property("dx", &RPitch::get_dx)

        // Time domain methods
        .method("get_time_from_frame", &RPitch::get_time_from_frame)
        .method("get_frame_from_time", &RPitch::get_frame_from_time)
        .method("get_number_of_frames", &RPitch::get_number_of_frames)
        .method("get_time_step", &RPitch::get_time_step)

        // Pitch value methods
        .method("get_value_at_time", &RPitch::get_value_at_time)
        .method("get_mean", &RPitch::get_mean)
        .method("get_standard_deviation", &RPitch::get_standard_deviation)
        .method("get_quantile", &RPitch::get_quantile)
        .method("get_minimum", &RPitch::get_minimum)
        .method("get_maximum", &RPitch::get_maximum)

        // Frame methods
        .method("count_voiced_frames", &RPitch::count_voiced_frames)
        .method("is_frame_voiced", &RPitch::is_frame_voiced)
        .method("get_value_in_frame", &RPitch::get_value_in_frame)

        // Conversions
        .method("to_vector", &RPitch::to_vector)
        .method("to_data_frame", &RPitch::to_data_frame)
    ;
}
```

### 1.2 Create R Compatibility Layer

**File: `R/pitch-module.R`** (replaces `R/pitch-r6.R`)

```r
# Load module on package load
.pitch_module <- NULL

.onLoad <- function(libname, pkgname) {
  .pitch_module <<- Module("pitch_module", PACKAGE = pkgname)
}

#' Pitch Object (Module-based)
#'
#' @description
#' Fundamental frequency contour. Created via Sound$to_pitch().
#'
#' @export
Pitch <- function(.ptr = NULL) {
  if (is.null(.ptr)) {
    stop("Pitch objects must be created from Sound$to_pitch()")
  }

  obj <- .pitch_module$Pitch$new(.ptr)

  # Add unit conversion wrapper for ergonomics
  obj$get_value_at_time_hz <- function(time, interpolate = TRUE) {
    obj$get_value_at_time(time, 0L, interpolate)  # 0 = Hertz
  }

  class(obj) <- c("Pitch", "PraatObject", class(obj))
  obj
}

# S3 methods for compatibility
#' @export
print.Pitch <- function(x, ...) {
  cat("<Pitch>\n")
  if (x$is_valid) {
    cat(sprintf("  Duration: %.3f s\n", x$duration))
    cat(sprintf("  Frames: %d (step: %.4f s)\n", x$nx, x$dx))
  } else {
    cat("  [Invalid object]\n")
  }
  invisible(x)
}

#' @export
as.data.frame.Pitch <- function(x, ...) {
  x$to_data_frame()
}
```

### 1.3 Update Tests

**File: `tests/testthat/test-pitch-module.R`**
```r
test_that("Pitch module creates valid objects", {
  sound <- Sound$from_file(test_wav_path())
  pitch <- sound$to_pitch()


  expect_true(pitch$is_valid)
  expect_gt(pitch$duration, 0)
  expect_gt(pitch$nx, 0)
})

test_that("Pitch module queries work", {
  sound <- Sound$from_file(test_wav_path())
  pitch <- sound$to_pitch()

  # Time domain
  expect_equal(pitch$get_frame_from_time(pitch$xmin), 1)

  # Values
  mean_f0 <- pitch$get_mean(0, 0, 0L)  # 0 = Hertz
  expect_true(is.numeric(mean_f0))

  # Data frame conversion
  df <- as.data.frame(pitch)
  expect_true("time" %in% names(df))
  expect_true("f0" %in% names(df))
})
```

### 1.4 Validation Checklist for Pilot

- [ ] Module compiles without errors
- [ ] All 24 original Pitch functions covered
- [ ] Test suite passes
- [ ] Performance comparison (benchmark old vs new)
- [ ] Memory leak check (valgrind/ASAN)
- [ ] Document any API differences

---

## Phase 2: Core Objects (Sound, Formant, Intensity, Spectrum)

### 2.1 Sound Module (Most Complex)

**File: `src/modules/sound_module.cpp`**

Sound is the largest class with ~80 exported functions. Key challenges:
- Factory methods (from_file, from_values, generate_*)
- Transformation methods returning other types (to_pitch, to_formant, etc.)
- Multi-channel support
- SIMD-optimized methods

**Structure:**
```cpp
class RSound {
public:
    XPtr<structSound> ptr;

    // Constructors
    RSound();
    RSound(XPtr<structSound> p);

    // Factory methods (static)
    static RSound from_file(std::string path);
    static RSound from_values(NumericMatrix values, double sample_rate);
    static RSound generate_tone(double frequency, double duration, double sr);
    static RSound generate_noise(std::string type, double duration, double sr);

    // Properties
    double get_duration();
    double get_sample_rate();
    int get_number_of_channels();
    int get_number_of_samples();

    // Time domain queries
    double get_value_at_time(int channel, double time);
    double get_time_from_index(int sample);
    int get_index_from_time(double time);

    // Statistics
    double get_mean(int channel, double from, double to);
    double get_rms(int channel, double from, double to);
    double get_energy(int channel, double from, double to);
    double get_power(int channel, double from, double to);

    // Transformations → other types
    RPitch to_pitch(double time_step, double min_pitch, double max_pitch);
    RFormant to_formant_burg(double time_step, int max_formants, double max_freq);
    RIntensity to_intensity(double min_pitch, double time_step);
    RSpectrum to_spectrum(bool fast);
    RSpectrogram to_spectrogram(double window_length, double max_freq);

    // Sound modifications (return new Sound)
    RSound extract_part(double from, double to, bool preserve_times);
    RSound resample(double new_sr, int precision);
    RSound convert_to_mono(std::string method);
    RSound reverse();
    RSound fade_in(double duration);
    RSound fade_out(double duration);

    // I/O
    void save(std::string path, std::string format);
    NumericMatrix to_matrix();
};

RCPP_MODULE(sound_module) {
    class_<RSound>("Sound")
        .constructor()
        .constructor<XPtr<structSound>>()
        .factory(&RSound::from_file, "from_file")
        .factory(&RSound::from_values, "from_values")
        // ... all methods
    ;
}
```

### 2.2 Formant Module

**File: `src/modules/formant_module.cpp`**

```cpp
class RFormant {
    XPtr<structFormant> ptr;

    // Queries
    double get_value_at_time(int formant_number, double time);
    double get_bandwidth_at_time(int formant_number, double time);
    int get_number_of_formants(int frame_number);

    // Statistics
    double get_mean(int formant_number, double from, double to);
    double get_minimum(int formant_number, double from, double to);
    double get_maximum(int formant_number, double from, double to);

    // Conversions
    DataFrame to_data_frame();
};
```

### 2.3 Intensity Module

**File: `src/modules/intensity_module.cpp`**

```cpp
class RIntensity {
    XPtr<structIntensity> ptr;

    double get_value_at_time(double time);
    double get_mean(double from, double to);
    double get_minimum(double from, double to);
    double get_maximum(double from, double to);
    double get_standard_deviation(double from, double to);
    double get_quantile(double quantile, double from, double to);

    NumericVector to_vector();
    DataFrame to_data_frame();
};
```

### 2.4 Spectrum Module

**File: `src/modules/spectrum_module.cpp`**

```cpp
class RSpectrum {
    XPtr<structSpectrum> ptr;

    // Properties
    double get_lowest_frequency();
    double get_highest_frequency();
    int get_number_of_bins();
    double get_bin_width();

    // Queries
    double get_real_value_at_bin(int bin);
    double get_imaginary_value_at_bin(int bin);
    double get_power_at_bin(int bin);
    double get_phase_at_bin(int bin);
    double get_band_energy(double from_freq, double to_freq);

    // Spectral moments
    double get_centre_of_gravity(double power);
    double get_standard_deviation(double power);
    double get_skewness(double power);
    double get_kurtosis(double power);

    // Modifications
    RSpectrum filter_pass_hann_band(double from_freq, double to_freq, double smoothing);
    RSpectrum filter_stop_hann_band(double from_freq, double to_freq, double smoothing);

    // Conversions
    RSound to_sound();
};
```

---

## Phase 3: Secondary Objects

### 3.1 File List by Priority

| Priority | File | Complexity | Dependencies |
|----------|------|------------|--------------|
| 1 | spectrogram_module.cpp | Medium | Sound |
| 2 | pointprocess_module.cpp | Medium | Sound, Pitch |
| 3 | textgrid_module.cpp | High | PointProcess |
| 4 | lpc_module.cpp | Medium | Sound |
| 5 | harmonicity_module.cpp | Low | Sound |
| 6 | ltas_module.cpp | Low | Sound, Spectrum |
| 7 | cepstrum_module.cpp | Low | Spectrum |
| 8 | powercepstrum_module.cpp | Low | Spectrum |
| 9 | manipulation_module.cpp | High | Sound, Pitch |
| 10 | pitchtier_module.cpp | Medium | Pitch |
| 11 | formantgrid_module.cpp | Medium | Formant |
| 12 | intensitytier_module.cpp | Low | Intensity |
| 13 | durationtier_module.cpp | Low | - |
| 14 | amplitudetier_module.cpp | Low | - |
| 15 | matrix_module.cpp | Low | - |
| 16 | table_module.cpp | Medium | - |
| 17 | cochleagram_module.cpp | Low | Sound |
| 18 | excitation_module.cpp | Low | Cochleagram |
| 19 | electroglottogram_module.cpp | Low | Sound |
| 20 | interpreter_module.cpp | High | All |

### 3.2 TextGrid Module (Complex Example)

```cpp
class RTextGrid {
    XPtr<structTextGrid> ptr;

    // Tier management
    int get_number_of_tiers();
    std::string get_tier_name(int tier);
    bool is_interval_tier(int tier);

    // Interval tier operations
    int get_number_of_intervals(int tier);
    double get_interval_start(int tier, int interval);
    double get_interval_end(int tier, int interval);
    std::string get_interval_label(int tier, int interval);
    void set_interval_label(int tier, int interval, std::string label);
    void insert_boundary(int tier, double time);
    void remove_boundary(int tier, double time);

    // Point tier operations
    int get_number_of_points(int tier);
    double get_point_time(int tier, int point);
    std::string get_point_label(int tier, int point);
    void add_point(int tier, double time, std::string label);
    void remove_point(int tier, int point);

    // I/O
    static RTextGrid from_file(std::string path);
    void save(std::string path, std::string format);

    // Conversions
    List to_list();  // Nested list structure
};
```

---

## Phase 4: Cross-Module Integration

### 4.1 Module Registration

**File: `src/pladdrr_modules.cpp`**

```cpp
#include <Rcpp.h>

// Forward declare all modules
RCPP_MODULE(sound_module);
RCPP_MODULE(pitch_module);
RCPP_MODULE(formant_module);
RCPP_MODULE(intensity_module);
RCPP_MODULE(spectrum_module);
RCPP_MODULE(spectrogram_module);
RCPP_MODULE(textgrid_module);
RCPP_MODULE(pointprocess_module);
RCPP_MODULE(lpc_module);
RCPP_MODULE(harmonicity_module);
RCPP_MODULE(ltas_module);
RCPP_MODULE(cepstrum_module);
RCPP_MODULE(powercepstrum_module);
RCPP_MODULE(manipulation_module);
RCPP_MODULE(pitchtier_module);
RCPP_MODULE(formantgrid_module);
RCPP_MODULE(intensitytier_module);
RCPP_MODULE(durationtier_module);
RCPP_MODULE(amplitudetier_module);
RCPP_MODULE(matrix_module);
RCPP_MODULE(table_module);
RCPP_MODULE(cochleagram_module);
RCPP_MODULE(excitation_module);
RCPP_MODULE(electroglottogram_module);
RCPP_MODULE(interpreter_module);
```

### 4.2 R Package Loading

**File: `R/zzz.R`**

```r
# Module references (populated on load)
.modules <- new.env(parent = emptyenv())

.onLoad <- function(libname, pkgname) {
  # Load all modules
  modules <- c(
    "sound", "pitch", "formant", "intensity", "spectrum",
    "spectrogram", "textgrid", "pointprocess", "lpc",
    "harmonicity", "ltas", "cepstrum", "powercepstrum",
    "manipulation", "pitchtier", "formantgrid",
    "intensitytier", "durationtier", "amplitudetier",
    "matrix", "table", "cochleagram", "excitation",
    "electroglottogram", "interpreter"
  )

  for (mod in modules) {
    .modules[[mod]] <- Module(paste0(mod, "_module"), PACKAGE = pkgname)
  }
}

# Accessor for modules
get_module <- function(name) {
  .modules[[name]]
}
```

### 4.3 Cross-Type Transformations

When `RSound::to_pitch()` returns an `RPitch`, both module classes must be visible:

```cpp
// In sound_module.cpp
#include "pitch_module.cpp"  // For RPitch definition

// Or use forward declaration + factory
RCPP_EXPOSED_CLASS(RPitch)

// In RSound
XPtr<structPitch> to_pitch_ptr(...) {
    // Return raw pointer, R code wraps it
}

// In R:
Sound$to_pitch <- function(...) {
    ptr <- .self$to_pitch_ptr(...)
    Pitch(ptr)
}
```

---

## Phase 5: Deprecation Layer

### 5.1 R6 Compatibility Shim

**File: `R/compat-r6.R`**

```r
#' @title R6 Compatibility Layer (Deprecated)
#' @description
#' Provides backwards compatibility for code using the R6 API.
#' Will be removed in pladdrr 3.0.
#'
#' @name r6-compat
NULL

# Create R6-style wrapper around module object
.make_r6_compat <- function(module_obj, class_name) {
  # Warn on first use
  warned <- FALSE
  warn_once <- function() {
    if (!warned) {
      .Deprecated(
        msg = sprintf(
          "%s R6 API is deprecated. Use %s() constructor instead.",
          class_name, class_name
        )
      )
      warned <<- TRUE
    }
  }

  # Create environment mimicking R6 object
  obj <- new.env(parent = emptyenv())
  obj$.module <- module_obj

  # Proxy all methods
  for (method in names(module_obj)) {
    if (is.function(module_obj[[method]])) {
      local({
        m <- method
        obj[[m]] <- function(...) {
          warn_once()
          obj$.module[[m]](...)
        }
      })
    }
  }

  class(obj) <- c(class_name, "PraatObject", "R6")
  obj
}

#' @rdname r6-compat
#' @export
Pitch.R6 <- R6::R6Class("Pitch",
  inherit = PraatObject,
  public = list(
    initialize = function(.xptr = NULL) {
      .Deprecated("Pitch()", msg = "R6 API deprecated. Use Pitch() instead.")
      private$.module <- get_module("pitch")$Pitch$new(.xptr)
    },
    # Forward all methods to module
    get_mean = function(...) private$.module$get_mean(...)
    # ... etc
  ),
  private = list(
    .module = NULL
  )
)
```

### 5.2 Migration Guide

**File: `vignettes/migration-2.0.Rmd`**

```markdown
# Migrating to pladdrr 2.0

## What Changed

pladdrr 2.0 replaces the R6 class system with Rcpp Modules for better
performance and simpler maintenance.

## API Changes

### Constructors

```r
# Old (1.x) - DEPRECATED
pitch <- Pitch$new(.xptr = ptr)

# New (2.0)
pitch <- Pitch(ptr)
```

### Method Calls (Unchanged)

```r
# Same in both versions
pitch$get_mean(0, 0, "hertz")
pitch$to_data_frame()
```

### Properties vs Methods

```r
# 1.x: Active bindings (computed)
pitch$duration  # Calls method internally

# 2.0: Direct properties (faster)
pitch$duration  # Direct C++ property access
```

## Migration Checklist

1. Replace `Class$new(...)` with `Class(...)`
2. Update any code that checks `inherits(x, "R6")`
3. Test all transformations (to_pitch, to_formant, etc.)
```

---

## Phase 6: Testing & Validation

### 6.1 Test Categories

| Category | Files | Focus |
|----------|-------|-------|
| Unit | `test-*-module.R` | Individual class methods |
| Integration | `test-transformations.R` | Cross-type conversions |
| Regression | `test-compat.R` | R6 API compatibility |
| Performance | `bench-modules.R` | Speed comparisons |
| Memory | `test-memory.R` | Leak detection |

### 6.2 Performance Benchmarks

**File: `dev/benchmark-modules.R`**

```r
library(bench)

# Load test data
sound <- Sound$from_file("test.wav")

# Compare old vs new
bench::mark(
  r6 = {
    pitch_r6 <- sound$to_pitch_r6()
    pitch_r6$get_mean(0, 0, 0L)
  },
  module = {
    pitch_mod <- sound$to_pitch()
    pitch_mod$get_mean(0, 0, 0L)
  },
  iterations = 1000
)
```

### 6.3 Memory Validation

```bash
# Build with ASAN
R CMD INSTALL --configure-args="CXXFLAGS=-fsanitize=address" .

# Run tests
R -d "valgrind --leak-check=full" -e "testthat::test_package('pladdrr')"
```

---

## Phase 7: Documentation & Release

### 7.1 Documentation Updates

| File | Changes |
|------|---------|
| `man/*.Rd` | Regenerate via roxygen2 |
| `README.md` | Update examples |
| `NEWS.md` | Document all changes |
| `vignettes/*` | Update code examples |

### 7.2 DESCRIPTION Changes

```
Package: pladdrr
Version: 2.0.0
Title: Object-Oriented Interface to Praat
Description: Provides R6-compatible classes backed by Rcpp Modules...
Imports:
    Rcpp (>= 1.0.0),
    methods
LinkingTo:
    Rcpp,
    RcppXsimd
Suggests:
    R6 (>= 2.5.0),  # Now optional, for compat layer
    testthat,
    ...
```

### 7.3 Release Checklist

- [ ] All tests pass
- [ ] R CMD check passes with no warnings
- [ ] Vignettes build successfully
- [ ] CRAN checks pass (if submitting)
- [ ] NEWS.md updated
- [ ] Version bumped to 2.0.0
- [ ] Git tag created

---

## Timeline Overview

| Phase | Description | Files | Est. Effort |
|-------|-------------|-------|-------------|
| 0 | Infrastructure setup | 5 new files | Small |
| 1 | Pilot (Pitch) | 2 files | Small |
| 2 | Core objects | 8 files | Medium |
| 3 | Secondary objects | 32 files | Large |
| 4 | Integration | 2 files | Small |
| 5 | Deprecation layer | 3 files | Small |
| 6 | Testing | 10+ files | Medium |
| 7 | Documentation | All docs | Medium |

---

## File Inventory

### Files to CREATE (src/modules/)

```
sound_module.cpp
pitch_module.cpp
formant_module.cpp
intensity_module.cpp
spectrum_module.cpp
spectrogram_module.cpp
textgrid_module.cpp
pointprocess_module.cpp
lpc_module.cpp
harmonicity_module.cpp
ltas_module.cpp
cepstrum_module.cpp
powercepstrum_module.cpp
manipulation_module.cpp
pitchtier_module.cpp
formantgrid_module.cpp
intensitytier_module.cpp
durationtier_module.cpp
amplitudetier_module.cpp
matrix_module.cpp
table_module.cpp
cochleagram_module.cpp
excitation_module.cpp
electroglottogram_module.cpp
interpreter_module.cpp
module_common.h
```

### Files to DELETE (after migration complete)

```
R/praat-object.R
R/sound-r6-new.R
R/pitch-r6.R
R/formant-r6.R
R/intensity-r6.R
R/spectrum-r6.R
R/spectrogram-r6.R
R/textgrid-r6.R
R/pointprocess-r6.R
R/lpc-r6.R
R/harmonicity.R
R/ltas-r6.R
R/cepstrum-r6.R
R/powercepstrum-r6.R
R/manipulation-r6.R
R/pitchtier-r6.R
R/formantgrid-r6.R
R/intensitytier-r6.R
R/durationtier-r6.R
R/amplitudetier-r6.R
R/matrix-r6.R
R/table-r6.R
R/cochleagram-r6.R
R/excitation-r6.R
R/electroglottogram-r6.R
R/praat-interpreter-r6.R
```

### Files to KEEP (no changes needed)

```
src/praat_xptr_utils.h
src/praat_error_handling.h
src/praat_types.h
src/simd_*.cpp (all SIMD files)
src/praat.github.io/ (submodule)
```

### Files to MODIFY

```
src/Makevars.in          # Add modules/ to sources
R/zzz.R                  # Module loading
R/s3-methods.R           # Update for module classes
R/autoplot-methods.R     # Update for module classes
DESCRIPTION              # Version, dependencies
NAMESPACE                # Export module classes
```

---

## Risk Mitigation

| Risk | Mitigation |
|------|------------|
| Breaking user code | 2.x deprecation warnings, 3.0 removal |
| Module compile errors | Incremental conversion, test each |
| Performance regression | Benchmark before/after each phase |
| Memory leaks | ASAN/valgrind on every module |
| Cross-platform issues | Test on macOS/Linux/Windows CI |

---

## Decision Log

| Decision | Rationale | Date |
|----------|-----------|------|
| Rcpp Modules over R6 | 40% code reduction, type safety | 2025-12-25 |
| Keep method-style API | Minimize user migration effort | 2025-12-25 |
| Defer R7 to 2.1+ | R7 still maturing, adds complexity | 2025-12-25 |
| Pilot with Pitch | Simple, complete, good test case | 2025-12-25 |
