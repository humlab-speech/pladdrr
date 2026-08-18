#' MelSpectrogram
#'
#' A mel-scale spectrogram, commonly used in speech technology (ASR, speaker
#' identification).
#'
#' @param .xptr Not for direct use. External pointer to the underlying C++
#'   MelSpectrogram object; set internally by \code{Sound$to_mel_spectrogram()}.
#' @return A MelSpectrogram object.
#'
#' @examples
#' snd <- Sound$create_tone(frequency = 150, duration = 0.3)
#' mel <- snd$to_mel_spectrogram()
#'
#' # Convert to MFCC
#' mfcc <- mel$to_mfcc(number_of_coefficients = 12)
#'
#' # Export as matrix
#' mat <- mel$as_matrix()
#'
#' @export
MelSpectrogram <- function(.xptr = NULL) {
  if (is.null(.xptr)) {
    stop("MelSpectrogram objects must be created from Sound$to_mel_spectrogram()")
  }

  ptr <- .xptr

  obj <- structure(list(
    .xptr = .xptr,

    to_mfcc = function(number_of_coefficients = 12L) {
      mfcc_ptr <- .mel_spectrogram_to_mfcc(ptr, as.integer(number_of_coefficients))
      MFCC(.xptr = mfcc_ptr)
    },

    to_matrix = function(to_db = TRUE) {
      mat_ptr <- .band_filter_spectrogram_to_matrix(ptr, to_db)
      Matrix(.xptr = mat_ptr)
    },

    to_intensity = function() {
      int_ptr <- .band_filter_spectrogram_to_intensity(ptr)
      Intensity(.xptr = int_ptr)
    },

    as_matrix = function(to_db = TRUE) {
      mat_obj <- obj$to_matrix(to_db)
      mat_obj$as_matrix()
    },

    print = function() {
      cat("<Praat MelSpectrogram>\n")
      invisible(obj)
    }

  ), class = c("MelSpectrogram", "PraatObject"))

  obj
}

#' @exportS3Method print MelSpectrogram
print.MelSpectrogram <- function(x, ...) {
  x$print()
  invisible(x)
}
