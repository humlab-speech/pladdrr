# spectrogram-wrapper.R - Spectrogram object using shared dispatch table (pladdrr 4.8.33)
# Architecture: minimal list + $.Spectrogram S3 dispatch → shared method env

#' Spectrogram Object
#'
#' @description
#' A Spectrogram is a time-frequency representation of sound — a matrix of
#' power values indexed by time (columns) and frequency (rows). Created from a
#' Sound via short-time Fourier transform (STFT).
#'
#' @section Methods:
#'
#' **Information:**
#' * `get_start_time()` / `get_end_time()` — Time range (s)
#' * `get_time_step()` — Time between frames (s)
#' * `get_number_of_time_bins()` — Number of time frames
#' * `get_lowest_frequency()` / `get_highest_frequency()` — Frequency range (Hz)
#' * `get_frequency_step()` — Frequency resolution (Hz)
#' * `get_number_of_frequency_bins()` — Number of frequency bins
#'
#' **Index mapping:**
#' * `get_time_from_frame(frame)` — Time for frame index
#' * `get_frame_from_time(time)` — Frame index for time
#' * `get_frequency_from_bin(bin)` — Frequency for bin index
#' * `get_bin_from_frequency(freq)` — Bin index for frequency
#'
#' **Power queries:**
#' * `get_power_at(time, frequency)` — Power at time×frequency point
#' * `get_power_at_points(times, frequencies)` — Power at vector of points (batch)
#' * `get_frame(time)` — Full frequency spectrum at one time
#' * `get_frequency_slice(frequency)` — Time series at one frequency
#' * `get_frames(times)` — Matrix of frames at multiple times
#' * `get_band_power(fmin, fmax)` — Integrated power in frequency band
#' * `get_spectral_moments_batch(power)` — Center of gravity, SD, skewness, kurtosis per frame (single C++ call)
#'
#' **Export:**
#' * `as_matrix(include_dimnames)` — Export as numeric matrix
#' * `as_data_frame()` — Export as data.frame
#'
#' **Transform:**
#' * `to_spectrum(time)` — Extract spectrum at one time point
#' * `to_dtw(reference)` — Dynamic Time Warping between spectrograms
#'
#' @seealso \code{\link{Sound}}, \code{\link{Spectrum}}, \code{\link{DTW}}, \code{\link{ComplexSpectrogram}}
#'
#' @return A \code{Spectrogram} object with methods for time-frequency spectral analysis.
#'
#' @examples
#' snd <- Sound$create_tone(duration = 0.5, frequency = 440, sampling_rate = 44100)
#' spec <- snd$to_spectrogram(window_length = 0.005, maximum_frequency = 5000)
#' power <- spec$get_power_at(time = 0.25, frequency = 440)
#'
#' @name Spectrogram
NULL

# ============================================================================
# Shared Method Dispatch Table
# ============================================================================

.spectrogram_methods <- new.env(hash = TRUE, parent = emptyenv())

# --- Time domain ---
.spectrogram_methods$get_start_time <- function(.self) .self$.cpp$get_xmin()
.spectrogram_methods$get_end_time <- function(.self) .self$.cpp$get_xmax()
.spectrogram_methods$get_time_step <- function(.self) .self$.cpp$get_time_step()
.spectrogram_methods$get_number_of_time_bins <- function(.self) .self$.cpp$get_number_of_frames()

# --- Frequency domain ---
.spectrogram_methods$get_lowest_frequency <- function(.self) .self$.cpp$get_ymin()
.spectrogram_methods$get_highest_frequency <- function(.self) .self$.cpp$get_ymax()
.spectrogram_methods$get_frequency_step <- function(.self) .self$.cpp$get_frequency_step()
.spectrogram_methods$get_number_of_frequency_bins <- function(.self) .self$.cpp$get_number_of_frequency_bins()

# --- Conversion ---
.spectrogram_methods$get_time_from_frame <- function(.self, frame) {
  .self$.cpp$get_time_from_frame(as.integer(frame))
}
.spectrogram_methods$get_frame_from_time <- function(.self, time) {
  .self$.cpp$get_frame_from_time(as.numeric(time))
}
.spectrogram_methods$get_frequency_from_bin <- function(.self, bin) {
  .self$.cpp$get_frequency_from_bin(as.integer(bin))
}
.spectrogram_methods$get_bin_from_frequency <- function(.self, frequency) {
  .self$.cpp$get_bin_from_frequency(as.numeric(frequency))
}

# --- Query ---
.spectrogram_methods$get_power_at <- function(.self, time, frequency) {
  .self$.cpp$get_power_at(as.numeric(time), as.numeric(frequency))
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
}

#' @export
as.data.frame.Spectrogram <- function(x, ...) {
  x$as_data_frame()
}
