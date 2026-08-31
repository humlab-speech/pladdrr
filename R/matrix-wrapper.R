#' @title Praat Matrix Object
#' @description
#' Praat Matrix object with direct C++ module binding for matrix operations.
#'
#' @details
#' Matrix objects represent two-dimensional sampled data with x and y axes.
#'
#' @return A \code{Matrix} object with methods for two-dimensional sampled data
#'  access.
#'
#' @examples
#' m <- Matrix(numberOfRows = 3, numberOfColumns = 4)
#' m$set_value(1, 1, 5.0)
#' m$get_value(1, 1)
#' m$get_number_of_rows()
#' as.matrix(m)
#'
#' # Save and read back
#' mat_file <- tempfile(fileext = ".Matrix")
#' m$save(mat_file)
#' m2 <- matrix_read(mat_file)
#' m2$get_value(1, 1)
#'
#' @name Matrix
NULL

# ============================================================================
# Shared Method Dispatch Table
# ============================================================================

.matrix_methods <- new.env(hash = TRUE, parent = emptyenv())

# Query - Structure
.matrix_methods$get_nx <- function(.self) .self$.cpp$get_nx()
.matrix_methods$get_ny <- function(.self) .self$.cpp$get_ny()
.matrix_methods$get_number_of_columns <- function(.self) .self$.cpp$get_ncol()
.matrix_methods$get_number_of_rows <- function(.self) .self$.cpp$get_nrow()
.matrix_methods$get_dx <- function(.self) .self$.cpp$get_dx()
.matrix_methods$get_dy <- function(.self) .self$.cpp$get_dy()
.matrix_methods$get_xmin <- function(.self) .self$.cpp$get_xmin()
.matrix_methods$get_xmax <- function(.self) .self$.cpp$get_xmax()
.matrix_methods$get_ymin <- function(.self) .self$.cpp$get_ymin()
.matrix_methods$get_ymax <- function(.self) .self$.cpp$get_ymax()
.matrix_methods$get_x1 <- function(.self) .self$.cpp$get_x1()
.matrix_methods$get_y1 <- function(.self) .self$.cpp$get_y1()

# Query - Values
.matrix_methods$get_value <- function(.self, row, col) {
  .self$.cpp$get_value(as.integer(row), as.integer(col))
}
.matrix_methods$set_value <- function(.self, row, col, value) {
  .self$.cpp$set_value(as.integer(row), as.integer(col), as.numeric(value))
  invisible(.self)
}
.matrix_methods$get_value_at_xy <- function(.self, x, y) {
  .self$.cpp$get_value_at_xy(as.numeric(x), as.numeric(y))
}

# Statistics
.matrix_methods$get_sum <- function(.self) .self$.cpp$get_sum()
.matrix_methods$get_mean <- function(.self) .self$.cpp$get_mean()
.matrix_methods$get_minimum <- function(.self) .self$.cpp$get_minimum()
.matrix_methods$get_maximum <- function(.self) .self$.cpp$get_maximum()

# Export
.matrix_methods$as_matrix <- function(.self) .matrix_to_r_matrix(.self$.xptr)

# I/O
.matrix_methods$save <- function(.self, path) {
  .self$.cpp$save(as.character(path))
  invisible(.self)
}

# Utility
.matrix_methods$get_xptr <- function(.self) .self$.xptr

# Print
.matrix_methods$print <- function(.self) {
  cat("<Praat Matrix>\n")
  cat(sprintf("  Dimensions: %d rows x %d columns\n",
              .self$.cpp$get_nrow(), .self$.cpp$get_ncol()))
  cat(
    sprintf("  X domain: %.3f to %.3f\n", .self$.cpp$get_xmin(),
      .self$.cpp$get_xmax()))
  cat(
    sprintf("  Y domain: %.3f to %.3f\n", .self$.cpp$get_ymin(),
      .self$.cpp$get_ymax()))
  invisible(.self)
}

.matrix_methods$is_valid <- function(.self) .self$.cpp$is_valid()
lockEnvironment(.matrix_methods, bindings = TRUE)

# ============================================================================
# S3 Dispatch
# ============================================================================

#' @method $ Matrix
#' @export
`$.Matrix` <- function(x, name) {
  val <- .subset2(x, name)
  if (!is.null(val)) return(val)
  method <- .matrix_methods[[name]]
  if (is.null(method)) return(NULL)
  function(...) method(x, ...)
}

# ============================================================================
# Constructor
# ============================================================================


# Check whether all full-domain Matrix construction parameters are present.
.matrix_has_full_params <- function(xmin, xmax, nx, dx, x1, ymin, ymax, ny,
  dy, y1) {
  !any(vapply(list(xmin, xmax, nx, dx, x1, ymin, ymax, ny, dy, y1),
             is.null, logical(1)))
}

#' @export
Matrix <- function(xmin = NULL, xmax = NULL, nx = NULL, dx = NULL, x1 = NULL,
                   ymin = NULL, ymax = NULL, ny = NULL, dy = NULL, y1 = NULL,
                   numberOfRows = NULL, numberOfColumns = NULL,
                   .xptr = NULL) {
  
  if (!is.null(.xptr)) {
    ptr <- .xptr
  } else if (!is.null(numberOfRows) && !is.null(numberOfColumns)) {
    ptr <- .matrix_create_simple(numberOfRows, numberOfColumns)
  } else if (
    .matrix_has_full_params(xmin, xmax, nx, dx, x1, ymin, ymax, ny, dy, y1)) {
    ptr <- .matrix_create(xmin, xmax, nx, dx, x1, ymin, ymax, ny, dy, y1)
  } else {
    stop(
      "Either provide (numberOfRows, numberOfColumns) or all full parameters")
  }
  
  mat_mod <- get_module("matrix_module")
  cpp_obj <- mat_mod$RMatrix$new(ptr)
  
  structure(list(
    .cpp = cpp_obj,
    .xptr = ptr
  ), class = c("Matrix", "PraatObject"))
}

#' @export
as.matrix.Matrix <- function(x, ...) x$as_matrix()

# Factory functions for backward compatibility

#' Create a Praat Matrix with full parameters
#'
#' Creates a new Matrix object with explicit domain and sampling parameters.
#'
#' @param xmin Minimum x value (start of x domain)
#' @param xmax Maximum x value (end of x domain)
#' @param nx Number of columns
#' @param dx X sampling period (step between columns)
#' @param x1 X value of first column
#' @param ymin Minimum y value (start of y domain)
#' @param ymax Maximum y value (end of y domain)
#' @param ny Number of rows
#' @param dy Y sampling period (step between rows)
#' @param y1 Y value of first row
#' @return A Matrix object
#' @seealso \code{\link{matrix_create_simple}} for simpler creation,
#'  \code{\link{Matrix}} for object methods
#' @examples
#' m <- matrix_create(xmin = 0, xmax = 2, nx = 2, dx = 1, x1 = 0.5,
#'                     ymin = 0, ymax = 1, ny = 1, dy = 1, y1 = 0.5)
#' m$get_number_of_rows()
#' m$get_number_of_columns()
#' @export
matrix_create <- function(xmin, xmax, nx, dx, x1, ymin, ymax, ny, dy, y1) {
  Matrix(xmin = xmin, xmax = xmax, nx = nx, dx = dx, x1 = x1,
         ymin = ymin, ymax = ymax, ny = ny, dy = dy, y1 = y1)
}

#' Create a simple Praat Matrix
#'
#' Creates a new Matrix object with given dimensions. Domain defaults to [0,1]
#'  for both axes.
#'
#' @inheritParams pladdrr_shared_analysis numberOfRows
#' @param numberOfColumns Number of columns
#' @return A Matrix object
#' @seealso \code{\link{matrix_create}} for full parameter control,
#'  \code{\link{Matrix}} for object methods
#' @examples
#' m <- matrix_create_simple(3, 4)
#' m$set_value(1, 1, 5.0)
#' m$get_value(1, 1)
#' @export
matrix_create_simple <- function(numberOfRows, numberOfColumns) {
  Matrix(numberOfRows = numberOfRows, numberOfColumns = numberOfColumns)
}

#' Read a Matrix from file
#'
#' Reads a Praat Matrix object from a text or binary file.
#'
#' @param path Path to the Matrix file
#' @return A Matrix object
#' @seealso \code{\link{matrix_create}}, \code{\link{matrix_create_simple}}
#' @examples
#' mat_file <- tempfile(fileext = ".Matrix")
#' m <- matrix_create_simple(1, 2)
#' m$set_value(1, 1, 1)
#' m$set_value(1, 2, 2)
#' m$save(mat_file)
#'
#' m2 <- matrix_read(mat_file)
#' m2$get_number_of_rows()
#' m2$get_value(1, 1)
#' @export
matrix_read <- function(path) {
  xptr <- .matrix_read(path)
  Matrix(.xptr = xptr)
}
