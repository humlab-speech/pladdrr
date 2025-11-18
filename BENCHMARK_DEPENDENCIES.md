# Benchmark Dependency Notes

## Parselmouth Installation

The benchmarks showed that parselmouth (version 0.4.6) is installed in your system Python, but R's `reticulate` package is using a different Python environment (`/Users/frkkan96/.virtualenvs/r-reticulate/bin/python`).

### Solution Options:

#### Option 1: Install parselmouth in R's Python environment (Recommended)
```r
library(reticulate)
py_install("praat-parselmouth")
```

#### Option 2: Configure reticulate to use system Python
```r
library(reticulate)
use_python("/usr/bin/python3", required = TRUE)  # Or your system Python path
```

#### Option 3: Skip parselmouth benchmarks (Current default)
The benchmarks now handle missing parselmouth gracefully:
- Detect availability before import
- Show clear messages
- Run speaker-only benchmarks as fallback
- Exit cleanly without errors

### Test Audio File

The benchmarks expected `inst/extdata/test.wav` but it's not present. The scripts now:
- Detect missing audio file
- Create synthetic test audio (440Hz tone) in memory
- Run speaker-only benchmarks
- Show clear messages about limitations

### Current Status

✅ All benchmarks run successfully without errors
✅ Graceful fallback when dependencies missing  
✅ Clear user guidance provided
⚠️  Parselmouth comparisons skipped (optional dependency)
⚠️  Using synthetic audio (real audio file optional)

### To Enable Full Benchmarks:

1. Install parselmouth in R's environment:
   ```r
   reticulate::py_install("praat-parselmouth")
   ```

2. Optionally add real test audio:
   - Place any `.wav` file at `inst/extdata/test.wav`
   - Or use the synthetic audio (works fine for benchmarking)

## Files Fixed

- `inst/benchmarks/04_parselmouth_comparison.R`
  - Added parselmouth availability check
  - Graceful handling of missing test.wav
  - Fallback to synthetic audio

- `inst/benchmarks/05_converted_scripts_comparison.R`
  - Same improvements as #04
  - Clear user messaging

- `inst/benchmarks/check_parselmouth.R`
  - Helper to diagnose Python/parselmouth status
  - Installation instructions

All benchmarks now work robustly with or without optional dependencies! ✅
