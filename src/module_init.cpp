// module_init.cpp
// Rcpp Module initialization hook (pladdrr 2.0)
// Module boot functions are registered in RcppExports.cpp CallEntries

#include <Rcpp.h>

// [[Rcpp::init]]
void register_module_entries(DllInfo* dll) {
    // Module boot functions are now registered directly in CallEntries
    // This function is a no-op but kept for the init hook mechanism
    (void)dll;  // Suppress unused parameter warning
}
