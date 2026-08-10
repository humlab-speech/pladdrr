# powercepstrum.R - PowerCepstrum and PowerCepstrogram using shared dispatch tables (pladdrr 4.8.33)
# Architecture: minimal list + S3 dispatch → shared method env

#' PowerCepstrum Class
#'
#' @description
#' A PowerCepstrum is the power spectrum of the log power spectrum — a
#' representation that separates the source (glottal pulse, low quefrency)
#' from the filter (vocal tract, high quefrency). Created from a Spectrum
#' or extracted from a PowerCepstrogram at a specific time. The primary
#' voice quality metric from this object is CPP (Cepstral Peak Prominence).
#'
#' @section Methods:
#'
#' **Information:**
#' * `get_qmin()` / `get_qmax()` — Quefrency range (s)
#' * `get_quefrency_range()` — Quefrency range as vector
#' * `get_n_bins()` — Number of quefrency bins
#' * `get_dq()` — Quefrency step (s)
#' * `get_q1()` — Starting quefrency value (s)
#'
#' **Peak analysis:**
#' * `get_peak_prominence(pitch_floor, pitch_ceiling, ...)` — CPP value (dB). Main voice quality metric.
#' * `get_peak_prominence_hillenbrand(pitch_floor, pitch_ceiling)` — CPP using Hillenbrand algorithm
#' * `get_quefrency_of_peak(interpolation)` — Quefrency of cepstral peak (s)
#' * `get_value_at_quefrency(quefrency, interpolation, unit)` — Cepstral amplitude at quefrency
#'
#' **Trend & smoothing:**
#' * `smooth(averaging_window)` — Smooth the cepstrum
#' * `fit_trend_line(qmin, qmax, trend_type, fit_method)` — Fit regression trend line
#' * `get_trend_line_value(quefrency, ...)` — Value of fitted trend at quefrency
#' * `subtract_trend(qstart_fit, qend_fit, ...)` — Subtract regression trend (returns new PowerCepstrum)
#' * `subtract_trend_inplace(qstart_fit, qend_fit, ...)` — Subtract trend in-place (mutates)
#'
#' **Export / Transform:**
#' * `as_matrix()` / `as_data_frame()` — Export
#' * `to_spectrum(random_phases)` — Convert back to Spectrum
#' * `to_matrix()` — Export as matrix
#'
#' @seealso \code{\link{Spectrum}}, \code{\link{PowerCepstrogram}}, \code{\link{Sound}}
#'
#' @return A \code{PowerCepstrum} object with methods for power cepstrum analysis including CPP measurement.
#'
#' @examples
#' sound <- Sound$create_tone(duration = 0.5, frequency = 200, sampling_rate = 44100)
#' spectrum <- sound$to_spectrum()
#' cepstrum <- spectrum$to_power_cepstrum()
#' cpp <- cepstrum$get_peak_prominence()
#' \dontrun{
#' sound <- Sound$new("voice.wav")
#' spectrum <- sound$to_spectrum()
#' cepstrum <- spectrum$to_power_cepstrum()
#' }
#'
#' @name PowerCepstrum
NULL

# ============================================================================
# PowerCepstrum Shared Method Dispatch Table
# ============================================================================

.powercepstrum_methods <- new.env(hash = TRUE, parent = emptyenv())

# --- Query ---
.powercepstrum_methods$is_valid <- function(.self) .self$.cpp$is_valid()
.powercepstrum_methods$get_qmin <- function(.self) .self$.cpp$get_qmin()
.powercepstrum_methods$get_qmax <- function(.self) .self$.cpp$get_qmax()
.powercepstrum_methods$get_quefrency_range <- function(.self) .self$.cpp$get_quefrency_range()
.powercepstrum_methods$get_n_bins <- function(.self) .self$.cpp$get_n_bins()
.powercepstrum_methods$get_dq <- function(.self) .self$.cpp$get_dq()
.powercepstrum_methods$get_q1 <- function(.self) .self$.cpp$get_q1()

.powercepstrum_methods$get_peak_prominence <- function(.self, pitch_floor = 60,
                                                       pitch_ceiling = 333.3,
                                                       interpolation = c("parabolic", "none", "cubic", "sinc70", "sinc700"),
                                                       qmin = 0.001, qmax = 0.05,
                                                       trend_type = c("exponential decay", "straight"),
                                                       fit_method = c("robust slow", "robust", "least squares", "least_squares"),
                                                       tolerance = 0.05) {
  interpolation <- match.arg(interpolation)
  if (missing(trend_type) && !missing(fit_method) &&
      length(fit_method) == 1L && fit_method %in% names(.trend_line_map)) {
    trend_type <- fit_method
    fit_method <- "robust slow"
  }
  trend_type <- match.arg(trend_type)
  fit_method <- match.arg(fit_method)
  .powercepstrum_get_peak_prominence(
    .self$.xptr, as.character(interpolation), as.numeric(pitch_floor),
    as.numeric(pitch_ceiling), as.numeric(qmin), as.numeric(qmax),
    as.character(trend_type), as.character(fit_method), as.numeric(tolerance)
  )
}

.powercepstrum_methods$get_quefrency_of_peak <- function(.self,
                                                         interpolation = c("parabolic", "none", "cubic"),
                                                         qmin = 0.003, qmax = 0.04) {
  interpolation <- match.arg(interpolation)
  .self$.cpp$get_quefrency_of_peak(interpolation, as.numeric(qmin), as.numeric(qmax))
}

.powercepstrum_methods$get_value_at_quefrency <- function(.self, quefrency,
                                                          interpolation = c("linear", "cubic"),
                                                          unit = c("dB", "linear")) {
  interpolation <- match.arg(interpolation)
  unit <- match.arg(unit)
  .self$.cpp$get_value_at_quefrency(as.numeric(quefrency), interpolation, unit)
}

.powercepstrum_methods$get_peak_prominence_hillenbrand <- function(.self, pitch_floor = 60,
                                                                   pitch_ceiling = 333.3) {
  .self$.cpp$get_peak_prominence_hillenbrand(as.numeric(pitch_floor), as.numeric(pitch_ceiling))
}

.powercepstrum_methods$get_rnr <- function(.self, pitch_floor = 60, pitch_ceiling = 333.3,
                                           f0_fractional_width = 0.05) {
  .powercepstrum_get_rnr(.self$.xptr, pitch_floor = pitch_floor,
                         pitch_ceiling = pitch_ceiling, f0_fractional_width = f0_fractional_width)
}

.powercepstrum_methods$tabulate_rhamonics <- function(.self, pitch_floor = 60, pitch_ceiling = 333.3,
                                                      interpolation = c("parabolic", "none", "cubic", "sinc70", "sinc700")) {
  interpolation <- match.arg(interpolation)
  interp_map <- .interp_map
  xptr <- .powercepstrum_tabulate_rhamonics(.self$.xptr, pitch_floor = pitch_floor,
                                            pitch_ceiling = pitch_ceiling,
                                            interpolation = interp_map[[interpolation]])
  Table(.xptr = xptr)
}

.powercepstrum_methods$fit_trend_line <- function(.self, qmin = 0.003, qmax = 0.05,
                                                  trend_type = c("straight", "exponential decay", "parabolic"),
                                                  fit_method = c("least squares", "robust", "robust slow")) {
  trend_type <- match.arg(trend_type)
  fit_method <- match.arg(fit_method)
  trend_map <- .trend_line_map
  fit_map <- .trend_fit_map
  .self$.cpp$fit_trend_line(as.numeric(qmin), as.numeric(qmax),
                            as.integer(trend_map[[trend_type]]),
                            as.integer(fit_map[[fit_method]]))
}

.powercepstrum_methods$get_trend_line_value <- function(.self, quefrency, qstart_fit = 0.003,
                                                        qend_fit = 0.05,
                                                        trend_type = c("straight", "exponential decay", "parabolic"),
                                                        fit_method = c("least squares", "robust", "robust slow")) {
  trend_type <- match.arg(trend_type)
  fit_method <- match.arg(fit_method)
  trend_map <- .trend_line_map
  fit_map <- .trend_fit_map
  .self$.cpp$get_trend_line_value(as.numeric(quefrency), as.numeric(qstart_fit),
                                  as.numeric(qend_fit),
                                  as.integer(trend_map[[trend_type]]),
                                  as.integer(fit_map[[fit_method]]))
}

# --- Transform (return new objects) ---
.powercepstrum_methods$smooth <- function(.self, averaging_window, nsamples = 100) {
  xptr <- .self$.cpp$smooth_ptr(as.numeric(averaging_window), as.integer(nsamples))
  PowerCepstrum(.xptr = xptr)
}
.powercepstrum_methods$subtract_trend <- function(.self, qstart_fit = 0.003, qend_fit = 0.05,
                                                  trend_type = c("straight", "exponential decay", "parabolic"),
                                                  fit_method = c("least squares", "robust", "robust slow")) {
  trend_type <- match.arg(trend_type)
  fit_method <- match.arg(fit_method)
  trend_map <- .trend_line_map
  fit_map <- .trend_fit_map
  xptr <- .self$.cpp$subtract_trend_ptr(as.numeric(qstart_fit), as.numeric(qend_fit),
                                        as.integer(trend_map[[trend_type]]),
                                        as.integer(fit_map[[fit_method]]))
  PowerCepstrum(.xptr = xptr)
}
.powercepstrum_methods$subtract_trend_inplace <- function(.self, qstart_fit = 0.001, qend_fit = 0.05,
                                                          trend_type = c("straight", "exponential decay", "parabolic"),
                                                          fit_method = c("least squares", "robust", "robust slow")) {
  trend_type <- match.arg(trend_type)
  fit_method <- match.arg(fit_method)
  trend_map <- .trend_line_map
  fit_map <- .trend_fit_map
  .self$.cpp$subtract_trend_inplace(as.numeric(qstart_fit), as.numeric(qend_fit),
                                    as.integer(trend_map[[trend_type]]),
                                    as.integer(fit_map[[fit_method]]))
  invisible(.self)
}
.powercepstrum_methods$to_matrix <- function(.self) {
  xptr <- .self$.cpp$to_matrix_ptr()
  Matrix(.xptr = xptr)
}
.powercepstrum_methods$to_spectrum <- function(.self, random_phases = FALSE) {
  xptr <- .self$.cpp$to_spectrum_ptr(as.logical(random_phases))
  Spectrum(.xptr = xptr)
}

# --- Export ---
.powercepstrum_methods$as_matrix <- function(.self) .self$.cpp$as_matrix()
.powercepstrum_methods$as_data_frame <- function(.self) .self$.cpp$as_data_frame()
.powercepstrum_methods$save <- function(.self, path) .self$.cpp$save(as.character(path))
.powercepstrum_methods$get_xptr <- function(.self) .self$.xptr

# --- Print ---
.powercepstrum_methods$print <- function(.self) {
  cat("<Praat PowerCepstrum>\n")
  cat(sprintf("  Quefrency range: [%.4f, %.4f] s\n", .self$.cpp$get_qmin(), .self$.cpp$get_qmax()))
  cat(sprintf("  Bins: %d\n", .self$.cpp$get_n_bins()))
  invisible(.self)
}

lockEnvironment(.powercepstrum_methods, bindings = TRUE)

# ============================================================================
# PowerCepstrum Constructor
# ============================================================================

#' @export
PowerCepstrum <- function(.xptr = NULL) {
  if (!inherits(.xptr, "externalptr")) {
    stop(".xptr must be an external pointer")
  }
  pc_mod <- get_module("powercepstrum_module")
  cpp_pc <- pc_mod$RPowerCepstrum$new(.xptr)
  structure(list(.xptr = .xptr, .cpp = cpp_pc), class = c("PowerCepstrum", "PraatObject"))
}

# ============================================================================
# PowerCepstrum S3 Dispatch
# ============================================================================

#' @method $ PowerCepstrum
#' @export
`$.PowerCepstrum` <- function(x, name) {
  val <- .subset2(x, name)
  if (!is.null(val)) return(val)
  if (name == ".pointer") return(.subset2(x, ".xptr"))
  method <- .powercepstrum_methods[[name]]
  if (is.null(method)) return(NULL)
  function(...) method(x, ...)
}

#' @export
print.PowerCepstrum <- function(x, ...) x$print()


# ============================================================================
# PowerCepstrogram Shared Method Dispatch Table
# ============================================================================

#' PowerCepstrogram Class
#'
#' @description
#' Represents a time-varying power cepstrum (PowerCepstrogram) from Praat.
#' Uses shared dispatch table for minimal memory per object.
#' Note: No Rcpp module — uses direct Rcpp function calls.
#'
#' @return A \code{PowerCepstrogram} object with methods for time-varying power cepstrum analysis.
#'
#' @examples
#' sound <- Sound$create_tone(frequency = 150, duration = 0.3)
#' cepstrogram <- sound$to_powercepstrogram(pitch_floor = 60)
#' mean_cpp <- cepstrogram$get_mean_cpp()
#'
#' @name PowerCepstrogram
NULL

.powercepstrogram_methods <- new.env(hash = TRUE, parent = emptyenv())

.powercepstrogram_methods$get_cpp_at_time <- function(.self, time,
                                                      interpolation = c("linear", "cubic"),
                                                      qmin = 0.003, qmax = 0.04,
                                                      fit_method = c("straight", "exponential decay", "parabolic"),
                                                      tolerance = 0.05) {
  interpolation <- match.arg(interpolation)
  fit_method <- match.arg(fit_method)
  .powercepstrogram_get_cpp_at_time(.self$.xptr, time = time, interpolation = interpolation,
                                    qmin = qmin, qmax = qmax, fit_method = fit_method,
                                    tolerance = tolerance)
}

.powercepstrogram_methods$get_mean_cpp <- function(.self, from_time = 0, to_time = 0,
                                                   qmin = 0.003, qmax = 0.04,
                                                   fit_method = c("straight", "exponential decay", "parabolic"),
                                                   tolerance = 0.05) {
  fit_method <- match.arg(fit_method)
  .powercepstrogram_get_mean_cpp(.self$.xptr, from_time = from_time, to_time = to_time,
                                 qmin = qmin, qmax = qmax, fit_method = fit_method,
                                 tolerance = tolerance)
}

.powercepstrogram_methods$get_power_cepstrum_at_time <- function(.self, time) {
  ptr <- .powercepstrogram_to_powercepstrum_slice(.self$.xptr, time = time)
  PowerCepstrum(.xptr = ptr)
}

.powercepstrogram_methods$to_matrix <- function(.self) {
  ptr <- .powercepstrogram_to_matrix(.self$.xptr)
  Matrix(.xptr = ptr)
}

.powercepstrogram_methods$as_matrix <- function(.self) {
  .powercepstrogram_as_matrix(.self$.xptr)
}

.powercepstrogram_methods$get_cpps <- function(.self, subtract_tilt = TRUE,
                                               time_averaging_window = 0.001,
                                               quefrency_averaging_window = 0.0005,
                                               pitch_floor = 60, pitch_ceiling = 333.3,
                                               delta_f0 = 0.05,
                                               interpolation = c("parabolic", "none", "cubic", "sinc70", "sinc700"),
                                               quefrency_range_start = 0.003,
                                               quefrency_range_end = 0.04,
                                               trend_line_type = c("straight", "exponential decay"),
                                               fit_method = c("robust", "least squares", "robust slow")) {
  interpolation <- match.arg(interpolation)
  trend_line_type <- match.arg(trend_line_type)
  fit_method <- match.arg(fit_method)
  .check_trend_fit_method(fit_method)
  .check_quefrency_range(quefrency_range_start, quefrency_range_end,
                         "quefrency_range_start", "quefrency_range_end")
  interp_map <- .interp_map
  trend_map <- .cpps_trend_map
  fit_map <- .trend_fit_map
  .powercepstrogram_get_cpps(.self$.xptr, subtract_tilt = subtract_tilt,
                             time_averaging_window = time_averaging_window,
                             quefrency_averaging_window = quefrency_averaging_window,
                             pitch_floor = pitch_floor, pitch_ceiling = pitch_ceiling,
                             delta_f0 = delta_f0, interpolation = interp_map[[interpolation]],
                             qstart_fit = quefrency_range_start, qend_fit = quefrency_range_end,
                             trend_type = trend_map[[trend_line_type]],
                             fit_method = fit_map[[fit_method]])
}

.powercepstrogram_methods$smooth <- function(.self, time_averaging_window, quefrency_averaging_window) {
  ptr <- .powercepstrogram_smooth(.self$.xptr,
                                  time_averaging_window = time_averaging_window,
                                  quefrency_averaging_window = quefrency_averaging_window)
  PowerCepstrogram(.xptr = ptr)
}

.powercepstrogram_methods$get_xptr <- function(.self) .self$.xptr

.powercepstrogram_methods$print <- function(.self) {
  cat("<Praat PowerCepstrogram>\n")
  invisible(.self)
}

lockEnvironment(.powercepstrogram_methods, bindings = TRUE)

# ============================================================================
# PowerCepstrogram Constructor
# ============================================================================

#' @export
PowerCepstrogram <- function(.xptr = NULL) {
  if (!inherits(.xptr, "externalptr")) {
    stop(".xptr must be an external pointer")
  }
  # No module — pure Rcpp function wrapper
  structure(list(.xptr = .xptr), class = c("PowerCepstrogram", "PraatObject"))
}

# ============================================================================
# PowerCepstrogram S3 Dispatch
# ============================================================================

#' @method $ PowerCepstrogram
#' @export
`$.PowerCepstrogram` <- function(x, name) {
  val <- .subset2(x, name)
  if (!is.null(val)) return(val)
  if (name == ".pointer") return(.subset2(x, ".xptr"))
  method <- .powercepstrogram_methods[[name]]
  if (is.null(method)) return(NULL)
  function(...) method(x, ...)
}

#' @export
print.PowerCepstrogram <- function(x, ...) x$print()
