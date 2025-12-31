// module_init.cpp
// Rcpp Module initialization hook (pladdrr 2.0)
// Enables dynamic symbol lookup for Rcpp Module boot functions

#include <Rcpp.h>
#include <R_ext/Rdynload.h>

// [[Rcpp::init]]
void register_module_entries(DllInfo* dll) {
    // Enable dynamic symbol lookup so Module() can find boot functions
    // This is called AFTER RcppExports registration, so it augments rather than replaces
    R_useDynamicSymbols(dll, TRUE);
}
