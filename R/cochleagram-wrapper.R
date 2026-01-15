#' @title Praat Cochleagram Object
#' @description
#' Praat Cochleagram object with direct C++ module binding for auditory modeling.
#'
#' @details
#' A Cochleagram represents the output of a bank of auditory filters arranged
#' along the basilar membrane. Frequency is measured in Bark units (0-25.6 Bark).
#'
#' @export
Cochleagram <- function(.xptr) {
  if (missing(.xptr) || is.null(.xptr)) {
    stop("Cochleagram objects should be created via Sound$to_cochleagram() or Sound$to_cochleagram_edb()")
  }
  
  coch_mod <- get_module("cochleagram_module")
  cpp_obj <- coch_mod$RCochleagram$new(.xptr)
  
  obj <- structure(list(
    .cpp = cpp_obj,
    .xptr = .xptr,
    
    # Query - Time domain
    get_start_time = function() cpp_obj$get_xmin(),
    get_end_time = function() cpp_obj$get_xmax(),
    get_duration = function() cpp_obj$get_duration(),
    get_number_of_frames = function() cpp_obj$get_number_of_frames(),
    get_time_step = function() cpp_obj$get_time_step(),
    get_time_from_column = function(i_col) cpp_obj$get_time_from_column(as.integer(i_col)),
    
    # Query - Frequency domain
    get_lowest_frequency = function() cpp_obj$get_ymin(),
    get_highest_frequency = function() cpp_obj$get_ymax(),
    get_number_of_frequency_bands = function() cpp_obj$get_number_of_frequency_bands(),
    get_frequency_step = function() cpp_obj$get_frequency_step(),
    get_frequency_from_row = function(i_row) cpp_obj$get_frequency_from_row(as.integer(i_row)),
    
    # Query - Values
    get_value_at_time_and_frequency = function(time, freq_bark) {
      cpp_obj$get_value_at_time_and_frequency(as.numeric(time), as.numeric(freq_bark))
    },
    
    # Transformations
    to_excitation = function(time) {
      xptr <- .cochleagram_to_excitation(.xptr, as.numeric(time))
      Excitation(.xptr = xptr)
    },
    
    get_difference = function(other, tmin = 0, tmax = 0) {
      if (!inherits(other, "Cochleagram")) stop("other must be a Cochleagram object")
      cpp_obj$get_difference(other$.xptr, as.numeric(tmin), as.numeric(tmax))
    },
    
    # Export
    as_matrix = function() {
      mat_list <- cpp_obj$as_matrix()
      list(
        values = mat_list$values,
        times = mat_list$times,
        frequencies = mat_list$frequencies
      )
    },
    
    # Utility
    get_xptr = function() .xptr,
    
    # Print
    print = function() {
      cat("<Praat Cochleagram>\n")
      cat(sprintf("  Time domain: %.3f to %.3f s\n", cpp_obj$get_xmin(), cpp_obj$get_xmax()))
      cat(sprintf("  Frequency range: %.2f to %.2f Bark\n", cpp_obj$get_ymin(), cpp_obj$get_ymax()))
      cat(sprintf("  %d frames × %d frequency bands\n", 
                  cpp_obj$get_number_of_frames(), cpp_obj$get_number_of_frequency_bands()))
      invisible(obj)
    }
  ), class = c("Cochleagram", "PraatObject"))
  
  obj
}

#' @export
print.Cochleagram <- function(x, ...) x$print()
