# Extracted from test-pca-r6.R:102

# test -------------------------------------------------------------------------
set.seed(3)
data <- cbind(f1 = rnorm(15, 500, 50), f2 = rnorm(15, 1500, 100))
pca <- pca_from_matrix(data)
proj_all <- pca$project(data)
expect_true(is.matrix(proj_all))
expect_equal(dim(proj_all), c(15, pca$get_number_of_components()),
  tolerance = sqrt(.Machine$double.eps))
proj1 <- pca$project(data, num_dimensions = 1)
expect_equal(dim(proj1), c(15, 1), tolerance = sqrt(.Machine$double.eps))
expect_equal(pca$transform(data), proj_all,
  tolerance = sqrt(.Machine$double.eps))
proj_df <- pca$project(as.data.frame(data))
expect_equal(proj_df, proj_all, tolerance = sqrt(.Machine$double.eps))
expect_error(pca$project(matrix(1:6, nrow = 2)), "dimension mismatch")
df <- pca$as_data_frame()
expect_s3_class(df, "data.frame")
expect_equal(nrow(df), pca$get_number_of_components(),
  tolerance = sqrt(.Machine$double.eps))
expect_named(df,
  c("component", "eigenvalue", "variance_fraction", "cumulative_variance"))
expect_equal(df$eigenvalue, pca$get_eigenvalues(),
  tolerance = sqrt(.Machine$double.eps))
expect_identical(df$cumulative_variance[nrow(df)], 1L)
