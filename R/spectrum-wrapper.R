# spectrum-wrapper.R - Spectrum object using shared dispatch table (pladdrr
#  4.8.33)
# Architecture: minimal list + $.Spectrum S3 dispatch → shared method env

#' Spectrum
#'
#' Praat Spectrum object with direct C++ module binding (complex FFT spectrum).
#' Spectrum objects represent frequency-domain representations of sounds.
#' Uses a shared dispatch table for minimal memory per object.
#'
#' @section Query methods:
#' \itemize{
#'   \item \code{get_lowest_frequency()} - lowest frequency (Hz)
#'   \item \code{get_highest_frequency()} - highest frequency (Hz)
#'   \item \code{get_number_of_bins()} - number of frequency bins
#'   \item \code{get_frequency_step()} - frequency step (Hz)
#'   \item \code{get_real_value_in_bin(bin)} - real part at a bin
#'   \item \code{get_imaginary_value_in_bin(bin)} - imaginary part at a bin
#'   \item \code{get_frequency_from_bin(bin)} - frequency for a bin number
#'   \item \code{get_bin_from_frequency(freq)} - bin number for a frequency
#' \item \code{get_band_density(fmin, fmax)} - power density in a band (Pa²/Hz²)
#'   \item \code{get_band_energy(fmin, fmax)} - energy in a band (Pa²·s)
#' \item \code{get_centre_of_gravity(power = 2.0)} - spectral center of gravity
#' \item \code{get_standard_deviation(power = 2.0)} - spectral standard
#'  deviation
#'   \item \code{get_skewness(power = 2.0)} - spectral skewness
#'   \item \code{get_kurtosis(power = 2.0)} - spectral kurtosis
#'   \item \code{get_central_moment(moment, power = 2.0)} - central moment
#' }
#'
#' @section Modification methods:
#' \itemize{
#' \item \code{pass_hann_band(fmin, fmax, smooth = 100)} - apply a Hann
#'  band-pass filter
#' \item \code{stop_hann_band(fmin, fmax, smooth = 100)} - apply a Hann
#'  band-stop filter
#' \item \code{cepstral_smoothing(bandwidth)} - smooth using the cepstral method
#' }
#'
#' @section Transform methods:
#' \itemize{
#'   \item \code{to_sound()} - convert to Sound (inverse FFT)
#'   \item \code{to_ltas(bandwidth)} - convert to long-term average spectrum
#'   \item \code{to_spectrogram(...)} - convert to Spectrogram
#' \item \code{to_excitation(erb_density)} - convert to Excitation (auditory
#'  representation)
#' }
#'
#' @section Export methods:
#' \itemize{
#'   \item \code{as_matrix()} - export as a numeric matrix (real + imaginary)
#' \item \code{as_data_frame()} - export as a data.frame (freq, real, imag,
#'  power)
#'   \item \code{save(path)} - save to a file
#' }
#'
#' @param .xptr Not for direct use. External pointer to the underlying C++
#'  Spectrum
#'   object; set internally when a method returns a new Spectrum.
#' @return A \code{Spectrum} object with methods for frequency-domain spectral
#'  analysis.
#'
#' @examples
#' sound <- Sound$create_tone(duration = 0.5, frequency = 440, sampling_rate =
#'  44100)
#' spectrum <- sound$to_spectrum(fast = FALSE)
#' cog <- spectrum$get_centre_of_gravity(power = 2.0)
#' energy <- spectrum$get_band_energy(fmin = 400, fmax = 500)
#'
#' # Create a spectrum from a recording read from disk
#' sound <- Sound(system.file("extdata", "test.wav", package = "pladdrr"))
#' spectrum <- sound$to_spectrum(fast = TRUE)
#' spec_df <- spectrum$as_data_frame()
#'
#' @seealso \code{\link{Sound}}, \code{\link{Spectrogram}}, \code{\link{Ltas}},
#'  \code{\link{PowerCepstrum}}
#' @name Spectrum
NULL

# ============================================================================
# Shared Method Dispatch Table
# ============================================================================

.spectrum_methods <- new.env(hash = TRUE, parent = emptyenv())

# --- Query: Basic info ---
.spectrum_methods$get_lowest_frequency <- function(
  .self) .spectrum_get_lowest_frequency(.self$.xptr)
.spectrum_methods$get_highest_frequency <- function(
  .self) .spectrum_get_highest_frequency(.self$.xptr)
.spectrum_methods$get_number_of_bins <- function(
  .self) .spectrum_get_number_of_bins(.self$.xptr)
.spectrum_methods$get_frequency_step <- function(
  .self) .spectrum_get_frequency_step(.self$.xptr)
.spectrum_methods$get_frequency_from_bin <- function(.self, bin) {
  .spectrum_get_frequency_from_bin(.self$.xptr, as.integer(bin))
}
.spectrum_methods$get_bin_from_frequency <- function(.self, frequency) {
  .spectrum_get_bin_from_frequency(.self$.xptr, as.numeric(frequency))
}

# --- Query: Values ---
.spectrum_methods$get_real_value_in_bin <- function(.self, bin) {
  .spectrum_get_real_value_in_bin(.self$.xptr, as.integer(bin))
}
.spectrum_methods$get_imaginary_value_in_bin <- function(.self, bin) {
  .spectrum_get_imaginary_value_in_bin(.self$.xptr, as.integer(bin))
}

# --- Query: Band statistics ---
.spectrum_methods$get_band_density <- function(.self, fmin, fmax) {
  .spectrum_get_band_density(.self$.xptr, as.numeric(fmin), as.numeric(fmax))
}
.spectrum_methods$get_band_energy <- function(.self, fmin, fmax) {
  .spectrum_get_band_energy(.self$.xptr, as.numeric(fmin), as.numeric(fmax))
}

# --- Query: Spectral moments ---
.spectrum_methods$get_centre_of_gravity <- function(.self, power = 2.0) {
  .spectrum_get_centre_of_gravity(.self$.xptr, as.numeric(power))
}
.spectrum_methods$get_standard_deviation <- function(.self, power = 2.0) {
  .spectrum_get_standard_deviation(.self$.xptr, as.numeric(power))
}
.spectrum_methods$get_skewness <- function(.self, power = 2.0) {
  .spectrum_get_skewness(.self$.xptr, as.numeric(power))
}
.spectrum_methods$get_kurtosis <- function(.self, power = 2.0) {
  .spectrum_get_kurtosis(.self$.xptr, as.numeric(power))
}
.spectrum_methods$get_central_moment <- function(.self, moment, power = 2.0) {
  .spectrum_get_central_moment(.self$.xptr, as.numeric(moment),
    as.numeric(power))
}

# --- Batch/Vectorized ---
.spectrum_methods$get_frequencies_vector <- function(
  .self) .self$.cpp$get_frequencies_vector()
.spectrum_methods$get_power_vector <- function(
  .self) .self$.cpp$get_power_vector()
.spectrum_methods$get_real_vector <- function(
  .self) .self$.cpp$get_real_vector()
.spectrum_methods$get_imaginary_vector <- function(
  .self) .self$.cpp$get_imaginary_vector()
.spectrum_methods$get_band_energies <- function(.self, fmins, fmaxs) {
  .self$.cpp$get_band_energies(as.numeric(fmins), as.numeric(fmaxs))
}
.spectrum_methods$get_band_densities <- function(.self, fmins, fmaxs) {
  .self$.cpp$get_band_densities(as.numeric(fmins), as.numeric(fmaxs))
}
.spectrum_methods$get_power_at_frequencies <- function(.self, frequencies) {
  .self$.cpp$get_power_at_frequencies(as.numeric(frequencies))
}

# --- Modification (in-place, self-returning) ---
.spectrum_methods$pass_hann_band <- function(.self, fmin, fmax, smooth = 100) {
  .spectrum_pass_hann_band(.self$.xptr, as.numeric(fmin), as.numeric(fmax),
    as.numeric(smooth))
  invisible(.self)
}
.spectrum_methods$stop_hann_band <- function(.self, fmin, fmax, smooth = 100) {
  .spectrum_stop_hann_band(.self$.xptr, as.numeric(fmin), as.numeric(fmax),
    as.numeric(smooth))
  invisible(.self)
}
.spectrum_methods$formula <- function(.self, formula) {
  .spectrum_formula(.self$.xptr, formula)
  invisible(.self)
}
.spectrum_methods$apply_pre_emphasis <- function(.self, from_frequency = 50) {
  .spectrum_apply_pre_emphasis(.self$.xptr, as.numeric(from_frequency))
  invisible(.self)
}
.spectrum_methods$multiply_by_frequency <- function(.self, power = 1.0) {
  .spectrum_multiply_by_frequency(.self$.xptr, as.numeric(power))
  invisible(.self)
}

# --- Modification (returns new object) ---
.spectrum_methods$cepstral_smoothing <- function(.self, bandwidth) {
  ptr <- .spectrum_cepstral_smoothing(.self$.xptr, as.numeric(bandwidth))
  Spectrum(.xptr = ptr)
}
.spectrum_methods$shift_frequencies <- function(.self, shift_by,
  new_maximum_frequency = 0,
                                                interpolation_depth = 50L) {
  if (new_maximum_frequency <= 0) new_maximum_frequency <- .self$.cpp$get_fmax()
  ptr <- .spectrum_shift_frequencies(.self$.xptr, as.numeric(shift_by),
    as.numeric(new_maximum_frequency), as.integer(interpolation_depth))
  Spectrum(.xptr = ptr)
}

# --- Transform ---
.spectrum_methods$to_sound <- function(.self) {
  ptr <- .spectrum_to_sound(.self$.xptr)
  Sound(.xptr = ptr)
}
.spectrum_methods$to_ltas <- function(.self, bandwidth = NULL) {
  if (is.null(bandwidth)) {
    ptr <- .spectrum_to_ltas_1to1(.self$.xptr)
    return(Ltas(.xptr = ptr))
  }
  dx <- .self$.cpp$get_df()
  if (bandwidth <= dx) {
    stop(sprintf(

        paste0("bandwidth (%.2f Hz) must be > frequency step (%.2f Hz). ",
               "Use bandwidth > %.1f or to_ltas() with no arguments for 1-to-1 mapping."),
      bandwidth, dx, dx
    ))
  }
  ptr <- .self$.cpp$to_ltas_ptr(as.numeric(bandwidth))
  Ltas(.xptr = ptr)
}
.spectrum_methods$to_ltas_1to1 <- function(.self) {
  ptr <- .spectrum_to_ltas_1to1(.self$.xptr)
  Ltas(.xptr = ptr)
}
.spectrum_methods$to_powercepstrum <- function(.self) {
  .Deprecated("to_power_cepstrum", package = "pladdrr",
              msg = "to_powercepstrum() is deprecated. Use to_power_cepstrum() instead.")
  ptr <- .spectrum_to_powercepstrum(.self$.xptr)
  PowerCepstrum(.xptr = ptr)
}
.spectrum_methods$to_power_cepstrum <- function(.self) {
  ptr <- .spectrum_to_powercepstrum(.self$.xptr)
  PowerCepstrum(.xptr = ptr)
}
.spectrum_methods$to_cepstrum <- function(.self) {
  xptr <- .spectrum_to_cepstrum(.self$.xptr)
  Cepstrum(.xptr = xptr)
}
.spectrum_methods$to_cepstrum_hillenbrand <- function(.self) {
  xptr <- .spectrum_to_cepstrum_hillenbrand(.self$.xptr)
  Cepstrum(.xptr = xptr)
}
.spectrum_methods$to_excitation <- function(.self, erb_density = 0.1) {
  stopifnot(
    "erb_density must be a positive number" = is.numeric(
      erb_density) && length(erb_density) == 1 && erb_density > 0
  )
  ptr <- .spectrum_to_excitation(.self$.xptr, as.numeric(erb_density))
  Excitation(.xptr = ptr)
}

# --- Export ---
.spectrum_methods$as_matrix <- function(.self) .spectrum_as_matrix(.self$.xptr)
.spectrum_methods$as_data_frame <- function(.self) {
  mat <- .spectrum_as_matrix(.self$.xptr)
  nbins <- ncol(mat)
  freq <- vapply(seq_len(nbins), .self$.cpp$get_frequency_from_bin, numeric(1))
  real_vals <- mat[1, ]
  imag_vals <- mat[2, ]
  power <- real_vals^2 + imag_vals^2
  phase <- atan2(imag_vals, real_vals)
  data.frame(
    bin = seq_len(nbins),
    frequency = freq,
    real = real_vals,
    imaginary = imag_vals,
    power = power,
    phase = phase,
    stringsAsFactors = FALSE
  )
}

# --- Print ---
.spectrum_methods$print <- function(.self) {
  cat("<Praat Spectrum>\n")
  cat(sprintf("  Frequency range: %.2f - %.2f Hz\n",
              .self$.cpp$get_fmin(),
              .self$.cpp$get_fmax()))
  cat(sprintf("  Number of bins: %d\n", .self$.cpp$get_n_bins()))
  cat(sprintf("  Frequency step: %.2f Hz\n", .self$.cpp$get_df()))
  invisible(.self)
}

.spectrum_methods$is_valid <- function(.self) .self$.cpp$is_valid()
lockEnvironment(.spectrum_methods, bindings = TRUE)

# ============================================================================
# Constructor
# ============================================================================

#' @export
Spectrum <- function(.xptr = NULL) {
  if (is.null(.xptr)) {
    stop("Spectrum objects must be created from Sound using to_spectrum()")
  }
  spectrum_mod <- get_module("spectrum_module")
  cpp_obj <- spectrum_mod$RSpectrum$new(.xptr)
  structure(list(.xptr = .xptr, .cpp = cpp_obj),
    class = c("Spectrum", "PraatObject"))
}

# ============================================================================
# S3 Dispatch
# ============================================================================

#' @method $ Spectrum
#' @export
`$.Spectrum` <- function(x, name) {
  val <- .subset2(x, name)
  if (!is.null(val)) return(val)
  if (name == ".pointer") return(.subset2(x, ".xptr"))
  method <- .spectrum_methods[[name]]
  if (is.null(method)) return(NULL)
  function(...) method(x, ...)
}
