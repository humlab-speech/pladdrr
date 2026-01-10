#' PowerCepstrum Class
#'
#' @description
#' Represents a power cepstrum object from Praat.
#' Implemented as list wrapper around Rcpp module for performance.
#' Used for voice quality analysis, particularly Cepstral Peak Prominence (CPP).
#'
#' @details
#' The power cepstrum is the power spectrum of the logarithmic power spectrum.
#' It's used in voice quality analysis to compute CPP (Cepstral Peak Prominence),
#' a measure of periodicity in the voice signal.
#'
#' ## Creating PowerCepstrum Objects
#'
#' PowerCepstrum objects are created from Spectrum objects:
#' - `spectrum$to_powercepstrum()` - Convert Spectrum to PowerCepstrum
#'
#' ## Query Methods
#'
#' - `$get_peak_prominence()` - Get CPP (Cepstral Peak Prominence) in dB
#' - `$get_quefrency_of_peak()` - Get quefrency of the cepstral peak
#' - `$get_value_at_quefrency()` - Get cepstral value at specific quefrency
#'
#' ## Modification
#'
#' - `$smooth()` - Smooth the cepstrum
#'
#' ## Export
#'
#' - `$to_matrix()` - Convert to Matrix object
#' - `$as_matrix()` - Export as R numeric matrix
#'
#' @examples
#' \dontrun{
#' # Extract CPP from a sound
#' sound <- Sound$new("voice.wav")
#' spectrum <- sound$to_spectrum()
#' cepstrum <- spectrum$to_powercepstrum()
#' cpp <- cepstrum$get_peak_prominence()
#' print(paste("CPP:", round(cpp, 2), "dB"))
#' }
#'
#' @export
PowerCepstrum <- function(.xptr = NULL) {
  if (!inherits(.xptr, "externalptr")) {
    stop(".xptr must be an external pointer")
  }
  
  # Load Rcpp Module
  pc_mod <- get_module("powercepstrum_module")
  cpp_pc <- pc_mod$RPowerCepstrum$new(.xptr)
  
  # Create wrapper
  pc <- structure(list(
    .cpp = cpp_pc,
    .xptr = .xptr,
    
    # Query methods
    is_valid = function() cpp_pc$is_valid(),
    get_qmin = function() cpp_pc$get_qmin(),
    get_qmax = function() cpp_pc$get_qmax(),
    get_quefrency_range = function() cpp_pc$get_quefrency_range(),
    get_n_bins = function() cpp_pc$get_n_bins(),
    get_dq = function() cpp_pc$get_dq(),
    get_q1 = function() cpp_pc$get_q1(),
    
    get_peak_prominence = function(pitch_floor = 60,
                                   pitch_ceiling = 333.3,
                                   interpolation = c("parabolic", "none", "cubic", "sinc70", "sinc700"),
                                   qmin = 0.001,
                                   qmax = 0.05,
                                   fit_method = c("exponential decay", "straight"),
                                   tolerance = 0.05) {
      interpolation <- match.arg(interpolation)
      fit_method <- match.arg(fit_method)
      
      # Use the internal .powercepstrum_get_peak_prominence function directly
      # since the Rcpp module wrapper needs to be regenerated
      .powercepstrum_get_peak_prominence(
        .xptr,
        as.character(interpolation),
        as.numeric(pitch_floor),
        as.numeric(pitch_ceiling),
        as.numeric(qmin),
        as.numeric(qmax),
        as.character(fit_method),
        as.numeric(tolerance)
      )
    },
    
    get_quefrency_of_peak = function(interpolation = c("parabolic", "none", "cubic"),
                                     qmin = 0.003,
                                     qmax = 0.04) {
      interpolation <- match.arg(interpolation)
      interp_map <- c("none" = 0, "parabolic" = 1, "cubic" = 2)
      
      cpp_pc$get_quefrency_of_peak(
        as.integer(interp_map[[interpolation]]),
        as.numeric(qmin),
        as.numeric(qmax)
      )
    },
    
    get_value_at_quefrency = function(quefrency, 
                                     interpolation = c("linear", "cubic"),
                                     unit = c("dB", "linear")) {
      interpolation <- match.arg(interpolation)
      unit <- match.arg(unit)
      
      interp_code <- if (interpolation == "linear") 0L else 1L
      unit_code <- if (unit == "dB") 0L else 1L
      
      cpp_pc$get_value_at_quefrency(
        as.numeric(quefrency),
        as.integer(interp_code),
        as.integer(unit_code)
      )
    },
    
    get_peak_prominence_hillenbrand = function(pitch_floor = 60, pitch_ceiling = 333.3) {
      cpp_pc$get_peak_prominence_hillenbrand(
        as.numeric(pitch_floor),
        as.numeric(pitch_ceiling)
      )
    },
    
    get_rnr = function(pitch_floor = 60, pitch_ceiling = 333.3, f0_fractional_width = 0.05) {
      .powercepstrum_get_rnr(
        .xptr,
        pitch_floor = pitch_floor,
        pitch_ceiling = pitch_ceiling,
        f0_fractional_width = f0_fractional_width
      )
    },
    
    tabulate_rhamonics = function(pitch_floor = 60, pitch_ceiling = 333.3,
                                  interpolation = c("parabolic", "none", "cubic", "sinc70", "sinc700")) {
      interpolation <- match.arg(interpolation)
      
      interp_map <- c(
        "none" = 0,
        "parabolic" = 1,
        "cubic" = 2,
        "sinc70" = 3,
        "sinc700" = 4
      )
      
      xptr <- .powercepstrum_tabulate_rhamonics(
        .xptr,
        pitch_floor = pitch_floor,
        pitch_ceiling = pitch_ceiling,
        interpolation = interp_map[[interpolation]]
      )
      Table(.xptr = xptr)
    },
    
    fit_trend_line = function(qmin = 0.003, qmax = 0.05,
                             trend_type = c("straight", "exponential decay", "parabolic"),
                             fit_method = c("least squares", "robust", "robust slow")) {
      trend_type <- match.arg(trend_type)
      fit_method <- match.arg(fit_method)
      
      trend_map <- c("straight" = 1, "exponential decay" = 2, "parabolic" = 3)
      # Praat enum: kCepstrum_trendFit: ROBUST_FAST=1, LEAST_SQUARES=2, ROBUST_SLOW=3
      fit_map <- c("robust" = 1, "least squares" = 2, "robust slow" = 3)
      
      cpp_pc$fit_trend_line(
        as.numeric(qmin),
        as.numeric(qmax),
        as.integer(trend_map[[trend_type]]),
        as.integer(fit_map[[fit_method]])
      )
    },
    
    get_trend_line_value = function(quefrency, qstart_fit = 0.003, qend_fit = 0.05,
                                   trend_type = c("straight", "exponential decay", "parabolic"),
                                   fit_method = c("least squares", "robust", "robust slow")) {
      trend_type <- match.arg(trend_type)
      fit_method <- match.arg(fit_method)
      
      trend_map <- c("straight" = 1, "exponential decay" = 2, "parabolic" = 3)
      # Praat enum: kCepstrum_trendFit: ROBUST_FAST=1, LEAST_SQUARES=2, ROBUST_SLOW=3
      fit_map <- c("robust" = 1, "least squares" = 2, "robust slow" = 3)
      
      cpp_pc$get_trend_line_value(
        as.numeric(quefrency),
        as.numeric(qstart_fit),
        as.numeric(qend_fit),
        as.integer(trend_map[[trend_type]]),
        as.integer(fit_map[[fit_method]])
      )
    },
    
    # Transformation methods (return new objects)
    smooth = function(averaging_window, nsamples = 100) {
      xptr <- cpp_pc$smooth_ptr(
        as.numeric(averaging_window),
        as.integer(nsamples)
      )
      PowerCepstrum(.xptr = xptr)
    },
    
    subtract_trend = function(qstart_fit = 0.003, qend_fit = 0.05,
                             trend_type = c("straight", "exponential decay", "parabolic"),
                             fit_method = c("least squares", "robust", "robust slow")) {
      trend_type <- match.arg(trend_type)
      fit_method <- match.arg(fit_method)
      
      trend_map <- c("straight" = 1, "exponential decay" = 2, "parabolic" = 3)
      # Praat enum: kCepstrum_trendFit: ROBUST_FAST=1, LEAST_SQUARES=2, ROBUST_SLOW=3
      fit_map <- c("robust" = 1, "least squares" = 2, "robust slow" = 3)
      
      xptr <- cpp_pc$subtract_trend_ptr(
        as.numeric(qstart_fit),
        as.numeric(qend_fit),
        as.integer(trend_map[[trend_type]]),
        as.integer(fit_map[[fit_method]])
      )
      PowerCepstrum(.xptr = xptr)
    },
    
    subtract_trend_inplace = function(qstart_fit = 0.001, qend_fit = 0.05,
                                     trend_type = c("straight", "exponential decay", "parabolic"),
                                     fit_method = c("least squares", "robust", "robust slow")) {
      trend_type <- match.arg(trend_type)
      fit_method <- match.arg(fit_method)
      
      trend_map <- c("straight" = 1, "exponential decay" = 2, "parabolic" = 3)
      # Praat enum: kCepstrum_trendFit: ROBUST_FAST=1, LEAST_SQUARES=2, ROBUST_SLOW=3
      fit_map <- c("robust" = 1, "least squares" = 2, "robust slow" = 3)
      
      cpp_pc$subtract_trend_inplace(
        as.numeric(qstart_fit),
        as.numeric(qend_fit),
        as.integer(trend_map[[trend_type]]),
        as.integer(fit_map[[fit_method]])
      )
      invisible(pc)
    },
    
    to_matrix = function() {
      xptr <- cpp_pc$to_matrix_ptr()
      Matrix(.xptr = xptr)
    },
    
    to_spectrum = function(random_phases = FALSE) {
      xptr <- cpp_pc$to_spectrum_ptr(as.logical(random_phases))
      Spectrum(.xptr = xptr)
    },
    
    # Export methods
    as_matrix = function() cpp_pc$as_matrix(),
    as_data_frame = function() cpp_pc$as_data_frame(),
    save = function(path) cpp_pc$save(as.character(path)),
    get_xptr = function() .xptr,
    
    print = function() {
      cat("<Praat PowerCepstrum>\n")
      cat(sprintf("  Quefrency range: [%.4f, %.4f] s\n", cpp_pc$get_qmin(), cpp_pc$get_qmax()))
      cat(sprintf("  Bins: %d\n", cpp_pc$get_n_bins()))
      invisible(pc)
    }
  ), class = c("PowerCepstrum", "PraatObject"))
  
  pc
}

#' @export
print.PowerCepstrum <- function(x, ...) x$print()


#' PowerCepstrogram Class (Function Wrapper)
#'
#' @description
#' Represents a time-varying power cepstrum (PowerCepstrogram) from Praat.
#' Allows analysis of CPP (Cepstral Peak Prominence) over time.
#'
#' @details
#' A PowerCepstrogram is a time-frequency representation of the power cepstrum,
#' similar to how a Spectrogram represents time-varying spectra. It allows
#' tracking of voice quality measures like CPP across time.
#'
#' ## Creating PowerCepstrogram Objects
#'
#' PowerCepstrogram objects are created from Sound objects:
#' - `sound$to_powercepstrogram()` - Compute time-varying power cepstrum
#'
#' ## Query Methods
#'
#' - `$get_cpp_at_time()` - Get CPP at specific time
#' - `$get_mean_cpp()` - Get mean CPP over time range
#' - `$get_power_cepstrum_at_time()` - Extract PowerCepstrum slice at time
#'
#' ## Modification
#'
#' - `$smooth()` - Smooth in time and quefrency dimensions
#'
#' ## Export
#'
#' - `$to_matrix()` - Convert to Matrix object
#' - `$as_matrix()` - Export as R numeric matrix (quefrency × time)
#'
#' @examples
#' \dontrun{
#' # Analyze CPP over time
#' sound <- Sound("voice.wav")
#' cepstrogram <- sound$to_powercepstrogram(pitch_floor = 60)
#' mean_cpp <- cepstrogram$get_mean_cpp()
#' print(paste("Mean CPP:", round(mean_cpp, 2), "dB"))
#'
#' # Get CPP at specific time
#' cpp_at_1s <- cepstrogram$get_cpp_at_time(time = 1.0)
#' }
#'
#' @export
PowerCepstrogram <- function(.xptr = NULL) {
  if (!inherits(.xptr, "externalptr")) {
    stop(".xptr must be an external pointer")
  }
  
  # Create wrapper
  pcg <- structure(list(
    .xptr = .xptr,
    
    # Query methods
    get_cpp_at_time = function(time,
                               interpolation = c("linear", "cubic"),
                               qmin = 0.003,
                               qmax = 0.04,
                               fit_method = c("straight", "exponential decay", "parabolic"),
                               tolerance = 0.05) {
      interpolation <- match.arg(interpolation)
      fit_method <- match.arg(fit_method)
      
      .powercepstrogram_get_cpp_at_time(
        .xptr,
        time = time,
        interpolation = interpolation,
        qmin = qmin,
        qmax = qmax,
        fit_method = fit_method,
        tolerance = tolerance
      )
    },
    
    get_mean_cpp = function(from_time = 0,
                           to_time = 0,
                           qmin = 0.003,
                           qmax = 0.04,
                           fit_method = c("straight", "exponential decay", "parabolic"),
                           tolerance = 0.05) {
      fit_method <- match.arg(fit_method)
      
      .powercepstrogram_get_mean_cpp(
        .xptr,
        from_time = from_time,
        to_time = to_time,
        qmin = qmin,
        qmax = qmax,
        fit_method = fit_method,
        tolerance = tolerance
      )
    },
    
    get_power_cepstrum_at_time = function(time) {
      ptr <- .powercepstrogram_to_powercepstrum_slice(.xptr, time = time)
      PowerCepstrum(.xptr = ptr)
    },
    
    to_matrix = function() {
      ptr <- .powercepstrogram_to_matrix(.xptr)
      Matrix(.xptr = ptr)
    },
    
    as_matrix = function() {
      .powercepstrogram_as_matrix(.xptr)
    },
    
    get_cpps = function(subtract_tilt = TRUE,
                       time_averaging_window = 0.001,
                       quefrency_averaging_window = 0.0005,
                       pitch_floor = 60,
                       pitch_ceiling = 333.3,
                       delta_f0 = 0.05,
                       interpolation = c("parabolic", "none", "cubic", "sinc70", "sinc700"),
                       quefrency_range_start = 0.003,
                       quefrency_range_end = 0.04,
                       trend_line_type = c("straight", "exponential decay"),
                       fit_method = c("robust", "least squares", "robust slow")) {
      
      interpolation <- match.arg(interpolation)
      trend_line_type <- match.arg(trend_line_type)
      fit_method <- match.arg(fit_method)
      
      # Map to Praat enum values
      interp_map <- c(
        "none" = 0, "parabolic" = 1, "cubic" = 2, 
        "sinc70" = 3, "sinc700" = 4
      )
      
      trend_map <- c("straight" = 1, "exponential decay" = 2)
      fit_map <- c("robust" = 1, "least squares" = 2, "robust slow" = 3)
      
      .powercepstrogram_get_cpps(
        .xptr,
        subtract_tilt = subtract_tilt,
        time_averaging_window = time_averaging_window,
        quefrency_averaging_window = quefrency_averaging_window,
        pitch_floor = pitch_floor,
        pitch_ceiling = pitch_ceiling,
        delta_f0 = delta_f0,
        interpolation = interp_map[[interpolation]],
        qstart_fit = quefrency_range_start,
        qend_fit = quefrency_range_end,
        trend_type = trend_map[[trend_line_type]],
        fit_method = fit_map[[fit_method]]
      )
    },
    
    smooth = function(time_averaging_window, quefrency_averaging_window) {
      ptr <- .powercepstrogram_smooth(
        .xptr,
        time_averaging_window = time_averaging_window,
        quefrency_averaging_window = quefrency_averaging_window
      )
      PowerCepstrogram(.xptr = ptr)
    },
    
    get_xptr = function() .xptr,
    
    print = function() {
      cat("<Praat PowerCepstrogram>\n")
      invisible(pcg)
    }
  ), class = c("PowerCepstrogram", "PraatObject"))
  
  pcg
}

#' @export
print.PowerCepstrogram <- function(x, ...) x$print()
