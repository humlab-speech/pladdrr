# Test SIMD window functions
# Validates numerical accuracy of windowing operations

test_that("SIMD Hamming window has correct properties", {
  skip_if_not_installed("pladdrr")
  library(pladdrr)
  
  if (exists(".apply_hamming_window_simd", where = asNamespace("pladdrr"), inherits = FALSE)) {
    n <- 256
    data <- rep(1.0, n)  # Unit signal
    
    windowed <- pladdrr:::.apply_hamming_window_simd(data)
    
    # Window should have correct length
    expect_length(windowed, n)
    
    # Endpoints should be close to zero (Hamming window property)
    expect_lt(windowed[1], 0.1)
    expect_lt(windowed[n], 0.1)
    
    # Maximum should be near center
    max_idx <- which.max(windowed)
    expect_true(abs(max_idx - n/2) < n/10)
    
    # All values should be positive
    expect_true(all(windowed >= 0))
  } else {
    skip("SIMD Hamming window function not exported")
  }
})

test_that("SIMD Hanning window has correct properties", {
  skip_if_not_installed("pladdrr")
  library(pladdrr)
  
  if (exists(".apply_hanning_window_simd", where = asNamespace("pladdrr"), inherits = FALSE)) {
    n <- 256
    data <- rep(1.0, n)
    
    windowed <- pladdrr:::.apply_hanning_window_simd(data)
    
    # Window should have correct length
    expect_length(windowed, n)
    
    # Hanning window endpoints should be exactly zero
    expect_equal(windowed[1], 0.0, tolerance = 1e-10)
    expect_equal(windowed[n], 0.0, tolerance = 1e-10)
    
    # Maximum at center
    max_idx <- which.max(windowed)
    expect_true(abs(max_idx - n/2) < 5)
    
    # Symmetric
    expect_equal(windowed[1:(n/2)], rev(windowed[(n/2+1):n]), tolerance = 1e-10)
  } else {
    skip("SIMD Hanning window function not exported")
  }
})

test_that("SIMD Gaussian window has correct shape", {
  skip_if_not_installed("pladdrr")
  library(pladdrr)
  
  if (exists(".apply_gaussian_window_simd", where = asNamespace("pladdrr"), inherits = FALSE)) {
    n <- 256
    data <- rep(1.0, n)
    alpha <- 2.5
    
    windowed <- pladdrr:::.apply_gaussian_window_simd(data, alpha)
    
    # Gaussian window properties
    expect_length(windowed, n)
    
    # Maximum at center
    max_idx <- which.max(windowed)
    expect_equal(max_idx, n/2, tolerance = 2)
    
    # Symmetric
    expect_equal(windowed[1:(n/2)], rev(windowed[(n/2+1):n]), tolerance = 1e-10)
    
    # All positive
    expect_true(all(windowed > 0))
  } else {
    skip("SIMD Gaussian window function not exported")
  }
})

test_that("SIMD Blackman window has correct properties", {
  skip_if_not_installed("pladdrr")
  library(pladdrr)
  
  if (exists(".apply_blackman_window_simd", where = asNamespace("pladdrr"), inherits = FALSE)) {
    n <- 256
    data <- rep(1.0, n)
    
    windowed <- pladdrr:::.apply_blackman_window_simd(data)
    
    # Blackman window endpoints near zero
    expect_lt(windowed[1], 0.01)
    expect_lt(windowed[n], 0.01)
    
    # Maximum near center
    max_idx <- which.max(windowed)
    expect_true(abs(max_idx - n/2) < 10)
    
    # Positive values
    expect_true(all(windowed >= 0))
  } else {
    skip("SIMD Blackman window function not exported")
  }
})

test_that("SIMD window functions preserve DC component correctly", {
  skip_if_not_installed("pladdrr")
  library(pladdrr)
  
  if (exists(".apply_hamming_window_simd", where = asNamespace("pladdrr"), inherits = FALSE)) {
    n <- 512
    amplitude <- 2.5
    data <- rep(amplitude, n)
    
    windowed <- pladdrr:::.apply_hamming_window_simd(data)
    
    # Windowed signal should have values scaled by window
    expect_true(max(windowed) <= amplitude)
    expect_true(min(windowed) >= 0)
    
    # Sum should be less than original (due to tapering)
    expect_true(sum(windowed) < sum(data))
  } else {
    skip("SIMD Hamming window function not exported")
  }
})

test_that("SIMD window functions handle different sizes", {
  skip_if_not_installed("pladdrr")
  library(pladdrr)
  
  if (exists(".apply_hamming_window_simd", where = asNamespace("pladdrr"), inherits = FALSE)) {
    # Small window
    data_small <- rep(1.0, 32)
    windowed_small <- pladdrr:::.apply_hamming_window_simd(data_small)
    expect_length(windowed_small, 32)
    
    # Medium window
    data_medium <- rep(1.0, 512)
    windowed_medium <- pladdrr:::.apply_hamming_window_simd(data_medium)
    expect_length(windowed_medium, 512)
    
    # Large window
    data_large <- rep(1.0, 4096)
    windowed_large <- pladdrr:::.apply_hamming_window_simd(data_large)
    expect_length(windowed_large, 4096)
    
    # Odd size
    data_odd <- rep(1.0, 511)
    windowed_odd <- pladdrr:::.apply_hamming_window_simd(data_odd)
    expect_length(windowed_odd, 511)
  } else {
    skip("SIMD Hamming window function not exported")
  }
})

test_that("SIMD window functions handle real signals", {
  skip_if_not_installed("pladdrr")
  library(pladdrr)
  
  if (exists(".apply_hamming_window_simd", where = asNamespace("pladdrr"), inherits = FALSE)) {
    # Sine wave
    t <- seq(0, 1, length.out = 512)
    signal <- sin(2 * pi * 50 * t)
    
    windowed <- pladdrr:::.apply_hamming_window_simd(signal)
    
    # Should taper signal at edges
    expect_true(abs(windowed[1]) < abs(signal[256]))
    expect_true(abs(windowed[512]) < abs(signal[256]))
    
    # Should preserve general shape
    expect_length(windowed, length(signal))
  } else {
    skip("SIMD Hamming window function not exported")
  }
})
