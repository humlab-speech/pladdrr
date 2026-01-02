# Session Notes: 2026-01-02

## Summary

Attempted Phase 2 module implementations. Discovered significant limitations in Praat source that block progress on certain modules.

## Work Completed

### 1. FormantPath Module Debugging (Phase 2.2)
**Status**: Incomplete - blocked by missing dependencies

**Issues found**:
- Missing `Formant_extractPart` function → Created stub in formant_stubs.cpp
- Fixed C++ signature mismatch (constFormant vs Formant)  
- **BLOCKER**: Missing `FormantModeler_getStress` and likely other FormantModeler functions
- FormantPath has deep dependencies on unimplemented Praat classes

**Commits**:
- 024f7e8: Enable FormantPath module
- 7e56006: Fix Formant_extractPart signature

**Outcome**: FormantPath cannot be completed without implementing entire FormantModeler class first. Deferred.

### 2. Harmonics Module Investigation (Phase 2.5)
**Status**: Abandoned - no Praat implementation exists

**Issues found**:
- Praat has `Harmonics.h` header with declarations
- NO corresponding `.cpp` implementation file
- Functions like `Sound_to_Harmonics()` are declared but never defined
- Harmonics is an incomplete/placeholder class in Praat

**Outcome**: Cannot implement module for non-existent functionality. Removed from Phase 2 scope.

## Current Phase 2 Status

**Complete**: 1/5 modules (20%)
- ✅ Polygon (working)

**Blocked/Deferred**:
- ⏸️  FormantPath - requires FormantModeler implementation (complex)
- ❌ Harmonics - no Praat implementation exists
- ⏳ KlattGrid - not started (6-8 days estimated, complex)
- ⏳ ComplexSpectrogram - not started (3-4 days estimated, simple)

## Lessons Learned

1. **Verify implementation exists**: Always check for `.cpp` files, not just headers
2. **Check dependencies**: FormantPath depends on FormantModeler which is also incomplete
3. **C++ signature matching**: constFormant vs Formant matters for linker symbol resolution
4. **Use `nm` for debugging**: Check object files for actual symbol names when debugging linker errors

## Recommendations

1. **Prioritize ComplexSpectrogram next**: Self-contained, ~300 lines, no complex dependencies
2. **Defer FormantPath**: Requires implementing FormantModeler first (significant work)
3. **Remove Harmonics from roadmap**: Cannot implement non-existent functionality
4. **Update Phase 2 goals**: Aim for 2-3 modules instead of 5, given constraints

## Technical Notes

### C++ Name Mangling Issue
```
// Declaration needed:
autoFormant Formant_extractPart (Formant me, double tmin, double tmax);

// NOT:
autoFormant Formant_extractPart (constFormant me, double tmin, double tmax);

// Reason: FormantPath.cpp calls with:
const Formant formant = ...;
Formant_extractPart(formant, ...)  // Passes as non-const Formant*
```

### Symbol Check Commands
```bash
# Check what symbol is needed:
nm src/praat.github.io/LPC/FormantPath.o | grep Formant_extractPart

# Check what symbol is provided:
nm src/formant_stubs.o | grep Formant_extractPart

# Must match exactly for linking to succeed
```

## Next Steps

1. Implement ComplexSpectrogram module (Phase 2.4)
2. Re-evaluate Phase 2 completion criteria
3. Consider Phase 3 or other high-value work if Phase 2 modules remain blocked
