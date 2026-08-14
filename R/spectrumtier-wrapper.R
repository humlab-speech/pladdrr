# spectrumtier-wrapper.R - SpectrumTier object using shared dispatch table (pladdrr 5.0.3)
# Architecture: minimal list + $.SpectrumTier S3 dispatch -> shared method env

#' SpectrumTier
#'
#' Holds the frequency peaks picked out of a long-term average spectrum.
#'
#' A SpectrumTier is the result of peak-picking an \link{Ltas}: each point is
#' one local maximum, recorded as a frequency and its power in dB. Use it to
#' pull out harmonic or formant-like peaks from a spectral average without
#' scanning the raw values by hand. It's read-only: build one with
#' \code{ltas$to_spectrum_tier_peaks()}, then inspect or export it.
#'
#' @section Usage:
#' \preformatted{
#' peaks <- ltas$to_spectrum_tier_peaks()
#' }
#'
#' @section Query methods:
#' \itemize{
#'   \item \code{get_lowest_frequency()}, \code{get_highest_frequency()} - the frequency range the peaks were picked from, in Hz
#'   \item \code{get_number_of_points()} - number of peaks found
#'   \item \code{get_frequency_from_index(index)} - frequency of one peak
#'   \item \code{get_value_at_index(index)} - power of one peak, in dB
#' }
#'
#' @section Export:
#' \itemize{
#'   \item \code{as_data_frame()} - all peaks as a data frame, with \code{frequency} and \code{power_db} columns
#'   \item \code{as_matrix()} - the same data as a plain matrix
#'   \item \code{save(path)} - write to a Praat text file
#' }
#'
#' @param .xptr Not for direct use. External pointer to the underlying C++
#'   object; set internally by \code{ltas$to_spectrum_tier_peaks()}.
#' @return A SpectrumTier object with methods for reading its frequency/power
#'   points.
#'
#' @examples
#' sound <- Sound$create_tone(frequency = 150, duration = 0.5)
#' ltas <- sound$to_ltas(bandwidth = 100)
#' peaks <- ltas$to_spectrum_tier_peaks()
#' peaks$get_number_of_points()
#' peaks$as_data_frame()
#'
#' @seealso \code{\link{Ltas}}
#' @name SpectrumTier
NULL

# ============================================================================
# Shared Method Dispatch Table
# ============================================================================

.spectrumtier_methods <- new.env(hash = TRUE, parent = emptyenv())

# --- Frequency domain ---
.spectrumtier_methods$get_lowest_frequency <- function(.self) .self$.cpp$get_fmin()
.spectrumtier_methods$get_highest_frequency <- function(.self) .self$.cpp$get_fmax()

# --- Point access ---
.spectrumtier_methods$get_number_of_points <- function(.self) .self$.cpp$get_number_of_points()
.spectrumtier_methods$get_frequency_from_index <- function(.self, index) {
  .self$.cpp$get_frequency(as.integer(index))
}
.spectrumtier_methods$get_value_at_index <- function(.self, index) {
  .self$.cpp$get_value(as.integer(index))
}

# --- Export ---
.spectrumtier_methods$as_data_frame <- function(.self) {
  df <- .self$.cpp$as_data_frame()
  names(df) <- c("frequency", "power_db")
  df
}
.spectrumtier_methods$as_matrix <- function(.self) {
  mat <- .self$.cpp$as_matrix()
  rbind(frequency = mat[, 1], power_db = mat[, 2])
}
.spectrumtier_methods$save <- function(.self, path) {
  .self$.cpp$save(path.expand(path))
  invisible(.self)
}

# --- Print ---
.spectrumtier_methods$print <- function(.self) {
  cat("<Praat SpectrumTier>\n")
  cat(sprintf("  Frequency range: %.2f - %.2f Hz\n", .self$.cpp$get_fmin(), .self$.cpp$get_fmax()))
  cat(sprintf("  Number of peaks: %d\n", .self$.cpp$get_number_of_points()))
  invisible(.self)
}

.spectrumtier_methods$is_valid <- function(.self) .self$.cpp$is_valid()
lockEnvironment(.spectrumtier_methods, bindings = TRUE)

# ============================================================================
# Constructor
# ============================================================================

#' @export
SpectrumTier <- function(.xptr = NULL) {
  if (is.null(.xptr)) {
    stop("SpectrumTier objects must be created from an Ltas object, e.g. ltas$to_spectrum_tier_peaks()")
  }
  tier_mod <- get_module("spectrumtier_module")
  cpp_obj <- tier_mod$RSpectrumTier$new(.xptr)
  structure(list(.xptr = .xptr, .cpp = cpp_obj), class = c("SpectrumTier", "PraatObject"))
}

# ============================================================================
# S3 Dispatch
# ============================================================================

#' @method $ SpectrumTier
#' @export
`$.SpectrumTier` <- function(x, name) {
  val <- .subset2(x, name)
  if (!is.null(val)) return(val)
  if (name == ".pointer") return(.subset2(x, ".xptr"))
  method <- .spectrumtier_methods[[name]]
  if (is.null(method)) return(NULL)
  function(...) method(x, ...)
}

#' @export
print.SpectrumTier <- function(x, ...) {
  x$print()
}

#' @export
as.data.frame.SpectrumTier <- function(x, ...) {
  x$as_data_frame()
}
