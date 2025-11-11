# Phase 1 Completion Plan

## Assessment Summary

### ✅ Harmonicity - COMPLETE
- All methods implemented and functional
- No action needed

### ✅ LPC - STUB (Documented as Future Extension)
- Currently a stub that throws errors if called
- No active R API usage found (only comments)
- Used internally by Praat but not exposed
- **Decision**: Keep as stub, document as Tier 3 future extension

### 🔲 Sound - Missing Advanced Modifications
Need to add: resample, convert_to_mono, convert_to_stereo, concatenate, mix

## Implementation: Missing Sound Methods

### 1. Resample
```r
#' @description Resample to different sampling frequency
#' @param new_frequency New sampling frequency in Hz
#' @param precision Number of samples per zero crossing (50 = high quality)
#' @return New Sound object with resampled waveform
resample = function(new_frequency, precision = 50) {
  Sound$new(.sound_resample(private$ptr, new_frequency, precision))
}
```

### 2. Convert to Mono
```r
#' @description Convert to mono (average all channels)
#' @return New Sound object with single channel
convert_to_mono = function() {
  Sound$new(.sound_convert_to_mono(private$ptr))
}
```

### 3. Convert to Stereo
```r
#' @description Convert mono to stereo (duplicate channel)
#' @return New Sound object with two identical channels
convert_to_stereo = function() {
  if (self$get_number_of_channels() > 1) {
    warning("Sound is already multi-channel, returning copy")
    return(Sound$new(.sound_copy(private$ptr)))
  }
  Sound$new(.sound_convert_to_stereo(private$ptr))
}
```

### 4. Concatenate
```r
#' @description Concatenate with another sound
#' @param other_sound Sound object to append
#' @param overlap Overlap duration in seconds (0 = no overlap)
#' @return New Sound object with concatenated audio
concatenate = function(other_sound, overlap = 0) {
  if (!inherits(other_sound, "Sound")) {
    stop("other_sound must be a Sound object")
  }
  Sound$new(.sound_concatenate(private$ptr, other_sound$.__enclos_env__$private$ptr, overlap))
}
```

### 5. Mix
```r
#' @description Mix (add) with another sound
#' @param other_sound Sound object to mix with
#' @param balance Mixing balance: 1 = equal, <1 = more of self, >1 = more of other
#' @return New Sound object with mixed audio
mix = function(other_sound, balance = 1) {
  if (!inherits(other_sound, "Sound")) {
    stop("other_sound must be a Sound object")
  }
  Sound$new(.sound_mix(private$ptr, other_sound$.__enclos_env__$private$ptr, balance))
}
```

## C++ Wrapper Implementation

File: `src/sound_wrappers.cpp`

```cpp
// [[Rcpp::export(.sound_resample)]]
SEXP sound_resample(SEXP xptr, double new_frequency, int precision) {
  try {
    autoSound sound = XPtr_to_Sound(xptr);
    autoSound resampled = Sound_resample(sound.get(), new_frequency, precision);
    return Sound_to_XPtr(resampled.move());
  } catch (MelderError) {
    Melder_clearError();
    Rcpp::stop("Error resampling sound");
  }
}

// [[Rcpp::export(.sound_convert_to_mono)]]
SEXP sound_convert_to_mono(SEXP xptr) {
  try {
    autoSound sound = XPtr_to_Sound(xptr);
    autoSound mono = Sound_convertToMono(sound.get());
    return Sound_to_XPtr(mono.move());
  } catch (MelderError) {
    Melder_clearError();
    Rcpp::stop("Error converting sound to mono");
  }
}

// [[Rcpp::export(.sound_convert_to_stereo)]]
SEXP sound_convert_to_stereo(SEXP xptr) {
  try {
    autoSound sound = XPtr_to_Sound(xptr);
    autoSound stereo = Sound_convertToStereo(sound.get());
    return Sound_to_XPtr(stereo.move());
  } catch (MelderError) {
    Melder_clearError();
    Rcpp::stop("Error converting sound to stereo");
  }
}

// [[Rcpp::export(.sound_copy)]]
SEXP sound_copy(SEXP xptr) {
  try {
    autoSound sound = XPtr_to_Sound(xptr);
    autoSound copy = Data_copy(sound.get());
    return Sound_to_XPtr(copy.move());
  } catch (MelderError) {
    Melder_clearError();
    Rcpp::stop("Error copying sound");
  }
}

// [[Rcpp::export(.sound_concatenate)]]
SEXP sound_concatenate(SEXP xptr1, SEXP xptr2, double overlap) {
  try {
    autoSound sound1 = XPtr_to_Sound(xptr1);
    autoSound sound2 = XPtr_to_Sound(xptr2);
    autoSound concatenated = Sounds_concatenate(sound1.get(), sound2.get(), overlap);
    return Sound_to_XPtr(concatenated.move());
  } catch (MelderError) {
    Melder_clearError();
    Rcpp::stop("Error concatenating sounds");
  }
}

// [[Rcpp::export(.sound_mix)]]
SEXP sound_mix(SEXP xptr1, SEXP xptr2, double balance) {
  try {
    autoSound sound1 = XPtr_to_Sound(xptr1);
    autoSound sound2 = XPtr_to_Sound(xptr2);
    // Mix with balance (1 = equal mix)
    autoSound mixed = Sounds_mix(sound1.get(), sound2.get(), balance);
    return Sound_to_XPtr(mixed.move());
  } catch (MelderError) {
    Melder_clearError();
    Rcpp::stop("Error mixing sounds");
  }
}
```

## Testing Plan

Add to `tests/testthat/test-sound.R`:

```r
test_that("Sound resampling works", {
  sound <- Sound$from_values(sin(2 * pi * 440 * seq(0, 1, 1/44100)), 44100)
  resampled <- sound$resample(22050, precision = 50)
  expect_equal(resampled$get_sampling_frequency(), 22050)
  expect_true(resampled$get_duration() > 0.99 && resampled$get_duration() < 1.01)
})

test_that("Sound mono/stereo conversion works", {
  sound_stereo <- Sound$from_values(matrix(rnorm(1000), ncol = 2), 44100)
  sound_mono <- sound_stereo$convert_to_mono()
  expect_equal(sound_mono$get_number_of_channels(), 1)
  
  sound_stereo2 <- sound_mono$convert_to_stereo()
  expect_equal(sound_stereo2$get_number_of_channels(), 2)
})

test_that("Sound concatenation works", {
  sound1 <- Sound$create_tone(0.5, 440, 44100, 0.5)
  sound2 <- Sound$create_tone(0.5, 880, 44100, 0.5)
  concatenated <- sound1$concatenate(sound2)
  expect_true(concatenated$get_duration() >= 1.0)
})

test_that("Sound mixing works", {
  sound1 <- Sound$create_tone(1, 440, 44100, 0.5)
  sound2 <- Sound$create_tone(1, 880, 44100, 0.5)
  mixed <- sound1$mix(sound2, balance = 1)
  expect_equal(mixed$get_duration(), sound1$get_duration())
  expect_equal(mixed$get_sampling_frequency(), 44100)
})
```

## Documentation Updates

Update `CLAUDE.md`:
```markdown
### Decision 7: LPC as Future Extension

**Choice**: Keep LPC as stub implementation (Tier 3 future extension)

**Rationale**:
- Not currently used by exposed R API
- Only referenced in comments
- Used internally by Praat for formant estimation (already working via formant_burg)
- Significant effort to implement full LPC object
- Can add later if demand exists

**Stub behavior**: Throws error if called (prevents silent failures)

**Future implementation** would include:
- LPC R6 class with coefficient access
- Methods: to_formant, to_spectrum, filter_sound
- Multiple estimation methods: auto, covariance, burg, marple
```

## Execution Steps

1. Update `R/sound-r6-new.R` - add 5 new methods
2. Update `src/sound_wrappers.cpp` - add 6 new C++ functions
3. Run `devtools::document()` - update NAMESPACE and man pages
4. Update `tests/testthat/test-sound.R` - add new tests
5. Run `R CMD build .` - verify package builds
6. Run `R CMD check speaker_*.tar.gz` - verify tests pass
7. Update `CLAUDE.md` - document LPC decision
8. Commit changes

