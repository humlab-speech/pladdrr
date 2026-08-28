# tests/testthat/test-ltas-wrapper-gaps.R
# Coverage gap-fill for R/ltas-wrapper.R (was ~63%): the bin/frequency
# geometry, value queries, and batch accessors.

ltas_fixture <- function() {
  Sound$create_tone(frequency = 220, duration = 0.3, sampling_rate = 16000)$to_ltas()
}

test_that("Ltas bin/frequency geometry", {
  l <- ltas_fixture()
  expect_gte(l$get_number_of_bins(), 1L)
  expect_gt(l$get_bin_width(), 0)
  expect_lte(l$get_lowest_frequency(), l$get_highest_frequency())
  fr <- l$get_frequency_range()
  expect_type(fr, "double")
  b <- l$get_bin_from_frequency(l$get_lowest_frequency() + 10)
  f <- l$get_frequency_from_bin(1)
  expect_gte(f, l$get_lowest_frequency())
})

test_that("Ltas value queries", {
  l <- ltas_fixture()
  v <- l$get_value_at_frequency(l$get_lowest_frequency() + 10)
  expect_type(v, "double")
  b <- l$get_value_in_bin(1)
  expect_type(b, "double")
  mn <- l$get_minimum()
  expect_type(mn, "double")
  mx <- l$get_maximum()
  expect_type(mx, "double")
  m <- l$get_mean()
  expect_type(m, "double")
  sd <- l$get_standard_deviation()
  expect_gte(sd, 0)
  fmax <- l$get_frequency_of_maximum()
  expect_type(fmax, "double")
})

test_that("Ltas batch accessors", {
  l <- ltas_fixture()
  fmin <- l$get_lowest_frequency() + 10
  fmax <- fmin + 50
  peaks <- l$get_peaks_batch(c(fmin, fmax), c(fmin + 20, fmax + 20))
  expect_true(is.list(peaks))
  mins <- l$get_minima_batch(c(fmin, fmax), c(fmin + 20, fmax + 20))
  expect_true(is.list(mins))
  vals <- l$get_values_at_frequencies(c(fmin, fmax))
  expect_type(vals, "double")
  means <- l$get_means_batch(c(fmin, fmax), c(fmin + 20, fmax + 20))
  expect_type(means, "double")
})
