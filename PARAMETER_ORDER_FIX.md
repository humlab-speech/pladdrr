# Parameter Order Fix (2025-12-10)

## Issue
`Sound$create_tone()` had inconsistent parameter order between R interface and C++ wrapper:
- **R interface**: `duration, frequency, sampling_rate, amplitude`  
- **C++ wrapper**: `duration, sampling_rate, frequency, amplitude`
- **Result**: Parameters were swapped when calling C++, causing confusion

## Fix
Aligned R interface with C++ wrapper order:
- **New order**: `duration, sampling_rate, frequency, amplitude`
- **Benefit**: Arguments pass directly to C++ without reordering

## Impact
✅ **No breaking changes** - All vignettes use named parameters
✅ **Clearer code** - No hidden parameter swapping
✅ **Better maintainability** - R signature matches C++ signature

## Files Changed
- `R/sound-r6-new.R` (lines 1216-1224)
- Documentation updated to reflect new order

## Testing
All 10 vignettes still render successfully with named parameters.
