# Next Steps: Pitch Detection Type Fix - Build & Test

## Status Summary
- ✅ Type mismatch fixed: `int` → `integer` in sound_wrappers.cpp  
- ✅ `integer` type defined in praat_types.h (intptr_t)
- ✅ Commits: 6d76338, 8fe51cb
- ⏳ Package build in progress (~2 hours on ARM Mac)

## When Build Completes

### Test Pitch Detection
```r
library(pladdrr)
snd <- Sound$new("inst/extdata/bell.wav")
pitch <- snd$to_pitch(pitch_floor = 75, pitch_ceiling = 600)
print(pitch$as_data_frame()[1:10,])
```

### Run Full Test
```bash
Rscript test_tremor_dsi_avqi.R
```

**Expected**: Tremor frequency ~1.7 Hz (not 4.999 Hz)

## If Tests Pass
1. Bump version: 1.2.0 → 1.2.1
2. Update NEWS.md
3. Commit & push

## Alternative Fix (if build issues persist)
Use explicit casting instead of changing parameter type:
```cpp
static_cast<integer>(max_candidates)
```
