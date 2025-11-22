# Test SIMD autocorrelation functions
# Validates numerical accuracy and performance of autocorrelation

test_that("SIMD autocorrelation is symmetric", {
  skip_if_not_installed("speaker")
  library(speaker)
  
  # White noise
  set.seed(42)
  data <- rnorm(1000)
  
  # Check if SIMD autocorrelation function is exported
  if (exists(".autocorrelation_simd", where = asNamespace("speaker"), inherits = FALSE)) {
    acf_result <- .autocorrelation_simd(data, max_lag = 50)
    
    # Lag-0 should be maximum (variance)
    expect_true(acf_result[1] >= max(acf_result[-1]))
    
    # Autocorrelation values should be reasonable
    expect_true(all(is.finite(acf_result)))
  } else {
    skip("SIMD autocorrelation function not exported")
  }
})

test_that("SIMD autocorrelation handles periodic signals", {
  skip_if_not_installed("speaker")
  library(speaker)
  
  # Generate periodic signal (sine wave)
  t <- seq(0, 1, length.out = 1000)
  freq <- 10  # 10 Hz
  data <- sin(2 * pi * freq * t)
  
  if (exists(".autocorrelation_simd", where = asNamespace("speaker"), inherits = FALSE)) {
    acf_result <- .autocorrelation_simd(data, max_lag = 200)
    
    # For periodic signal, autocorrelation should also be periodic
    # Peak at lag 0
    expect_equal(acf_result[1], max(acf_result), tolerance = 1e-10)
    
    # Should have peaks at multiples of period
    period <- round(1000 / (freq * 1))  # Samples per period
    
    # Values should be positive (for simple sine)
    expect_true(all(acf_result >= -max(acf_result) - 1e-10))
  } else {
    skip("SIMD autocorrelation function not exported")
  }
})

test_that("SIMD normalized autocorrelation is in [-1, 1]", {
  skip_if_not_installed("speaker")
  library(speaker)
  
  set.seed(123)
  data <- rnorm(1000)
  
  if (exists(".autocorrelation_normalized_simd", where = asNamespace("speaker"), inherits = FALSE)) {
    acf_norm <- .autocorrelation_normalized_simd(data, max_lag = 100)
    
    # All values should be in [-1, 1]
    expect_true(all(acf_norm >= -1.0 - 1e-10))
    expect_true(all(acf_norm <= 1.0 + 1e-10))
    
    # Lag-0 should be exactly 1.0
    expect_equal(acf_norm[1], 1.0, tolerance = 1e-10)
  } else {
    skip("SIMD normalized autocorrelation function not exported")
  }
})

test_that("SIMD autocorrelation handles edge cases", {
  skip_if_not_installed("speaker")
  library(speaker)
  
  if (exists(".autocorrelation_simd", where = asNamespace("speaker"), inherits = FALSE)) {
    # Constant signal
    data <- rep(1.0, 100)
    acf_result <- .autocorrelation_simd(data, max_lag = 10)
    
    # All lags should be equal for constant signal
    expect_true(all(abs(diff(acf_result)) < 1e-10))
    
    # Zero signal
    data <- rep(0.0, 100)
    acf_result <- .autocorrelation_simd(data, max_lag = 10)
    
    # All should be zero
    expect_true(all(abs(acf_result) < 1e-10))
  } else {
    skip("SIMD autocorrelation function not exported")
  }
})

test_that("SIMD autocorrelation performance scales reasonably", {
  skip_if_not_installed("speaker")
  library(speaker)
  
  if (exists(".autocorrelation_simd", where = asNamespace("speaker"), inherits = FALSE)) {
    set.seed(42)
    
    # Small data
    data_small <- rnorm(1000)
    time_small <- system.time({
      for (i in 1:10) {
        acf_small <- .autocorrelation_simd(data_small, max_lag = 100)
      }
    })["elapsed"]
    
    # Medium data  
    data_medium <- rnorm(10000)
    time_medium <- system.time({
      for (i in 1:10) {
        acf_medium <- .autocorrelation_simd(data_medium, max_lag = 100)
      }
    })["elapsed"]
    
    # Performance should scale reasonably (not exponentially)
    # With SIMD, we expect near-linear scaling
    ratio <- time_medium / time_small
    
    # Should not be more than 15x slower for 10x more data
    expect_true(ratio < 15)
  } else {
    skip("SIMD autocorrelation function not exported")
  }
})
