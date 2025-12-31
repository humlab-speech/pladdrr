#' @title Praat DurationTier Object
#' @description
#' Praat DurationTier object with direct C++ module binding for duration manipulation.
#'
#' @details
#' DurationTiers are used in conjunction with Manipulation objects to modify the
#' duration/tempo of sounds. Values represent duration multiplication factors:
#' - 1.0 = normal speed
#' - 2.0 = half speed (doubled duration)
#' - 0.5 = double speed (halved duration)
#'
#' @export
DurationTier <- function(tmin = NULL, tmax = NULL, .xptr = NULL) {
  
  if (!is.null(.xptr)) {
    ptr <- .xptr
  } else if (!is.null(tmin) && !is.null(tmax)) {
    ptr <- .durationtier_create(as.numeric(tmin), as.numeric(tmax))
  } else {
    stop("Must provide either (tmin, tmax) or .xptr")
  }
  
  tier_mod <- get_module("durationtier_module")
  cpp_obj <- tier_mod$RDurationTier$new(ptr)
  
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
      n_points <- cpp_obj$get_number_of_points()
      if (n_points == 0) {
        return(data.frame(time = numeric(0), duration_factor = numeric(0)))
      }
      times <- numeric(n_points)
      values <- numeric(n_points)
      for (i in seq_len(n_points)) {
        times[i] <- cpp_obj$get_time(i)
        values[i] <- cpp_obj$get_value(i)
      }
      data.frame(time = times, duration_factor = values)
    },
    save = function(path) {
      .durationtier_save(.xptr, as.character(path))
      invisible(obj)
    },
    
    # Utility
    get_xptr = function() .xptr,
    
    # Print
    print = function() {
      cat("<Praat DurationTier>\n")
      cat(sprintf("  Time domain: %.3f to %.3f s\n", cpp_obj$get_xmin(), cpp_obj$get_xmax()))
      cat(sprintf("  Number of points: %d\n", cpp_obj$get_number_of_points()))
      invisible(obj)
    }
  ), class = c("DurationTier", "PraatObject"))
  
  obj
}

#' @export
print.DurationTier <- function(x, ...) x$print()

#' @export
as.data.frame.DurationTier <- function(x, ...) x$as_data_frame()
