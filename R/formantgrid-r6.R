#' @title Praat FormantGrid Object
#' @description
#' Praat FormantGrid object with direct C++ module binding for formant manipulation.
#'
#' @details
#' FormantGrid objects allow manipulation of formant frequencies and bandwidths
#' over time for voice transformation and synthesis. This is the editable
#' counterpart to the read-only Formant object.
#'
#' @export
FormantGrid <- function(tmin = NULL, tmax = NULL, number_of_formants = 10,
                        initial_first_formant = 550, initial_formant_spacing = 1100,
                        initial_first_bandwidth = 60, initial_bandwidth_spacing = 50,
                        .xptr = NULL) {
  
  if (!is.null(.xptr)) {
    ptr <- .xptr
  } else {
    stopifnot(
      "tmin and tmax must be provided" = !is.null(tmin) && !is.null(tmax),
      "tmin must be less than tmax" = tmin < tmax,
      "number_of_formants must be positive" = number_of_formants > 0
    )
    ptr <- .formantgrid_create(
      tmin, tmax, as.integer(number_of_formants),
      initial_first_formant, initial_formant_spacing,
      initial_first_bandwidth, initial_bandwidth_spacing
    )
  }
  
  grid_mod <- get_module("formantgrid_module")
  cpp_obj <- grid_mod$RFormantGrid$new(ptr)
  
  obj <- structure(list(
    .cpp = cpp_obj,
    .xptr = ptr,
    
    # Query - Time domain
    get_start_time = function() cpp_obj$get_xmin(),
    get_end_time = function() cpp_obj$get_xmax(),
    get_number_of_formants = function() cpp_obj$get_number_of_formants(),
    
    # Query - Values
    get_formant_at_time = function(formant_number, time) {
      cpp_obj$get_formant_at_time(as.integer(formant_number), as.numeric(time))
    },
    get_bandwidth_at_time = function(formant_number, time) {
      cpp_obj$get_bandwidth_at_time(as.integer(formant_number), as.numeric(time))
    },
    
    # Modification
    add_formant_point = function(formant_number, time, value) {
      cpp_obj$add_formant_point(as.integer(formant_number), as.numeric(time), as.numeric(value))
      invisible(obj)
    },
    add_bandwidth_point = function(formant_number, time, value) {
      cpp_obj$add_bandwidth_point(as.integer(formant_number), as.numeric(time), as.numeric(value))
      invisible(obj)
    },
    remove_formant_points_between = function(formant_number, tmin, tmax) {
      cpp_obj$remove_formant_points_between(as.integer(formant_number), as.numeric(tmin), as.numeric(tmax))
      invisible(obj)
    },
    remove_bandwidth_points_between = function(formant_number, tmin, tmax) {
      cpp_obj$remove_bandwidth_points_between(as.integer(formant_number), as.numeric(tmin), as.numeric(tmax))
      invisible(obj)
    },
    
    # Conversion
    to_formant = function(time_step = 0.005, intensity = 1.0, first_frequency = 100, 
                          ceiling = 0, bandwidth_fraction = 1.0) {
      ptr_out <- .formantgrid_to_formant(ptr, time_step, intensity, first_frequency, ceiling, bandwidth_fraction)
      Formant(.xptr = ptr_out)
    },
    
    # Export
    as_data_frame = function() {
      df <- cpp_obj$as_data_frame()
      names(df) <- c("formant_number", "time", "frequency", "bandwidth")
      df
    },
    save = function(path) {
      cpp_obj$save(as.character(path))
      invisible(obj)
    },
    
    # Utility
    get_xptr = function() ptr,
    
    # Print
    print = function() {
      cat("<Praat FormantGrid>\n")
      cat(sprintf("  Time domain: %.3f to %.3f s\n", cpp_obj$get_xmin(), cpp_obj$get_xmax()))
      cat(sprintf("  Number of formants: %d\n", cpp_obj$get_number_of_formants()))
      invisible(obj)
    }
  ), class = c("FormantGrid", "PraatObject"))
  
  obj
}

#' @export
print.FormantGrid <- function(x, ...) x$print()

#' @export
as.data.frame.FormantGrid <- function(x, ...) x$as_data_frame()
