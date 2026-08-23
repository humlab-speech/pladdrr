# test-polygon-r6.R
# Coverage gap-fill for src/modules/polygon_module.cpp (Task 30)
#
# Polygon is an R6-style S3 class wrapping the polygon_module Rcpp module.
# It previously had no dedicated test file (only incidental use inside
# autoplot tests).
#
# Note: randomize()/optimize_salesperson() are deliberately NOT exercised
# here — they run Praat's randomized traveling-salesman optimizer, which
# crashed (Trace/BPT trap) under gcov instrumentation during a full-suite
# coverage run, so the deterministic surface is covered instead.

test_that("Polygon constructs from x/y vectors and reports basics", {
  poly <- Polygon(x = c(0, 1, 1, 0), y = c(0, 0, 1, 1))

  expect_s3_class(poly, "Polygon")
  expect_true(poly$is_valid())
  expect_equal(poly$n_points(), 4)
  expect_equal(poly$get_x(1), 0, tolerance = 1e-9)
  expect_equal(poly$get_y(2), 0, tolerance = 1e-9)
  expect_equal(poly$get_all_x(), c(0, 1, 1, 0), tolerance = 1e-9)
  expect_equal(poly$get_all_y(), c(0, 0, 1, 1), tolerance = 1e-9)
})

test_that("Polygon perimeter works", {
  poly <- Polygon(x = c(0, 1, 1, 0), y = c(0, 0, 1, 1))

  expect_type(poly$get_perimeter(), "double")
  expect_gte(poly$get_perimeter(), 4.0)
})

test_that("Polygon export methods work", {
  poly <- Polygon(x = c(0, 1, 1, 0), y = c(0, 0, 1, 1))

  df <- poly$as_data_frame()
  expect_s3_class(df, "data.frame")

  mat <- poly$as_matrix()
  expect_true(is.matrix(mat))
  expect_equal(nrow(mat), 4)

  tmp <- tempfile(fileext = ".Polygon")
  on.exit(unlink(tmp), add = TRUE)
  poly$save(tmp)
  expect_true(file.exists(tmp))

  expect_output(print(poly), "Polygon")
})
