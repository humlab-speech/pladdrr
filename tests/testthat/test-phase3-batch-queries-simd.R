# Phase 3 Task 3.2: Batch Query SIMD Tests
#
# Tests for SIMD-optimized batch query operations
# Target: Statistics calculations and interval processing

library(testthat)
library(pladdrr)

# ============================================================================
# Test 1: SIMD mean calculation
# ============================================================================

test_that("SIMD mean matches scalar implementation", {
  # Generate test data
  values <- rnorm(1000, mean = 100, sd = 15)

  # R built-in
  r_mean <- mean(values)

  # SIMD implementation
  simd_mean <- calculate_mean_simd_bridge(values)

  expect_equal(simd_mean, r_mean, tolerance = 1e-10)
})

test_that("SIMD mean handles edge cases", {
  # Empty vector
  expect_true(is.na(calculate_mean_simd_bridge(numeric(0))))

  # Single value
  expect_equal(calculate_mean_simd_bridge(c(42)), 42)

  # Two values
  expect_equal(calculate_mean_simd_bridge(c(10, 20)), 15)

  # Large values
  large_values <- rep(1e10, 100)
  expect_equal(calculate_mean_simd_bridge(large_values), 1e10)
})

# ============================================================================
# Test 2: SIMD standard deviation
# ============================================================================

test_that("SIMD stdev matches R implementation", {
  values <- rnorm(1000, mean = 50, sd = 10)

  # R built-in
  r_stdev <- sd(values)

  # SIMD implementation
  simd_stdev <- calculate_stdev_simd_bridge(values)

  expect_equal(simd_stdev, r_stdev, tolerance = 1e-10)
})

test_that("SIMD stdev with pre-computed mean", {
  values <- rnorm(1000, mean = 75, sd = 20)
  mean_val <- mean(values)

  # SIMD with pre-computed mean
  simd_stdev <- calculate_stdev_simd_bridge(values, mean_val)

  # R implementation
  r_stdev <- sd(values)

  expect_equal(simd_stdev, r_stdev, tolerance = 1e-10)
})

test_that("SIMD stdev handles edge cases", {
  # Single value
  expect_equal(calculate_stdev_simd_bridge(c(42)), 0)

  # Two identical values
  expect_equal(calculate_stdev_simd_bridge(c(10, 10)), 0)

  # Two different values
  expect_equal(calculate_stdev_simd_bridge(c(10, 20)), sd(c(10, 20)))
})

# ============================================================================
# Test 3: SIMD min/max
# ============================================================================

test_that("SIMD min/max matches R implementation", {
  values <- rnorm(1000, mean = 0, sd = 5)

  result <- calculate_min_max_simd_bridge(values)

  expect_equal(result$min, min(values), tolerance = 1e-10)
  expect_equal(result$max, max(values), tolerance = 1e-10)
})

test_that("SIMD min/max handles negative and positive values", {
  values <- c(-100, -50, 0, 50, 100)

  result <- calculate_min_max_simd_bridge(values)

  expect_equal(result$min, -100)
  expect_equal(result$max, 100)
})

test_that("SIMD min/max handles edge cases", {
  # Empty vector
  result <- calculate_min_max_simd_bridge(numeric(0))
  expect_true(is.na(result$min))
  expect_true(is.na(result$max))

  # Single value
  result <- calculate_min_max_simd_bridge(c(42))
  expect_equal(result$min, 42)
  expect_equal(result$max, 42)
})

# ============================================================================
# Test 4: SIMD quantile
# ============================================================================

test_that("SIMD quantile matches R implementation", {
  values <- rnorm(1000, mean = 100, sd = 15)

  # Test various quantiles
  for (q in c(0.25, 0.5, 0.75)) {
    simd_q <- calculate_quantile_simd_bridge(values, q)
    r_q <- quantile(values, q, type = 7)  # type 7 is default

    # Allow some tolerance due to interpolation differences
    expect_equal(simd_q, as.numeric(r_q), tolerance = 0.1)
  }
})

test_that("SIMD quantile handles edge cases", {
  # Empty vector
  expect_true(is.na(calculate_quantile_simd_bridge(numeric(0), 0.5)))

  # Single value
  expect_equal(calculate_quantile_simd_bridge(c(42), 0.5), 42)

  # Edge quantiles
  values <- 1:100
  expect_equal(calculate_quantile_simd_bridge(values, 0.0), 1, tolerance = 0.5)
  expect_equal(calculate_quantile_simd_bridge(values, 1.0), 100, tolerance = 0.5)
})

# ============================================================================
# Test 5: SIMD batch statistics
# ============================================================================

test_that("SIMD batch statistics computes all metrics correctly", {
  values <- rnorm(1000, mean = 50, sd = 10)

  result <- calculate_batch_statistics_simd_bridge(values)

  expect_equal(result$mean, mean(values), tolerance = 1e-10)
  expect_equal(result$stdev, sd(values), tolerance = 1e-10)
  expect_equal(result$min, min(values), tolerance = 1e-10)
  expect_equal(result$max, max(values), tolerance = 1e-10)
})

test_that("SIMD batch statistics handles edge cases", {
  # Empty vector
  result <- calculate_batch_statistics_simd_bridge(numeric(0))
  expect_true(is.na(result$mean))
  expect_true(is.na(result$stdev))
  expect_true(is.na(result$min))
  expect_true(is.na(result$max))

  # Single value
  result <- calculate_batch_statistics_simd_bridge(c(42))
  expect_equal(result$mean, 42)
  expect_equal(result$stdev, 0)
  expect_equal(result$min, 42)
  expect_equal(result$max, 42)
})

# ============================================================================
# Test 6: Interval statistics
# ============================================================================

test_that("SIMD interval statistics processes multiple intervals", {
  # Create test intervals
  intervals <- list(
    rnorm(100, mean = 50, sd = 5),
    rnorm(200, mean = 60, sd = 10),
    rnorm(150, mean = 70, sd = 15)
  )

  # Test "all" metrics
  result <- calculate_interval_statistics_simd_bridge(intervals, "all")

  expect_equal(nrow(result), 3)
  expect_equal(ncol(result), 4)
  expect_equal(colnames(result), c("mean", "stdev", "min", "max"))

  # Verify first interval (result cells carry dimnames; compare values only)
  expect_equal(as.numeric(result[1, "mean"]), mean(intervals[[1]]), tolerance = 1e-10)
  expect_equal(as.numeric(result[1, "stdev"]), sd(intervals[[1]]), tolerance = 1e-10)
})

test_that("SIMD interval statistics handles single metrics", {
  intervals <- list(
    rnorm(100, mean = 50, sd = 5),
    rnorm(100, mean = 60, sd = 10)
  )

  # Test individual metrics
  mean_result <- calculate_interval_statistics_simd_bridge(intervals, "mean")
  expect_length(mean_result, 2)
  expect_equal(mean_result[1], mean(intervals[[1]]), tolerance = 1e-10)

  stdev_result <- calculate_interval_statistics_simd_bridge(intervals, "stdev")
  expect_length(stdev_result, 2)
  expect_equal(stdev_result[1], sd(intervals[[1]]), tolerance = 1e-10)
})

# ============================================================================
# Test 7: Interval quantiles
# ============================================================================

test_that("SIMD interval quantiles processes multiple quantiles", {
  intervals <- list(
    rnorm(100, mean = 50, sd = 5),
    rnorm(100, mean = 60, sd = 10)
  )

  quantiles <- c(0.25, 0.5, 0.75)

  result <- calculate_interval_quantiles_simd_bridge(intervals, quantiles)

  expect_equal(nrow(result), 2)
  expect_equal(ncol(result), 3)
  expect_equal(colnames(result), c("q0.25", "q0.5", "q0.75"))

  # Verify approximate match to R quantile
  for (i in 1:2) {
    for (j in 1:3) {
      r_q <- quantile(intervals[[i]], quantiles[j], type = 7)
      expect_equal(as.numeric(result[i, j]), as.numeric(r_q), tolerance = 0.1)
    }
  }
})

# ============================================================================
# Test 8: SIMD toggle verification
# ============================================================================

test_that("SIMD batch-queries status is reported as a logical", {
  # should_use_simd_for_batch_queries() reflects a compiled global. Unlike the
  # TextGrid path (set_textgrid_simd_enabled_bridge), the batch-queries global
  # has no R-level setter, so we can only assert the getter's contract, not a
  # runtime on/off toggle. Expose a bridge setter if runtime control is needed.
  simd_status <- should_use_simd_for_batch_queries_bridge()
  expect_type(simd_status, "logical")
  expect_length(simd_status, 1)
})

# ============================================================================
# Test 9: Large dataset performance
# ============================================================================

test_that("SIMD handles large datasets correctly", {
  # Large dataset
  large_values <- rnorm(10000, mean = 100, sd = 20)

  result <- calculate_batch_statistics_simd_bridge(large_values)

  expect_equal(result$mean, mean(large_values), tolerance = 1e-9)
  expect_equal(result$stdev, sd(large_values), tolerance = 1e-9)
  expect_equal(result$min, min(large_values), tolerance = 1e-10)
  expect_equal(result$max, max(large_values), tolerance = 1e-10)
})

# ============================================================================
# Test 10: Numerical stability
# ============================================================================

test_that("SIMD maintains numerical stability", {
  # Values close together (potential precision issues)
  close_values <- seq(1e10, 1e10 + 1, length.out = 1000)

  result <- calculate_batch_statistics_simd_bridge(close_values)

  expect_equal(result$mean, mean(close_values), tolerance = 1e-6)
  expect_gt(result$stdev, 0)  # Should detect variation
  expect_equal(result$min, min(close_values), tolerance = 1e-6)
  expect_equal(result$max, max(close_values), tolerance = 1e-6)
})
