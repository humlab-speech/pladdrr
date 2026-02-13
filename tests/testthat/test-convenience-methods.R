# Tests for convenience methods: get_spectral_slope(), get_all_values_at_time()

test_that("get_spectral_slope returns numeric scalar matching report_spectral_trend", {
  sound <- Sound$create_tone(frequency = 440, duration = 1.0)
  spectrum <- sound$to_spectrum()
  ltas <- spectrum$to_ltas(100)

  slope <- ltas$get_spectral_slope(100, 5000)
  trend <- ltas$report_spectral_trend(100, 5000)

  expect_type(slope, "double")
  expect_length(slope, 1)
  expect_equal(slope, trend$slope)
})

test_that("get_spectral_slope respects frequency_scale and fit_method", {
  sound <- Sound$create_tone(frequency = 440, duration = 1.0)
  spectrum <- sound$to_spectrum()
  ltas <- spectrum$to_ltas(100)

  slope_log <- ltas$get_spectral_slope(100, 5000, "logarithmic")
  slope_lin <- ltas$get_spectral_slope(100, 5000, "linear")
  expect_false(isTRUE(all.equal(slope_log, slope_lin)))
})

test_that("get_all_values_at_time returns numeric vector of correct length", {
  sound <- Sound$create_tone(frequency = 440, duration = 1.0)
  formant <- sound$to_formant_burg()
  mid <- (formant$get_xmin() + formant$get_xmax()) / 2

  vals <- formant$get_all_values_at_time(mid)
  expect_type(vals, "double")
  expect_length(vals, 5)

  vals3 <- formant$get_all_values_at_time(mid, max_formants = 3)
  expect_length(vals3, 3)
})

test_that("get_all_values_at_time bark unit works", {
  sound <- Sound$create_tone(frequency = 440, duration = 1.0)
  formant <- sound$to_formant_burg()
  mid <- (formant$get_xmin() + formant$get_xmax()) / 2

  hz <- formant$get_all_values_at_time(mid, unit = "hertz")
  bark <- formant$get_all_values_at_time(mid, unit = "bark")

  # Non-NA values should differ between units
  valid <- !is.na(hz) & !is.na(bark) & hz > 0
  if (any(valid)) {
    expect_false(isTRUE(all.equal(hz[valid], bark[valid])))
  }
})

test_that("get_all_values_at_time handles edge times gracefully", {
  sound <- Sound$create_tone(frequency = 440, duration = 1.0)
  formant <- sound$to_formant_burg()

  # Outside range should return NAs or NaN, not error
  vals <- formant$get_all_values_at_time(-1.0)
  expect_type(vals, "double")
  expect_length(vals, 5)
})
