#' @title Praat AmplitudeTier Object
#' @description
#' Praat AmplitudeTier object with direct C++ module binding for amplitude analysis.
#'
#' @details
#' AmplitudeTier represents sound pressure amplitude in Pascals as a function of time,
#' stored as a sequence of (time, value) points with interpolation between points.
#'
#' @export
AmplitudeTier <- function(.xptr = NULL) {
  if (is.null(.xptr)) {
    stop("AmplitudeTier objects must be created using amplitude_tier_create() or related functions")
  }
  
  tier_mod <- get_module("amplitudetier_module")
  cpp_obj <- tier_mod$RAmplitudeTier$new(.xptr)
  
  obj <- structure(list(
    .cpp = cpp_obj,
    .xptr = .xptr,
    
    # Query
    get_start_time = function() cpp_obj$get_xmin(),
    get_end_time = function() cpp_obj$get_xmax(),
    get_number_of_points = function() cpp_obj$get_number_of_points(),
    get_time_from_index = function(index) cpp_obj$get_time(as.integer(index)),
    get_value_at_index = function(index) cpp_obj$get_value(as.integer(index)),
    get_value_at_time = function(time) cpp_obj$get_value_at_time(as.numeric(time)),
    
    # Modification
    add_point = function(time, value) {
      cpp_obj$add_point(as.numeric(time), as.numeric(value))
      invisible(obj)
    },
    remove_point = function(index) {
      cpp_obj$remove_point(as.integer(index))
      invisible(obj)
    },
    
    # Conversion
    to_intensity_tier = function(threshold_db = -200) {
      ptr <- .amplitudetier_to_intensitytier(.xptr, threshold_db)
      IntensityTier(.xptr = ptr)
    },
    
    # Shimmer measures
    get_shimmer_local = function(period_floor = 0.0001, period_ceiling = 0.02, max_period_factor = 1.3) {
      .amplitudetier_get_shimmer_local(.xptr, period_floor, period_ceiling, max_period_factor)
    },
    get_shimmer_local_db = function(period_floor = 0.0001, period_ceiling = 0.02, max_period_factor = 1.3) {
      .amplitudetier_get_shimmer_local_db(.xptr, period_floor, period_ceiling, max_period_factor)
    },
    get_shimmer_apq3 = function(period_floor = 0.0001, period_ceiling = 0.02, max_period_factor = 1.3) {
      .amplitudetier_get_shimmer_apq3(.xptr, period_floor, period_ceiling, max_period_factor)
    },
    get_shimmer_apq5 = function(period_floor = 0.0001, period_ceiling = 0.02, max_period_factor = 1.3) {
      .amplitudetier_get_shimmer_apq5(.xptr, period_floor, period_ceiling, max_period_factor)
    },
    get_shimmer_apq11 = function(period_floor = 0.0001, period_ceiling = 0.02, max_period_factor = 1.3) {
      .amplitudetier_get_shimmer_apq11(.xptr, period_floor, period_ceiling, max_period_factor)
    },
    get_shimmer_dda = function(period_floor = 0.0001, period_ceiling = 0.02, max_period_factor = 1.3) {
      .amplitudetier_get_shimmer_dda(.xptr, period_floor, period_ceiling, max_period_factor)
    },
    
    # Export
    as_data_frame = function() {
      n_points <- cpp_obj$get_number_of_points()
      if (n_points == 0) {
        return(data.frame(time = numeric(0), amplitude_pa = numeric(0)))
      }
      times <- numeric(n_points)
      values <- numeric(n_points)
      for (i in seq_len(n_points)) {
        times[i] <- cpp_obj$get_time(i)
        values[i] <- cpp_obj$get_value(i)
      }
      data.frame(time = times, amplitude_pa = values)
    },
    save = function(path) {
      .amplitudetier_save(.xptr, as.character(path))
      invisible(obj)
    },
    
    # Utility
    get_xptr = function() .xptr,
    .pointer = .xptr,  # For legacy compatibility
    
    # Print
    print = function() {
      cat("<Praat AmplitudeTier>\n")
      cat(sprintf("  Time domain: %.3f to %.3f s\n", cpp_obj$get_xmin(), cpp_obj$get_xmax()))
      cat(sprintf("  Number of points: %d\n", cpp_obj$get_number_of_points()))
      invisible(obj)
    }
  ), class = c("AmplitudeTier", "PraatObject"))
  
  obj
}

#' @export
print.AmplitudeTier <- function(x, ...) x$print()

#' @export
as.data.frame.AmplitudeTier <- function(x, ...) x$as_data_frame()

# Factory functions (keep existing exports)
#' @export
amplitude_tier_create <- function(tmin, tmax) {
  ptr <- amplitude_tier_create_cpp(tmin, tmax)
  AmplitudeTier(.xptr = ptr)
}

#' @export
amplitude_tier_from_point_process <- function(point_process, sound) {
  if (!inherits(point_process, "PointProcess")) {
    stop("point_process must be a PointProcess object")
  }
  if (!inherits(sound, "Sound")) {
    stop("sound must be a Sound object")
  }
  ptr <- point_process_sound_to_amplitude_tier_point_cpp(point_process$.pointer, sound$.pointer)
  AmplitudeTier(.xptr = ptr)
}

#' @export
intensity_tier_to_amplitude_tier <- function(intensity_tier) {
  if (!inherits(intensity_tier, "IntensityTier")) {
    stop("intensity_tier must be an IntensityTier object")
  }
  ptr <- intensity_tier_to_amplitude_tier_cpp(intensity_tier$.pointer)
  AmplitudeTier(.xptr = ptr)
}
