# Regression tests for PowerCepstrum quefrency methods.
# get_quefrency_of_peak() and get_value_at_quefrency() previously passed
# integer interpolation/unit codes to Rcpp module methods that expect
# std::string, causing an internal Rcpp::as<std::string> throw on every call.

make_test_cepstrum <- function() {
  sound <- Sound$create_tone(duration = 0.5, frequency = 200, sampling_rate = 44100)
  spectrum <- sound$to_spectrum()
  spectrum$to_power_cepstrum()
}

test_that("get_quefrency_of_peak works for all interpolation methods", {
  cepstrum <- make_test_cepstrum()

  for (interp in c("parabolic", "none", "cubic")) {
    q <- cepstrum$get_quefrency_of_peak(interpolation = interp, qmin = 0.003, qmax = 0.04)
    expect_type(q, "double")
    expect_false(is.na(q))
    expect_true(q >= 0.003 && q <= 0.04)
  }
})

test_that("get_value_at_quefrency works for all interpolation/unit combinations", {
  cepstrum <- make_test_cepstrum()
  q <- cepstrum$get_quefrency_of_peak()

  for (interp in c("linear", "cubic")) {
    for (unit in c("dB", "linear")) {
      val <- cepstrum$get_value_at_quefrency(q, interpolation = interp, unit = unit)
      expect_type(val, "double")
      expect_false(is.na(val))
    }
  }
})
