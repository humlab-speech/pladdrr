# Quickstart Guide: speaker Package

**Date**: 2025-11-02
**Purpose**: Rapid onboarding guide for speaker package users and developers

## For Users

### Installation

```r
# Install from GitHub
# install.packages("devtools")
devtools::install_github("humlab-speech/speaker")
```

### Basic Workflow (5 minutes)

```r
library(speaker)

# 1. Load or create sound
sound <- generate_sine_wave(frequency = 440, duration = 1.0)

# 2. Extract properties
duration <- get_duration(sound)
sr <- get_sampling_rate(sound)

print(sound)
# Praat Sound object
#   Duration: 1.000 seconds
#   Sampling rate: 44100 Hz
#   Channels: 1

# 3. Compute statistics
stats <- sound_statistics(sound)
print(stats)
# $mean: 0.000
# $min: -0.990
# $max: 0.990
# $rms: 0.700
# $length: 44100
```

### Pitch Analysis Workflow

```r
# Load speech audio
sound <- read_sound("speech.wav")

# Extract pitch
pitch <- extract_pitch(sound,
                       pitch_floor = 75,     # Male: 75, Female: 100
                       pitch_ceiling = 500)  # Male: 300, Female: 500

# Query measurements
mean_f0 <- get_mean_pitch(pitch)
min_f0 <- get_min_pitch(pitch)
max_f0 <- get_max_pitch(pitch)

cat(sprintf("Mean F0: %.1f Hz\n", mean_f0))
cat(sprintf("Range: %.1f - %.1f Hz\n", min_f0, max_f0))

# Time series data
pitch_df <- as.data.frame(pitch)
head(pitch_df)
#   time frequency strength
# 1 0.01      120     0.85
# 2 0.02      122     0.88
# 3 0.03       NA       NA   # unvoiced
```

### Formant Analysis Workflow

```r
# Extract formants
formants <- extract_formants(sound,
                             max_formant = 5500)  # Female: 5500, Male: 5000

# Query at specific time (vowel midpoint)
vowel_time <- 0.5
f1 <- get_formant_at_time(formants, 1, vowel_time)
f2 <- get_formant_at_time(formants, 2, vowel_time)
f3 <- get_formant_at_time(formants, 3, vowel_time)

cat(sprintf("Formants at %.2f s: F1=%.0f Hz, F2=%.0f Hz, F3=%.0f Hz\n",
            vowel_time, f1, f2, f3))

# Statistics over time range
f1_stats <- get_formant_statistics(formants, 1, time_min = 0.4, time_max = 0.6)
print(f1_stats)
# $mean: 720
# $min: 680
# $max: 760
# $sd: 25
```

### Common Patterns

**Handle NA values**:
```r
# Pitch may be NA for unvoiced segments
pitch <- extract_pitch(sound)

# Calculate mean, excluding NA
mean_f0 <- mean(pitch$frequency, na.rm = TRUE)

# Count voiced vs unvoiced frames
n_voiced <- sum(!is.na(pitch$frequency))
n_unvoiced <- sum(is.na(pitch$frequency))
```

**Suppress warnings**:
```r
# Suppress quality warnings for batch processing
suppressWarnings({
  pitch <- extract_pitch(noisy_sound)
})
```

**Multi-channel audio**:
```r
# Stereo file - extract left channel (default)
sound_left <- read_sound("stereo.wav", channel = 1)

# Extract right channel
sound_right <- read_sound("stereo.wav", channel = 2)
```

## For Developers

### Test Data Setup

```r
# Create test audio directory
dir.create("tests/testthat/fixtures", recursive = TRUE)

# Generate test signals
sound_440 <- generate_sine_wave(frequency = 440, duration = 0.5)
write_sound(sound_440, "tests/testthat/fixtures/sine_440hz.wav")

noise <- generate_noise(duration = 0.5, seed = 12345)
write_sound(noise, "tests/testthat/fixtures/noise.wav")
```

### Running Tests

```r
# Run all tests
devtools::test()

# Run specific test file
devtools::test(filter = "sound")

# Check coverage
covr::package_coverage()
```

### TDD Workflow

Following constitution Principle IV (Test-Driven Development):

```r
# 1. Write test FIRST
test_that("extract_pitch handles unvoiced segments", {
  # Create whispered audio (mostly unvoiced)
  sound <- generate_noise(duration = 0.1)

  pitch <- extract_pitch(sound)

  # Expect many NA values
  expect_gt(sum(is.na(pitch$frequency)), 0)

  # Should still return valid pitch object
  expect_s3_class(pitch, "praat_pitch")
})

# 2. Verify test FAILS
devtools::test()  # Should fail if extract_pitch not implemented yet

# 3. Implement feature
# ... write extract_pitch() in R/pitch.R and src/pitch_wrapper.cpp

# 4. Verify test PASSES
devtools::test()  # Should pass now

# 5. Refactor if needed
```

### Building Package

```r
# Update documentation
devtools::document()

# Run R CMD check
devtools::check()

# Build vignettes
devtools::build_vignettes()

# Install locally
devtools::install()
```

### Adding New Function

**Steps**:

1. **Write roxygen2 documentation in R file**:
```r
#' Extract pitch from sound
#'
#' @param sound A praat_sound object
#' @param pitch_floor Minimum F0 to search (Hz)
#' @param pitch_ceiling Maximum F0 to search (Hz)
#' @return A praat_pitch object (data frame)
#' @export
#' @examples
#' sound <- generate_sine_wave(440, 1.0)
#' pitch <- extract_pitch(sound, pitch_floor = 75, pitch_ceiling = 600)
extract_pitch <- function(sound, pitch_floor = 75, pitch_ceiling = 600) {
  # Implementation
}
```

2. **Implement C++ wrapper** (if needed):
```cpp
// [[Rcpp::export]]
Rcpp::DataFrame extract_pitch_cpp(SEXP sound_ptr, double pitch_floor, double pitch_ceiling) {
  // Praat C integration
}
```

3. **Write tests**:
```r
test_that("extract_pitch returns valid pitch object", {
  sound <- generate_sine_wave(440, 1.0)
  pitch <- extract_pitch(sound)

  expect_s3_class(pitch, "praat_pitch")
  expect_true("frequency" %in% names(pitch))
})
```

4. **Update NAMESPACE**:
```r
devtools::document()  # Auto-generates from roxygen2
```

### Debugging C++ Code

```r
# Build with debug symbols
Sys.setenv(PKG_CXXFLAGS = "-g")
devtools::load_all()

# Use gdb/lldb
# R -d gdb
# (gdb) run
# > library(speaker)
# > sound <- read_sound("test.wav")  # Set breakpoint in C++
```

### Memory Leak Detection

```bash
# Use valgrind on Linux
R -d valgrind --vanilla < test_script.R

# Or with R CMD check
R CMD check --use-valgrind speaker_*.tar.gz
```

## User Story Test Scenarios

### User Story 1: Basic Sound Operations

```r
# Scenario: Load audio and extract properties
sound <- read_sound("speech.wav")
expect_true(get_duration(sound) > 0)
expect_true(get_sampling_rate(sound) %in% c(16000, 22050, 44100, 48000))

# Scenario: Compute statistics
stats <- sound_statistics(sound)
expect_true(all(c("mean", "min", "max", "rms") %in% names(stats)))

# Scenario: Generate test signal
sine <- generate_sine_wave(440, 1.0)
expect_equal(get_duration(sine), 1.0, tolerance = 0.01)
```

### User Story 2: Pitch Analysis

```r
# Scenario: Extract pitch and query measurements
sound <- read_sound("speech.wav")
pitch <- extract_pitch(sound, pitch_floor = 75, pitch_ceiling = 500)

mean_f0 <- get_mean_pitch(pitch)
expect_true(mean_f0 >= 75 && mean_f0 <= 500)

# Scenario: Handle unvoiced segments
expect_true(any(is.na(pitch$frequency)))  # Some unvoiced frames expected
```

### User Story 3: Formant Analysis

```r
# Scenario: Extract formants and query values
sound <- read_sound("vowel.wav")
formants <- extract_formants(sound, max_formant = 5500)

f1 <- get_formant_at_time(formants, 1, 0.5)
f2 <- get_formant_at_time(formants, 2, 0.5)

# Typical vowel formant ranges
expect_true(f1 >= 200 && f1 <= 1000)   # F1 range
expect_true(f2 >= 500 && f2 <= 3000)   # F2 range
expect_true(f1 < f2)                    # F1 < F2
```

### User Story 4: Intensity and Spectral Analysis

```r
# Scenario: Compute intensity
sound <- read_sound("speech.wav")
intensity <- compute_intensity(sound)

mean_intensity <- mean(intensity$intensity, na.rm = TRUE)
expect_true(mean_intensity >= 40 && mean_intensity <= 100)  # Typical speech dB range

# Scenario: Create spectrogram
spectrogram <- create_spectrogram(sound, max_frequency = 5000)
power <- get_power_at(spectrogram, time = 0.5, frequency = 1000)
expect_true(power >= 0)  # Power is non-negative
```

## Performance Benchmarks

Target performance (from Success Criteria):

```r
library(microbenchmark)

# SC-001: Load and extract properties < 10 seconds
sound_5min <- read_sound("speech_5min.wav")  # 5-minute audio
microbenchmark(
  {
    dur <- get_duration(sound_5min)
    sr <- get_sampling_rate(sound_5min)
  },
  times = 10
)
# Target: median < 10 seconds

# SC-008: 10x faster than external Praat scripts
microbenchmark(
  speaker = extract_pitch(sound),
  external_praat = system("praat extract_pitch.praat"),
  times = 10
)
# Target: speaker median < 0.1 * external_praat median
```

## Troubleshooting

**Issue**: `Error: Rcpp package not found`
**Solution**: `install.packages("Rcpp")`

**Issue**: Compilation fails on Windows
**Solution**: Install Rtools: https://cran.r-project.org/bin/windows/Rtools/

**Issue**: `Warning: Few pitch frames detected`
**Solution**: Adjust `pitch_floor` and `pitch_ceiling` parameters for your audio

**Issue**: Formant values seem incorrect
**Solution**: Adjust `max_formant` (5500 for female, 5000 for male voices)

**Issue**: Memory usage high for long audio files
**Solution**: Process in chunks or reduce sampling rate before analysis

## Next Steps

- **Users**: See vignettes for detailed workflows
  - `vignette("basic-usage")`
  - `vignette("pitch-analysis")`
  - `vignette("formant-analysis")`

- **Developers**: See `specs/001-praat-r-access/plan.md` for architecture
- **Contributors**: See CONTRIBUTING.md and constitution.md for guidelines

## Quick Reference

| Task | Function |
|------|----------|
| Load audio | `read_sound(file)` |
| Create from vector | `create_sound(values, sr)` |
| Generate test signal | `generate_sine_wave(freq, dur)` |
| Get duration | `get_duration(sound)` |
| Extract pitch | `extract_pitch(sound)` |
| Extract formants | `extract_formants(sound)` |
| Compute intensity | `compute_intensity(sound)` |
| Create spectrogram | `create_spectrogram(sound)` |

---

**Documentation Version**: 1.0
**Last Updated**: 2025-11-02
