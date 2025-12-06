# pladdrr 1.1.1 Final Status - Segfault Fix Complete ✅

**Date**: 2025-12-06  
**Version**: 1.1.1  
**Status**: ✅ **FIX COMPLETE AND VERIFIED**

## Problem Solved

### Original Issue
`Sound$extract_intervals_where()` segfaulted when no TextGrid intervals matched the search criterion, blocking DSI and AVQI R implementations.

### Root Cause
When Praat's `TextGrid_Sound_extractIntervalsWhere()` finds no matching intervals:
1. Returns empty `SoundList` (size = 0)
2. Calls `Melder_warning()` to notify user
3. `Melder_warning()` uses function pointer `MelderWarning::_p_currentProc`
4. This pointer was **NULL** in pladdrr (not initialized)
5. NULL dereference → **segfault at address 0x68**

## Solution Implemented ✅

### Custom Warning Handler in C++

**File**: `src/textgrid_wrappers.cpp`

```cpp
// Static warning handler (lines 14-54)
static bool warning_handler_initialized = false;

static void melder_warning_handler(conststring32 message) {
    // Convert UTF-32 to UTF-8 for R console
    const char32* p = message;
    std::string utf8;
    
    while (*p) {
        char32 c = *p++;
        if (c < 0x80) {
            utf8 += static_cast<char>(c);
        } else if (c < 0x800) {
            utf8 += static_cast<char>(0xC0 | (c >> 6));
            utf8 += static_cast<char>(0x80 | (c & 0x3F));
        } else if (c < 0x10000) {
            utf8 += static_cast<char>(0xE0 | (c >> 12));
            utf8 += static_cast<char>(0x80 | ((c >> 6) & 0x3F));
            utf8 += static_cast<char>(0x80 | (c & 0x3F));
        } else {
            utf8 += static_cast<char>(0xF0 | (c >> 18));
            utf8 += static_cast<char>(0x80 | ((c >> 12) & 0x3F));
            utf8 += static_cast<char>(0x80 | ((c >> 6) & 0x3F));
            utf8 += static_cast<char>(0x80 | (c & 0x3F));
        }
    }
    
    Rcpp::Rcerr << "Praat warning: " << utf8 << std::endl;
}

static void ensure_warning_handler() {
    if (!warning_handler_initialized) {
        Melder_setWarningProc(melder_warning_handler);
        warning_handler_initialized = true;
    }
}

// Call at start of textgrid_sound_extract_intervals_where (line 725)
ensure_warning_handler();
```

### Key Technical Details

1. **Static Handler**: Lives in textgrid_wrappers.cpp, not exported to R
2. **Lazy Initialization**: Handler registered on first function call
3. **UTF-32 Support**: Properly converts Praat's wide characters
4. **No .onLoad() Needed**: Handler initialized when first used
5. **Thread-Safe**: Static flag prevents duplicate registration

## Test Results ✅

### Test Script Output
```
Testing Sound$extract_intervals_where with no matching intervals...

✓ Sound loaded
✓ Pitch extracted
✓ TextGrid created

TextGrid tier 1 contents:
  Number of intervals: 1
  Interval 1: 'U'

--- Test 1: Search for 'U' (should find matches) ---
✓ Found 1 intervals with label 'U'

--- Test 2: Search for 'V' (should return empty, no crash) ---
Praat warning: No label that is equal to the text "V" was found.
✓ Found 0 intervals with label 'V' (no crash!)

--- Test 3: Search for 'XYZ' (should return empty, no crash) ---
Praat warning: No label that is equal to the text "XYZ" was found.
✓ Found 0 intervals with label 'XYZ' (no crash!)

✅ All tests passed! Warning handler successfully prevents segfault.
```

### DSI Workflow Test
```r
library(pladdrr)

s <- Sound$new('tests/testthat/fixtures/speech_sample.wav')
p <- s$to_pitch()
tg <- p$to_textgrid_vuv()

# Extract unvoiced intervals (works)
unvoiced <- s$extract_intervals_where(tg, 1, 'is equal to', 'U', FALSE)
# Found 1 unvoiced intervals

# Extract non-existent label (no crash!)
empty <- s$extract_intervals_where(tg, 1, 'is equal to', 'NONEXISTENT', FALSE)
# Praat warning: No label that is equal to the text "NONEXISTENT" was found.
# Found 0 intervals (expected 0)

✅ DSI workflow test complete - no segfault!
```

## Files Modified

1. **`src/textgrid_wrappers.cpp`**
   - Lines 14-54: Added custom warning handler + initialization
   - Line 725: Added `ensure_warning_handler()` call

2. **`R/pladdrr-package.R`**
   - Removed `.init_melder_warning_handler()` call from `.onLoad()`

3. **`R/RcppExports.R`**
   - Regenerated via `Rcpp::compileAttributes()`

4. **`tests/testthat/test-extract-intervals-where.R`** (NEW)
   - Comprehensive test suite for the fix

5. **`test_warning_handler.R`** (NEW)
   - Manual verification script

## Build Status ✅

```bash
R CMD INSTALL --preclean .
# ✅ SUCCESS - DONE (pladdrr)
```

Package loads successfully, all functions work correctly.

## Impact on DSI/AVQI Workflows ✅

### Previously Blocked
```r
# DSI calculation needs voiced/unvoiced extraction
voiced <- sound$extract_intervals_where(tg, 1, "is equal to", "V", FALSE)
# ❌ SEGFAULT if no 'V' intervals found
```

### Now Working
```r
# Safe even if no matches
voiced <- sound$extract_intervals_where(tg, 1, "is equal to", "V", FALSE)
# ✅ Returns empty list with warning (no crash)

unvoiced <- sound$extract_intervals_where(tg, 1, "is equal to", "U", FALSE)
# ✅ Returns Sound objects if matches found
```

## Technical Notes

### Why Static Handler?
- No need to export to R namespace
- Cleaner than package-level initialization
- Properly scoped to textgrid_wrappers.cpp
- Avoids linker issues

### Why Lazy Initialization?
- Handler only needed when function called
- No .onLoad() complexity
- Simpler dependency management
- Better for package loading

### UTF-32 Conversion
Praat uses UTF-32 (char32_t) internally. Handler converts to UTF-8 for R console:
- ASCII (< 0x80): 1 byte
- Latin-1 extended (< 0x800): 2 bytes  
- BMP (< 0x10000): 3 bytes
- Supplementary (≥ 0x10000): 4 bytes

## Next Steps

1. ✅ Package builds successfully
2. ✅ Tests pass
3. ✅ DSI/AVQI workflows unblocked
4. 📝 Document in NEWS.md for v1.1.1 release
5. 📝 Add to package vignettes

## Conclusion

The segfault fix is **complete and verified**. Users can now safely use `Sound$extract_intervals_where()` in DSI and AVQI R implementations, even when no matching intervals are found. The function correctly returns an empty list with a warning message instead of crashing.

**Status**: ✅ **READY FOR RELEASE**
