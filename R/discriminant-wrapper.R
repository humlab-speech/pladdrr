#' @title Discriminant Analysis (LDA)
#' @description
#' Linear Discriminant Analysis for vowel classification, speaker identification,
#' and other multivariate acoustic classification tasks.
#'
#' @details
#' Discriminant analysis is commonly used in phonetics for:
#' - Vowel classification (F1/F2/F3 space)
#' - Speaker identification
#' - Dialect/accent classification
#' - Phoneme recognition
#'
#' ## Creating Discriminant Objects
#'
#' Discriminant objects are created from labeled data matrices:
#' - `discriminant_from_matrix(data, labels)` - Create from matrix with group labels
#'
#' ## Querying Properties
#'
#' - `$get_number_of_groups()` - Number of classes/groups
#' - `$get_number_of_functions()` - Number of discriminant functions
#' - `$get_dimension()` - Original data dimension
#' - `$get_eigenvalues()` - Vector of eigenvalues
#' - `$get_fraction_variance(from, to)` - Cumulative variance explained
#'
#' ## Statistical Significance
#'
#' - `$get_wilks_lambda(from)` - Wilks' Lambda statistic
#' - `$get_partial_discrimination_probability(n_dim)` - Chi-squared test results
#'
#' ## Group Information
#'
#' - `$get_group_labels()` - Names of groups
#' - `$get_group_centroids()` - Group means in original space
#' - `$get_apriori_probabilities()` - Prior probabilities for each group
#'
#' @examples
#' \dontrun{
#' # Create Discriminant from vowel formant data
#' # Each row is a vowel token, columns are F1, F2, F3
#' vowels <- matrix(c(
#'   # F1    F2    F3
#'   700,  1200, 2500,  # /a/ token 1
#'   720,  1180, 2520,  # /a/ token 2
#'   350,  2100, 2800,  # /i/ token 1
#'   340,  2150, 2780,  # /i/ token 2
#'   450,  700,  2400,  # /u/ token 1
#'   460,  720,  2420   # /u/ token 2
#' ), ncol = 3, byrow = TRUE)
#'
#' labels <- c("a", "a", "i", "i", "u", "u")
#'
#' # Compute LDA
#' lda <- discriminant_from_matrix(vowels, labels)
#'
#' # Check discriminability
#' lda$get_wilks_lambda(1)  # Should be small for good separation
#' lda$get_eigenvalues()
#' lda$get_fraction_variance(1, 2)  # First 2 functions
#'
#' # Get group centroids
#' lda$get_group_centroids()
#'
#' # Get discriminant function coefficients
#' coefs <- lda$get_eigenvector(1)  # First discriminant function
#' }
#'
#' @export
Discriminant <- function(.xptr = NULL) {
  if (is.null(.xptr)) {
    stop("Discriminant objects must be created using discriminant_from_matrix()")
  }

  disc_mod <- get_module("discriminant_module")
  cpp_obj <- disc_mod$RDiscriminant$new(.xptr)

  obj <- structure(list(
    .cpp = cpp_obj,
    .xptr = .xptr,

    # Query - Properties
    get_number_of_groups = function() cpp_obj$get_number_of_groups(),
    get_number_of_functions = function() cpp_obj$get_number_of_functions(),
    get_dimension = function() cpp_obj$get_dimension(),
    get_number_of_observations = function(group) cpp_obj$get_number_of_observations(as.integer(group)),
    get_total_observations = function() cpp_obj$get_total_observations(),

    # Eigenvalues
    get_eigenvalues = function() cpp_obj$get_eigenvalues(),
    get_eigenvalue = function(func) cpp_obj$get_eigenvalue(as.integer(func)),

    # Variance explained
    get_fraction_variance = function(from = 1, to = 0) {
      cpp_obj$get_fraction_variance(as.integer(from), as.integer(to))
    },

    get_variance_explained = function(from = 1, to = 0) {
      obj$get_fraction_variance(from, to)
    },

    # Statistical significance
    get_wilks_lambda = function(from = 1) {
      cpp_obj$get_wilks_lambda(as.integer(from))
    },

    get_partial_discrimination_probability = function(num_dimensions) {
      cpp_obj$get_partial_discrimination_probability(as.integer(num_dimensions))
    },

    get_ln_determinant_group = function(group) {
      cpp_obj$get_ln_determinant_group(as.integer(group))
    },

    get_ln_determinant_total = function() cpp_obj$get_ln_determinant_total(),

    # Eigenvectors (discriminant function coefficients)
    get_eigenvector = function(func) {
      cpp_obj$get_eigenvector(as.integer(func))
    },

    get_eigenvectors = function() cpp_obj$get_eigenvectors(),
    get_coefficients = function() cpp_obj$get_eigenvectors(),

    # Group information
    get_group_labels = function() cpp_obj$get_group_labels(),
    get_group_centroids = function() cpp_obj$get_group_centroids(),
    get_apriori_probabilities = function() cpp_obj$get_apriori_probabilities(),

    set_apriori_probability = function(group, prob) {
      cpp_obj$set_apriori_probability(as.integer(group), prob)
      invisible(obj)
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

      cat("<Discriminant Analysis (LDA)>\n")
      cat(sprintf("  Groups: %d, Functions: %d, Dimension: %d\n",
                  info$n_groups, info$n_functions, info$dimension))
      cat(sprintf("  Total observations: %d\n", info$n_observations))
      cat(sprintf("  Group labels: %s\n", paste(info$group_labels, collapse = ", ")))
      cat("  Discriminant functions:\n")
      for (i in 1:min(5, length(eigenvals))) {
        wilks <- cpp_obj$get_wilks_lambda(i)
        cat(sprintf("    DF%d: eigenvalue=%.3f (%.1f%%), Wilks' Lambda=%.4f\n",
                    i, eigenvals[i], 100 * cum_var[i], wilks))
      }
      if (length(eigenvals) > 5) {
        cat(sprintf("    ... and %d more functions\n", length(eigenvals) - 5))
      }
      invisible(obj)
    }

  ), class = c("Discriminant", "PraatObject"))

  obj
}

#' @export
print.Discriminant <- function(x, ...) {
  x$print()
}

#' Create Discriminant Analysis from labeled data
#'
#' Performs Linear Discriminant Analysis on a labeled numeric matrix.
#'
#' @param data Numeric matrix where rows are observations and columns are variables
#' @param labels Character vector of group labels (one per row in data)
#' @return A Discriminant object
#'
#' @examples
#' \dontrun{
#' # Vowel formant data with labels
#' vowels <- matrix(c(
#'   700, 1200, 2500,  # /a/
#'   350, 2100, 2800,  # /i/
#'   450, 700, 2400    # /u/
#' ), ncol = 3, byrow = TRUE)
#'
#' labels <- c("a", "i", "u")
#' lda <- discriminant_from_matrix(vowels, labels)
#' lda$get_wilks_lambda(1)
#' }
#'
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
