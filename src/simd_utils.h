#ifndef SIMD_UTILS_H
#define SIMD_UTILS_H

#include <Rcpp.h>

// Check if SIMD should be used
inline bool use_simd() {
#ifdef HAVE_XSIMD
    // Check global option
    Rcpp::Environment base_env = Rcpp::Environment::namespace_env("base");
    Rcpp::Function getOption = base_env["getOption"];
    
    SEXP opt = getOption("speaker.use_simd", Rcpp::LogicalVector::create(true));
    
    if (Rcpp::is<Rcpp::LogicalVector>(opt)) {
        Rcpp::LogicalVector lv = Rcpp::as<Rcpp::LogicalVector>(opt);
        if (lv.size() > 0 && !Rcpp::LogicalVector::is_na(lv[0])) {
            return lv[0];
        }
    }
    return true;  // Default to using SIMD if available
#else
    return false;  // SIMD not available
#endif
}

#endif // SIMD_UTILS_H
