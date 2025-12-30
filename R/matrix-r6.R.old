#' Matrix Class
#'
#' R6 class representing a Praat Matrix object. Matrix objects represent
#' two-dimensional sampled data with x and y axes.
#'
#' @examples
#' \dontrun{
#' # Create a simple 10x5 matrix
#' mat <- Matrix$new(numberOfRows = 10, numberOfColumns = 5)
#' 
#' # Set and get values
#' mat$set_value(row = 3, col = 2, value = 42.0)
#' val <- mat$get_value(row = 3, col = 2)
#' 
#' # Get matrix dimensions
#' nrows <- mat$get_number_of_rows()
#' ncols <- mat$get_number_of_columns()
#' }
#' 
#' @export
Matrix <- R6::R6Class("Matrix",
  inherit = PraatObject,
  
  public = list(
    #' @description
    #' Create a new Matrix object
    #' @param xmin Minimum x value
    #' @param xmax Maximum x value
    #' @param nx Number of x samples
    #' @param dx X step size
    #' @param x1 First x value
    #' @param ymin Minimum y value
    #' @param ymax Maximum y value
    #' @param ny Number of y samples
    #' @param dy Y step size
    #' @param y1 First y value
    #' @param numberOfRows Simple matrix: number of rows
    #' @param numberOfColumns Simple matrix: number of columns
    #' @param .xptr Internal: external pointer to Praat Matrix object
    #' @return A new Matrix object
    initialize = function(xmin = NULL, xmax = NULL, nx = NULL, dx = NULL, x1 = NULL,
                         ymin = NULL, ymax = NULL, ny = NULL, dy = NULL, y1 = NULL,
                         numberOfRows = NULL, numberOfColumns = NULL,
                         .xptr = NULL) {
      if (!is.null(.xptr)) {
        if (!inherits(.xptr, "externalptr")) {
          stop(".xptr must be an external pointer")
        }
        private$ptr <- .xptr
      } else if (!is.null(numberOfRows) && !is.null(numberOfColumns)) {
        # Simple matrix creation
        private$ptr <- .matrix_create_simple(numberOfRows, numberOfColumns)
      } else if (!is.null(xmin) && !is.null(xmax) && !is.null(nx) && 
                 !is.null(dx) && !is.null(x1) && !is.null(ymin) && 
                 !is.null(ymax) && !is.null(ny) && !is.null(dy) && !is.null(y1)) {
        # Full matrix creation
        private$ptr <- .matrix_create(xmin, xmax, nx, dx, x1, ymin, ymax, ny, dy, y1)
      } else {
        stop("Either provide (numberOfRows, numberOfColumns) or all full parameters")
      }
    },
    
    # ========================================================================
    # Query methods - Structure
    # ========================================================================
    
    #' @description Get number of columns
    #' @return Integer number of columns
    get_nx = function() {
      .matrix_get_nx(private$ptr)
    },
    
    #' @description Get number of rows
    #' @return Integer number of rows
    get_ny = function() {
      .matrix_get_ny(private$ptr)
    },
    
    #' @description Get x step size
    #' @return Numeric x step
    get_dx = function() {
      .matrix_get_dx(private$ptr)
    },
    
    #' @description Get y step size
    #' @return Numeric y step
    get_dy = function() {
      .matrix_get_dy(private$ptr)
    },
    
    #' @description Get first x value
    #' @return Numeric first x
    get_x1 = function() {
      .matrix_get_x1(private$ptr)
    },
    
    #' @description Get first y value
    #' @return Numeric first y
    get_y1 = function() {
      .matrix_get_y1(private$ptr)
    },
    
    #' @description Get minimum x value
    #' @return Numeric xmin
    get_xmin = function() {
      .matrix_get_xmin(private$ptr)
    },
    
    #' @description Get maximum x value
    #' @return Numeric xmax
    get_xmax = function() {
      .matrix_get_xmax(private$ptr)
    },
    
    #' @description Get minimum y value
    #' @return Numeric ymin
    get_ymin = function() {
      .matrix_get_ymin(private$ptr)
    },
    
    #' @description Get maximum y value
    #' @return Numeric ymax
    get_ymax = function() {
      .matrix_get_ymax(private$ptr)
    },
    
    # ========================================================================
    # Query methods - Value access
    # ========================================================================
    
    #' @description Get value at continuous x,y coordinates
    #' @param x Numeric x coordinate
    #' @param y Numeric y coordinate
    #' @return Numeric value (interpolated)
    get_value_at_xy = function(x, y) {
      .matrix_get_value_at_xy(private$ptr, x, y)
    },
    
    #' @description Get value at row, column indices
    #' @param row Integer row number (1-based)
    #' @param col Integer column number (1-based)
    #' @return Numeric value
    get_value = function(row, col) {
      .matrix_get_value(private$ptr, row, col)
    },
    
    # ========================================================================
    # Modification methods
    # ========================================================================
    
    #' @description Set value at row, column indices
    #' @param row Integer row number (1-based)
    #' @param col Integer column number (1-based)
    #' @param value Numeric value
    set_value = function(row, col, value) {
      invisible(.matrix_set_value(private$ptr, row, col, value))
    },
    
    #' @description Apply formula to matrix
    #' @param formula Character string formula
    formula = function(formula) {
      invisible(.matrix_formula(private$ptr, formula))
    },
    
    # ========================================================================
    # Statistical methods
    # ========================================================================
    
    #' @description Get sum of all values
    #' @return Numeric sum
    get_sum = function() {
      .matrix_get_sum(private$ptr)
    },
    
    #' @description Get mean of all values
    #' @return Numeric mean
    get_mean = function() {
      .matrix_get_mean(private$ptr)
    },
    
    #' @description Get minimum value
    #' @return Numeric minimum
    get_minimum = function() {
      .matrix_get_minimum(private$ptr)
    },
    
    #' @description Get maximum value
    #' @return Numeric maximum
    get_maximum = function() {
      .matrix_get_maximum(private$ptr)
    },
    
    # ========================================================================
    # Conversion methods
    # ========================================================================
    
    #' @description Convert matrix to R matrix
    #' @return Numeric matrix
    to_matrix = function() {
      .matrix_to_r_matrix(private$ptr)
    }
  )
)

#' Create a Matrix object
#'
#' @param xmin Minimum x value
#' @param xmax Maximum x value
#' @param nx Number of x samples
#' @param dx X step size
#' @param x1 First x value
#' @param ymin Minimum y value
#' @param ymax Maximum y value
#' @param ny Number of y samples
#' @param dy Y step size
#' @param y1 First y value
#' @return A Matrix object
#' @export
praat_matrix <- function(xmin, xmax, nx, dx, x1, ymin, ymax, ny, dy, y1) {
  Matrix$new(xmin = xmin, xmax = xmax, nx = nx, dx = dx, x1 = x1,
             ymin = ymin, ymax = ymax, ny = ny, dy = dy, y1 = y1)
}

#' Create a simple Matrix object
#'
#' @param numberOfRows Integer number of rows
#' @param numberOfColumns Integer number of columns
#' @return A Matrix object
#' @export
praat_matrix_simple <- function(numberOfRows, numberOfColumns) {
  Matrix$new(numberOfRows = numberOfRows, numberOfColumns = numberOfColumns)
}

#' Create Matrix from R matrix
#'
#' @param rmatrix Numeric R matrix
#' @return A Matrix object
#' @export
praat_matrix_from_matrix <- function(rmatrix) {
  xptr <- .matrix_from_r_matrix(rmatrix)
  Matrix$new(.xptr = xptr)
}
