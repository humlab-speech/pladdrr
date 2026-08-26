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
    expect_gte(q, 0.003); expect_lte(q, 0.04)
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

test_that("get_value_at_quefrency dB and linear units agree and are plausible", {
  # z[1][.] stores linear power; dB = 10*log10(power). A cepstral peak is
  # typically tens of dB, not the ~2e8 (or Inf) produced when the unit
  # branches were swapped. Query an exact grid point (q1) so interpolation
  # is a no-op and dB/linear must match bit-exactly; away from grid points
  # they legitimately diverge because dB and linear interpolate in
  # different domains (Praat's own convention, see todBs()).
  cepstrum <- make_test_cepstrum()
  q1 <- cepstrum$get_q1()

  db_value <- cepstrum$get_value_at_quefrency(q1, interpolation = "linear", unit = "dB")
  linear_value <- cepstrum$get_value_at_quefrency(q1, interpolation = "linear", unit = "linear")

  expect_gt(db_value, -300); expect_lt(db_value, 300)
  expect_gte(linear_value, 0)
  expect_equal(db_value, 10 * log10(linear_value + 1e-30), tolerance = 1e-9)
})
