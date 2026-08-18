# spectrogram-wrapper.R - Spectrogram object using shared dispatch table (pladdrr 4.8.33)
# Architecture: minimal list + $.Spectrogram S3 dispatch → shared method env

#' Spectrogram
#'
#' A Spectrogram is a time-frequency representation of sound: a matrix of
#' power values indexed by time (columns) and frequency (rows). Created from a
#' Sound via short-time Fourier transform (STFT).
#'
#' @section Query methods:
#' \itemize{
#'   \item \code{get_start_time()}, \code{get_end_time()} - time range (s)
#'   \item \code{get_time_step()} - time between frames (s)
#'   \item \code{get_number_of_time_bins()} - number of time frames
#'   \item \code{get_lowest_frequency()}, \code{get_highest_frequency()} - frequency range (Hz)
#'   \item \code{get_frequency_step()} - frequency resolution (Hz)
#'   \item \code{get_number_of_frequency_bins()} - number of frequency bins
#' }
#'
#' @section Index mapping:
#' \itemize{
#'   \item \code{get_time_from_frame(frame)} - time for a frame index
#'   \item \code{get_frame_from_time(time)} - frame index for a time
#'   \item \code{get_frequency_from_bin(bin)} - frequency for a bin index
#'   \item \code{get_bin_from_frequency(freq)} - bin index for a frequency
#' }
#'
#' @section Power queries:
#' \itemize{
#'   \item \code{get_power_at(time, frequency)} - power at a time-frequency point
#'   \item \code{get_power_at_points(times, frequencies)} - power at a vector of points (batch)
#'   \item \code{get_frame(time)} - full frequency spectrum at one time
#'   \item \code{get_frequency_slice(frequency)} - time series at one frequency
#'   \item \code{get_frames(times)} - matrix of frames at multiple times
#'   \item \code{get_band_power(fmin, fmax)} - integrated power in a frequency band
#'   \item \code{get_spectral_moments_batch(power)} - center of gravity, SD, skewness, and kurtosis per frame (single C++ call)
#' }
#'
#' @section Export:
#' \itemize{
#'   \item \code{as_matrix(include_dimnames)} - export as a numeric matrix
#'   \item \code{as_data_frame()} - export as a data.frame
#' }
#'
#' @section Transform:
#' \itemize{
#'   \item \code{to_spectrum(time)} - extract a spectrum at one time point
#'   \item \code{to_dtw(reference)} - dynamic time warping between spectrograms
#' }
#'
#' @seealso \code{\link{Sound}}, \code{\link{Spectrum}}, \code{\link{DTW}}, \code{\link{ComplexSpectrogram}}
#'
#' @return A Spectrogram object.
#'
#' @examples
#' snd <- Sound$create_tone(duration = 0.5, frequency = 440, sampling_rate = 44100)
#' spec <- snd$to_spectrogram(window_length = 0.005, max_frequency = 5000)
#' power <- spec$get_power_at(time = 0.25, frequency = 440)
#'
#' @name Spectrogram
NULL

# ============================================================================
# Shared Method Dispatch Table
# ============================================================================

.spectrogram_methods <- new.env(hash = TRUE, parent = emptyenv())

# --- Time domain ---
.spectrogram_methods$get_start_time <- function(.self) .spectrogram_get_start_time(.self$.xptr)
.spectrogram_methods$get_end_time <- function(.self) .spectrogram_get_end_time(.self$.xptr)
.spectrogram_methods$get_time_step <- function(.self) .spectrogram_get_time_step(.self$.xptr)
.spectrogram_methods$get_number_of_time_bins <- function(.self) .spectrogram_get_number_of_time_bins(.self$.xptr)

# --- Frequency domain ---
.spectrogram_methods$get_lowest_frequency <- function(.self) .spectrogram_get_lowest_frequency(.self$.xptr)
.spectrogram_methods$get_highest_frequency <- function(.self) .spectrogram_get_highest_frequency(.self$.xptr)
.spectrogram_methods$get_frequency_step <- function(.self) .spectrogram_get_frequency_step(.self$.xptr)
.spectrogram_methods$get_number_of_frequency_bins <- function(.self) .spectrogram_get_number_of_frequency_bins(.self$.xptr)

# --- Conversion ---
.spectrogram_methods$get_time_from_frame <- function(.self, frame) {
  .spectrogram_get_time_from_frame(.self$.xptr, as.integer(frame))
}
.spectrogram_methods$get_frame_from_time <- function(.self, time) {
  .self$.cpp$get_frame_from_time(as.numeric(time))
}
.spectrogram_methods$get_frequency_from_bin <- function(.self, bin) {
  .spectrogram_get_frequency_from_bin(.self$.xptr, as.integer(bin))
}
.spectrogram_methods$get_bin_from_frequency <- function(.self, frequency) {
  .self$.cpp$get_bin_from_frequency(as.numeric(frequency))
}

# --- Query ---
.spectrogram_methods$get_power_at <- function(.self, time, frequency) {
  .spectrogram_get_power_at(.self$.xptr, as.numeric(time), as.numeric(frequency))
}

# --- Batch/Vectorized ---
.spectrogram_methods$get_times_vector <- function(.self) .self$.cpp$get_times_vector()
.spectrogram_methods$get_frequencies_vector <- function(.self) .self$.cpp$get_frequencies_vector()
.spectrogram_methods$get_power_at_points <- function(.self, times, frequencies) {
  .self$.cpp$get_power_at_points(as.numeric(times), as.numeric(frequencies))
}
.spectrogram_methods$get_frame <- function(.self, time) {
  .self$.cpp$get_frame(as.numeric(time))
}
.spectrogram_methods$get_frequency_slice <- function(.self, frequency) {
  .self$.cpp$get_frequency_slice(as.numeric(frequency))
}
.spectrogram_methods$get_frames <- function(.self, times) {
  .self$.cpp$get_frames(as.numeric(times))
}
.spectrogram_methods$get_band_power <- function(.self, fmin, fmax) {
  .self$.cpp$get_band_power(as.numeric(fmin), as.numeric(fmax))
}
.spectrogram_methods$get_spectral_moments_batch <- function(.self, power = 2.0) {
  get_spectral_moments_batch(.self, as.numeric(power))
}

# --- Transform ---
.spectrogram_methods$to_spectrum <- function(.self, time) {
  spectrum_ptr <- .self$.cpp$to_spectrum_ptr(as.numeric(time))
  Spectrum(.xptr = spectrum_ptr)
}
.spectrogram_methods$to_dtw <- function(.self, reference, match_start = TRUE, match_end = TRUE,
                                        slope = 1, metric = 2.0) {
  if (!inherits(reference, "Spectrogram")) stop("reference must be a Spectrogram object")
  spectrograms_to_dtw(reference, .self, match_start, match_end, slope, metric)
}

# --- Export ---
.spectrogram_methods$as_matrix <- function(.self, include_dimnames = TRUE) {
  mat <- .spectrogram_as_matrix(.self$.xptr)
  if (include_dimnames) {
    rownames(mat) <- .self$.cpp$get_frequencies_vector()
    colnames(mat) <- .self$.cpp$get_times_vector()
  }
  mat
}
.spectrogram_methods$as_data_frame <- function(.self) {
  mat <- .spectrogram_as_matrix(.self$.xptr)
  n_time <- .self$.cpp$get_nx()
  n_freq <- .self$.cpp$get_ny()
  times <- vapply(seq_len(n_time), function(i) .self$.cpp$get_time_from_frame(as.integer(i)), numeric(1))
  freqs <- vapply(seq_len(n_freq), function(i) .self$.cpp$get_frequency_from_bin(as.integer(i)), numeric(1))
  df <- expand.grid(time = times, frequency = freqs)
  df$power <- as.vector(t(mat))
  df
}

# --- Print ---
.spectrogram_methods$print <- function(.self) {
  cat("<Praat Spectrogram>\n")
  cat(sprintf("  Time: %.3f - %.3f s (%d bins, step %.4f s)\n",
              .self$.cpp$get_xmin(), .self$.cpp$get_xmax(),
              .self$.cpp$get_nx(), .self$.cpp$get_dx()))
  cat(sprintf("  Frequency: %.2f - %.2f Hz (%d bins, step %.2f Hz)\n",
              .self$.cpp$get_ymin(), .self$.cpp$get_ymax(),
              .self$.cpp$get_ny(), .self$.cpp$get_dy()))
  invisible(.self)
}

.spectrogram_methods$is_valid <- function(.self) .self$.cpp$is_valid()
lockEnvironment(.spectrogram_methods, bindings = TRUE)

# ============================================================================
# Constructor
# ============================================================================

#' @export
Spectrogram <- function(.xptr = NULL) {
  if (is.null(.xptr)) {
    stop("Spectrogram objects must be created from Sound$to_spectrogram()")
  }
  spectrogram_mod <- get_module("spectrogram_module")
  cpp_obj <- spectrogram_mod$RSpectrogram$new(.xptr)
  structure(list(.xptr = .xptr, .cpp = cpp_obj), class = c("Spectrogram", "PraatObject"))
}

# ============================================================================
# S3 Dispatch
# ============================================================================

#' @method $ Spectrogram
#' @export
`$.Spectrogram` <- function(x, name) {
  val <- .subset2(x, name)
  if (!is.null(val)) return(val)
  if (name == ".pointer") return(.subset2(x, ".xptr"))
  method <- .spectrogram_methods[[name]]
  if (is.null(method)) return(NULL)
  function(...) method(x, ...)
}

#' @export
print.Spectrogram <- function(x, ...) {
  x$print()
  invisible(x)
}

#' @export
as.data.frame.Spectrogram <- function(x, ...) {
  x$as_data_frame()
}
