# test-discriminant-r6.R - Tests for R/discriminant-wrapper.R (Discriminant object)
#
# NOTE: discriminant_from_matrix() with more than one predictor column is
# currently unreliable (documented in R/discriminant-wrapper.R and confirmed
# here: multi-column input reproducibly fails to build a Discriminant, or
# fails inside LAPACK with a BLAS/LAPACK error). All tests below therefore
# use single-column (ncol = 1) input, matching the package's own example.

test_that("Discriminant constructs from a matrix and reports basic properties", {
  set.seed(1)
  data <- matrix(c(rnorm(10, 500), rnorm(10, 700)), ncol = 1,
                  dimnames = list(NULL, "f1"))
  labels <- rep(c("a", "i"), each = 10)
  disc <- discriminant_from_matrix(data, labels)

  expect_s3_class(disc, "Discriminant")
  expect_s3_class(disc, "PraatObject")
  expect_true(disc$is_valid())
  expect_equal(disc$get_number_of_groups(), 2)
  expect_gte(disc$get_number_of_functions(), 1)
  expect_equal(disc$get_dimension(), 1)
  expect_equal(disc$get_number_of_observations(1), 10)
  expect_equal(disc$get_total_observations(), 20)
})

test_that("Discriminant eigen/variance/probability queries work", {
  set.seed(2)
  data <- matrix(c(rnorm(10, 300, 30), rnorm(10, 700, 30), rnorm(10, 1100, 30)),
                  ncol = 1, dimnames = list(NULL, "f1"))
  labels <- rep(c("a", "e", "i"), each = 10)
  disc <- discriminant_from_matrix(data, labels)

  # dimension 1 -> only min(n_groups - 1, dimension) = 1 discriminant function
  expect_equal(disc$get_number_of_functions(), 1)

  ev <- disc$get_eigenvalues()
  expect_type(ev, "double")
  expect_length(ev, 1)
  expect_equal(disc$get_eigenvalue(1), ev[1])
  expect_type(disc$get_fraction_variance(1, 1), "double")
  expect_equal(disc$get_fraction_variance(1, 1), 1)  # only function explains 100%
  expect_type(disc$get_variance_explained(1, 1), "double")
  expect_type(disc$get_wilks_lambda(1), "double")

  # get_partial_discrimination_probability() returns a 3-element list
  # (probability, chi_squared, df), not a bare double. Per
  # Discriminant_getPartialDiscriminationProbability() in
  # src/praat.github.io/dwtools/Discriminant.cpp, the result is only
  # defined (non-NaN) when num_dimensions < number_of_functions, so with
  # a single function we must query with num_dimensions = 0.
  partial_prob <- disc$get_partial_discrimination_probability(0)
  expect_type(partial_prob, "list")
  expect_named(partial_prob, c("probability", "chi_squared", "df"))
  expect_type(partial_prob$probability, "double")
  expect_type(partial_prob$chi_squared, "double")
  expect_type(partial_prob$df, "double")
  expect_false(is.nan(partial_prob$probability))

  expect_type(disc$get_ln_determinant_group(1), "double")
  expect_type(disc$get_ln_determinant_total(), "double")

  vec <- disc$get_eigenvector(1)
  expect_type(vec, "double")
  expect_length(vec, disc$get_dimension())
  expect_equal(disc$get_eigenvectors(), disc$get_coefficients())
  expect_true(is.matrix(disc$get_eigenvectors()))
  expect_equal(disc$get_group_labels(), c("a", "e", "i"))

  # get_group_centroids() returns a numeric matrix: one row per group,
  # one column per variable, row-named by group label.
  centroids <- disc$get_group_centroids()
  expect_true(is.matrix(centroids))
  expect_equal(dim(centroids), c(3, 1))
  expect_equal(rownames(centroids), c("a", "e", "i"))

  expect_type(disc$get_apriori_probabilities(), "double")
  expect_length(disc$get_apriori_probabilities(), 3)
})

test_that("Discriminant set_apriori_probability, as_data_frame, get_info, save round-trip", {
  set.seed(3)
  data <- matrix(c(rnorm(10, 500, 30), rnorm(10, 900, 30)), ncol = 1,
                  dimnames = list(NULL, "f1"))
  labels <- rep(c("a", "i"), each = 10)
  disc <- discriminant_from_matrix(data, labels)

  disc$set_apriori_probability(1, 0.6)
  probs <- disc$get_apriori_probabilities()
  expect_type(probs, "double")
  expect_equal(probs[1], 0.6)

  df <- disc$as_data_frame()
  expect_s3_class(df, "data.frame")
  # "function" is an R reserved word; DataFrame::create() from Rcpp becomes
  # a data.frame with make.names()-syntactic column names, so it's punned
  # to "function." on the R side.
  expect_equal(names(df), c("function.", "eigenvalue", "variance_fraction",
                             "cumulative_variance", "wilks_lambda"))
  expect_equal(nrow(df), disc$get_number_of_functions())

  # get_info() returns a structured list summary, not a character string.
  info <- disc$get_info()
  expect_type(info, "list")
  expect_named(info, c("n_groups", "n_functions", "dimension", "n_observations",
                        "eigenvalues", "group_labels", "apriori_probabilities"))
  expect_equal(info$n_groups, 2)
  expect_equal(info$n_observations, 20)
  expect_equal(info$group_labels, c("a", "i"))

  tmp <- tempfile(fileext = ".Discriminant")
  on.exit(unlink(tmp), add = TRUE)
  disc$save(tmp)
  expect_true(file.exists(tmp))
  expect_gt(file.size(tmp), 0)

  expect_output(print(disc), "Discriminant Analysis")
})

test_that("discriminant_from_matrix validates input", {
  data <- matrix(rnorm(20), ncol = 1)
  labels_short <- rep("a", 5)

  expect_error(discriminant_from_matrix(data, labels_short),
               "Number of rows in data must match length of labels")
  expect_error(discriminant_from_matrix(data, rep("a", 20)),
               "Need at least 2 groups")

  bad_data <- matrix(c("x", "y"), ncol = 1)
  expect_error(discriminant_from_matrix(bad_data, c("a", "b")),
               "data must be numeric")
})

test_that("Discriminant rejects out-of-range group and function indices", {
  set.seed(4)
  data <- matrix(c(rnorm(10, 500), rnorm(10, 700)), ncol = 1)
  labels <- rep(c("a", "i"), each = 10)
  disc <- discriminant_from_matrix(data, labels)

  expect_error(disc$get_number_of_observations(3), "Group index out of range")
  expect_error(disc$get_ln_determinant_group(0), "Group index out of range")
  expect_error(disc$set_apriori_probability(1, 1.5), "Probability must be between 0 and 1")
})
