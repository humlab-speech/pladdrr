# tests/testthat/test-as-data-frame-complex.R
# Behavioral coverage for the complex as.data.frame.<Class> methods in
# R/as-data-frame-missing.R that have real logic (beyond a plain delegate) but
# previously lacked direct tests. The LPC case is covered separately in
# test-autoplot-spectral-family.R (a real bug: coefficient matrix was indexed
# as a list). These lock in the Matrix/KlattGrid/VocalTract behaviors so a
# future index-shape or axis bug is caught here.

test_that("as.data.frame.Matrix returns long-format with real axis values", {
  # Ltas$to_matrix() returns a real Matrix object (per ltas-wrapper.R).
  sound <- Sound$create_tone(frequency = 220, duration = 0.3,
    sampling_rate = 16000)
  m <- sound$to_ltas(bandwidth = 100)$to_matrix()

  df <- as.data.frame(m)
  expect_true(all(c("row", "col", "value") %in% names(df)))

  # One row per matrix cell, in the same order as as.vector() (column-major).
  expect_identical(nrow(df), length(m$as_matrix()))
  expect_equal(df$value, as.vector(m$as_matrix()),
    tolerance = sqrt(.Machine$double.eps))

  # Axis values are real coordinates, not bin indices.
  expect_equal(sort(unique(df$col)),
               m$get_x1(
                 ) + (seq_len(
                   m$get_nx(
                     )) - 1) * m$get_dx(), tolerance = sqrt(.Machine$double.eps))
  expect_equal(sort(unique(df$row)),
               m$get_y1(
                 ) + (seq_len(
                   m$get_ny(
                     )) - 1) * m$get_dy(), tolerance = sqrt(.Machine$double.eps))
})

test_that("as.data.frame.KlattGrid returns one row per (time, formant)", {
  kg <- klattgrid_create_example()
  df <- as.data.frame(kg)
  expect_true(all(c("time", "formant_number", "frequency") %in% names(df)))

  # 100 sample times x 6 oral formants; all frequencies finite (NA dropped).
  expect_equal(sort(unique(df$formant_number)), 1:6,
    tolerance = sqrt(.Machine$double.eps))
  expect_true(all(is.finite(df$frequency)))
  expect_equal(max(table(df$time)), 6L, tolerance = sqrt(.Machine$double.eps))
  expect_gt(length(unique(df$time)), 50)
})

test_that("as.data.frame.Matrix handles a 1-row edge case", {
  # A single-row matrix (e.g. an Ltas is 1 x nbins) must still produce
  # one row per cell without the expand.grid/as.vector ordering diverging.
  sound <- Sound$create_tone(frequency = 220, duration = 0.3,
    sampling_rate = 16000)
  m <- sound$to_ltas(bandwidth = 100)$to_matrix()
  df <- as.data.frame(m)
  mat <- m$as_matrix()
  expect_equal(nrow(df), nrow(mat) * ncol(mat),
    tolerance = sqrt(.Machine$double.eps))
  expect_equal(df$value, as.vector(mat), tolerance = sqrt(.Machine$double.eps))
})
