# Debug Logging Removal Summary (2025-12-16)

## Problem

After fixing NAMESPACE exports and installing pladdrr 1.2.6, discovered excessive debug logging flooding console:
- `fprintf(stderr, "WR APPER: sound_to_pitch called...")` in `src/sound_wrappers.cpp:353`
- Additional debug statements in `src/praat.github.io/melder/NUMinterpol.cpp` (already removed in previous session)

## Solution

### Files Modified

**src/sound_wrappers.cpp**
- Line 353: Removed `fprintf(stderr, "WR APPER: sound_to_pitch called, floor=%.1f ceiling=%.1f\n", pitch_floor, pitch_ceiling); fflush(stderr);`
- Clean output during pitch extraction operations

### Installation

Package successfully installed to user library:
```bash
rm -rf ~/R/library/00LOCK*
R CMD INSTALL --library=~/R/library --no-test-load .
```

### Test Results

**Before** (with debug logging):
```
WR APPER: sound_to_pitch called, floor=75.0 ceiling=600.0
[... debug spam ...]
```

**After** (clean):
```
pladdrr: Direct access to Praat C functionality
Loading test sound...
Duration: 1 s

Testing formant extraction...
Formants extracted OK
Num frames: 190 

Testing Pitch->TextGrid VUV...
VUV TextGrid tiers: 1 

Testing Pitch->TextGrid silences...
Silence TextGrid tiers: 1 

✅ All tests passed!
```

## Commits

- **cdd88a8** - "chore: remove debug logging from sound_wrappers"

## Status

✅ Debug logging completely removed
✅ Package installed successfully
✅ All tests passing
✅ Production-ready

## Next Steps

1. Update NEWS.md for v1.2.7 (or amend v1.2.6)
2. Consider CRAN submission
3. Continue with documentation and examples
