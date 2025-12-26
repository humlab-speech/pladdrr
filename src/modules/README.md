# Rcpp Modules (pladdrr 2.0)

This directory contains Rcpp Module implementations for pladdrr 2.0 architecture.

## After Running `Rcpp::compileAttributes()`

The auto-generated `src/RcppExports.cpp` needs manual patches for module boot function registration.

Add the following after the includes (around line 9):

```cpp
// Forward declaration for Rcpp Module boot functions (pladdrr 2.0)
extern "C" SEXP _rcpp_module_boot_pitch_module();
```

And add to the `CallEntries` array before `{NULL, NULL, 0}`:

```cpp
    // Rcpp Module boot functions (pladdrr 2.0)
    {"_rcpp_module_boot_pitch_module", (DL_FUNC) &_rcpp_module_boot_pitch_module, 0},
```

## Module Files

- `pitch_module.cpp` - RPitch class exposing Pitch analysis functionality
- `module_common.h` - Shared utilities and validation macros

## Traits (src/traits/)

- `praat_object_traits.h` - Base traits for Praat objects
- `sampled_object_traits.h` - Traits for time-domain sampled objects
