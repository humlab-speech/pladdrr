#' BarkSpectrogram Object
#'
#' @description
#' Praat BarkSpectrogram: Bark-scale spectrogram used in psychoacoustic
#' and perceptual analysis of speech.
#'
#' @param .xptr Internal use only - external pointer to C++ BarkSpectrogram object
#' @return A BarkSpectrogram object
#'
#' @examples
#' \dontrun{
#' snd <- Sound("speech.wav")
#' bark <- snd$to_bark_spectrogram()
#'
#' # Export as matrix
#' mat <- bark$as_matrix()
#' }
#'
#' @export
BarkSpectrogram <- function(.xptr = NULL) {
  if (is.null(.xptr)) {
    stop("BarkSpectrogram objects must be created from Sound$to_bark_spectrogram()")
  }

  ptr <- .xptr

  obj <- structure(list(
    .xptr = .xptr,

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
      cat("<Praat BarkSpectrogram>\n")
      invisible(obj)
    }

  ), class = c("BarkSpectrogram", "PraatObject"))

  obj
}

#' @exportS3Method print BarkSpectrogram
print.BarkSpectrogram <- function(x, ...) x$print()
