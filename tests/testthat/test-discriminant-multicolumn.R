# Regression test for the GSVD iwork fix (NUMlapack.h dggsvd_): LAPACK writes
# N integers, but the shim used to hand it a single int. With one predictor
# (N = 1) the overflow was invisible; with two or more it corrupted the stack
# and Discriminant construction failed. All older Discriminant tests use
# ncol = 1, so this is the only test that exercises N > 1.

test_that("Discriminant supports two predictor columns", {
  set.seed(20261111)
  group <- rep(c("a", "i"), each = 20)
  data <- cbind(
    f1 = c(rnorm(20, 500, 40), rnorm(20, 700, 40)),
    f2 = c(rnorm(20, 800, 60), rnorm(20, 1200, 60))
  )

  disc <- discriminant_from_matrix(data, group)

  expect_identical(disc$get_dimension(), 2L)
  expect_lte(disc$get_number_of_functions(), 1L)

  eigenvalues <- disc$get_eigenvalues()
  expect_true(all(is.finite(eigenvalues)))
  expect_true(all(diff(eigenvalues) <= 0))
  expect_equal(sum(disc$get_fraction_variance(1, 0)), 1, tolerance = 1e-9)

  centroids <- disc$get_group_centroids()
  expect_equal(dim(centroids), c(2L, 2L))
  expect_equal(rownames(centroids), c("a", "i"))
  expect_equal(
    unname(centroids["a", ]),
    unname(colMeans(data[group == "a", ])),
    tolerance = 1e-9
  )
  expect_equal(
    unname(centroids["i", ]),
    unname(colMeans(data[group == "i", ])),
    tolerance = 1e-9
  )
})

test_that("Discriminant supports three predictor columns and three groups", {
  set.seed(20261112)
  group <- rep(c("u", "o", "a"), each = 20)
  data <- cbind(
    f1 = c(rnorm(20, 400, 30), rnorm(20, 500, 30), rnorm(20, 600, 30)),
    f2 = c(rnorm(20, 800, 50), rnorm(20, 1200, 50), rnorm(20, 1600, 50)),
    f3 = c(rnorm(20, 2400, 80), rnorm(20, 2500, 80), rnorm(20, 2600, 80))
  )

  disc <- discriminant_from_matrix(data, group)

  expect_identical(disc$get_dimension(), 3L)
  expect_lte(disc$get_number_of_functions(), 2L)
  expect_true(all(is.finite(disc$get_eigenvalues())))
  expect_equal(sum(disc$get_fraction_variance(1, 0)), 1, tolerance = 1e-9)

  centroids <- disc$get_group_centroids()
  expect_equal(dim(centroids), c(3L, 3L))
  expect_setequal(rownames(centroids), c("u", "o", "a"))
  for (label in c("u", "o", "a")) {
    expect_equal(
      unname(centroids[label, ]),
      unname(colMeans(data[group == label, ])),
      tolerance = 1e-9
    )
  }
})
