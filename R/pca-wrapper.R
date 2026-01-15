#' @title Principal Component Analysis (PCA)
#' @description
#' PCA for dimensionality reduction and analysis of multivariate acoustic data.
#'
#' @details
#' PCA is commonly used in phonetics for:
#' - Vowel space analysis (F1/F2/F3 reduction)
#' - Speaker normalization
#' - Acoustic feature extraction
#' - Data visualization
#'
#' ## Creating PCA Objects
#'
#' PCA objects are created from numeric matrices or Matrix objects:
#' - `pca_from_matrix(data)` - Create PCA from R matrix
#' - `matrix$to_pca()` - Create PCA from pladdrr Matrix object
#'
#' ## Querying Properties
#'
#' - `$get_number_of_components()` - Number of principal components
#' - `$get_dimension()` - Original data dimension
#' - `$get_number_of_observations()` - Number of data points used
#' - `$get_eigenvalues()` - Vector of eigenvalues
#' - `$get_fraction_variance(from, to)` - Cumulative variance explained
#' - `$get_dimension_of_fraction(frac)` - Components needed for fraction of variance
#'
#' ## Eigenvectors
#'
#' - `$get_eigenvector(i)` - Get i-th eigenvector (loadings)
#' - `$get_eigenvectors()` - Matrix of all eigenvectors
#' - `$get_centroid()` - Data centroid
#'
#' ## Projection
#'
#' - `$project(data, n_dim)` - Project new data onto principal components
#'
#' @examples
#' \dontrun{
#' # Create PCA from vowel formant data
#' vowels <- matrix(c(
#'   # F1    F2    F3
#'   700,  1200, 2500,  # /a/
#'   350,  2100, 2800,  # /i/
#'   450,  700,  2400,  # /u/
#'   550,  1800, 2600,  # /e/
#'   600,  900,  2450   # /o/
#' ), ncol = 3, byrow = TRUE)
#'
#' # Compute PCA
#' pca <- pca_from_matrix(vowels)
#'
#' # Check variance explained
#' pca$get_eigenvalues()
#' pca$get_fraction_variance(1, 2)  # First 2 components
#'
#' # Get loadings
#' pc1_loadings <- pca$get_eigenvector(1)
#'
#' # Project new data
#' new_data <- matrix(c(680, 1150, 2480), ncol = 3)
#' projected <- pca$project(new_data, num_dimensions = 2)
#' }
#'
#' @export
PCA <- function(.xptr = NULL) {
  if (is.null(.xptr)) {
    stop("PCA objects must be created using pca_from_matrix() or matrix$to_pca()")
  }

  pca_mod <- get_module("pca_module")
  cpp_obj <- pca_mod$RPCA$new(.xptr)

  obj <- structure(list(
    .cpp = cpp_obj,
    .xptr = .xptr,

    # Query - Properties
    get_number_of_components = function() cpp_obj$get_number_of_components(),
    get_dimension = function() cpp_obj$get_dimension(),
    get_number_of_observations = function() cpp_obj$get_number_of_observations(),

    # Eigenvalues
    get_eigenvalues = function() cpp_obj$get_eigenvalues(),
    get_eigenvalue = function(component) cpp_obj$get_eigenvalue(as.integer(component)),

    # Variance explained
    get_fraction_variance = function(from = 1, to = 0) {
      cpp_obj$get_fraction_variance(as.integer(from), as.integer(to))
    },

    get_variance_explained = function(from = 1, to = 0) {
      obj$get_fraction_variance(from, to)
    },

    get_dimension_of_fraction = function(fraction) {
      cpp_obj$get_dimension_of_fraction(fraction)
    },

    # Eigenvectors
    get_eigenvector = function(component) {
      cpp_obj$get_eigenvector(as.integer(component))
    },

    get_eigenvectors = function() cpp_obj$get_eigenvectors(),
    get_loadings = function() cpp_obj$get_eigenvectors(),

    # Other
    get_centroid = function() cpp_obj$get_centroid(),
    get_labels = function() cpp_obj$get_labels(),

    # Projection
    project = function(data, num_dimensions = 0) {
      if (!is.matrix(data)) data <- as.matrix(data)
      cpp_obj$project(data, as.integer(num_dimensions))
    },

    transform = function(data, num_dimensions = 0) {
      obj$project(data, num_dimensions)
    },

    # Export
    as_data_frame = function() cpp_obj$as_data_frame(),
    get_info = function() cpp_obj$get_info(),

    # Utility
    get_xptr = function() .xptr,

    save = function(path) {
      cpp_obj$save(path)
      invisible(obj)
    },

    # Display
    print = function() {
      info <- cpp_obj$get_info()
      eigenvals <- info$eigenvalues
      total <- sum(eigenvals)
      cum_var <- cumsum(eigenvals / total)

      cat("<PCA>\n")
      cat(sprintf("  Components: %d, Dimension: %d\n", info$n_components, info$dimension))
      cat(sprintf("  Observations: %d\n", info$n_observations))
      cat("  Variance explained:\n")
      for (i in 1:min(5, length(eigenvals))) {
        cat(sprintf("    PC%d: %.1f%% (cumulative: %.1f%%)\n",
                    i, 100 * eigenvals[i] / total, 100 * cum_var[i]))
      }
      if (length(eigenvals) > 5) {
        cat(sprintf("    ... and %d more components\n", length(eigenvals) - 5))
      }
      invisible(obj)
    }

  ), class = c("PCA", "PraatObject"))

  obj
}

#' @export
print.PCA <- function(x, ...) {
  x$print()
}

#' Create PCA from data matrix
#'
#' Performs Principal Component Analysis on a numeric matrix.
#'
#' @param data Numeric matrix where rows are observations and columns are variables
#' @return A PCA object
#'
#' @examples
#' \dontrun{
#' # Vowel formant data (F1, F2, F3)
#' vowels <- matrix(c(
#'   700, 1200, 2500,
#'   350, 2100, 2800,
#'   450, 700, 2400
#' ), ncol = 3, byrow = TRUE)
#'
#' pca <- pca_from_matrix(vowels)
#' pca$get_eigenvalues()
#' }
#'
#' @export
pca_from_matrix <- function(data) {
  if (!is.matrix(data)) data <- as.matrix(data)
  if (!is.numeric(data)) stop("data must be numeric")
  if (nrow(data) < 2) stop("Need at least 2 observations")
  if (ncol(data) < 2) stop("Need at least 2 variables")

  pca_mod <- get_module("pca_module")
  pca_ptr <- pca_mod$PCA_from_matrix(data)
  PCA(.xptr = pca_ptr)
}
