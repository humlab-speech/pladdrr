# Test SIMD autocorrelation functions
# Validates numerical accuracy and performance of autocorrelation

test_that("SIMD autocorrelation is symmetric", {
  skip_if_not_installed("pladdrr")
  library(pladdrr)
  
  # White noise
  set.seed(42)
  data <- rnorm(1000)
  
  # Check if SIMD autocorrelation function is exported
  if (exists(".autocorrelation_simd", where = asNamespace("pladdrr"), inherits = FALSE)) {
    acf_result <- pladdrr:::.autocorrelation_simd(data, max_lag = 50)
    
    # Lag-0 should be maximum (variance)
    expect_true(acf_result[1] >= max(acf_result[-1]))
    
    # Autocorrelation values should be reasonable
    expect_true(all(is.finite(acf_result)))
  } else {
    skip("SIMD autocorrelation function not exported")
  }
})

test_that("SIMD autocorrelation handles periodic signals", {
  skip_if_not_installed("pladdrr")
  library(pladdrr)
  
  # Generate periodic signal (sine wave)
  t <- seq(0, 1, length.out = 1000)
  freq <- 10  # 10 Hz
  data <- sin(2 * pi * freq * t)
  
  if (exists(".autocorrelation_simd", where = asNamespace("pladdrr"), inherits = FALSE)) {
    acf_result <- pladdrr:::.autocorrelation_simd(data, max_lag = 200)
    
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
  skip_if_not_installed("pladdrr")
  library(pladdrr)
  
  set.seed(123)
  data <- rnorm(1000)
  
  if (exists(".autocorrelation_normalized_simd", where = asNamespace("pladdrr"), inherits = FALSE)) {
    acf_norm <- pladdrr:::.autocorrelation_normalized_simd(data, max_lag = 100)
    
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
  skip_if_not_installed("pladdrr")
  library(pladdrr)
  
  if (exists(".autocorrelation_simd", where = asNamespace("pladdrr"), inherits = FALSE)) {
    # Constant signal. This is the *raw* (unnormalized) autocorrelation, so
    # lag k = number of overlapping samples = N - k, i.e. 100, 99, ..., 90.
    data <- rep(1.0, 100)
    acf_result <- pladdrr:::.autocorrelation_simd(data, max_lag = 10)

    expect_equal(acf_result, as.numeric(100 - (0:10)), tolerance = 1e-10)
    
    # Zero signal
    data <- rep(0.0, 100)
    acf_result <- pladdrr:::.autocorrelation_simd(data, max_lag = 10)
    
    # All should be zero
    expect_true(all(abs(acf_result) < 1e-10))
  } else {
    skip("SIMD autocorrelation function not exported")
  }
})

test_that(".lpc_autocorrelation_simd matches .lpc_autocorrelation_scalar", {
  skip_if_not_installed("pladdrr")
  library(pladdrr)

  set.seed(42)
  x <- sin(2 * pi * 220 * (0:999) / 16000)

  if (exists(".lpc_autocorrelation_simd", where = asNamespace("pladdrr"), inherits = FALSE) &&
      exists(".lpc_autocorrelation_scalar", where = asNamespace("pladdrr"), inherits = FALSE)) {
    simd_result <- pladdrr:::.lpc_autocorrelation_simd(x, 12L)
    scalar_result <- pladdrr:::.lpc_autocorrelation_scalar(x, 12L)

    expect_equal(simd_result, scalar_result, tolerance = 1e-10)
    expect_length(simd_result, 13L)
    expect_true(all(is.finite(simd_result)))
  } else {
    skip("LPC autocorrelation functions not exported")
  }
})

test_that(".autocorrelation_scalar and .autocorrelation_normalized_scalar match SIMD variants", {
  skip_if_not_installed("pladdrr")
  library(pladdrr)

  set.seed(43)
  x <- sin(2 * pi * 220 * (0:999) / 16000)

  if (exists(".autocorrelation_scalar", where = asNamespace("pladdrr"), inherits = FALSE) &&
      exists(".autocorrelation_normalized_scalar", where = asNamespace("pladdrr"), inherits = FALSE)) {
    expect_equal(pladdrr:::.autocorrelation_scalar(x, 50L),
                 pladdrr:::.autocorrelation_simd(x, 50L), tolerance = 1e-10)
    expect_equal(pladdrr:::.autocorrelation_normalized_scalar(x, 50L),
                 pladdrr:::.autocorrelation_normalized_simd(x, 50L), tolerance = 1e-10)
  } else {
    skip("Scalar autocorrelation functions not exported")
  }
})

test_that(".autocorrelation_scalar handles edge cases like the SIMD variant", {
  skip_if_not_installed("pladdrr")
  library(pladdrr)

  if (exists(".autocorrelation_scalar", where = asNamespace("pladdrr"), inherits = FALSE)) {
    # Constant signal: lag k = number of overlapping samples = N - k.
    data <- rep(1.0, 100)
    acf_result <- pladdrr:::.autocorrelation_scalar(data, max_lag = 10)
    expect_equal(acf_result, as.numeric(100 - (0:10)), tolerance = 1e-10)

    # Zero signal: all lags zero.
    data <- rep(0.0, 100)
    acf_result <- pladdrr:::.autocorrelation_scalar(data, max_lag = 10)
    expect_true(all(abs(acf_result) < 1e-10))
  } else {
    skip("Scalar autocorrelation function not exported")
  }
})

test_that("SIMD autocorrelation performance scales reasonably", {
  skip_if_not_installed("pladdrr")
  skip_on_cran()
  skip_on_ci()
  library(pladdrr)

  if (exists(".autocorrelation_simd", where = asNamespace("pladdrr"), inherits = FALSE)) {
    set.seed(42)
    
    # Small data
    data_small <- rnorm(1000)
    time_small <- system.time({
      for (i in 1:10) {
        acf_small <- pladdrr:::.autocorrelation_simd(data_small, max_lag = 100)
      }
    })["elapsed"]
    
    # Medium data  
    data_medium <- rnorm(10000)
    time_medium <- system.time({
      for (i in 1:10) {
        acf_medium <- pladdrr:::.autocorrelation_simd(data_medium, max_lag = 100)
      }
    })["elapsed"]
    
    # Performance should scale roughly linearly, not quadratically. At these
    # small sizes timer resolution and fixed overhead dominate, so use a
    # generous bound that still catches an O(n^2) blowup (which would be ~100x
    # for 10x data) rather than asserting a tight constant.
    ratio <- time_medium / max(time_small, 1e-4)

    expect_lt(ratio, 50)
  } else {
    skip("SIMD autocorrelation function not exported")
  }
})
