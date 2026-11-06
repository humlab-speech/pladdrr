# ltas-wrapper.R - Ltas object using shared dispatch table (pladdrr 4.8.33)
# Architecture: minimal list + $.Ltas S3 dispatch -> shared method env

#' Ltas
#'
#' Represents a long-term average spectrum (LTAS): the frequency spectrum of
#' a sound averaged over its whole duration.
#'
#' An Ltas collapses a recording into a single spectral shape: how much
#' energy sits in each frequency band once the moment-to-moment detail is
#' averaged out. It's the standard tool for describing overall spectral
#' shape (tilt, resonance pattern, noise floor), useful for comparing voice
#' quality across speakers or checking a recording's frequency balance.
#'
#' @section Usage:
#' \preformatted{
#' ltas <- sound$to_ltas(bandwidth = 100)
#' ltas <- sound$to_ltas_pitch_corrected(pitch_floor = 75, pitch_ceiling = 600)
#' }
#'
#' @section Units and interpolation:
#' The five averaging queries - \code{get_mean()}, \code{get_means_batch()},
#' \code{get_standard_deviation()}, \code{get_slope()} and
#' \code{get_local_peak_height()} - all \emph{return decibels}, whatever
#' \code{unit} you name. \code{unit} selects the domain the average is taken
#' in: \code{"dB"} (the default) averages the bin values, \code{"energy"}
#' averages \code{10^(z/10)} and \code{"sones"} averages \code{2^(z/10)}
#' (Praat's own conversions), and the result is converted back to dB, exactly
#' as Praat's Ltas queries do. The three therefore give three different
#' numbers - the \code{"energy"} mean is the one comparable with broadband
#' energy sums. Spelling is case-insensitive, and an unrecognised \code{unit}
#' is an error naming the accepted spellings (in the queries that average:
#' \code{get_mean()}, \code{get_means_batch()}, \code{get_standard_deviation()},
#' \code{get_slope()}, \code{get_local_peak_height()}). The peak/trough and
#' value-at-frequency locators take a \code{unit} argument for compatibility but
#' answer in the bins' own dB, so they accept only \code{"dB"} and raise a
#' \code{pladdrr_input_error} for anything else. Averages cover the whole bins between the two frequencies, weighting
#' the two bins at an incomplete range edge by the fraction of the bin inside
#' the range (Praat's non-interpolating averaging window). Methods that locate
#' a peak or trough take an \code{interpolation} of
#' \code{"none"}, \code{"parabolic"} (the default), \code{"cubic"},
#' \code{"sinc70"}, or \code{"sinc700"} - parabolic and cubic refine the
#' peak's position between bins instead of snapping to the nearest one.
#' \code{get_value_at_frequency()} takes a plain \code{interpolate} flag
#' (\code{TRUE}/\code{FALSE}) rather than a named method.
#'
#' @section Frequency domain:
#' \itemize{
#' \item \code{get_lowest_frequency()}, \code{get_highest_frequency()} - the
#'  frequency range, in Hz
#'   \item \code{get_frequency_range()} - the width of that range, in Hz
#'   \item \code{get_number_of_bins()} - number of frequency bins
#'   \item \code{get_bin_width()} - width of each bin, in Hz
#'   \item \code{get_frequency_from_bin(bin)} - centre frequency of a bin
#' \item \code{get_bin_from_frequency(frequency)} - the bin nearest a frequency
#' }
#'
#' @section Query values:
#' \itemize{
#' \item \code{get_value_at_frequency(frequency, unit, interpolate)} - power at
#'  a given frequency
#' \item \code{get_value_in_bin(bin)} - power in one bin, read directly with no
#'  interpolation
#' \item \code{get_minimum(fmin, fmax, unit, interpolation)},
#'  \code{get_maximum(fmin, fmax, unit, interpolation)} - lowest/highest power
#'  in a frequency range
#' \item \code{get_frequency_of_minimum(fmin, fmax, interpolation)},
#'  \code{get_frequency_of_maximum(fmin, fmax, interpolation)} - where those
#'  extremes occur
#' \item \code{get_mean(fmin, fmax, unit)} - average power across a frequency
#'  range, in dB (see "Units and interpolation" for what \code{unit} changes)
#' \item \code{get_standard_deviation(fmin, fmax, unit)} - how much the power
#'  varies across a frequency range, in dB
#' \item \code{get_slope(f1min, f1max, f2min, f2max, unit)} - the difference in
#'  average power between two bands in dB, e.g. spectral tilt (high-frequency
#'  band minus low-frequency band)
#' \item \code{get_local_peak_height(environment_min, environment_max, peak_min,
#'  peak_max, unit)} - how far a peak rises above its surrounding band, in dB,
#'  e.g. harmonic-to-noise prominence
#' }
#'
#' @section Batch queries:
#' Faster than calling the single-value methods in a loop, since each call
#' crosses into C++ once for the whole set of frequencies or ranges.
#' \itemize{
#' \item \code{get_values_at_frequencies(frequencies, interpolation)} - values
#'  at many frequencies at once
#' \item \code{get_means_batch(fmins, fmaxs, unit)} - means in dB for many frequency
#'  ranges at once
#' \item \code{get_peaks_batch(fmins, fmaxs, interpolation)},
#'  \code{get_minima_batch(fmins, fmaxs, interpolation)} - peaks or troughs
#'  for many ranges at once, returned as a data frame
#' }
#'
#' @section Trend and peaks:
#' \itemize{
#' \item \code{compute_trend_line(fmin, fmax)} - the fitted trend line, as its
#'  own Ltas
#' \item \code{subtract_trend_line(fmin, fmax)} - the spectrum with that trend
#'  removed, e.g. to flatten spectral tilt before comparing bands
#' \item \code{report_spectral_trend(fmin, fmax, frequency_scale, fit_method)} -
#'  slope, intercept, and fit quality (R-squared, residual error) as a
#'  structured result; print it directly or read \code{$fitted_values} for the
#'  per-point predictions
#' \item \code{get_spectral_slope(fmin, fmax, frequency_scale, fit_method)} -
#'  just the slope from the above, when that's all you need
#' \item \code{to_spectrum_tier_peaks()} - the local maxima across the whole
#'  spectrum, as a \link{SpectrumTier}
#' }
#'
#' @section Export:
#' \itemize{
#'   \item \code{as_data_frame()} - frequency and power as a data frame
#'   \item \code{as_matrix()} - frequency and power as a plain matrix
#' \item \code{to_matrix()} - the Ltas converted to a full \link{Matrix} object
#'   \item \code{save(path)} - write to a Praat text file
#' }
#'
#' @param .xptr Not for direct use. External pointer to the underlying C++
#'   object; set internally when a method returns a new Ltas.
#' @return An Ltas object with methods for long-term average spectrum analysis.
#'
#' @examples
#' sound <- Sound$create_tone(frequency = 150, duration = 0.5)
#' ltas <- sound$to_ltas(bandwidth = 100)
#' ltas$get_mean()
#' ltas$get_number_of_bins()
#'
#' @seealso \code{\link{Sound}}, \code{\link{Spectrum}},
#'  \code{\link{Spectrogram}}, \code{\link{SpectrumTier}}
#' @name Ltas
NULL

# ============================================================================
# Helpers
# ============================================================================

# Praat's Ltas averaging CHOICE has no MEDIAN and is 1-based, so "dB" is 3
# (fon/praat_uvafon_init.cpp:1101-1105); Ltas_getSlope and
# Ltas_getLocalPeakHeight branch on averagingUnits == 3 for the dB case
# (fon/Ltas.cpp:87, :95). Whatever the unit averaged in, the answer comes back in
# dB -- see the *_standardUnit entry points cited in
# tests/testthat/test-ltas-averaging-unit.R.
.ltas_unit_code <- function(unit, routine = "get_mean") {
  switch(tolower(unit), "energy" = 1L, "sones" = 2L, "db" = 3L,
    .stop_input(routine, "unit",
      paste0('must be one of "energy", "sones", "dB": ', unit)))
}

# The locators (get_value_at_frequency, get_minimum, get_maximum) read bins that
# are already in dB; Praat's own dialogs for them have no unit at all. pladdrr
# kept a `unit` argument, which used to be ignored, so unit = "energy" silently
# returned dB. Refuse anything but dB rather than answer in a unit that was not
# the one asked for.
.check_ltas_db_unit <- function(unit, routine) {
  if (!.is_string_scalar(unit) || is.na(unit) || tolower(unit) != "db") {
    .stop_input(routine, "unit",
      paste0('this query always answers in dB, so unit must be "dB"; the ',
        '"energy" and "sones" domains belong to get_mean(), ',
        'get_standard_deviation(), get_slope() and get_local_peak_height(): ',
        deparse(unit)))
  }
  invisible(TRUE)
}


# ============================================================================
# Shared Method Dispatch Table
# ============================================================================

.ltas_methods <- new.env(hash = TRUE, parent = emptyenv())

# --- Frequency domain ---
.ltas_methods$get_bin_from_frequency <- function(.self, frequency) {
  .self$.cpp$get_bin_from_frequency(as.numeric(frequency))
}
.ltas_methods$get_frequency_from_bin <- function(.self, bin) {
  .self$.cpp$get_frequency_from_bin(as.integer(bin))
}
.ltas_methods$get_number_of_bins <- function(
  .self) .self$.cpp$get_number_of_bins()
.ltas_methods$get_bin_width <- function(.self) .self$.cpp$get_bandwidth()
.ltas_methods$get_lowest_frequency <- function(.self) .self$.cpp$get_fmin()
.ltas_methods$get_highest_frequency <- function(.self) .self$.cpp$get_fmax()
.ltas_methods$get_frequency_range <- function(
  .self) .self$.cpp$get_frequency_range()

# --- Query values ---
.ltas_methods$get_value_at_frequency <- function(.self, frequency,
  unit = "dB", interpolate = TRUE) {
  .check_ltas_db_unit(unit, "get_value_at_frequency")
  .self$.cpp$get_value_at_frequency(as.numeric(frequency),
    if (interpolate) 2 else 0)
}
.ltas_methods$get_value_in_bin <- function(.self, bin) {
  .self$.cpp$get_value_at_bin(as.integer(bin))
}
.ltas_methods$get_minimum <- function(.self, fmin = 0, fmax = 0, unit = "dB",
  interpolation = "parabolic") {
  .check_ltas_db_unit(unit, "get_minimum")
  .self$.cpp$get_minimum(fmin, fmax,
    .praat_peak_interpolation_code(interpolation))
}
.ltas_methods$get_maximum <- function(.self, fmin = 0, fmax = 0, unit = "dB",
  interpolation = "parabolic") {
  .check_ltas_db_unit(unit, "get_maximum")
  .self$.cpp$get_maximum(fmin, fmax,
    .praat_peak_interpolation_code(interpolation))
}
.ltas_methods$get_mean <- function(.self, fmin = 0, fmax = 0, unit = "dB") {
  .self$.cpp$get_mean(fmin, fmax, .ltas_unit_code(unit, "get_mean"))
}
.ltas_methods$get_slope <- function(.self, f1min, f1max, f2min, f2max,
  unit = "dB") {
  .self$.cpp$get_slope(f1min, f1max, f2min, f2max,
    .ltas_unit_code(unit, "get_slope"))
}
.ltas_methods$get_local_peak_height <- function(.self, environment_min,
  environment_max,
                                                peak_min, peak_max, unit = "dB")
                                                    {
  .self$.cpp$get_local_peak_height(environment_min, environment_max, peak_min,
    peak_max,
                                   .ltas_unit_code(unit,
                                     "get_local_peak_height"))
}
.ltas_methods$get_standard_deviation <- function(.self, fmin = 0, fmax = 0,
  unit = "dB") {
  .self$.cpp$get_standard_deviation(fmin, fmax,
    .ltas_unit_code(unit, "get_standard_deviation"))
}

# --- Batch ---
.ltas_methods$get_peaks_batch <- function(.self, fmins, fmaxs,
  interpolation = "parabolic") {
  .self$.cpp$get_peaks_batch(as.numeric(fmins), as.numeric(fmaxs),
                             .praat_peak_interpolation_code(interpolation))
}
.ltas_methods$get_minima_batch <- function(.self, fmins, fmaxs,
  interpolation = "parabolic") {
  .self$.cpp$get_minima_batch(as.numeric(fmins), as.numeric(fmaxs),
                              .praat_peak_interpolation_code(interpolation))
}
.ltas_methods$get_values_at_frequencies <- function(.self, frequencies,
  interpolation = "cubic") {
  .self$.cpp$get_values_at_frequencies(as.numeric(frequencies),
                                       .praat_interpolation_code(interpolation))
}
.ltas_methods$get_means_batch <- function(.self, fmins, fmaxs, unit = "dB") {
  .self$.cpp$get_means_batch(as.numeric(fmins), as.numeric(fmaxs),
    .ltas_unit_code(unit, "get_means_batch"))
}
.ltas_methods$get_frequency_of_maximum <- function(.self, fmin = 0, fmax = 0,
  interpolation = "parabolic") {
  .self$.cpp$get_frequency_of_maximum(fmin, fmax,
    .praat_peak_interpolation_code(interpolation))
}
.ltas_methods$get_frequency_of_minimum <- function(.self, fmin = 0, fmax = 0,
  interpolation = "parabolic") {
  .self$.cpp$get_frequency_of_minimum(fmin, fmax,
    .praat_peak_interpolation_code(interpolation))
}

# --- Transform ---
.ltas_methods$subtract_trend_line <- function(.self, fmin = 0, fmax = 0) {
  ptr <- .ltas_subtract_trend_line(.self$.xptr, fmin, fmax)
  Ltas(.xptr = ptr)
}
.ltas_methods$compute_trend_line <- function(.self, fmin = 0, fmax = 0) {
  ptr <- .ltas_compute_trend_line(.self$.xptr, fmin, fmax)
  Ltas(.xptr = ptr)
}
.ltas_methods$report_spectral_trend <- function(.self, fmin = 100, fmax = 5000,
                                                frequency_scale = c(
                                                  "logarithmic", "linear"),
                                                fit_method = c(
                                                  "least squares", "robust")) {
  frequency_scale <- match.arg(frequency_scale)
  fit_method <- match.arg(fit_method)
  result <- .ltas_report_spectral_trend(.self$.xptr, as.numeric(fmin),
    as.numeric(fmax),
                                        frequency_scale, fit_method)
  class(result) <- c("ltas_spectral_trend", "list")
  result
}
.ltas_methods$get_spectral_slope <- function(.self, fmin = 100, fmax = 5000,
                                             frequency_scale = c(
                                               "logarithmic", "linear"),
                                             fit_method = c("least squares",
                                               "robust")) {
  frequency_scale <- match.arg(frequency_scale)
  fit_method <- match.arg(fit_method)
  trend <- .ltas_report_spectral_trend(.self$.xptr, as.numeric(fmin),
    as.numeric(fmax),
                                       frequency_scale, fit_method)
  trend$slope
}

# --- Analyse ---
.ltas_methods$to_spectrum_tier_peaks <- function(.self) {
  ptr <- .ltas_to_spectrum_tier_peaks(.self$.xptr)
  SpectrumTier(.xptr = ptr)
}

# --- Export ---
.ltas_methods$as_data_frame <- function(.self) {
  df <- .self$.cpp$as_data_frame()
  names(df) <- c("frequency", "power_db")
  df
}
.ltas_methods$as_matrix <- function(.self) {
  mat <- .self$.cpp$as_matrix()
  rbind(frequency = mat[, 1], power_db = mat[, 2])
}
.ltas_methods$to_matrix <- function(.self) {
  ptr <- .self$.cpp$to_matrix_ptr()
  Matrix(.xptr = ptr)
}
.ltas_methods$save <- function(.self, path) {
  .self$.cpp$save(path.expand(path))
  invisible(.self)
}

# --- Print ---
.ltas_methods$print <- function(.self) {
  cat("<Praat Ltas>\n")
  cat(
    sprintf("  Frequency range: %.2f - %.2f Hz\n", .self$.cpp$get_fmin(),
      .self$.cpp$get_fmax()))
  cat(sprintf("  Number of bins: %d\n", .self$.cpp$get_number_of_bins()))
  cat(sprintf("  Bin width: %.2f Hz\n", .self$.cpp$get_bandwidth()))
  invisible(.self)
}

.ltas_methods$is_valid <- function(.self) .self$.cpp$is_valid()
lockEnvironment(.ltas_methods, bindings = TRUE)

# ============================================================================
# Constructor
# ============================================================================

#' @export
Ltas <- function(.xptr = NULL) {
  if (is.null(.xptr)) {
    stop("Ltas objects must be created from a Sound or Spectrum object")
  }
  ltas_mod <- get_module("ltas_module")
  cpp_obj <- with_pladdrr_errors(ltas_mod$RLtas$new(.xptr))
  structure(list(.xptr = .xptr, .cpp = cpp_obj),
    class = c("Ltas", "PraatObject"))
}

# ============================================================================
# S3 Dispatch
# ============================================================================

#' @method $ Ltas
#' @export
`$.Ltas` <- function(x, name) {
  val <- .subset2(x, name)
  if (!is.null(val)) return(val)
  if (name == ".pointer") return(.subset2(x, ".xptr"))
  method <- .ltas_methods[[name]]
  if (is.null(method)) return(NULL)
  function(...) method(x, ...)
}

#' Average multiple Ltas objects
#'
#' @param ... Ltas objects to average
#' @return A new Ltas object representing the average
#' @examples
#' s1 <- Sound$create_tone(frequency = 200, duration = 0.5, sampling_rate =
#'  16000)
#' s2 <- Sound$create_tone(frequency = 240, duration = 0.5, sampling_rate =
#'  16000)
#' avg <- ltas_average(s1$to_ltas(), s2$to_ltas())
#' @export
ltas_average <- function(...) {
  ltas_list <- list(...)
  if (
    length(
      ltas_list) == 1 && is.list(ltas_list[[1]]) && !inherits(ltas_list[[1]],
          "Ltas")) {
    ltas_list <- ltas_list[[1]]
  }
  stopifnot("Need at least one Ltas object" = length(ltas_list) >= 1)
  xptrs <- lapply(ltas_list, function(l) {
    if (!inherits(l, "Ltas")) stop("All arguments must be Ltas objects")
    l$.xptr
  })
  result_ptr <- .ltases_average(xptrs)
  Ltas(.xptr = result_ptr)
}

#' @export
print.ltas_spectral_trend <- function(x, ...) {
  cat("Spectral Trend Analysis\n")
  cat("=======================\n")
  cat(sprintf("Frequency range: %.1f - %.1f Hz\n", x$fmin, x$fmax))
  cat(sprintf("Frequency scale: %s\n", x$frequency_scale))
  cat(sprintf("Fit method: %s\n", x$fit_method))
  cat(sprintf("Data points: %d\n\n", x$n_points))
  cat("Trend Line Coefficients:\n")
  cat(sprintf("  Slope:     %.6f %s\n", x$slope, x$slope_units))
  cat(sprintf("  Intercept: %.4f dB\n\n", x$intercept))
  cat("Fit Quality:\n")
  cat(sprintf("  R^2:                   %.6f\n", x$r_squared))
  cat(sprintf("  Residual Std Error:    %.4f dB\n\n", x$residual_std_error))
  if (x$frequency_scale == "logarithmic") {
    cat("Model: power_dB = intercept + slope * log10(frequency_Hz)\n")
  } else {
    cat("Model: power_dB = intercept + slope * frequency_Hz\n")
  }
  cat("\nNote: Use $fitted_values to access predicted values for plotting\n")
  invisible(x)
}
