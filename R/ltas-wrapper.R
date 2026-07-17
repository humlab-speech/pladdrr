# ltas-wrapper.R - Ltas object using shared dispatch table (pladdrr 4.8.33)
# Architecture: minimal list + $.Ltas S3 dispatch -> shared method env

#' @title Praat Ltas (Long-term Average Spectrum) Object
#' @description
#' Praat Ltas object for long-term spectral analysis.
#' Uses shared dispatch table for minimal memory per object.
#'
#' @name Ltas
NULL

# ============================================================================
# Helpers
# ============================================================================

.ltas_unit_code <- function(unit) {
  switch(tolower(unit), "energy" = 1L, "sones" = 2L, "db" = 0L, 1L)
}

.ltas_interpolation_code <- function(method) {
  switch(tolower(method),
    "nearest" = 0, "linear" = 1, "cubic" = 2, "sinc70" = 3, "sinc700" = 4, 2)
}

.ltas_peak_interpolation_code <- function(method) {
  switch(tolower(method),
    "none" = 0, "parabolic" = 1, "cubic" = 2, "sinc70" = 3, "sinc700" = 4, 1)
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
.ltas_methods$get_number_of_bins <- function(.self) .self$.cpp$get_number_of_bins()
.ltas_methods$get_bin_width <- function(.self) .self$.cpp$get_bandwidth()
.ltas_methods$get_lowest_frequency <- function(.self) .self$.cpp$get_fmin()
.ltas_methods$get_highest_frequency <- function(.self) .self$.cpp$get_fmax()

# --- Query values ---
.ltas_methods$get_value_at_frequency <- function(.self, frequency, unit = "dB", interpolate = TRUE) {
  .self$.cpp$get_value_at_frequency(as.numeric(frequency), if (interpolate) 2 else 0)
}
.ltas_methods$get_minimum <- function(.self, fmin = 0, fmax = 0, unit = "dB", interpolation = "parabolic") {
  .self$.cpp$get_minimum(fmin, fmax, .ltas_peak_interpolation_code(interpolation))
}
.ltas_methods$get_maximum <- function(.self, fmin = 0, fmax = 0, unit = "dB", interpolation = "parabolic") {
  .self$.cpp$get_maximum(fmin, fmax, .ltas_peak_interpolation_code(interpolation))
}
.ltas_methods$get_mean <- function(.self, fmin = 0, fmax = 0, unit = "dB") {
  .self$.cpp$get_mean(fmin, fmax, .ltas_unit_code(unit))
}
.ltas_methods$get_slope <- function(.self, f1min, f1max, f2min, f2max, unit = "dB") {
  .self$.cpp$get_slope(f1min, f1max, f2min, f2max, .ltas_unit_code(unit))
}

# --- Batch ---
.ltas_methods$get_peaks_batch <- function(.self, fmins, fmaxs, interpolation = "parabolic") {
  .self$.cpp$get_peaks_batch(as.numeric(fmins), as.numeric(fmaxs),
                             .ltas_peak_interpolation_code(interpolation))
}
.ltas_methods$get_minima_batch <- function(.self, fmins, fmaxs, interpolation = "parabolic") {
  .self$.cpp$get_minima_batch(as.numeric(fmins), as.numeric(fmaxs),
                              .ltas_peak_interpolation_code(interpolation))
}
.ltas_methods$get_values_at_frequencies <- function(.self, frequencies, interpolation = "cubic") {
  .self$.cpp$get_values_at_frequencies(as.numeric(frequencies),
                                       .ltas_interpolation_code(interpolation))
}
.ltas_methods$get_means_batch <- function(.self, fmins, fmaxs, unit = "dB") {
  .self$.cpp$get_means_batch(as.numeric(fmins), as.numeric(fmaxs), .ltas_unit_code(unit))
}
.ltas_methods$get_frequency_of_maximum <- function(.self, fmin = 0, fmax = 0, interpolation = "parabolic") {
  .self$.cpp$get_frequency_of_maximum(fmin, fmax, .ltas_peak_interpolation_code(interpolation))
}
.ltas_methods$get_frequency_of_minimum <- function(.self, fmin = 0, fmax = 0, interpolation = "parabolic") {
  .self$.cpp$get_frequency_of_minimum(fmin, fmax, .ltas_peak_interpolation_code(interpolation))
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
                                                frequency_scale = c("logarithmic", "linear"),
                                                fit_method = c("least squares", "robust")) {
  frequency_scale <- match.arg(frequency_scale)
  fit_method <- match.arg(fit_method)
  result <- .ltas_report_spectral_trend(.self$.xptr, as.numeric(fmin), as.numeric(fmax),
                                        frequency_scale, fit_method)
  class(result) <- c("ltas_spectral_trend", "list")
  result
}
.ltas_methods$get_spectral_slope <- function(.self, fmin = 100, fmax = 5000,
                                             frequency_scale = c("logarithmic", "linear"),
                                             fit_method = c("least squares", "robust")) {
  frequency_scale <- match.arg(frequency_scale)
  fit_method <- match.arg(fit_method)
  trend <- .ltas_report_spectral_trend(.self$.xptr, as.numeric(fmin), as.numeric(fmax),
                                       frequency_scale, fit_method)
  trend$slope
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

# --- Print ---
.ltas_methods$print <- function(.self) {
  cat("<Praat Ltas>\n")
  cat(sprintf("  Frequency range: %.2f - %.2f Hz\n", .self$.cpp$get_fmin(), .self$.cpp$get_fmax()))
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
  cpp_obj <- ltas_mod$RLtas$new(.xptr)
  structure(list(.xptr = .xptr, .cpp = cpp_obj), class = c("Ltas", "PraatObject"))
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

#' @export
print.Ltas <- function(x, ...) {
  x$print()
}

#' @export
as.data.frame.Ltas <- function(x, ...) {
  x$as_data_frame()
}

#' Average multiple Ltas objects
#'
#' @param ... Ltas objects to average
#' @return A new Ltas object representing the average
#' @export
ltas_average <- function(...) {
  ltas_list <- list(...)
  if (length(ltas_list) == 1 && is.list(ltas_list[[1]]) && !inherits(ltas_list[[1]], "Ltas")) {
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
