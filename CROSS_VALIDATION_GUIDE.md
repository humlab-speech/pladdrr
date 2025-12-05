# Cross-Validation Testing Guide

This document describes the comprehensive cross-validation test suite for AVQI, DSI, and tremor analysis implementations across three platforms: **Praat scripts**, **Python/plabench**, and **R/pladdrr**.

## Overview

The test suite ensures that all three implementations produce identical results within numerical tolerance:

1. **Praat Scripts** - Original reference implementations
   - AVQI v2.03 and v3.01
   - DSI v2.01
   - Tremor v3.05

2. **Python/plabench** - Python port using Parselmouth
   - Located in `/Users/frkkan96/Documents/src/plabench`
   - Uses Parselmouth for Praat DSP operations

3. **R/pladdrr** - R implementation using direct C calls
   - Located in `/Users/frkkan96/Documents/src/pladdrr`
   - Uses embedded Praat C++ source code via Rcpp

## Test Architecture

```
┌─────────────────┐
│  Test Audio     │
│  Files          │
└────────┬────────┘
         │
    ┌────┴────────────────────────┐
    │                             │
    ▼                             ▼
┌─────────┐                   ┌─────────┐
│  Praat  │                   │ Python  │
│ Scripts │                   │plabench │
└────┬────┘                   └────┬────┘
     │                             │
     │    ┌─────────┐             │
     └───►│   R     │◄────────────┘
          │pladdrr  │
          └────┬────┘
               │
               ▼
        ┌──────────────┐
        │ Validation   │
        │ Within       │
        │ Tolerance    │
        └──────────────┘
```

## Prerequisites

### 1. Praat Application

```bash
# Praat must be installed at:
/Applications/Praat.app/Contents/MacOS/Praat

# Verify installation:
/Applications/Praat.app/Contents/MacOS/Praat --version
```

### 2. Python Environment

```bash
# Install plabench
cd /Users/frkkan96/Documents/src/plabench
pip install -e .

# Verify installation
python3 -c "import plabench; print(plabench.__version__)"
```

### 3. R Environment

```R
# Install pladdrr dependencies
install.packages(c("R6", "testthat", "jsonlite"))

# Install pladdrr
setwd("/Users/frkkan96/Documents/src/pladdrr")
devtools::load_all()

# Verify installation
library(speaker)
packageVersion("speaker")
```

### 4. Optional: speakr Package

The `speakr` package provides an alternative method for calling Praat scripts from R:

```R
install.packages("speakr")
library(speakr)

# Test speakr
praat("writeInfoLine: \"Hello\"", capture = TRUE)
```

## Test Data

Test audio files are organized by analysis type:

```
plabench/signalfiles/
├── AVQI/
│   └── input/
│       ├── cs1.wav, cs2.wav, cs3.wav  # Continuous speech
│       └── sv1.wav, sv2.wav, sv3.wav  # Sustained vowels
├── DSI/
│   └── input/
│       ├── mpt1.wav, mpt2.wav, mpt3.wav  # Maximum phonation time
│       ├── fh1.wav, fh2.wav, fh3.wav     # Highest frequency
│       ├── im1.wav, im2.wav, im3.wav     # Lowest intensity
│       └── ppq1.wav, ppq2.wav, ppq3.wav  # Jitter measurement
└── tremor/
    └── sustained_vowel.wav  # (to be added)
```

## Running Cross-Validation Tests

### Method 1: R Test Suite (Recommended)

```R
# Load the test suite
setwd("/Users/frkkan96/Documents/src/pladdrr")
source("tests/test_cross_validation.R")

# Run all cross-validation tests
run_cross_validation()

# Or run specific tests
testthat::test_file("tests/test_cross_validation.R")
```

### Method 2: Generate Praat Reference Data First

```bash
# Generate reference output from Praat scripts
cd /Users/frkkan96/Documents/src/pladdrr/tests
./generate_praat_reference.sh

# This creates:
# - reference_output/avqi_reference.csv
# - reference_output/dsi_reference.csv
# - reference_output/tremor_*.csv
```

Then compare against R and Python implementations:

```R
# Load reference data
avqi_ref <- read.csv("/Users/frkkan96/Documents/src/plabench/reference_output/avqi_reference.csv")

# Run R implementation
r_result <- compute_avqi(...)

# Compare
all.equal(avqi_ref$avqi, r_result$avqi, tolerance = 0.01)
```

### Method 3: Direct Praat Script Calling via speakr

```R
library(speakr)

# Call Praat script directly
praat_output <- praat(
  script = "/Users/frkkan96/Documents/src/plabench/AVQI301.praat",
  arguments = list(
    input_directory = "/path/to/input",
    output_directory = "/path/to/output"
  ),
  capture = TRUE
)

# Parse output
parse_praat_output(praat_output)
```

## Numerical Tolerances

Different measures require different tolerance levels due to numerical precision:

| Measure | Tolerance | Unit | Reason |
|---------|-----------|------|--------|
| AVQI score | 0.01 | - | Composite measure |
| CPPS | 0.1 | dB | FFT precision |
| HNR | 0.1 | dB | Autocorrelation precision |
| Shimmer | 0.01 | % | Period detection precision |
| Slope/Tilt | 0.1 | dB | Regression precision |
| DSI score | 0.01 | - | Composite measure |
| MPT | 0.1 | s | Duration precision |
| I-low | 0.5 | dB | Intensity estimation |
| F0-high | 1.0 | Hz | Pitch tracking |
| Jitter ppq5 | 0.001 | % | Period perturbation |
| Tremor F | 0.1 | Hz | Spectrum peak detection |
| Tremor I | 1.0 | % | Power estimation |

These tolerances account for:
- Floating-point arithmetic differences between languages
- Different FFT library implementations
- Minor algorithmic variations (e.g., interpolation methods)

## Validation Workflow

### 1. Unit Tests (Individual Components)

Test each DSP operation in isolation:

```R
test_that("Pitch extraction matches Praat", {
  sound <- Sound$new("test.wav")

  # R implementation
  pitch <- sound$to_pitch(time_step = 0.01, pitch_floor = 75, pitch_ceiling = 600)
  r_f0 <- pitch$get_mean(0, 0, "hertz")

  # Python implementation
  python_f0 <- system2("python3", args = c("-c",
    "import parselmouth; s = parselmouth.Sound('test.wav');
     p = s.to_pitch(); print(p.get_mean())"),
    stdout = TRUE)

  expect_equal(r_f0, as.numeric(python_f0), tolerance = 1.0)
})
```

### 2. Integration Tests (Full Pipelines)

Test complete analysis pipelines:

```R
test_that("AVQI v3.01 end-to-end", {
  # R implementation
  r_avqi <- compute_avqi(cs_files, sv_files)

  # Python implementation
  py_avqi <- run_python_plabench_avqi(cs_files, sv_files)

  # Praat reference
  praat_avqi <- read_praat_reference("avqi_reference.csv")

  # Three-way comparison
  expect_equal(r_avqi$avqi, py_avqi$avqi, tolerance = 0.01)
  expect_equal(r_avqi$avqi, praat_avqi$avqi, tolerance = 0.01)
})
```

### 3. Regression Tests (Version Control)

Lock in validated results:

```R
# Save validated results
saveRDS(list(
  avqi = r_avqi,
  dsi = r_dsi,
  tremor = r_tremor
), "tests/validated_results.rds")

# Future runs compare against validated baseline
test_that("No regression from baseline", {
  baseline <- readRDS("tests/validated_results.rds")
  current <- compute_avqi(...)
  expect_equal(current$avqi, baseline$avqi$avqi, tolerance = 0.001)
})
```

## Troubleshooting

### Issue: Praat Script Doesn't Output Parseable Data

**Solution:** Modify Praat scripts to output CSV or JSON:

```praat
# At end of AVQI script:
writeFileLine: output_file$, "avqi,cpps,hnr,shimmer_local,shimmer_db,slope,tilt"
appendFileLine: output_file$, "'avqi','cpps','hnr','shimmer_local','shimmer_db','slope','tilt'"
```

### Issue: Python Module Not Found

**Solution:** Ensure plabench is installed in editable mode:

```bash
cd /Users/frkkan96/Documents/src/plabench
pip install -e .
python3 -c "import sys; print(sys.path)"
```

### Issue: R Package Functions Not Found

**Solution:** Load the package with devtools:

```R
devtools::load_all("/Users/frkkan96/Documents/src/pladdrr")
ls("package:speaker")
```

### Issue: Numerical Differences Too Large

**Diagnosis steps:**

1. Check intermediate results:
```R
# R
pitch <- sound$to_pitch(...)
print(pitch$get_mean(0, 0, "hertz"))

# Python
import parselmouth
pitch = sound.to_pitch()
print(pitch.get_mean())
```

2. Verify audio loading:
```R
# R
sound <- Sound$new("test.wav")
print(sound$get_duration())
print(sound$get_sampling_frequency())

# Python
sound = parselmouth.Sound("test.wav")
print(sound.duration, sound.sampling_frequency)
```

3. Check for encoding issues (UTF-8 vs UTF-16):
```R
# Praat scripts may use UTF-16
con <- file("output.csv", encoding = "UTF-16")
data <- read.csv(con)
```

## Continuous Integration

### GitHub Actions Workflow

```yaml
name: Cross-Validation Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: macos-latest

    steps:
    - uses: actions/checkout@v2

    - name: Install Praat
      run: |
        brew install --cask praat

    - name: Setup Python
      uses: actions/setup-python@v2
      with:
        python-version: '3.9'

    - name: Install Python dependencies
      run: |
        pip install -e plabench

    - name: Setup R
      uses: r-lib/actions/setup-r@v2

    - name: Install R dependencies
      run: |
        Rscript -e 'install.packages(c("R6", "testthat", "jsonlite"))'

    - name: Run cross-validation tests
      run: |
        Rscript -e 'source("tests/test_cross_validation.R"); run_cross_validation()'
```

## Expected Test Results

When all implementations are correctly synchronized:

```
✓ AVQI v3.01: R/pladdrr vs Python/plabench
  AVQI:        R=3.142  Python=3.141  Diff=0.001 ✓
  CPPS:        R=12.45  Python=12.46  Diff=0.01 dB ✓
  HNR:         R=14.23  Python=14.22  Diff=0.01 dB ✓
  Shimmer:     R=3.45   Python=3.46   Diff=0.01% ✓
  Shimmer dB:  R=0.31   Python=0.31   Diff=0.00 dB ✓
  Slope:       R=-12.3  Python=-12.4  Diff=0.1 dB ✓
  Tilt:        R=8.92   Python=8.91   Diff=0.01 dB ✓

✓ DSI v2.01: R/pladdrr vs Python/plabench
  DSI:         R=3.45   Python=3.44   Diff=0.01 ✓
  MPT:         R=15.2   Python=15.3   Diff=0.1 s ✓
  I-low:       R=52.3   Python=52.5   Diff=0.2 dB ✓
  F0-high:     R=523.1  Python=523.8  Diff=0.7 Hz ✓
  Jitter ppq5: R=0.523  Python=0.524  Diff=0.001% ✓

✓ Tremor v3.05: R/pladdrr vs Python/plabench
  FTrF:        R=4.23   Python=4.24   Diff=0.01 Hz ✓
  FTrI:        R=23.4   Python=23.5   Diff=0.1% ✓
  ATrF:        R=4.87   Python=4.88   Diff=0.01 Hz ✓
  ATrI:        R=18.2   Python=18.3   Diff=0.1% ✓

=============================================================
All tests passed! ✓
=============================================================
```

## Contributing

When modifying any implementation:

1. Run cross-validation tests before committing
2. If intentional algorithmic changes are made, update tolerance levels
3. Document any deviations from original Praat scripts
4. Update this guide with new test procedures

## References

- **AVQI:** Barsties & Maryn (2015). American Journal of Otolaryngology, 36(5), 647-656.
- **DSI:** Wuyts et al. (2000). Journal of Speech, Language, and Hearing Research, 43(3), 796-809.
- **Tremor:** Brückl (2012). Vocal Tremor Measurement Based on Autocorrelation of Contours. Interspeech '12.
- **Praat:** Boersma & Weenink. http://www.praat.org/
- **Parselmouth:** Jadoul et al. (2018). Journal of Phonetics, 71, 1-15.

## Contact

For issues or questions about the cross-validation test suite:
- GitHub Issues: https://github.com/yourusername/pladdrr/issues
- Email: your.email@example.com
