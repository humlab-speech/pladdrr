#' @title Praat IntensityTier Object
#' @description
#' Praat IntensityTier object with direct C++ module binding for intensity manipulation.
#'
#' @details
#' IntensityTiers contain discrete time-value pairs representing intensity in dB SPL.
#' They can be used to modify the amplitude envelope of sounds.
#'
#' @export
IntensityTier <- function(tmin = NULL, tmax = NULL, .xptr = NULL) {
  
  # Handle creation modes
  if (!is.null(.xptr)) {
    ptr <- .xptr
  } else if (!is.null(tmin) && !is.null(tmax)) {
    ptr <- .intensitytier_create(as.numeric(tmin), as.numeric(tmax))
  } else {
    stop("Must provide either (tmin, tmax) or .xptr")
  }
  
  tier_mod <- get_module("intensitytier_module")
  cpp_obj <- tier_mod$RIntensityTier$new(ptr)
  
  obj <- structure(list(
    .cpp = cpp_obj,
    .xptr = ptr,
    
    # Query
    get_start_time = function() cpp_obj$get_xmin(),
    get_end_time = function() cpp_obj$get_xmax(),
    get_number_of_points = function() cpp_obj$get_number_of_points(),
    get_time_from_index = function(index) cpp_obj$get_time(as.integer(index)),
    get_value_at_index = function(index) cpp_obj$get_value(as.integer(index)),
    get_value_at_time = function(time) cpp_obj$get_value_at_time(as.numeric(time)),
    get_mean = function(tmin = NULL, tmax = NULL) {
      if (is.null(tmin)) tmin <- cpp_obj$get_xmin()
      if (is.null(tmax)) tmax <- cpp_obj$get_xmax()
      cpp_obj$get_mean_curve(as.numeric(tmin), as.numeric(tmax))
    },
    
    # Modification
    add_point = function(time, value) {
      cpp_obj$add_point(as.numeric(time), as.numeric(value))
      invisible(obj)
    },
    remove_point = function(index) {
      cpp_obj$remove_point(as.integer(index))
      invisible(obj)
    },
    
    # Export
    as_data_frame = function() {
      df <- cpp_obj$as_data_frame()
      names(df) <- c("time", "intensity_db")
      df
    },
    save = function(path) {
      cpp_obj$save(as.character(path))
      invisible(obj)
    },
    
    # Utility
    get_xptr = function() .xptr,
    
    # Print
    print = function() {
      cat("<Praat IntensityTier>\n")
      cat(sprintf("  Time domain: %.3f to %.3f s\n", cpp_obj$get_xmin(), cpp_obj$get_xmax()))
      n_points <- cpp_obj$get_number_of_points()
      cat(sprintf("  Number of points: %d\n", n_points))
      if (n_points > 0) {
        mean_int <- cpp_obj$get_mean_curve(cpp_obj$get_xmin(), cpp_obj$get_xmax())
        cat(sprintf("  Mean intensity: %.1f dB\n", mean_int))
      }
      invisible(obj)
    }
  ), class = c("IntensityTier", "PraatObject"))
  
  obj
}

#' @export
print.IntensityTier <- function(x, ...) x$print()

#' @export
as.data.frame.IntensityTier <- function(x, ...) x$as_data_frame()
