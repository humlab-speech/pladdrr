# test-pca-r6.R - Tests for R/pca-wrapper.R (PCA object)
#
# Unlike Discriminant, PCA's C++ path (Module_PCA_from_matrix ->
# Matrix_to_PCA_byRows) is not affected by the multi-column
# TableOfReal_to_Discriminant defect documented for Discriminant; PCA is
# fundamentally a multi-column technique and works correctly with 2+ columns
# here (verified interactively before writing these assertions).

test_that("PCA constructs from a matrix and reports basic properties", {
  set.seed(1)
  data <- cbind(f1 = rnorm(20, 500, 50), f2 = rnorm(20, 1500, 100))
  pca <- pca_from_matrix(data)

  expect_s3_class(pca, "PCA")
  expect_s3_class(pca, "PraatObject")
  expect_true(pca$is_valid())
  expect_equal(pca$get_number_of_observations(), 20)
  expect_equal(pca$get_dimension(), 2)
  # dimension == 2 (two variables) -> at most 2 components
  expect_gte(pca$get_number_of_components(), 1)
  expect_lte(pca$get_number_of_components(), 2)
})

test_that("PCA eigen/variance/projection queries work", {
  set.seed(2)
  data <- cbind(
    f1 = rnorm(30, 500, 50),
    f2 = rnorm(30, 1500, 100),
    f3 = rnorm(30, 2500, 150)
  )
  pca <- pca_from_matrix(data)

  expect_equal(pca$get_number_of_components(), 3)
  expect_equal(pca$get_dimension(), 3)

  ev <- pca$get_eigenvalues()
  expect_type(ev, "double")
  expect_length(ev, 3)
  # eigenvalues are sorted descending
  expect_true(all(diff(ev) <= 0))
  expect_equal(pca$get_eigenvalue(1), ev[1])
  expect_equal(pca$get_eigenvalue(3), ev[3])

  expect_type(pca$get_fraction_variance(1, 1), "double")
  # get_variance_explained() is a documented alias for get_fraction_variance()
  expect_equal(pca$get_variance_explained(1, 1), pca$get_fraction_variance(1, 1))
  # fraction over the full range (default to = 0 -> all components) is 1
  expect_equal(pca$get_fraction_variance(1, 0), 1)
  expect_gte(pca$get_dimension_of_fraction(0.9), 1)
  expect_lte(pca$get_dimension_of_fraction(0.9), 3)

  eigvec1 <- pca$get_eigenvector(1)
  expect_type(eigvec1, "double")
  expect_length(eigvec1, 3)

  eigvecs <- pca$get_eigenvectors()
  expect_true(is.matrix(eigvecs))
  expect_equal(dim(eigvecs), c(3, 3))
  expect_equal(eigvecs[, 1], eigvec1)
  # get_loadings() is a documented alias for get_eigenvectors()
  expect_equal(pca$get_loadings(), eigvecs)

  centroid <- pca$get_centroid()
  expect_type(centroid, "double")
  expect_length(centroid, 3)
  expect_equal(unname(centroid), unname(colMeans(data)), tolerance = 1e-6)

  # out-of-range component indices error
  expect_error(pca$get_eigenvalue(0), "out of range")
  expect_error(pca$get_eigenvalue(100), "out of range")
  expect_error(pca$get_eigenvector(0), "out of range")
})

test_that("PCA project/transform, as_data_frame, get_info, save, labels", {
  set.seed(3)
  data <- cbind(f1 = rnorm(15, 500, 50), f2 = rnorm(15, 1500, 100))
  pca <- pca_from_matrix(data)

  proj_all <- pca$project(data)
  expect_true(is.matrix(proj_all))
  expect_equal(dim(proj_all), c(15, pca$get_number_of_components()))

  proj1 <- pca$project(data, num_dimensions = 1)
  expect_equal(dim(proj1), c(15, 1))

  # transform() is a documented alias for project()
  expect_equal(pca$transform(data), proj_all)

  # data.frame input is coerced to a matrix internally
  proj_df <- pca$project(as.data.frame(data))
  expect_equal(proj_df, proj_all)

  # mismatched column count errors (pca has dimension 2, matrix has 3 columns)
  expect_error(pca$project(matrix(1:6, nrow = 2)), "dimension mismatch")

  df <- pca$as_data_frame()
  expect_s3_class(df, "data.frame")
  expect_equal(nrow(df), pca$get_number_of_components())
  expect_named(df, c("component", "eigenvalue", "variance_fraction", "cumulative_variance"))
  expect_equal(df$eigenvalue, pca$get_eigenvalues())
  # cumulative_variance sums to 1 for the last component
  expect_equal(df$cumulative_variance[nrow(df)], 1)

  info <- pca$get_info()
  expect_type(info, "list")
  expect_equal(info$n_components, pca$get_number_of_components())
  expect_equal(info$dimension, pca$get_dimension())
  expect_equal(info$n_observations, 15)
  expect_equal(info$eigenvalues, pca$get_eigenvalues())
  expect_equal(info$centroid, pca$get_centroid())

  # `data` has no column names carried through to Matrix_to_PCA_byRows, so
  # labels (length == dimension, i.e. number of variables) are all NA
  labels <- pca$get_labels()
  expect_length(labels, pca$get_dimension())
  expect_true(all(is.na(labels)))

  # get_xptr() returns the raw external pointer
  expect_true(is(pca$get_xptr(), "externalptr"))

  # save() round-trips to a Praat text file and returns self invisibly
  tf <- tempfile(fileext = ".PCA")
  on.exit(unlink(tf), add = TRUE)
  ret <- pca$save(tf)
  expect_true(file.exists(tf))
  expect_identical(ret, pca)
  saved <- readLines(tf)
  expect_true(any(grepl('Object class = "PCA"', saved, fixed = TRUE)))

  # print() output
  expect_output(print(pca), "<PCA>")
  expect_output(print(pca), "Components: 2, Dimension: 2")
})

test_that("pca_from_matrix validates input", {
  expect_error(pca_from_matrix(matrix("a", 2, 2)), "must be numeric")
  expect_error(pca_from_matrix(matrix(1, 1, 2)), "at least 2 observations")
  expect_error(pca_from_matrix(matrix(1, 2, 1)), "at least 2 variables")
})

test_that("PCA() rejects a missing external pointer", {
  expect_error(PCA(), "pca_from_matrix")
})
