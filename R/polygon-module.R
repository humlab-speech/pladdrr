# Polygon Object - Rcpp Module Wrapper
# 2D polygon representation for geometric operations

#' Polygon Object
#'
#' 2D polygon for geometric operations and spatial analysis.
#'
#' Uses Rcpp Modules for high-performance access to Praat's Polygon object.
#'
#' @section Common uses:
#' \itemize{
#'   \item Vowel space boundaries
#'   \item Formant space visualization
#'   \item Acoustic space analysis
#'   \item Convex hull computation
#' }
#'
#' @param x Numeric vector of x coordinates. Required unless \code{.xptr} is given.
#' @param y Numeric vector of y coordinates. Required unless \code{.xptr} is given.
#' @param .xptr Not for direct use. External pointer to the underlying C++ Polygon
#'   object; set internally when a method returns a new Polygon.
#' @return A Polygon object with methods for geometry operations.
#'
#' @examples
#' # Create polygon from formant data
#' poly <- Polygon(x = c(730, 1090, 2440), y = c(1090, 1220, 2440))
#'
#' # Geometry queries
#' perimeter <- poly$get_perimeter()
#' n_points <- poly$n_points()
#'
#' # Optimize path (traveling salesman)
#' poly$optimize_salesperson(iterations = 100)
#'
#' # Export
#' df <- as.data.frame(poly)
#'
#' @name Polygon
NULL

# ============================================================================
# Shared Method Dispatch Table
# ============================================================================

.polygon_methods <- new.env(hash = TRUE, parent = emptyenv())

# Properties
.polygon_methods$is_valid <- function(.self) .self$.cpp$is_valid()
.polygon_methods$n_points <- function(.self) .self$.cpp$get_number_of_points()

# Data access (1-based indexing)
.polygon_methods$get_x <- function(.self, i) .self$.cpp$get_x(as.integer(i))
.polygon_methods$get_y <- function(.self, i) .self$.cpp$get_y(as.integer(i))
.polygon_methods$get_all_x <- function(.self) .self$.cpp$get_all_x()
.polygon_methods$get_all_y <- function(.self) .self$.cpp$get_all_y()

# Geometry
.polygon_methods$get_perimeter <- function(.self) .self$.cpp$get_perimeter()
.polygon_methods$randomize <- function(.self) {
  .self$.cpp$randomize()
  invisible(.self)
}
.polygon_methods$optimize_salesperson <- function(.self, iterations = 100) {
  .self$.cpp$optimize_salesperson(as.integer(iterations))
  invisible(.self)
}

# Export
.polygon_methods$as_data_frame <- function(.self) .self$.cpp$as_data_frame()
.polygon_methods$as_matrix <- function(.self) .self$.cpp$as_matrix()
.polygon_methods$save <- function(.self, path) {
  .self$.cpp$save(as.character(path))
  invisible(.self)
}

# Display
.polygon_methods$print <- function(.self) {
  cat("<Praat Polygon (Module)>\n")
  if (.self$.cpp$is_valid()) {
    n <- .self$.cpp$get_number_of_points()
    cat(sprintf("  Points: %d\n", n))
    tryCatch({
      perim <- .self$.cpp$get_perimeter()
      if (!is.na(perim)) {
        cat(sprintf("  Perimeter: %.3f\n", perim))
      }
    }, error = function(e) {})
    if (n > 0) {
      show_n <- min(3, n)
      cat("  First points:\n")
      for (i in seq_len(show_n)) {
        x_val <- .self$.cpp$get_x(i)
        y_val <- .self$.cpp$get_y(i)
        cat(sprintf("    %d: (%.3f, %.3f)\n", i, x_val, y_val))
      }
      if (n > 3) {
        cat(sprintf("    ... (%d more points)\n", n - 3))
      }
    }
  } else {
    cat("  [Invalid object]\n")
  }
  invisible(.self)
}

lockEnvironment(.polygon_methods, bindings = TRUE)

# ============================================================================
# S3 Dispatch
# ============================================================================

#' @method $ Polygon
#' @export
`$.Polygon` <- function(x, name) {
  val <- .subset2(x, name)
  if (!is.null(val)) return(val)
  method <- .polygon_methods[[name]]
  if (is.null(method)) return(NULL)
  function(...) method(x, ...)
}

# ============================================================================
# Constructor
# ============================================================================

#' @export
Polygon <- function(x, y, .xptr = NULL) {
  poly_mod <- get_module("polygon_module")
  if (is.null(poly_mod)) {
    stop("polygon_module not available - package installation may be incomplete")
  }

  if (!is.null(.xptr)) {
    xptr <- .xptr
  } else {
    if (missing(x) || missing(y)) stop("Both x and y coordinates required")
    if (length(x) != length(y)) stop("x and y must have same length")
    if (length(x) < 1) stop("At least 1 point required")
    xptr <- poly_mod$polygon_create_xptr(as.numeric(x), as.numeric(y))
  }

  cpp_obj <- poly_mod$RPolygon$new(xptr)

  structure(list(
    .xptr = xptr,
    .cpp = cpp_obj
  ), class = c("Polygon", "PraatObject"))
}

# ============================================================================
# S3 Methods
# ============================================================================

#' @export
as.matrix.Polygon <- function(x, ...) {
  x$as_matrix()
}
