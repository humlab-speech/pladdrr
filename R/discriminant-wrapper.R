#' @title Discriminant Analysis (LDA)
#' @description
#' Linear Discriminant Analysis for vowel classification, speaker identification,
#' and other multivariate acoustic classification tasks.
#'
#' @details
#' Discriminant analysis is commonly used in phonetics for vowel classification,
#' speaker identification, dialect/accent classification, and phoneme recognition.
#'
#' @seealso \code{\link{PCA}}
#' @name Discriminant
NULL

# ============================================================================
# Shared Method Dispatch Table
# ============================================================================

.discriminant_methods <- new.env(hash = TRUE, parent = emptyenv())

# Query - Properties
.discriminant_methods$get_number_of_groups <- function(.self) .self$.cpp$get_number_of_groups()
.discriminant_methods$get_number_of_functions <- function(.self) .self$.cpp$get_number_of_functions()
.discriminant_methods$get_dimension <- function(.self) .self$.cpp$get_dimension()
.discriminant_methods$get_number_of_observations <- function(.self, group) {
  .self$.cpp$get_number_of_observations(as.integer(group))
}
.discriminant_methods$get_total_observations <- function(.self) .self$.cpp$get_total_observations()

# Eigenvalues
.discriminant_methods$get_eigenvalues <- function(.self) .self$.cpp$get_eigenvalues()
.discriminant_methods$get_eigenvalue <- function(.self, func) {
  .self$.cpp$get_eigenvalue(as.integer(func))
}

# Variance explained
.discriminant_methods$get_fraction_variance <- function(.self, from = 1, to = 0) {
  .self$.cpp$get_fraction_variance(as.integer(from), as.integer(to))
}
.discriminant_methods$get_variance_explained <- function(.self, from = 1, to = 0) {
  .self$.cpp$get_fraction_variance(as.integer(from), as.integer(to))
}

# Statistical significance
.discriminant_methods$get_wilks_lambda <- function(.self, from = 1) {
  .self$.cpp$get_wilks_lambda(as.integer(from))
}
.discriminant_methods$get_partial_discrimination_probability <- function(.self, num_dimensions) {
  .self$.cpp$get_partial_discrimination_probability(as.integer(num_dimensions))
}
.discriminant_methods$get_ln_determinant_group <- function(.self, group) {
  .self$.cpp$get_ln_determinant_group(as.integer(group))
}
.discriminant_methods$get_ln_determinant_total <- function(.self) .self$.cpp$get_ln_determinant_total()

# Eigenvectors
.discriminant_methods$get_eigenvector <- function(.self, func) {
  .self$.cpp$get_eigenvector(as.integer(func))
}
.discriminant_methods$get_eigenvectors <- function(.self) .self$.cpp$get_eigenvectors()
.discriminant_methods$get_coefficients <- function(.self) .self$.cpp$get_eigenvectors()

# Group information
.discriminant_methods$get_group_labels <- function(.self) .self$.cpp$get_group_labels()
.discriminant_methods$get_group_centroids <- function(.self) .self$.cpp$get_group_centroids()
.discriminant_methods$get_apriori_probabilities <- function(.self) .self$.cpp$get_apriori_probabilities()
.discriminant_methods$set_apriori_probability <- function(.self, group, prob) {
  .self$.cpp$set_apriori_probability(as.integer(group), prob)
  invisible(.self)
}

# Export
.discriminant_methods$as_data_frame <- function(.self) .self$.cpp$as_data_frame()
.discriminant_methods$get_info <- function(.self) .self$.cpp$get_info()

# Utility
.discriminant_methods$get_xptr <- function(.self) .self$.xptr
.discriminant_methods$save <- function(.self, path) {
  .self$.cpp$save(path)
  invisible(.self)
}

# Display
.discriminant_methods$print <- function(.self) {
  info <- .self$.cpp$get_info()
  eigenvals <- info$eigenvalues
  total <- sum(eigenvals)
  cum_var <- cumsum(eigenvals / total)

  cat("<Discriminant Analysis (LDA)>\n")
  cat(sprintf("  Groups: %d, Functions: %d, Dimension: %d\n",
              info$n_groups, info$n_functions, info$dimension))
  cat(sprintf("  Total observations: %d\n", info$n_observations))
  cat(sprintf("  Group labels: %s\n", paste(info$group_labels, collapse = ", ")))
  cat("  Discriminant functions:\n")
  for (i in 1:min(5, length(eigenvals))) {
    wilks <- .self$.cpp$get_wilks_lambda(i)
    cat(sprintf("    DF%d: eigenvalue=%.3f (%.1f%%), Wilks' Lambda=%.4f\n",
                i, eigenvals[i], 100 * cum_var[i], wilks))
  }
  if (length(eigenvals) > 5) {
    cat(sprintf("    ... and %d more functions\n", length(eigenvals) - 5))
  }
  invisible(.self)
}

.discriminant_methods$is_valid <- function(.self) .self$.cpp$is_valid()
lockEnvironment(.discriminant_methods, bindings = TRUE)

# ============================================================================
# S3 Dispatch
# ============================================================================

#' @method $ Discriminant
#' @export
`$.Discriminant` <- function(x, name) {
  val <- .subset2(x, name)
  if (!is.null(val)) return(val)
  method <- .discriminant_methods[[name]]
  if (is.null(method)) return(NULL)
  function(...) method(x, ...)
}

# ============================================================================
# Constructor
# ============================================================================

#' @export
Discriminant <- function(.xptr = NULL) {
  if (is.null(.xptr)) {
    stop("Discriminant objects must be created using discriminant_from_matrix()")
  }

  disc_mod <- get_module("discriminant_module")
  cpp_obj <- disc_mod$RDiscriminant$new(.xptr)

  structure(list(
    .cpp = cpp_obj,
    .xptr = .xptr
  ), class = c("Discriminant", "PraatObject"))
}

#' @export
print.Discriminant <- function(x, ...) x$print()

#' Create Discriminant Analysis from labeled data
#'
#' Performs Linear Discriminant Analysis on a labeled numeric matrix.
#'
#' @param data Numeric matrix where rows are observations and columns are variables
#' @param labels Character vector of group labels (one per row in data)
#' @return A Discriminant object
#' @export
discriminant_from_matrix <- function(data, labels) {
  if (!is.matrix(data)) data <- as.matrix(data)
  if (!is.numeric(data)) stop("data must be numeric")
  if (nrow(data) != length(labels)) {
    stop("Number of rows in data must match length of labels")
  }
  if (length(unique(labels)) < 2) stop("Need at least 2 groups")
  if (ncol(data) < 1) stop("Need at least 1 variable")

  labels <- as.character(labels)

  disc_mod <- get_module("discriminant_module")
  disc_ptr <- disc_mod$Discriminant_from_labeled_matrix(data, labels)
  Discriminant(.xptr = disc_ptr)
}
