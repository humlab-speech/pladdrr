# Test suite for Ltas$report_spectral_trend()
# Tests the spectral trend analysis functionality including slope, intercept,
# R-squared, and fitted values

test_that("report_spectral_trend returns correct structure", {
  sound <- Sound$create_tone(frequency = 440, duration = 1.0)
  spectrum <- sound$to_spectrum()
  ltas <- spectrum$to_ltas(100)
  
  result <- ltas$report_spectral_trend(100, 5000, "logarithmic", "least squares")
  
  expect_type(result, "list")
  expect_s3_class(result, "ltas_spectral_trend")
  expect_named(result, c("slope", "intercept", "frequency_scale", "fit_method", 
                         "fmin", "fmax", "slope_units", "r_squared", 
                         "residual_std_error", "n_points", "fitted_values"))
  
  expect_type(result$slope, "double")
  expect_type(result$intercept, "double")
  expect_type(result$r_squared, "double")
  expect_type(result$residual_std_error, "double")
  expect_type(result$n_points, "integer")
  
  expect_s3_class(result$fitted_values, "data.frame")
  expect_named(result$fitted_values, c("frequency", "power_db_observed", 
                                        "power_db_fitted", "residual"))
})

test_that("logarithmic scale produces correct slope units", {
  sound <- Sound$create_tone(frequency = 440, duration = 1.0)
  spectrum <- sound$to_spectrum()
  ltas <- spectrum$to_ltas(100)
  
  result <- ltas$report_spectral_trend(100, 5000, "logarithmic", "least squares")
  
  expect_identical(result$slope_units, "dB/decade")
  expect_identical(result$frequency_scale, "logarithmic")
})

test_that("linear scale produces correct slope units", {
  sound <- Sound$create_tone(frequency = 440, duration = 1.0)
  spectrum <- sound$to_spectrum()
  ltas <- spectrum$to_ltas(100)
  
  result <- ltas$report_spectral_trend(100, 5000, "linear", "least squares")
  
  expect_identical(result$slope_units, "dB/Hz")
  expect_identical(result$frequency_scale, "linear")
})

test_that("R-squared is between 0 and 1", {
  sound <- Sound$create_tone(frequency = 440, duration = 1.0)
  spectrum <- sound$to_spectrum()
  ltas <- spectrum$to_ltas(100)
  
  result <- ltas$report_spectral_trend(100, 5000, "logarithmic", "least squares")
  
  expect_gte(result$r_squared, 0.0)
  expect_lte(result$r_squared, 1.0)
})

test_that("fitted_values has correct number of rows", {
  sound <- Sound$create_tone(frequency = 440, duration = 1.0)
  spectrum <- sound$to_spectrum()
  ltas <- spectrum$to_ltas(100)
  
  result <- ltas$report_spectral_trend(100, 5000, "logarithmic", "least squares")
  
  expect_equal(nrow(result$fitted_values), result$n_points, tolerance = sqrt(.Machine$double.eps))
  expect_gt(result$n_points, 1)  # Should have at least 2 points
})

test_that("residuals sum to approximately zero", {
  sound <- Sound$create_tone(frequency = 440, duration = 1.0)
  spectrum <- sound$to_spectrum()
  ltas <- spectrum$to_ltas(100)
  
  result <- ltas$report_spectral_trend(100, 5000, "logarithmic", "least squares")
  
  # Sum of residuals should be near zero (within numerical precision)
  expect_lt(abs(sum(result$fitted_values$residual)), 1e-10)
})

test_that("logarithmic scale matches lm() workaround approximately", {
  sound <- Sound$create_tone(frequency = 440, duration = 1.0)
  spectrum <- sound$to_spectrum()
  ltas <- spectrum$to_ltas(100)
  
  # pladdrr method
  result <- ltas$report_spectral_trend(100, 5000, "logarithmic", "least squares")
  
  # Workaround method
  ltas_df <- ltas$as_data_frame()
  ltas_sub <- ltas_df[ltas_df$frequency >= 100 & ltas_df$frequency <= 5000, ]
  lm_result <- lm(power_db ~ log10(frequency), data = ltas_sub)
  
  # Should be close but not exact (Praat uses specific bin selection)
  expect_equal(unname(result$slope), unname(coef(lm_result)[2]), tolerance = 0.1)
  expect_equal(unname(result$intercept), unname(coef(lm_result)[1]), tolerance = 1.0)
  
  # Check R² matches
  lm_r_squared <- summary(lm_result)$r.squared
  expect_equal(result$r_squared, lm_r_squared, tolerance = 0.01)
})

test_that("robust method runs without error", {
  sound <- Sound$create_tone(frequency = 440, duration = 1.0)
  spectrum <- sound$to_spectrum()
  ltas <- spectrum$to_ltas(100)
  
  result <- ltas$report_spectral_trend(100, 5000, "logarithmic", "robust")
  
  expect_type(result$slope, "double")
  expect_type(result$intercept, "double")
  expect_identical(result$fit_method, "robust")
})

test_that("default parameters work correctly", {
  sound <- Sound$create_tone(frequency = 440, duration = 1.0)
  spectrum <- sound$to_spectrum()
  ltas <- spectrum$to_ltas(100)
  
  # Should use logarithmic scale and least squares by default
  result <- ltas$report_spectral_trend()
  
  expect_identical(result$frequency_scale, "logarithmic")
  expect_identical(result$fit_method, "least squares")
  expect_equal(result$fmin, 100, tolerance = sqrt(.Machine$double.eps))
  expect_equal(result$fmax, 5000, tolerance = sqrt(.Machine$double.eps))
})

test_that("print method works without error", {
  sound <- Sound$create_tone(frequency = 440, duration = 1.0)
  spectrum <- sound$to_spectrum()
  ltas <- spectrum$to_ltas(100)
  
  result <- ltas$report_spectral_trend(100, 5000, "logarithmic", "least squares")
  
  # Should print without error
  expect_output(print(result), "Spectral Trend Analysis")
  expect_output(print(result), "Slope:")
  expect_output(print(result), "R\\^2:")
})

test_that("fitted values can be used for plotting", {
  sound <- Sound$create_tone(frequency = 440, duration = 1.0)
  spectrum <- sound$to_spectrum()
  ltas <- spectrum$to_ltas(100)
  
  result <- ltas$report_spectral_trend(100, 5000, "logarithmic", "least squares")
  
  # Check fitted_values structure allows plotting
  expect_true(all(result$fitted_values$frequency >= 100))
  expect_true(all(result$fitted_values$frequency <= 5000))
  expect_equal(
    result$fitted_values$residual,
    result$fitted_values$power_db_observed - result$fitted_values$power_db_fitted
  , tolerance = sqrt(.Machine$double.eps))
})

test_that("fmin=0 and fmax=0 use full frequency range", {
  sound <- Sound$create_tone(frequency = 440, duration = 1.0)
  spectrum <- sound$to_spectrum()
  ltas <- spectrum$to_ltas(100)
  
  result <- ltas$report_spectral_trend(0, 0, "logarithmic", "least squares")
  
  # Should use full LTAS range
  expect_equal(result$fmin, ltas$get_lowest_frequency(), tolerance = sqrt(.Machine$double.eps))
  expect_equal(result$fmax, ltas$get_highest_frequency(), tolerance = sqrt(.Machine$double.eps))
})
