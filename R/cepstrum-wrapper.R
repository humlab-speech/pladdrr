#' @title Praat Cepstrum Object
#' @description
#' Praat Cepstrum object with direct C++ module binding.
#'
#' @details
#' The cepstrum is the inverse Fourier transform of the logarithm of the spectrum.
#' Unlike PowerCepstrum, it preserves phase information.
#'
#' @export
Cepstrum <- function(.xptr) {
  if (!inherits(.xptr, "externalptr")) {
    stop(".xptr must be an external pointer")
  }
  
  ceps_mod <- get_module("cepstrum_module")
  cpp_obj <- ceps_mod$RCepstrum$new(.xptr)
  
  obj <- structure(list(
    .cpp = cpp_obj,
    .xptr = .xptr,
    
    # Conversion
    to_sound = function() {
      xptr <- .cepstrum_to_sound(.xptr)
      Sound$new(xptr)
    },
    to_spectrum = function() {
      xptr <- .cepstrum_to_spectrum(.xptr)
      Spectrum(.xptr = xptr)
    },
    to_powercepstrum = function() {
      xptr <- .cepstrum_to_powercepstrum(.xptr)
      PowerCepstrum(.xptr = xptr)
    },
    # Praat-compatible alias (underscore variant)
    to_power_cepstrum = function() {
      xptr <- .cepstrum_to_powercepstrum(.xptr)
      PowerCepstrum(.xptr = xptr)
    },
    
    # Utility
    get_xptr = function() .xptr,
    
    # Print
    print = function() {
      cat("<Praat Cepstrum>\n")
      cat(sprintf("  Quefrency range: %.4f to %.4f s\n", cpp_obj$get_qmin(), cpp_obj$get_qmax()))
      cat(sprintf("  Number of coefficients: %d\n", cpp_obj$get_number_of_coefficients()))
      invisible(obj)
    }
  ), class = c("Cepstrum", "PraatObject"))
  
  obj
}

#' @export
print.Cepstrum <- function(x, ...) x$print()
