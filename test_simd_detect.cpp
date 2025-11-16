// Test if RcppXsimd is being detected
#include <Rcpp.h>

#ifdef RCPP_XSIMD_AVAILABLE
#include <xsimd/xsimd.hpp>
#endif

// [[Rcpp::export]]
bool check_simd_available() {
#ifdef RCPP_XSIMD_AVAILABLE
  return true;
#else
  return false;
#endif
}

// [[Rcpp::export]]
std::string get_simd_info() {
#ifdef RCPP_XSIMD_AVAILABLE
  using batch_type = xsimd::batch<double>;
  std::string info = "SIMD enabled - ";
  info += "SIMD width: " + std::to_string(batch_type::size) + " doubles";
  return info;
#else
  return "SIMD NOT available - using scalar fallback";
#endif
}

/*** R
check_simd_available()
get_simd_info()
*/
