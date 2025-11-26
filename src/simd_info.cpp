// simd_info.cpp - SIMD capability reporting
// [[Rcpp::interfaces(r, cpp)]]

#include <Rcpp.h>
#include "simd_utils.h"

#ifdef HAVE_XSIMD
#include <xsimd/xsimd.hpp>
namespace simd = xsimd;
#endif

//' Get SIMD capabilities (internal)
//' @keywords internal
// [[Rcpp::export(.simd_info)]]
Rcpp::List simd_info() {
#ifdef HAVE_XSIMD
  return Rcpp::List::create(
    Rcpp::Named("enabled") = use_simd(),
    Rcpp::Named("available") = true,
    Rcpp::Named("architecture") = get_simd_arch(),
    Rcpp::Named("batch_size_double") = (int)simd::batch<double>::size,
    Rcpp::Named("batch_size_float") = (int)simd::batch<float>::size,
    Rcpp::Named("version") = "xsimd"
  );
#else
  return Rcpp::List::create(
    Rcpp::Named("enabled") = false,
    Rcpp::Named("available") = false,
    Rcpp::Named("architecture") = "None",
    Rcpp::Named("batch_size_double") = 1,
    Rcpp::Named("batch_size_float") = 1,
    Rcpp::Named("version") = "Scalar fallback"
  );
#endif
}
