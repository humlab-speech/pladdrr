# Polygon Object - Rcpp Module Wrapper
# 2D polygon representation for geometric operations

#' Polygon Object
#'
#' @description
#' 2D polygon for geometric operations and spatial analysis.
#' Uses Rcpp Modules for high-performance access to Praat's Polygon object.
#' 
#' **Common uses:**
#' - Vowel space boundaries
#' - Formant space visualization
#' - Acoustic space analysis
#' - Convex hull computation
#' 
#' @param x Numeric vector of x coordinates
#' @param y Numeric vector of y coordinates
#' @return Polygon object with methods for geometry operations
#' 
#' @examples
#' \dontrun{
#' # Create polygon from formant data
#' poly <- Polygon(x = c(730, 1090, 2440), y = c(1090, 1220, 2440))
#' 
#' # Geometry queries
#' perimeter <- poly$get_perimeter()
#' n_points <- poly$get_number_of_points()
#' 
#' # Optimize path (traveling salesman)
#' poly$optimize_salesperson(iterations = 100)
#' 
#' # Export
#' df <- as.data.frame(poly)
#' }
#' 
#' @export
Polygon <- function(x, y) {
  if (missing(x) || missing(y)) {
    stop("Both x and y coordinates required")
  }
  if (length(x) != length(y)) {
    stop("x and y must have same length")
  }
  if (length(x) < 1) {
    stop("At least 1 point required")
  }
  
  # Load Rcpp Module
  poly_mod <- get_module("polygon_module")
  if (is.null(poly_mod)) {
    stop("polygon_module not available - package installation may be incomplete")
  }
  
  # Create XPtr first, then wrap in module class
  xptr <- poly_mod$polygon_create_xptr(
    as.numeric(x), 
    as.numeric(y)
  )
  
  # Wrap in module class
  cpp_obj <- poly_mod$RPolygon$new(xptr)
  
  # Create wrapper object
  obj <- structure(list(
    .cpp = cpp_obj,
    
    # Properties
    is_valid = function() cpp_obj$is_valid(),
    n_points = function() cpp_obj$get_number_of_points(),
    
    # Data access (1-based indexing for users, converted internally)
    get_x = function(i) cpp_obj$get_x(as.integer(i)),
    get_y = function(i) cpp_obj$get_y(as.integer(i)),
    get_all_x = function() cpp_obj$get_all_x(),
    get_all_y = function() cpp_obj$get_all_y(),
    
    # Geometry
    get_perimeter = function() cpp_obj$get_perimeter(),
    randomize = function() {
      cpp_obj$randomize()
      invisible(obj)
    },
    optimize_salesperson = function(iterations = 100) {
      cpp_obj$optimize_salesperson(as.integer(iterations))
      invisible(obj)
    },
    
    # Export
    as_data_frame = function() cpp_obj$as_data_frame(),
    as_matrix = function() cpp_obj$as_matrix(),
    save = function(path) {
      cpp_obj$save(as.character(path))
      invisible(obj)
    },
    
    # Print method
    print = function() {
      cat("<Praat Polygon (Module)>\n")
      
      if (cpp_obj$is_valid()) {
        n <- cpp_obj$get_number_of_points()
        cat(sprintf("  Points: %d\n", n))
        
        tryCatch({
          perim <- cpp_obj$get_perimeter()
          if (!is.na(perim)) {
            cat(sprintf("  Perimeter: %.3f\n", perim))
          }
        }, error = function(e) {})
        
        # Show first few points
        if (n > 0) {
          show_n <- min(3, n)
          cat("  First points:\n")
          for (i in 1:show_n) {
            x_val <- cpp_obj$get_x(i)
            y_val <- cpp_obj$get_y(i)
            cat(sprintf("    %d: (%.3f, %.3f)\n", i, x_val, y_val))
          }
          if (n > 3) {
            cat(sprintf("    ... (%d more points)\n", n - 3))
          }
        }
      } else {
        cat("  [Invalid object]\n")
      }
      
      invisible(obj)
    }
  ), class = c("Polygon", "PraatObject"))
  
  obj
}

#' @export
print.Polygon <- function(x, ...) {
  x$print()
}

#' @export
as.data.frame.Polygon <- function(x, row.names = NULL, optional = FALSE, ...) {
  x$as_data_frame()
}

#' @export
as.matrix.Polygon <- function(x, ...) {
  x$as_matrix()
}
