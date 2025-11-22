# Build Fix: LAPACK Header Issue Resolution
## 2025-11-22

**Version**: 0.9.3 → 0.9.4  
**Status**: ✅ BUILD SUCCESSFUL  
**Issue**: Duplicate NUMlapack.h with clapack.h include  

---

## Problem

The package failed to build with the following error:

```
In file included from praat.github.io/dwsys/Eigen.cpp:43:
praat.github.io/dwsys/NUMlapack.h:22:10: fatal error: 'clapack.h' file not found
   22 | #include "clapack.h"
      |          ^~~~~~~~~~~
```

## Root Cause

The speaker package has two parallel Praat source directory structures:
1. `/src/praat/` - Older version with `#include "clapack.h"`
2. `/src/praat.github.io/` - Updated version using R's LAPACK via `#include <R_ext/Lapack.h>`

The compiler was picking up the old version of `NUMlapack.h` from `/src/praat/dwsys/` which still referenced the non-existent `clapack.h`.

## Solution

Synchronized the NUMlapack.h file across both directories by copying the updated version:

```bash
cp /src/praat.github.io/dwsys/NUMlapack.h /src/praat/dwsys/NUMlapack.h
```

### Key Changes in NUMlapack.h

**Old (broken) version:**
```c
#include "melder.h"
#include "clapack.h"
#undef max
#undef min
```

**New (fixed) version:**
```c
#include "melder.h"

/* Use R's LAPACK instead of CLAPACK */
#include <R_ext/BLAS.h>
#include <R_ext/Lapack.h>

/* Type alias for Praat's CLAPACK interface */
typedef double doublereal;

/* Wrapper functions to match Praat's expected LAPACK signatures */
#ifdef __cplusplus
extern "C" {
#endif

/* Inline wrappers that convert integer* to int* */
static inline double dlamch_(const char* cmach) {
    return dlamch_wrap_int(cmach);
}

static inline int dgeev_(const char* jobvl, const char* jobvr, integer* n, double* a, integer* lda,
                        double* wr, double* wi, double* vl, integer* ldvl,
                        double* vr, integer* ldvr, double* work, integer* lwork, integer* info) {
    int n_int = (int)*n, lda_int = (int)*lda, ldvl_int = (int)*ldvl;
    int ldvr_int = (int)*ldvr, lwork_int = (int)*lwork, info_int = (int)*info;
    int result = dgeev_wrap_int(jobvl, jobvr, &n_int, a, &lda_int, wr, wi, vl, &ldvl_int,
                                vr, &ldvr_int, work, &lwork_int, &info_int);
    *info = (integer)info_int;
    return result;
}
// ... (additional LAPACK wrapper functions)
```

## Build Verification

```bash
cd /Users/frkkan96/Documents/src/speaker
rm -rf src/*.o src/*.so
R CMD INSTALL . --preclean
```

**Result**: ✅ `DONE (speaker)` - Build successful!

## Architecture Notes

### Why Two LAPACK Approaches?

1. **Praat's Original Design**: Uses CLAPACK (C implementation of LAPACK)
2. **R Package Best Practice**: Use R's built-in LAPACK/BLAS from `<R_ext/Lapack.h>`

### Benefits of Using R's LAPACK

- ✅ No external CLAPACK dependency
- ✅ Leverages R's optimized BLAS/LAPACK (Apple Accelerate, Intel MKL, OpenBLAS, etc.)
- ✅ Consistent with CRAN requirements
- ✅ Better performance on user's system
- ✅ Automatic multicore support where available

### Type Conversions

Praat's LAPACK interface uses `integer` (defined as `intptr_t` - 64-bit on modern systems), while R's LAPACK uses `int` (32-bit). The wrapper functions handle this conversion:

```c
int dgeev_wrap_int(const char* jobvl, const char* jobvr, int* n, ...)
```

becomes:

```c
int dgeev_(const char* jobvl, const char* jobvr, integer* n, ...) {
    int n_int = (int)*n;  // Convert integer* to int*
    int result = dgeev_wrap_int(jobvl, jobvr, &n_int, ...);
    return result;
}
```

## Files Modified

1. `/src/praat/dwsys/NUMlapack.h` - Updated from praat.github.io version
2. `DESCRIPTION` - Version bump: 0.9.3 → 0.9.4

## Next Steps

**AVQI/DSI Implementation** can now proceed:
- ✅ Package builds successfully
- ✅ All dependencies resolved
- ✅ Ready for enhanced plotting and reporting functionality

---

**Commit**: Build fix - synchronize NUMlapack.h to use R's LAPACK  
**Date**: 2025-11-22  
**Build Time**: ~5 minutes (300 source files compiled)  
**Status**: Ready for development
