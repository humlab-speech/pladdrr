#' @title Principal Component Analysis (PCA)
#' @description
#' PCA for dimensionality reduction and analysis of multivariate acoustic data.
#'
#' @details
#' PCA is commonly used in phonetics for vowel space analysis, speaker
#' normalization, acoustic feature extraction, and data visualization.
#'
#' @return A \code{PCA} object with methods for querying components, eigenvalues,
#'   and projections.
#'
#' @examples
#' set.seed(1)
#' data <- cbind(f1 = rnorm(20, 500, 50), f2 = rnorm(20, 1500, 100))
#' pca <- pca_from_matrix(data)
#' pca$get_number_of_components()
#' pca$get_eigenvalues()
#'
#' @seealso \code{\link{Discriminant}}
#' @name PCA
NULL

# ============================================================================
# Shared Method Dispatch Table
# ============================================================================

.pca_methods <- new.env(hash = TRUE, parent = emptyenv())

# Query - Properties
.pca_methods$get_number_of_components <- function(.self) .self$.cpp$get_number_of_components()
.pca_methods$get_dimension <- function(.self) .self$.cpp$get_dimension()
.pca_methods$get_number_of_observations <- function(.self) .self$.cpp$get_number_of_observations()

# Eigenvalues
.pca_methods$get_eigenvalues <- function(.self) .self$.cpp$get_eigenvalues()
.pca_methods$get_eigenvalue <- function(.self, component) {
  .self$.cpp$get_eigenvalue(as.integer(component))
}

# Variance explained
.pca_methods$get_fraction_variance <- function(.self, from = 1, to = 0) {
  .self$.cpp$get_fraction_variance(as.integer(from), as.integer(to))
}
.pca_methods$get_variance_explained <- function(.self, from = 1, to = 0) {
  .self$.cpp$get_fraction_variance(as.integer(from), as.integer(to))
}
.pca_methods$get_dimension_of_fraction <- function(.self, fraction) {
  .self$.cpp$get_dimension_of_fraction(fraction)
}

# Eigenvectors
.pca_methods$get_eigenvector <- function(.self, component) {
  .self$.cpp$get_eigenvector(as.integer(component))
}
.pca_methods$get_eigenvectors <- function(.self) .self$.cpp$get_eigenvectors()
.pca_methods$get_loadings <- function(.self) .self$.cpp$get_eigenvectors()

# Other
.pca_methods$get_centroid <- function(.self) .self$.cpp$get_centroid()
.pca_methods$get_labels <- function(.self) .self$.cpp$get_labels()

# Projection
.pca_methods$project <- function(.self, data, num_dimensions = 0) {
  if (!is.matrix(data)) data <- as.matrix(data)
  .self$.cpp$project(data, as.integer(num_dimensions))
}
.pca_methods$transform <- function(.self, data, num_dimensions = 0) {
  if (!is.matrix(data)) data <- as.matrix(data)
  .self$.cpp$project(data, as.integer(num_dimensions))
}

# Export
.pca_methods$as_data_frame <- function(.self) .self$.cpp$as_data_frame()
.pca_methods$get_info <- function(.self) .self$.cpp$get_info()

# Utility
.pca_methods$get_xptr <- function(.self) .self$.xptr
.pca_methods$save <- function(.self, path) {
  .self$.cpp$save(path)
  invisible(.self)
}

# Display
.pca_methods$print <- function(.self) {
  info <- .self$.cpp$get_info()
  eigenvals <- info$eigenvalues
  total <- sum(eigenvals)
  cum_var <- cumsum(eigenvals / total)

  cat("<PCA>\n")
  cat(sprintf("  Components: %d, Dimension: %d\n", info$n_components, info$dimension))
  cat(sprintf("  Observations: %d\n", info$n_observations))
  cat("  Variance explained:\n")
  for (i in seq_len(min(5, length(eigenvals)))) {
    cat(sprintf("    PC%d: %.1f%% (cumulative: %.1f%%)\n",
                i, 100 * eigenvals[i] / total, 100 * cum_var[i]))
  }
  if (length(eigenvals) > 5) {
    cat(sprintf("    ... and %d more components\n", length(eigenvals) - 5))
  }
  invisible(.self)
}

.pca_methods$is_valid <- function(.self) .self$.cpp$is_valid()
lockEnvironment(.pca_methods, bindings = TRUE)

# ============================================================================
# S3 Dispatch
# ============================================================================

#' @method $ PCA
#' @export
`$.PCA` <- function(x, name) {
  val <- .subset2(x, name)
  if (!is.null(val)) return(val)
  method <- .pca_methods[[name]]
  if (is.null(method)) return(NULL)
  function(...) method(x, ...)
}

# ============================================================================
# Constructor
# ============================================================================

#' @export
PCA <- function(.xptr = NULL) {
  if (is.null(.xptr)) {
    stop("PCA objects must be created using pca_from_matrix() or matrix$to_pca()")
  }

  pca_mod <- get_module("pca_module")
  cpp_obj <- pca_mod$RPCA$new(.xptr)

  structure(list(
    .cpp = cpp_obj,
    .xptr = .xptr
  ), class = c("PCA", "PraatObject"))
}

#' @export
print.PCA <- function(x, ...) x$print()

#' Create PCA from data matrix
#'
#' Performs Principal Component Analysis on a numeric matrix.
#'
#' @param data Numeric matrix where rows are observations and columns are variables
#' @return A PCA object
#' @examples
#' set.seed(1)
#' data <- matrix(rnorm(50), nrow = 10, ncol = 5)
#' pca <- pca_from_matrix(data)
#' print(pca)
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
