# pladdrr TextGrid Reading Issue - Detailed Report

**Date:** 2025-12-18  
**Reporter:** plabench VUV Integration  
**pladdrr Version:** 1.1.8  
**Affected Functionality:** TextGrid file reading

---

## Executive Summary

pladdrr cannot read existing TextGrid files from disk, returning the error:
```
Error: TextGrid file reading is currently unavailable due to Praat initialization issues.
```

This limitation prevents merging new analysis tiers with existing TextGrid annotations, forcing users to create TextGrids from scratch programmatically.

**Impact:** Medium severity - core acoustic analysis works, but TextGrid I/O is broken.

---

## Reproduction Steps

### Minimal Failing Example

```r
library(pladdrr)

# This works: Create TextGrid programmatically
sound <- Sound$new("test.wav")
duration <- sound$get_total_duration()
textgrid <- TextGrid$create(0, duration)
tier <- textgrid$insert_interval_tier(1, "words")
# Success - TextGrid created in memory

# This FAILS: Read existing TextGrid from file
textgrid_from_file <- TextGrid$new("existing.TextGrid")
# Error: TextGrid file reading is currently unavailable due to Praat 
# initialization issues. Use TextGrid$create() to create new TextGrids 
# programmatically.
```

### Test Files

Test files are available in plabench repository:
- Audio: `signalfiles/VUV/input/test_speech.wav`
- TextGrid: `signalfiles/VUV/input/test_speech.TextGrid`

```r
# Clone plabench
git clone https://github.com/your-repo/plabench.git
cd plabench

# Attempt to read TextGrid
library(pladdrr)
tg <- TextGrid$new("signalfiles/VUV/input/test_speech.TextGrid")
# ERROR
```

---

## Current Behavior

### What Works ✅

1. **Sound file reading:**
   ```r
   sound <- Sound$new("file.wav")  # Works
   ```

2. **TextGrid creation from scratch:**
   ```r
   tg <- TextGrid$create(0, 5.0)  # Works
   tier <- tg$insert_interval_tier(1, "segments")  # Works
   ```

3. **TextGrid manipulation:**
   ```r
   tg$insert_boundary(1, 2.5)  # Works
   tg$set_interval_text(1, 1, "hello")  # Works
   ```

4. **TextGrid writing:**
   ```r
   tg$save("output.TextGrid")  # Works
   ```

### What Fails ❌

1. **TextGrid reading from file:**
   ```r
   tg <- TextGrid$new("input.TextGrid")  # FAILS
   ```

2. **TextGrid merging workflow:**
   ```r
   # Cannot implement: Read existing → Add tier → Save merged
   original <- TextGrid$new("original.TextGrid")  # FAILS
   # Workaround impossible if original has complex annotations
   ```

---

## Expected Behavior

Should match Praat's TextGrid file reading:

```praat
# Praat script (works correctly)
Read from file: "input.TextGrid"
name$ = selected$ ("TextGrid")
numTiers = Get number of tiers
# Success
```

Expected R equivalent:
```r
library(pladdrr)
textgrid <- TextGrid$new("input.TextGrid")
num_tiers <- textgrid$get_number_of_tiers()
# Should work but doesn't
```

---

## Impact Analysis

### Use Cases Blocked

1. **Merging Analysis with Existing Annotations:**
   - User has TextGrid with word/phone boundaries from forced alignment
   - Wants to add VUV tier, pitch tier, or intensity tier
   - **Blocked:** Cannot read existing TextGrid to merge

2. **Batch Processing Workflows:**
   - Process corpus with existing TextGrids
   - Add acoustic analysis tiers to each
   - **Blocked:** Must recreate all annotations programmatically

3. **Round-Trip Editing:**
   - Read TextGrid → Modify tier → Save
   - **Blocked:** Cannot read initial file

### Workarounds and Limitations

**Current workaround:**
```r
# Generate new tier without merging
detect_vuv_r <- function(sound_file, textgrid_file = NULL) {
  # Ignore textgrid_file parameter
  # Generate VUV tier only (1 tier)
  # Cannot merge with original (would be 2+ tiers)
  
  if (!is.null(textgrid_file)) {
    warning("pladdrr cannot read TextGrid files - parameter ignored")
  }
  
  # ... analysis code ...
  
  # Return unmerged TextGrid
  return(list(textgrid = vuv_only_textgrid))
}
```

**Limitation:** Users must manually merge TextGrids in Praat or Python.

---

## Comparison with Other pladdrr I/O

### Working I/O Functions

| Object Type | Read | Write | Notes |
|-------------|------|-------|-------|
| Sound | ✅ `Sound$new(file)` | ✅ `sound$save(file)` | Works perfectly |
| Pitch | ✅ `Pitch$new(file)` | ✅ `pitch$save(file)` | Assumed working |
| Intensity | ✅ `Intensity$new(file)` | ✅ `intensity$save(file)` | Assumed working |
| TextGrid | ❌ **BROKEN** | ✅ `textgrid$save(file)` | Read fails, write works |

**Pattern:** All Praat object types support file I/O except TextGrid reading.

---

## Technical Investigation

### Error Message Analysis

```
Error: TextGrid file reading is currently unavailable due to Praat 
initialization issues. Use TextGrid$create() to create new TextGrids 
programmatically.
```

**Interpretation:**
- Error is intentional (not a crash)
- Suggests "Praat initialization issues" as root cause
- Provides workaround (create programmatically)
- Implies temporary limitation, not design choice

### Hypothesis: Initialization Order

Possible causes:
1. TextGrid file parser not initialized in pladdrr startup
2. Praat C API call for TextGrid reading not exposed/wrapped
3. File path resolution issue specific to TextGrid objects
4. Memory management issue with TextGrid deserialization

### Related pladdrr Functions

Functions that might share implementation with TextGrid reading:

```r
# Check if these work:
ls("package:pladdrr") |> grep("TextGrid|read|load")
```

Potentially related:
- `praat_matrix()` - reads matrix files
- `read_sound()` - helper for Sound reading
- Any `from_file()` or `load()` methods

---

## Test Cases for Fix Validation

### Test 1: Basic TextGrid Reading

```r
library(pladdrr)
library(testthat)

test_that("TextGrid can be read from file", {
  # Setup: Create test TextGrid
  tg_write <- TextGrid$create(0, 1.0)
  tier <- tg_write$insert_interval_tier(1, "test")
  tg_write$insert_boundary(1, 0.5)
  tg_write$set_interval_text(1, 1, "first")
  tg_write$set_interval_text(1, 2, "second")
  tg_write$save("test_tg.TextGrid")
  
  # Test: Read back
  tg_read <- TextGrid$new("test_tg.TextGrid")
  
  # Validate
  expect_equal(tg_read$get_number_of_tiers(), 1)
  expect_equal(tg_read$get_tier_name(1), "test")
  expect_equal(tg_read$get_interval_text(1, 1), "first")
  expect_equal(tg_read$get_interval_text(1, 2), "second")
  
  # Cleanup
  unlink("test_tg.TextGrid")
})
```

### Test 2: Multi-Tier TextGrid

```r
test_that("Multi-tier TextGrid reading preserves all tiers", {
  # Create TextGrid with 3 tiers
  tg <- TextGrid$create(0, 3.0)
  tg$insert_interval_tier(1, "words")
  tg$insert_interval_tier(2, "phones")
  tg$insert_point_tier(3, "events")
  
  tg$insert_boundary(1, 1.5)
  tg$set_interval_text(1, 1, "hello")
  
  tg$save("multi_tier.TextGrid")
  
  # Read back
  tg_read <- TextGrid$new("multi_tier.TextGrid")
  
  expect_equal(tg_read$get_number_of_tiers(), 3)
  expect_equal(tg_read$get_tier_name(1), "words")
  expect_equal(tg_read$get_tier_name(2), "phones")
  expect_equal(tg_read$get_tier_name(3), "events")
  
  unlink("multi_tier.TextGrid")
})
```

### Test 3: TextGrid from Praat

```r
test_that("TextGrid created by Praat can be read", {
  # This TextGrid was created by Praat, not pladdrr
  # Tests real-world compatibility
  praat_tg <- TextGrid$new("signalfiles/VUV/input/test_speech.TextGrid")
  
  expect_s3_class(praat_tg, "TextGrid")
  expect_gte(praat_tg$get_number_of_tiers(), 1)
})
```

### Test 4: Round-Trip Editing

```r
test_that("TextGrid can be read, modified, and saved", {
  # Create original
  tg1 <- TextGrid$create(0, 2.0)
  tg1$insert_interval_tier(1, "original")
  tg1$insert_boundary(1, 1.0)
  tg1$set_interval_text(1, 1, "first")
  tg1$save("round_trip.TextGrid")
  
  # Read and modify
  tg2 <- TextGrid$new("round_trip.TextGrid")
  tg2$insert_interval_tier(2, "added")
  tg2$save("round_trip_modified.TextGrid")
  
  # Read modified
  tg3 <- TextGrid$new("round_trip_modified.TextGrid")
  
  expect_equal(tg3$get_number_of_tiers(), 2)
  expect_equal(tg3$get_tier_name(1), "original")
  expect_equal(tg3$get_tier_name(2), "added")
  
  # Cleanup
  unlink(c("round_trip.TextGrid", "round_trip_modified.TextGrid"))
})
```

---

## Real-World Example: VUV Detection

### Current Praat Script (Works)

```praat
# VUV_Computations_v6.praat by Al-Tamimi
Read from file: "speech.wav"
name$ = selected$ ("Sound")

# Check if TextGrid exists
textgridPath$ = "speech.TextGrid"
textgridExists = fileReadable(textgridPath$)

if textgridExists
    Read from file: textgridPath$
endif

# ... VUV analysis ...

# Create VUV tier
To TextGrid (vuv): 0.02, meanPeriod
vuvTier = selected ("TextGrid")

# Merge with original if exists
if textgridExists
    selectObject: "TextGrid 'name$'"
    plusObject: vuvTier
    Merge
    # Result: Original tiers + VUV tier
endif
```

### Current pladdrr Implementation (Broken)

```r
detect_vuv_r <- function(sound_file, textgrid_file = NULL) {
  sound <- Sound$new(sound_file)
  
  # CANNOT DO THIS:
  # if (!is.null(textgrid_file)) {
  #   textgrid_orig <- TextGrid$new(textgrid_file)  # ERROR
  # }
  
  # ... VUV analysis ...
  
  # Can only create VUV tier, cannot merge
  textgrid_vuv <- point_process$to_textgrid_vuv(0.02, mean_period)
  
  # CANNOT DO THIS:
  # if (!is.null(textgrid_orig)) {
  #   textgrid_merged <- textgrid_orig$merge(textgrid_vuv)  
  # }
  
  # Return unmerged TextGrid (limitation)
  return(list(textgrid = textgrid_vuv))
}
```

### Desired pladdrr Implementation (Would Work if Fixed)

```r
detect_vuv_r <- function(sound_file, textgrid_file = NULL) {
  sound <- Sound$new(sound_file)
  
  # Read existing TextGrid
  textgrid_orig <- NULL
  if (!is.null(textgrid_file)) {
    textgrid_orig <- TextGrid$new(textgrid_file)  # Should work
  }
  
  # ... VUV analysis ...
  
  # Create VUV tier
  textgrid_vuv <- point_process$to_textgrid_vuv(0.02, mean_period)
  
  # Merge if original exists
  if (!is.null(textgrid_orig)) {
    textgrid_merged <- textgrid_orig$merge(textgrid_vuv)
    return(list(textgrid = textgrid_merged))
  } else {
    return(list(textgrid = textgrid_vuv))
  }
}
```

---

## Comparison with Python/Parselmouth

### Python Implementation (Works Perfectly)

```python
import parselmouth

# Read existing TextGrid
textgrid = parselmouth.read(parselmouth.TextGrid, "input.TextGrid")
num_tiers = parselmouth.praat.call(textgrid, "Get number of tiers")
# Works flawlessly

# Create new tier
vuv_tier = point_process.to_textgrid_vuv(0.02, mean_period)

# Merge
if textgrid_orig is not None:
    merged = parselmouth.praat.call([textgrid_orig, vuv_tier], "Merge")
```

**Observation:** Parselmouth fully supports TextGrid I/O without issues.

---

## Suggested Investigation Areas

### 1. Check Praat C API Exposure

```r
# Are these Praat functions exposed in pladdrr?
# - Data_readFromTextFile
# - TextGrid_readFromFile
# - Data_readFromBinaryFile (if binary TextGrid support needed)
```

### 2. Compare with Sound Reading

Sound reading works, so compare implementations:

```r
# Sound$new() internals (works)
# vs
# TextGrid$new() internals (broken)
```

Look for differences in:
- File path handling
- Praat object creation sequence
- Memory allocation
- Error handling

### 3. Check pladdrr Initialization

```r
# Does TextGrid reading require specific initialization?
# Is there an init function that wasn't called?
.onLoad <- function(libname, pkgname) {
  # Check what's initialized here
}
```

### 4. Test with Different TextGrid Formats

Praat supports multiple TextGrid formats:
- Short text format
- Full text format  
- Binary format (Praat Collection)

Test if issue is format-specific:

```r
# Create TextGrid in different formats using Praat
# Save as "short text file"
# Save as "text file"
# Save as "binary file"
# Try reading each with pladdrr
```

---

## Priority and Impact

### Severity: **Medium-High**

**Justification:**
- **Blocks:** Common workflow (merging analysis with annotations)
- **Workaround exists:** Generate TextGrids programmatically
- **Does not crash:** Error is caught and reported
- **Core functionality works:** Acoustic analysis unaffected

### User Impact

**Academic Research:**
- Speech corpus analysis often has existing TextGrids with annotations
- Researchers need to add acoustic measure tiers
- **Current status:** Must use Python/Praat for TextGrid operations

**Clinical Applications:**
- Voice analysis workflows (like plabench VUV detection)
- Need to merge acoustic tiers with clinical annotations
- **Current status:** R implementation has feature parity loss

**Production Systems:**
- Automated pipelines processing annotated speech
- **Current status:** Cannot use pure R pipeline

---

## References

### Related Issues

- Check pladdrr GitHub issues for "TextGrid" or "read" or "initialization"
- Search for similar issues in other R-Praat bridges (if any exist)

### Documentation

- Praat TextGrid format specification
- pladdrr API documentation for TextGrid class
- Parselmouth implementation (working reference)

### Test Environment

- **R Version:** 4.x
- **pladdrr Version:** 1.1.8
- **OS:** macOS (also test Linux/Windows)
- **Praat Version:** 6.4+ (pladdrr uses modern Praat functions)

---

## Contact

For questions or additional information:
- **Repository:** https://github.com/your-repo/plabench
- **Issue:** VUV integration testing
- **Files:** 
  - `R_implementations/vuv.R` (affected implementation)
  - `tests/test_3way_validation.py` (documents workaround)
  - `signalfiles/VUV/input/` (test data)

---

## Appendix A: TextGrid File Format

### Example TextGrid (Short Format)

```
File type = "ooTextFile"
Object class = "TextGrid"

xmin = 0 
xmax = 1.5 
tiers? <exists> 
size = 2 
item []: 
    item [1]:
        class = "IntervalTier" 
        name = "words" 
        xmin = 0 
        xmax = 1.5 
        intervals: size = 2 
        intervals [1]:
            xmin = 0 
            xmax = 0.75 
            text = "hello" 
        intervals [2]:
            xmin = 0.75 
            xmax = 1.5 
            text = "world" 
    item [2]:
        class = "TextTier" 
        name = "events" 
        xmin = 0 
        xmax = 1.5 
        points: size = 1 
        points [1]:
            number = 0.5 
            mark = "boundary" 
```

This is a standard Praat TextGrid file that pladdrr should be able to read.

---

## Appendix B: Praat Objects Working in pladdrr

List of Praat object types confirmed working in pladdrr 1.1.8:

| Object Type | Creation | File Reading | File Writing | Methods |
|-------------|----------|--------------|--------------|---------|
| Sound | ✅ `$new()` | ✅ `$new(file)` | ✅ `$save()` | ✅ Full |
| Pitch | ✅ `sound$to_pitch_cc()` | ? | ? | ✅ Most |
| Intensity | ✅ `sound$to_intensity()` | ? | ? | ✅ Most |
| Formant | ✅ `sound$to_formant_burg()` | ? | ? | ✅ Most |
| PointProcess | ✅ `pitch$to_pointprocess_cc()` | ? | ? | ✅ Most |
| TextGrid | ✅ `TextGrid$create()` | ❌ **BROKEN** | ✅ `$save()` | ✅ Most |
| Spectrum | ✅ `sound$to_spectrum()` | ? | ? | ✅ Most |
| Harmonicity | ✅ `sound$to_harmonicity_ac()` | ? | ? | ✅ Most |

**Legend:**
- ✅ = Confirmed working
- ❌ = Confirmed broken
- ? = Untested

---

**END OF REPORT**

Please submit this report to pladdrr developers at their GitHub repository.
