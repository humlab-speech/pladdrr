#' BarkSpectrogram
#'
#' A Bark-scale spectrogram, used in psychoacoustic and perceptual analysis
#' of speech.
#'
#' @param .xptr Not for direct use. External pointer to the underlying C++
#'   BarkSpectrogram object; set internally by \code{Sound$to_bark_spectrogram()}.
#' @return A BarkSpectrogram object.
#'
#' @examples
#' snd <- Sound$create_tone(frequency = 150, duration = 0.3)
#' bark <- snd$to_bark_spectrogram()
#'
#' # Export as matrix
#' mat <- bark$as_matrix()
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
print.BarkSpectrogram <- function(x, ...) {
  x$print()
  invisible(x)
}
