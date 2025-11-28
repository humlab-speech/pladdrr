# GSL 2.8 Integration Plan
**Date**: 2025-11-28  
**Package Version**: 1.0.3 → 1.0.4  
**Status**: Ready for Implementation

## Executive Summary

The speaker package currently uses stub implementations for GSL (GNU Scientific Library) functions. GSL 2.8 is already present in `src/gsl-2.8/` and can be fully integrated to replace all stubs, providing real implementations for:

1. Special functions (Bessel, Beta, Gamma, Error functions, etc.)
2. Cumulative Distribution Functions (CDFs)
3. Polynomial solvers

## Current Status

### Stub Files to Replace
- `src/gsl_stubs.cpp` - 74 lines of stub implementations
- Partial functionality in `src/roots_stubs.cpp` - polynomial root finding
- Minimal impact in `src/svd_stubs.cpp` - SVD is separate (LAPACK-based)

### GSL 2.8 Availability
✅ **Confirmed present**: `src/gsl-2.8/` contains full GSL 2.8 source code with:
- `specfunc/` - Special functions (Bessel, Beta, Gamma, Erf, Hypergeometric, Psi, Sinc)
- `cdf/` - Cumulative Distribution Functions (F-dist, Log-normal, Gaussian, Beta, Chi-squared, t-dist)
- `poly/` - Polynomial solvers (quadratic, cubic)

### Functions Currently Stubbed

#### Special Functions (24 functions)
```cpp
// Bessel functions
gsl_sf_bessel_In_e, gsl_sf_bessel_Kn_e
gsl_sf_bessel_I0, gsl_sf_bessel_K0
gsl_sf_bessel_I1, gsl_sf_bessel_K1

// Beta functions
gsl_sf_beta_inc_e, gsl_sf_beta_e, gsl_sf_beta
gsl_sf_lnbeta_e, gsl_sf_lnbeta

// Gamma functions  
gsl_sf_gamma_inc_P_e, gsl_sf_gamma_inc_Q_e
gsl_sf_lngamma_e, gsl_sf_lngamma_complex_e
gsl_sf_gamma, gsl_sf_lngamma

// Error functions
gsl_sf_erfc_e, gsl_sf_erfc
gsl_sf_erf, gsl_sf_erf_e

// Hypergeometric
gsl_sf_hyperg_2F1, gsl_sf_hyperg_2F1_e

// Psi (digamma) functions
gsl_sf_psi_n, gsl_sf_psi, gsl_sf_psi_1

// Sinc
gsl_sf_sinc_e, gsl_sf_sinc
```

#### CDF Functions (28 functions)
```cpp
// F-distribution
gsl_cdf_fdist_Q, gsl_cdf_fdist_Qinv

// Log-normal
gsl_cdf_lognormal_P, gsl_cdf_lognormal_Q
gsl_cdf_lognormal_Pinv, gsl_cdf_lognormal_Qinv

// Gaussian
gsl_cdf_gaussian_P, gsl_cdf_gaussian_Q
gsl_cdf_gaussian_Pinv, gsl_cdf_gaussian_Qinv

// Beta
gsl_cdf_beta_P, gsl_cdf_beta_Q
gsl_cdf_beta_Pinv, gsl_cdf_beta_Qinv

// Chi-squared
gsl_cdf_chisq_P, gsl_cdf_chisq_Q
gsl_cdf_chisq_Pinv, gsl_cdf_chisq_Qinv

// t-distribution
gsl_cdf_tdist_P, gsl_cdf_tdist_Q
gsl_cdf_tdist_Pinv, gsl_cdf_tdist_Qinv

// Unit Gaussian
gsl_cdf_ugaussian_P, gsl_cdf_ugaussian_Q
gsl_cdf_ugaussian_Pinv, gsl_cdf_ugaussian_Qinv
```

#### Polynomial Solvers (2 functions)
```cpp
gsl_poly_solve_quadratic  // Used by NUMspecfunc.cpp
gsl_poly_solve_cubic
```

## Used By

### Praat Source Files Using GSL
1. **melder/NUMspecfunc.cpp** - Statistical functions, probability distributions
   - Beta functions, Gamma functions, Error functions
   - F-distribution, Log-normal, Chi-squared, t-distribution CDFs
   - Used by statistical analysis throughout Praat

2. **melder/NUMmath.cpp** - Polynomial solvers
   - `gsl_poly_solve_quadratic` for quadratic equations

3. **LPC/Sound_and_LPC.cpp** - Linear Predictive Coding (indirectly)
   - Uses NUMspecfunc statistical functions

4. **fon/VoiceAnalysis.cpp** - Voice quality metrics (indirectly)
   - Statistical calculations via NUMspecfunc

## Implementation Plan

### Phase 1: Build GSL 2.8 Library ✅
**Status**: GSL 2.8 source already present in `src/gsl-2.8/`

**Actions**:
1. Build libgsl.a from source in `src/gsl-2.8/`
2. Add to `PKG_LIBS` in Makevars
3. Add include path to `PKG_CPPFLAGS`

### Phase 2: Remove Stub Implementations
**Target files**:
- `src/gsl_stubs.cpp` - DELETE entirely
- Update `src/Makevars` to remove `gsl_stubs.cpp` from `WRAPPER_SRC`

### Phase 3: Update Polynomial Root Finding
**Target**: `src/roots_stubs.cpp`
- Keep the stub structure (Roots class is intentionally disabled)
- But now `gsl_poly_solve_quadratic` will work via real GSL

### Phase 4: Testing & Validation
1. Build package with GSL linked
2. Test LPC functionality (uses polynomial solvers)
3. Test statistical functions in NUMspecfunc
4. Verify no regressions

## Build Configuration Changes

### Makevars Updates

```makefile
# Add GSL include path
PKG_CPPFLAGS += -Igsl-2.8

# Build GSL library components needed
GSL_SRC = gsl-2.8/specfunc/*.c gsl-2.8/cdf/*.c gsl-2.8/poly/*.c \
          gsl-2.8/err/*.c gsl-2.8/sys/*.c

# Link against GSL
PKG_LIBS += -L. -lgsl $(LAPACK_LIBS) $(BLAS_LIBS) -pthread
```

### Dependencies
- **No new external dependencies** - GSL 2.8 source is self-contained
- Requires standard C math library (-lm, already linked)
- Compatible with existing LAPACK/BLAS linkage

## Benefits

### Functional Benefits
1. ✅ **Real polynomial solving** for LPC and other analyses
2. ✅ **Accurate statistical functions** for voice quality metrics
3. ✅ **Complete special function support** for advanced analyses
4. ✅ **Proper probability distributions** for statistical tests

### Code Quality
1. ✅ Remove ~150 lines of stub code
2. ✅ More maintainable (use well-tested GSL code)
3. ✅ Better error handling (GSL's error system)
4. ✅ Numerical accuracy guaranteed by GSL

### Performance
- Negligible impact (functions are rarely called)
- GSL is highly optimized C code
- No R ↔ C overhead (called directly by Praat C++ code)

## Risks & Mitigations

### Risk 1: Build Complexity
**Risk**: Building GSL from source may fail on some platforms  
**Mitigation**: GSL 2.8 is mature, builds on all POSIX systems  
**Fallback**: Keep selective compilation in configure script

### Risk 2: Library Size
**Risk**: GSL adds to package size  
**Mitigation**: Only compile needed modules (specfunc, cdf, poly)  
**Estimate**: ~500KB compiled code

### Risk 3: Licensing
**Risk**: GSL is GPL (not LGPL)  
**Mitigation**: Package is already GPL-3, fully compatible

## Timeline

- **Phase 1**: Build GSL library - 1 hour
- **Phase 2**: Remove stubs, update Makevars - 30 minutes
- **Phase 3**: Testing - 1 hour
- **Phase 4**: Documentation update - 30 minutes

**Total**: ~3 hours

## Success Criteria

1. ✅ Package builds without errors on macOS, Linux, Windows
2. ✅ All tests pass
3. ✅ LPC analysis produces correct results
4. ✅ Statistical functions return accurate values
5. ✅ No increase in build warnings
6. ✅ Package size increase < 1MB

## Next Steps After GSL Integration

Once GSL is integrated:
1. Assess if any LPC functionality can be enhanced
2. Remove related "not implemented" warnings
3. Update documentation to reflect full GSL support
4. Consider additional statistical analyses enabled by GSL

## Notes

- SVD functionality remains stubbed (requires LAPACK, separate concern)
- Roots class remains intentionally disabled (Praat design decision)
- This integration is **low-risk, high-reward**
- Enables more accurate scientific computing throughout the package
