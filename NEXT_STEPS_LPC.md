# LPC Implementation Plan

**Priority**: HIGH - Critical for v1.0.0  
**Estimated Effort**: 1-2 days  
**Status**: Planning

## Overview

Linear Predictive Coding (LPC) is a critical spectral analysis method needed for:
- All-pole modeling of the vocal tract
- Formant extraction (alternative to Burg method)
- Spectral envelope estimation
- Speech coding and synthesis

## Praat Source Files Available

The complete LPC implementation is available in `src/praat.github.io/LPC/`:
- `LPC.h` / `LPC.cpp` - Core LPC object
- `LPC_def.h` - Object definition
- `Sound_and_LPC.h` - Sound → LPC conversion
- `LPC_and_Formant.cpp` - LPC → Formant conversion
- `LPC_and_Polynomial.cpp` - Coefficient analysis
- `LPC_enums.h` - Enumeration types

## Implementation Steps

### Step 1: Replace Stub (src/lpc_stub.cpp)
Current file contains stubs that throw errors. Replace with:

```cpp
// lpc_stub.cpp → DELETE
// Create: src/lpc_wrappers.cpp

#include "praat_types.h"
#include <Rcpp.h>
#include "praat_xptr_utils.h"
#include "praat_error_handling.h"

// Praat LPC headers
#include "LPC/LPC.h"
#include "LPC/Sound_and_LPC.h"
#include "LPC/LPC_and_Formant.h"

// Wrapper implementations...
```

### Step 2: Compile LPC Source Files
Add to Makevars:
```make
# LPC sources
LPC_SOURCES = \
    LPC/LPC.cpp \
    LPC/LPC_and_Formant.cpp \
    LPC/LPC_and_Polynomial.cpp \
    ...
```

### Step 3: Implement C++ Wrappers (src/lpc_wrappers.cpp)

Key functions to wrap:
```cpp
// Creation from Sound
SEXP lpc_from_sound_burg(XPtr<structSound> sound, ...);
SEXP lpc_from_sound_autocorrelation(XPtr<structSound> sound, ...);
SEXP lpc_from_sound_covariance(XPtr<structSound> sound, ...);

// Queries
int lpc_get_number_of_frames(XPtr<structLPC> lpc);
int lpc_get_prediction_order(XPtr<structLPC> lpc);
double lpc_get_sampling_period(XPtr<structLPC> lpc);

// Coefficients
NumericVector lpc_get_coefficients_at_frame(XPtr<structLPC> lpc, int frame);
NumericMatrix lpc_get_all_coefficients(XPtr<structLPC> lpc);
double lpc_get_gain_at_frame(XPtr<structLPC> lpc, int frame);

// Transformations
SEXP lpc_to_formant(XPtr<structLPC> lpc, double margin);
SEXP lpc_to_spectrum(XPtr<structLPC> lpc, double time, ...);
SEXP lpc_to_polynomial(XPtr<structLPC> lpc, double time);

// Export
NumericMatrix lpc_as_matrix(XPtr<structLPC> lpc);
```

### Step 4: Create R6 Class (R/lpc-r6.R)

```r
LPC <- R6::R6Class("LPC",
  inherit = PraatObject,
  public = list(
    initialize = function(.xptr = NULL) {...},
    
    # Query methods
    get_number_of_frames = function() {...},
    get_prediction_order = function() {...},
    get_sampling_period = function() {...},
    
    # Coefficient access
    get_coefficients_at_frame = function(frame) {...},
    get_all_coefficients = function() {...},
    get_gain_at_frame = function(frame) {...},
    
    # Transformations
    to_formant = function(margin = 50) {...},
    to_spectrum = function(time, ...) {...},
    to_polynomial = function(time) {...},
    
    # Export
    as_matrix = function() {...},
    as_data_frame = function() {...},
    
    print = function() {...}
  )
)
```

### Step 5: Add to Sound Class (R/sound-r6-new.R)

Add transformation methods:
```r
# In Sound$public:
to_lpc_burg = function(prediction_order = 16, 
                       analysis_width = 0.025,
                       time_step = 0.005,
                       pre_emphasis_from = 50) {
  lpc_ptr <- .sound_to_lpc_burg(self$.xptr, prediction_order, 
                                 analysis_width, time_step, 
                                 pre_emphasis_from)
  LPC$new(.xptr = lpc_ptr)
},

to_lpc_autocorrelation = function(...) {...},
to_lpc_covariance = function(...) {...}
```

### Step 6: Tests (tests/testthat/test-lpc.R)

```r
test_that("LPC can be created from Sound", {
  sound <- Sound$new_from_file(test_wav)
  lpc <- sound$to_lpc_burg()
  expect_s3_class(lpc, "LPC")
})

test_that("LPC coefficients are accessible", {
  sound <- Sound$new_from_file(test_wav)
  lpc <- sound$to_lpc_burg(prediction_order = 16)
  expect_equal(lpc$get_prediction_order(), 16)
  coefs <- lpc$get_coefficients_at_frame(1)
  expect_equal(length(coefs), 16)
})

test_that("LPC can convert to Formant", {
  sound <- Sound$new_from_file(test_wav)
  lpc <- sound$to_lpc_burg()
  formant <- lpc$to_formant()
  expect_s3_class(formant, "Formant")
})
```

### Step 7: Documentation (man/LPC.Rd)

Complete Rd file documenting:
- LPC creation methods
- Coefficient access
- Transformations
- Integration with Sound and Formant

## Dependencies

LPC requires these Praat modules (check if already compiled):
- ✅ dwsys/ - Numerical algorithms
- ✅ fon/Sampled.cpp - Base class
- ⚠️ fon/Matrix.cpp - Matrix operations (check if compiled)
- ⚠️ LPC/*.cpp - LPC-specific code (NOT YET COMPILED)

## Build System Changes

Update `src/Makevars` to compile LPC sources:
1. Add LPC source files to SOURCES
2. Add LPC include path
3. Test compilation

## Testing Strategy

1. Unit tests for each LPC method
2. Integration with Sound
3. Integration with Formant
4. Compare results with Praat GUI
5. Memory leak testing

## Timeline

- **Day 1 Morning**: Set up build system, compile LPC sources
- **Day 1 Afternoon**: Implement C++ wrappers
- **Day 2 Morning**: Create R6 class, integrate with Sound
- **Day 2 Afternoon**: Tests, documentation, validation

## Success Criteria

- [ ] LPC objects can be created from Sound
- [ ] All LPC query methods work
- [ ] LPC → Formant conversion works
- [ ] LPC → Spectrum conversion works
- [ ] Tests pass
- [ ] Documentation complete
- [ ] No memory leaks

## Current Status

- ✅ LPC source code available
- ✅ Stub file identified
- ⏳ Implementation not started
- ⏳ Build system not updated

## Next Action

Start with build system: add LPC sources to Makevars and test compilation.
