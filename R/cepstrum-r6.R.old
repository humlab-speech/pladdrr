#' Cepstrum R6 Class
#'
#' @description
#' Represents a complex cepstrum object from Praat.
#' The cepstrum is the inverse Fourier transform of the logarithm of the spectrum.
#'
#' @details
#' Unlike PowerCepstrum which only contains magnitude information, the Cepstrum
#' preserves phase information from the original signal. It can be converted
#' back to Sound or Spectrum.
#'
#' ## Creating Cepstrum Objects
#'
#' Cepstrum objects are created from Sound or Spectrum objects:
#' - `sound$to_cepstrum()` - Convert Sound to Cepstrum
#' - `sound$to_cepstrum_bw()` - Convert Sound to bandwidth-weighted Cepstrum
#' - `spectrum$to_cepstrum()` - Convert Spectrum to Cepstrum
#' - `spectrum$to_cepstrum_hillenbrand()` - Convert using Hillenbrand method
#'
#' ## Conversion Methods
#'
#' - `$to_sound()` - Convert back to Sound
#' - `$to_spectrum()` - Convert to Spectrum
#' - `$to_powercepstrum()` - Convert to PowerCepstrum (magnitude only)
#'
#' @examples
#' \dontrun{
#' # Create cepstrum and convert back
#' sound <- Sound$new("voice.wav")
#' cepstrum <- sound$to_cepstrum()
#' reconstructed <- cepstrum$to_sound()
#' }
#'
#' @export
Cepstrum <- R6::R6Class(
  "Cepstrum",
  public = list(
    #' @field .xptr External pointer to Praat Cepstrum object
    .xptr = NULL,
    
    #' @description
    #' Create a new Cepstrum object (internal use)
    #' @param .xptr External pointer to Praat object
    initialize = function(.xptr) {
      if (!inherits(.xptr, "externalptr")) {
        stop(".xptr must be an external pointer")
      }
      private$ptr <- .xptr
    },
    
    #' @description
    #' Convert Cepstrum to Sound
    #' 
    #' Reconstructs the original Sound from the Cepstrum by applying
    #' inverse transformations. This preserves phase information.
    #' 
    #' @return Sound object
    to_sound = function() {
      xptr <- .cepstrum_to_sound(private$ptr)
      Sound$new(xptr)
    },
    
    #' @description
    #' Convert Cepstrum to Spectrum
    #' 
    #' Converts the cepstrum to its corresponding spectrum representation.
    #' 
    #' @return Spectrum object
    to_spectrum = function() {
      xptr <- .cepstrum_to_spectrum(private$ptr)
      Spectrum(xptr)
    },
    
    #' @description
    #' Convert Cepstrum to PowerCepstrum
    #' 
    #' Extracts magnitude information only, discarding phase.
    #' The resulting PowerCepstrum can be used for CPP analysis.
    #' 
    #' @return PowerCepstrum object
    to_powercepstrum = function() {
      xptr <- .cepstrum_to_powercepstrum(private$ptr)
      PowerCepstrum$new(xptr)
    }
  ),

  private = list(
    ptr = NULL
  )
)
