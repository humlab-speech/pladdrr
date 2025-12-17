# Build and Installation Guide

## Prerequisites

### System Requirements

- R >= 3.5.0
- C++11 compatible compiler
  - Linux: g++ >= 4.9 or clang++ >= 3.4
  - macOS: Xcode command line tools
  - Windows: Rtools >= 3.5

### R Package Dependencies

- Rcpp >= 1.0.0
- methods (base R)

### Development Dependencies

- devtools
- testthat >= 3.0.0
- microbenchmark (for benchmarks)
- R6 (for benchmark comparisons)

## Installation

### From Source

```bash
# Clone repository
git clone https://github.com/humlab-speech/pladdrr.git
cd pladdrr

# Install dependencies
R -e "install.packages(c('Rcpp', 'devtools', 'testthat', 'microbenchmark', 'R6'))"

# Build and install
R CMD build .
R CMD INSTALL pladdrr_*.tar.gz
```

### Using devtools

```r
# In R
devtools::install_github("humlab-speech/pladdrr")
```

## Building from Source

### Step 1: Generate RcppExports

The package needs to generate `RcppExports.R` and `RcppExports.cpp`:

```r
# In R, from package root
library(Rcpp)
Rcpp::compileAttributes(".")
```

This will create:
- `R/RcppExports.R` - R wrapper functions
- `src/RcppExports.cpp` - C++ registration code

### Step 2: Build the Package

```bash
R CMD build .
```

This creates a tarball: `pladdrr_0.1.0.tar.gz`

### Step 3: Check the Package

```bash
R CMD check pladdrr_0.1.0.tar.gz
```

Expected warnings:
- "No Praat source integrated" - This is expected for the mock implementation
- Tests skipped - Mock implementation can't run full tests

### Step 4: Install

```bash
R CMD INSTALL pladdrr_0.1.0.tar.gz
```

Or within R:
```r
install.packages("pladdrr_0.1.0.tar.gz", repos = NULL, type = "source")
```

## Development Workflow

### Quick Check (No Full Build)

```r
# Load with devtools for development
devtools::load_all(".")

# Run tests
devtools::test()

# Check package
devtools::check()
```

### Rebuilding After C++ Changes

```r
# Recompile C++ code
devtools::clean_dll()
devtools::load_all(".")
```

## Integrating Praat Source

**Current Status**: The package uses mock implementations for demonstration.

**To integrate real Praat code**:

### Option 1: Vendor Praat Source

```bash
# Add Praat as subdirectory
mkdir src/praat
# Copy Praat source files to src/praat/
```

Update `src/Makevars`:
```makefile
PKG_CXXFLAGS = -I. -Ipraat/sys -Ipraat/fon -Ipraat/dwtools
PKG_LIBS = # Add any required Praat libraries
```

### Option 2: System Praat Library

If Praat is installed system-wide:

```makefile
# src/Makevars
PKG_CXXFLAGS = $(shell pkg-config --cflags praat)
PKG_LIBS = $(shell pkg-config --libs praat)
```

### Option 3: Git Submodule

```bash
git submodule add https://github.com/praat/praat.git src/praat
git submodule update --init --recursive
```

## Testing

### Running Tests

```r
# All tests
devtools::test()

# Specific test file
testthat::test_file("tests/testthat/test-sound.R")
```

### Current Test Status

Most tests are skipped because they require:
1. Real Praat integration
2. Test audio files

When Praat is integrated:
1. Add test audio files to `inst/extdata/`
2. Remove `skip()` calls from tests
3. Run full test suite

## Benchmarking

```r
# Run benchmarks
source("benchmarks/compare_performance.R")

# Expected results (with real implementation):
# - Module approach 3-5x faster than R6
# - Memory usage 30-50% lower
```

## Troubleshooting

### "undefined symbol" errors

This usually means Praat functions aren't linked. Check:
1. Praat source is included in `src/`
2. `Makevars` includes correct paths
3. All required Praat `.c` files are compiled

### "module not found" errors

```r
# Rebuild and reload
devtools::clean_dll()
devtools::load_all(".")
```

### Compilation errors

Common issues:
1. **C++11 not enabled**: Check `Makevars` has `CXX_STD = CXX11`
2. **Missing headers**: Add include paths to `PKG_CXXFLAGS`
3. **Praat compatibility**: Praat code may need adaptation for C++

## Platform-Specific Notes

### Linux

Should work out of the box with g++ or clang++.

### macOS

Requires Xcode command line tools:
```bash
xcode-select --install
```

### Windows

Requires Rtools:
1. Download from https://cran.r-project.org/bin/windows/Rtools/
2. Install and add to PATH
3. May need to configure `src/Makevars.win` separately

## Continuous Integration

Suggested GitHub Actions workflow:

```yaml
name: R-CMD-check

on: [push, pull_request]

jobs:
  check:
    runs-on: ${{ matrix.os }}
    strategy:
      matrix:
        os: [ubuntu-latest, macos-latest, windows-latest]
        r: [release, devel]
        
    steps:
      - uses: actions/checkout@v2
      - uses: r-lib/actions/setup-r@v2
        with:
          r-version: ${{ matrix.r }}
      - uses: r-lib/actions/setup-r-dependencies@v2
      - name: Check
        run: rcmdcheck::rcmdcheck(args = "--no-manual", error_on = "error")
```

## Documentation

### Generating Documentation

```r
# Generate Rd files from roxygen comments
devtools::document()

# Build package website
pkgdown::build_site()
```

### Viewing Documentation

```r
# After installation
?pladdrr::read_sound
help(package = "pladdrr")
```

## Performance Testing

After integration with real Praat:

```r
# Create test files
library(pladdrr)
library(microbenchmark)

# Load audio
snd <- read_sound("test.wav")

# Benchmark pitch extraction
microbenchmark(
  pitch = snd$to_pitch(),
  times = 100
)

# Compare to parselmouth (if available)
# Install: pip install praat-parselmouth
library(reticulate)
pm <- import("parselmouth")
pm_snd <- pm$Sound("test.wav")

microbenchmark(
  r_pladdrr = snd$to_pitch(),
  python_pm = pm_snd$to_pitch(),
  times = 100
)
```

Expected: pladdrr and parselmouth should have similar performance.

## Next Steps for Production

1. ✅ Package structure complete
2. ✅ Rcpp module architecture implemented
3. ⚠️ TODO: Integrate Praat source code
4. ⚠️ TODO: Implement real wrappers (replace mocks)
5. ⚠️ TODO: Add test audio files
6. ⚠️ TODO: Enable and expand tests
7. ⚠️ TODO: Comprehensive benchmarking
8. ⚠️ TODO: Documentation and examples
9. ⚠️ TODO: CRAN submission preparation
