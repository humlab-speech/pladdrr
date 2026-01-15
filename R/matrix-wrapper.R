#' @title Praat Matrix Object
#' @description
#' Praat Matrix object with direct C++ module binding for matrix operations.
#'
#' @details
#' Matrix objects represent two-dimensional sampled data with x and y axes.
#'
#' @export
Matrix <- function(xmin = NULL, xmax = NULL, nx = NULL, dx = NULL, x1 = NULL,
                   ymin = NULL, ymax = NULL, ny = NULL, dy = NULL, y1 = NULL,
                   numberOfRows = NULL, numberOfColumns = NULL,
                   .xptr = NULL) {
  
  if (!is.null(.xptr)) {
    ptr <- .xptr
  } else if (!is.null(numberOfRows) && !is.null(numberOfColumns)) {
    ptr <- .matrix_create_simple(numberOfRows, numberOfColumns)
  } else if (!is.null(xmin) && !is.null(xmax) && !is.null(nx) && 
             !is.null(dx) && !is.null(x1) && !is.null(ymin) && 
             !is.null(ymax) && !is.null(ny) && !is.null(dy) && !is.null(y1)) {
    ptr <- .matrix_create(xmin, xmax, nx, dx, x1, ymin, ymax, ny, dy, y1)
  } else {
    stop("Either provide (numberOfRows, numberOfColumns) or all full parameters")
  }
  
  mat_mod <- get_module("matrix_module")
  cpp_obj <- mat_mod$RMatrix$new(ptr)
  
  obj <- structure(list(
    .cpp = cpp_obj,
    .xptr = ptr,
    
    # Query - Structure
    get_nx = function() cpp_obj$get_nx(),
    get_ny = function() cpp_obj$get_ny(),
    get_number_of_columns = function() cpp_obj$get_ncol(),
    get_number_of_rows = function() cpp_obj$get_nrow(),
    get_dx = function() cpp_obj$get_dx(),
    get_dy = function() cpp_obj$get_dy(),
    get_xmin = function() cpp_obj$get_xmin(),
    get_xmax = function() cpp_obj$get_xmax(),
    get_ymin = function() cpp_obj$get_ymin(),
    get_ymax = function() cpp_obj$get_ymax(),
    
    # Query - Values
    get_value = function(row, col) {
      cpp_obj$get_value(as.integer(row), as.integer(col))
    },
    set_value = function(row, col, value) {
      cpp_obj$set_value(as.integer(row), as.integer(col), as.numeric(value))
      invisible(obj)
    },
    get_value_at_xy = function(x, y) {
      cpp_obj$get_value_at_xy(as.numeric(x), as.numeric(y))
    },
    
    # Statistics
    get_sum = function() cpp_obj$get_sum(),
    get_mean = function() cpp_obj$get_mean(),
    get_minimum = function() cpp_obj$get_minimum(),
    get_maximum = function() cpp_obj$get_maximum(),
    
    # Export
    as_matrix = function() {
      .matrix_to_r(ptr)
    },
    
    # Utility
    get_xptr = function() ptr,
    
    # Print
    print = function() {
      cat("<Praat Matrix>\n")
      cat(sprintf("  Dimensions: %d rows × %d columns\n", cpp_obj$get_nrow(), cpp_obj$get_ncol()))
      cat(sprintf("  X domain: %.3f to %.3f\n", cpp_obj$get_xmin(), cpp_obj$get_xmax()))
      cat(sprintf("  Y domain: %.3f to %.3f\n", cpp_obj$get_ymin(), cpp_obj$get_ymax()))
      invisible(obj)
    }
  ), class = c("Matrix", "PraatObject"))
  
  obj
}

#' @export
print.Matrix <- function(x, ...) x$print()

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
#' @seealso [matrix_create_simple()] for simpler creation, [Matrix] for object methods
#' @export
matrix_create <- function(xmin, xmax, nx, dx, x1, ymin, ymax, ny, dy, y1) {
  Matrix(xmin = xmin, xmax = xmax, nx = nx, dx = dx, x1 = x1,
         ymin = ymin, ymax = ymax, ny = ny, dy = dy, y1 = y1)
}

#' Create a simple Praat Matrix
#'
#' Creates a new Matrix object with given dimensions. Domain defaults to [0,1] for both axes.
#'
#' @param numberOfRows Number of rows
#' @param numberOfColumns Number of columns
#' @return A Matrix object
#' @seealso [matrix_create()] for full parameter control, [Matrix] for object methods
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
#' @seealso [matrix_create()], [matrix_create_simple()]
#' @export
matrix_read <- function(path) {
  xptr <- .matrix_read(path)
  Matrix(.xptr = xptr)
}
