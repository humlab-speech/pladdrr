# tests/testthat/test-matrix-wrapper-gaps.R
# Coverage gap-fill for R/matrix-wrapper.R (was ~67%): geometry getters,
# value access, and statistics.

mat_fixture <- function() {
  Matrix(numberOfRows = 3, numberOfColumns = 4)
}

test_that("Matrix geometry getters", {
  m <- mat_fixture()
  expect_identical(m$get_nx(), 4L)
  expect_identical(m$get_ny(), 3L)
  expect_identical(m$get_number_of_columns(), 4L)
  expect_identical(m$get_number_of_rows(), 3L)
  expect_gt(m$get_dx(), 0)
  expect_gt(m$get_dy(), 0)
  expect_lte(m$get_xmin(), m$get_xmax())
  expect_lte(m$get_ymin(), m$get_ymax())
  expect_type(m$get_x1(), "double")
  expect_type(m$get_y1(), "double")
})

test_that("Matrix value access", {
  m <- mat_fixture()
  m$set_value(1, 1, 3.5)
  expect_equal(m$get_value(1, 1), 3.5)
  # get_value_at_xy needs the x/y domain; x1 is the first x
  v <- m$get_value_at_xy(m$get_x1(), m$get_y1())
  expect_type(v, "double")
})

test_that("Matrix statistics", {
  m <- mat_fixture()
  expect_type(m$get_sum(), "double")
  expect_type(m$get_mean(), "double")
  expect_type(m$get_minimum(), "double")
})
