# Test SIMD matrix operations
# Validates numerical accuracy of SIMD-accelerated matrix functions

test_that("SIMD matrix sum matches scalar result", {
  skip_if_not_installed("speaker")
  library(speaker)
  
  # Small matrix
  mat <- matrix(runif(100 * 100), nrow = 100, ncol = 100)
  mat_obj <- praat_matrix_from_matrix(mat)
  simd_sum <- mat_obj$get_sum()
  scalar_sum <- sum(mat)
  
  expect_equal(simd_sum, scalar_sum, tolerance = 1e-10)
  
  # Medium matrix
  mat <- matrix(runif(500 * 500), nrow = 500, ncol = 500)
  mat_obj <- praat_matrix_from_matrix(mat)
  simd_sum <- mat_obj$get_sum()
  scalar_sum <- sum(mat)
  
  expect_equal(simd_sum, scalar_sum, tolerance = 1e-10)
  
  # Large matrix
  mat <- matrix(runif(1000 * 1000), nrow = 1000, ncol = 1000)
  mat_obj <- praat_matrix_from_matrix(mat)
  simd_sum <- mat_obj$get_sum()
  scalar_sum <- sum(mat)
  
  expect_equal(simd_sum, scalar_sum, tolerance = 1e-10)
})

test_that("SIMD matrix mean matches scalar result", {
  skip_if_not_installed("speaker")
  library(speaker)
  
  mat <- matrix(runif(500 * 500), nrow = 500, ncol = 500)
  mat_obj <- praat_matrix_from_matrix(mat)
  simd_mean <- mat_obj$get_mean()
  scalar_mean <- mean(mat)
  
  expect_equal(simd_mean, scalar_mean, tolerance = 1e-10)
})

test_that("SIMD matrix min matches scalar result", {
  skip_if_not_installed("speaker")
  library(speaker)
  
  mat <- matrix(runif(500 * 500, min = -100, max = 100), nrow = 500, ncol = 500)
  mat_obj <- praat_matrix_from_matrix(mat)
  simd_min <- mat_obj$get_minimum()
  scalar_min <- min(mat)
  
  expect_equal(simd_min, scalar_min, tolerance = 1e-10)
})

test_that("SIMD matrix max matches scalar result", {
  skip_if_not_installed("speaker")
  library(speaker)
  
  mat <- matrix(runif(500 * 500, min = -100, max = 100), nrow = 500, ncol = 500)
  mat_obj <- praat_matrix_from_matrix(mat)
  simd_max <- mat_obj$get_maximum()
  scalar_max <- max(mat)
  
  expect_equal(simd_max, scalar_max, tolerance = 1e-10)
})

test_that("SIMD matrix operations handle edge cases", {
  skip_if_not_installed("speaker")
  library(speaker)
  
  # Single element
  mat <- matrix(42.0, nrow = 1, ncol = 1)
  mat_obj <- praat_matrix_from_matrix(mat)
  expect_equal(mat_obj$get_sum(), 42.0)
  expect_equal(mat_obj$get_mean(), 42.0)
  expect_equal(mat_obj$get_minimum(), 42.0)
  expect_equal(mat_obj$get_maximum(), 42.0)
  
  # Odd dimensions
  mat <- matrix(runif(99 * 97), nrow = 99, ncol = 97)
  mat_obj <- praat_matrix_from_matrix(mat)
  expect_equal(mat_obj$get_sum(), sum(mat), tolerance = 1e-10)
  expect_equal(mat_obj$get_mean(), mean(mat), tolerance = 1e-10)
  
  # With negative values
  mat <- matrix(rnorm(100 * 100), nrow = 100, ncol = 100)
  mat_obj <- praat_matrix_from_matrix(mat)
  expect_equal(mat_obj$get_sum(), sum(mat), tolerance = 1e-10)
  expect_equal(mat_obj$get_mean(), mean(mat), tolerance = 1e-10)
  expect_equal(mat_obj$get_minimum(), min(mat), tolerance = 1e-10)
  expect_equal(mat_obj$get_maximum(), max(mat), tolerance = 1e-10)
})

test_that("SIMD matrix operations handle special values", {
  skip_if_not_installed("speaker")
  library(speaker)
  
  # Matrix with zeros
  mat <- matrix(0, nrow = 100, ncol = 100)
  mat_obj <- praat_matrix_from_matrix(mat)
  expect_equal(mat_obj$get_sum(), 0)
  expect_equal(mat_obj$get_mean(), 0)
  expect_equal(mat_obj$get_minimum(), 0)
  expect_equal(mat_obj$get_maximum(), 0)
  
  # Matrix with identical values
  mat <- matrix(3.14159, nrow = 100, ncol = 100)
  mat_obj <- praat_matrix_from_matrix(mat)
  expect_equal(mat_obj$get_sum(), 3.14159 * 10000, tolerance = 1e-8)
  expect_equal(mat_obj$get_mean(), 3.14159, tolerance = 1e-10)
  expect_equal(mat_obj$get_minimum(), 3.14159, tolerance = 1e-10)
  expect_equal(mat_obj$get_maximum(), 3.14159, tolerance = 1e-10)
})
