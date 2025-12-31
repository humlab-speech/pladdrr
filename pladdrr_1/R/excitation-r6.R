#' @title Praat Excitation Object
#' @description
#' Praat Excitation object with direct C++ module binding for auditory modeling.
#'
#' @details
#' An Excitation pattern represents the perceptual loudness distribution across
#' the auditory frequency range, measured in Bark scale.
#'
#' @export
Excitation <- function(.xptr) {
  if (missing(.xptr) || is.null(.xptr)) {
    stop("Excitation objects should be created via Spectrum$to_excitation() or Cochleagram$to_excitation()")
  }
  
  exc_mod <- get_module("excitation_module")
  cpp_obj <- exc_mod$RExcitation$new(.xptr)
  
  obj <- structure(list(
    .cpp = cpp_obj,
    .xptr = .xptr,
    
    # Query
    get_loudness = function() cpp_obj$get_loudness(),
    get_value_at_frequency = function(freq_bark) {
      cpp_obj$get_value_at_frequency(as.numeric(freq_bark))
    },
    get_distance = function(other) {
      if (!inherits(other, "Excitation")) stop("other must be an Excitation object")
      cpp_obj$get_distance(other$.xptr)
    },
    
    # Conversion
    to_formant = function(max_formants = 20) {
      ptr <- .excitation_to_formant(.xptr, as.integer(max_formants))
      Formant(.xptr = ptr)
    },
    
    # Export
    as_vector = function() {
      v <- cpp_obj$as_vector()
      names(v) <- paste0("bin_", seq_along(v))
      v
    },
    as_data_frame = function() {
      df <- cpp_obj$as_data_frame()
      names(df) <- c("frequency_bark", "excitation")
      df
    },
    
    # Utility
    get_xptr = function() .xptr,
    
    # Print
    print = function() {
      cat("<Praat Excitation>\n")
      cat(sprintf("  Frequency range: %.2f to %.2f Bark\n", cpp_obj$get_fmin(), cpp_obj$get_fmax()))
      cat(sprintf("  Number of bins: %d\n", cpp_obj$get_number_of_bins()))
      cat(sprintf("  Loudness: %.2f sones\n", cpp_obj$get_loudness()))
      invisible(obj)
    }
  ), class = c("Excitation", "PraatObject"))
  
  obj
}

#' @export
print.Excitation <- function(x, ...) x$print()

#' @export
as.data.frame.Excitation <- function(x, ...) x$as_data_frame()
