test_that("Matrix R6 class basic operations work", {
  # Create a simple matrix
  mat <- Matrix(numberOfRows = 5, numberOfColumns = 3)
  
  expect_s3_class(mat, "Matrix")
  
  # Check dimensions
  expect_equal(mat$get_ny(), 5)
  expect_equal(mat$get_nx(), 3)
  
  # Set and get values
  mat$set_value(row = 2, col = 2, value = 42.0)
  expect_equal(mat$get_value(row = 2, col = 2), 42.0)
  
  # Check initial values are 0
  expect_equal(mat$get_value(row = 1, col = 1), 0.0)
})

test_that("Matrix R6 class full parameter creation works", {
  mat <- Matrix(
    xmin = 0.0, xmax = 1.0, nx = 10, dx = 0.1, x1 = 0.05,
    ymin = 0.0, ymax = 2.0, ny = 20, dy = 0.1, y1 = 0.05
  )
  
  expect_s3_class(mat, "Matrix")
  
  # Check dimensions
  expect_equal(mat$get_nx(), 10)
  expect_equal(mat$get_ny(), 20)
  expect_equal(mat$get_xmin(), 0.0)
  expect_equal(mat$get_xmax(), 1.0)
})

test_that("Matrix export works", {
  mat <- Matrix(numberOfRows = 3, numberOfColumns = 3)

  mat$set_value(row = 1, col = 1, value = 1)
  mat$set_value(row = 3, col = 2, value = 5)

  exported <- mat$as_matrix()
  expect_true(is.matrix(exported))
  expect_equal(dim(exported), c(3, 3))
  expect_equal(exported[1, 1], 1)
  expect_equal(exported[3, 2], 5)
})

test_that("Matrix R6 class error handling works", {
  mat <- Matrix(numberOfRows = 3, numberOfColumns = 3)
  
  # Out of bounds access
  expect_error(mat$get_value(row = 10, col = 1))
  expect_error(mat$get_value(row = 1, col = 10))
  
  # Invalid initialization
  expect_error(Matrix())  # No parameters
  expect_error(Matrix(numberOfRows = 3))  # Missing numberOfColumns
})

test_that("Matrix R6 class sum and mean work", {
  mat <- Matrix(numberOfRows = 2, numberOfColumns = 2)
  
  # Set known values
  mat$set_value(row = 1, col = 1, value = 1.0)
  mat$set_value(row = 1, col = 2, value = 2.0)
  mat$set_value(row = 2, col = 1, value = 3.0)
  mat$set_value(row = 2, col = 2, value = 4.0)
  
  # Check sum and mean
  total_sum <- mat$get_sum()
  expect_equal(total_sum, 10.0)
  
  mean_val <- mat$get_mean()
  expect_equal(mean_val, 2.5)
})
