# LPC Implementation Status - November 13, 2025

## Status: Deferred Due to CLAPACK Dependency

### Summary
LPC (Linear Predictive Coding) implementation attempted but requires CLAPACK (linear algebra library) which is a large external dependency not currently in the build system.

### What Was Done
- ✅ Created complete LPC C++ wrappers (src/lpc_wrappers.cpp)  
- ✅ Created LPC R6 class (R/lpc-r6.R)
- ✅ Added LPC methods to Sound class
- ✅ Configured Makevars for LPC sources

### The Problem
Praat's LPC implementation requires:
1. **SoundFrames.cpp** → needs **SVD.cpp** → needs **clapack.h**
2. **LPC_to_Formant** → needs **Roots.cpp** → needs **clapack.h**

CLAPACK is a large C library (~500KB+) with platform-specific compilation requirements.

### Workaround for Users
Use existing formant extraction:
```r
# Instead of LPC approach:
formant <- sound$to_formant_burg()  # Works perfectly!
```

### Future Plans
- **v1.x**: LPC remains disabled
- **v2.0**: Consider CLAPACK integration or GSL alternative
- All LPC code remains in repository, ready for future activation

### Decision
Prioritize package stability and easy installation over LPC feature. The 18 other Praat objects (~330 methods) work perfectly.
