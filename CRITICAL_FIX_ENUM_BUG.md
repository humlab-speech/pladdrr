# CRITICAL BUG FIX: kMelder_string Enum Off-by-One Error

## Issue
`TextGrid$extract_intervals_where()` was SEGFAULTING at address 0x68 when searching for non-existent intervals.

## Root Cause
**Off-by-one error in enum mapping** in `R/textgrid-r6.R` lines 569-576.

The `kMelder_string` enum is **1-based**, not 0-based:
```cpp
// From src/praat/melder/melder_enums.h
enums_begin (kMelder_string, 1)    // <-- Starts at 1, not 0!
	enums_add (kMelder_string, 1, EQUAL_TO, U"is equal to")
	enums_add (kMelder_string, 2, NOT_EQUAL_TO, U"is not equal to")
	enums_add (kMelder_string, 3, CONTAINS, U"contains")
	...
```

But our R code was mapping:
```r
# WRONG (0-based):
criterion_map <- c(
  "is equal to" = 0L,      # Should be 1L
  "is not equal to" = 1L,  # Should be 2L
  "contains" = 2L,         # Should be 3L
  ...
)
```

Passing `0` as the criterion caused undefined behavior in Praat's string matching function, leading to null pointer dereference (segfault at 0x68).

## Fix Applied
Updated `R/textgrid-r6.R` lines 568-581 to use correct 1-based enum values:

```r
# CORRECT (1-based, matches kMelder_string enum):
criterion_map <- c(
  "is equal to" = 1L,
  "is not equal to" = 2L,
  "contains" = 3L,
  "does not contain" = 4L,
  "starts with" = 5L,
  "does not start with" = 6L,
  "ends with" = 7L,
  "does not end with" = 8L,
  "contains a word equal to" = 9L,
  "does not contain a word equal to" = 10L,
  "matches regex" = 21L
)
```

## Files Modified
- `R/textgrid-r6.R` - Fixed enum mapping (lines 568-581)

## Testing Required
After rebuild, test:
```r
library(pladdrr)
snd <- Sound$from_values(rep(sin(2*pi*440*seq(0,1,length.out=44100)), 1), 44100, 0)
pitch <- snd$to_pitch()
tg <- pitch$to_textgrid_vuv()

# Should now work without segfault:
result <- tg$extract_intervals_where(snd, 1, "is equal to", "V", FALSE)
```

## Impact
This fix resolves:
- Test 4: TextGrid$extract_intervals_where() 
- Unblocks Tests 5-8 (DSI/AVQI/tremor workflows)

## Status
✅ Code fix complete
⏳ Rebuild required
⏳ Testing pending
