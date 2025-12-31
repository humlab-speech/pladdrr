#' PowerCepstrum R6 Class
#'
#' @description
#' Represents a power cepstrum object from Praat.
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
    
    get_peak_prominence = function(interpolation = c("parabolic", "none", "cubic", "sinc70", "sinc700"),
                                   qmin = 0.001,
                                   qmax = 0,
                                   fit_method = c("straight", "exponential decay", "parabolic"),
                                   tolerance = 0.05) {
      interpolation <- match.arg(interpolation)
      fit_method <- match.arg(fit_method)
      
      interp_map <- c("none" = 0, "parabolic" = 1, "cubic" = 2, "sinc70" = 3, "sinc700" = 4)
      fit_map <- c("straight" = 1, "exponential decay" = 2, "parabolic" = 3)
      
      cpp_pc$get_peak_prominence(
        as.integer(interp_map[[interpolation]]),
        as.numeric(qmin),
        as.numeric(qmax),
        as.integer(fit_map[[fit_method]]),
        as.numeric(tolerance)
      )
    },
    
    get_quefrency_of_peak = function(interpolation = c("parabolic", "none", "cubic"),
                                     qmin = 0.001,
                                     qmax = 0) {
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
    
    fit_trend_line = function(qmin = 0.001, qmax = 0.05,
                             trend_type = c("straight", "exponential decay", "parabolic"),
                             fit_method = c("least squares", "robust", "robust slow")) {
      trend_type <- match.arg(trend_type)
      fit_method <- match.arg(fit_method)
      
      trend_map <- c("straight" = 1, "exponential decay" = 2, "parabolic" = 3)
      fit_map <- c("least squares" = 1, "robust" = 2, "robust slow" = 3)
      
      cpp_pc$fit_trend_line(
        as.numeric(qmin),
        as.numeric(qmax),
        as.integer(trend_map[[trend_type]]),
        as.integer(fit_map[[fit_method]])
      )
    },
    
    get_trend_line_value = function(quefrency, qstart_fit = 0.001, qend_fit = 0.05,
                                   trend_type = c("straight", "exponential decay", "parabolic"),
                                   fit_method = c("least squares", "robust", "robust slow")) {
      trend_type <- match.arg(trend_type)
      fit_method <- match.arg(fit_method)
      
      trend_map <- c("straight" = 1, "exponential decay" = 2, "parabolic" = 3)
      fit_map <- c("least squares" = 1, "robust" = 2, "robust slow" = 3)
      
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
    
    subtract_trend = function(qstart_fit = 0.001, qend_fit = 0.05,
                             trend_type = c("straight", "exponential decay", "parabolic"),
                             fit_method = c("least squares", "robust", "robust slow")) {
      trend_type <- match.arg(trend_type)
      fit_method <- match.arg(fit_method)
      
      trend_map <- c("straight" = 1, "exponential decay" = 2, "parabolic" = 3)
      fit_map <- c("least squares" = 1, "robust" = 2, "robust slow" = 3)
      
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
      fit_map <- c("least squares" = 1, "robust" = 2, "robust slow" = 3)
      
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


#' PowerCepstrogram R6 Class
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
#' sound <- Sound$new("voice.wav")
#' cepstrogram <- sound$to_powercepstrogram(pitch_floor = 60)
#' mean_cpp <- cepstrogram$get_mean_cpp()
#' print(paste("Mean CPP:", round(mean_cpp, 2), "dB"))
#'
#' # Get CPP at specific time
#' cpp_at_1s <- cepstrogram$get_cpp_at_time(time = 1.0)
#' }
#'
#' @export
PowerCepstrogram <- R6::R6Class(
  "PowerCepstrogram",
  public = list(
    #' @field .xptr External pointer to Praat PowerCepstrogram object
    .xptr = NULL,
    
    #' @description
    #' Create a new PowerCepstrogram object (internal use)
    #' @param .xptr External pointer to Praat object
    initialize = function(.xptr) {
      if (!inherits(.xptr, "externalptr")) {
        stop(".xptr must be an external pointer")
      }
      private$ptr <- .xptr
    },
    
    #' @description
    #' Get CPP at a specific time
    #' @param time Numeric. Time in seconds
    #' @param interpolation Character. Time interpolation method
    #' @param qmin Numeric. Minimum quefrency
    #' @param qmax Numeric. Maximum quefrency
    #' @param fit_method Character. Fit method for trend line
    #' @param tolerance Numeric. Tolerance for fit
    #' @return Numeric. CPP value in dB
    get_cpp_at_time = function(time,
                               interpolation = c("linear", "cubic"),
                               qmin = 0.001,
                               qmax = 0,
                               fit_method = c("straight", "exponential decay", "parabolic"),
                               tolerance = 0.05) {
      interpolation <- match.arg(interpolation)
      fit_method <- match.arg(fit_method)
      
      .powercepstrogram_get_cpp_at_time(
        private$ptr,
        time = time,
        interpolation = interpolation,
        qmin = qmin,
        qmax = qmax,
        fit_method = fit_method,
        tolerance = tolerance
      )
    },
    
    #' @description
    #' Get mean CPP over a time range
    #' @param from_time Numeric. Start time (0 = start of object)
    #' @param to_time Numeric. End time (0 = end of object)
    #' @param qmin Numeric. Minimum quefrency
    #' @param qmax Numeric. Maximum quefrency
    #' @param fit_method Character. Fit method for trend line
    #' @param tolerance Numeric. Tolerance for fit
    #' @return Numeric. Mean CPP in dB
    get_mean_cpp = function(from_time = 0,
                           to_time = 0,
                           qmin = 0.001,
                           qmax = 0,
                           fit_method = c("straight", "exponential decay", "parabolic"),
                           tolerance = 0.05) {
      fit_method <- match.arg(fit_method)
      
      .powercepstrogram_get_mean_cpp(
        private$ptr,
        from_time = from_time,
        to_time = to_time,
        qmin = qmin,
        qmax = qmax,
        fit_method = fit_method,
        tolerance = tolerance
      )
    },
    
    #' @description
    #' Get PowerCepstrum slice at a specific time
    #' @param time Numeric. Time in seconds
    #' @return PowerCepstrum object
    get_power_cepstrum_at_time = function(time) {
      xptr <- .powercepstrogram_to_powercepstrum_slice(private$ptr, time = time)
      PowerCepstrum(.xptr = xptr)
    },
    
    #' @description
    #' Convert to Matrix
    #' @return Matrix object
    to_matrix = function() {
      xptr <- .powercepstrogram_to_matrix(private$ptr)
      Matrix(.xptr = xptr)
    },
    
    #' @description
    #' Convert to R matrix
    #' @return Numeric matrix (quefrency × time)
    as_matrix = function() {
      .powercepstrogram_as_matrix(private$ptr)
    },
    
    #' @description
    #' Get CPPS (Smoothed Cepstral Peak Prominence) - CRITICAL FOR AVQI
    #' 
    #' Computes the Smoothed Cepstral Peak Prominence, a robust measure of voice quality
    #' that is less sensitive to noise than traditional CPP. This is one of the six
    #' acoustic measures required for AVQI calculation.
    #' 
    #' @param subtract_tilt Logical. Subtract trend line before smoothing (default: TRUE)
    #' @param time_averaging_window Numeric. Time smoothing window in seconds (default: 0.001)
    #' @param quefrency_averaging_window Numeric. Quefrency smoothing window in seconds (default: 0.0005)
    #' @param pitch_floor Numeric. Minimum pitch in Hz for peak search (default: 60)
    #' @param pitch_ceiling Numeric. Maximum pitch in Hz for peak search (default: 333.3)
    #' @param delta_f0 Numeric. Step size for F0 search (default: 0.05)
    #' @param interpolation Character. Peak interpolation method (default: "parabolic")
    #' @param quefrency_range_start Numeric. Start of quefrency fit range (default: 0.001)
    #' @param quefrency_range_end Numeric. End of quefrency fit range (default: 0.05)
    #' @param trend_line_type Character. Trend line type (default: "straight")
    #' @param fit_method Character. Fitting method (default: "least squares")
    #' 
    #' @return Numeric. CPPS value in dB
    #' 
    #' @details
    #' CPPS is computed by:
    #' 1. Optionally subtracting a trend line from the cepstrogram
    #' 2. Smoothing in both time and quefrency dimensions
    #' 3. Finding the peak in the expected F0 range
    #' 4. Measuring the prominence of that peak above the regression line
    #'
    #' For AVQI, use the default parameters which match the AVQI protocol
    #' (Barsties & Maryn, 2015).
    #' 
    #' @examples
    #' \dontrun{
    #' sound <- Sound$new("voice.wav")
    #' cepstrogram <- sound$to_power_cepstrogram(
    #'   pitch_floor = 60,
    #'   time_step = 0.002,
    #'   max_frequency = 5000,
    #'   pre_emphasis_from = 50
    #' )
    #' 
    #' # Get CPPS with AVQI-standard parameters
    #' cpps <- cepstrogram$get_cpps(
    #'   subtract_tilt = TRUE,
    #'   time_averaging_window = 0.001,
    #'   quefrency_averaging_window = 0.05,
    #'   pitch_floor = 60,
    #'   pitch_ceiling = 330
    #' )
    #' cat("CPPS:", round(cpps, 2), "dB\n")
    #' }
    get_cpps = function(subtract_tilt = TRUE,
                       time_averaging_window = 0.001,
                       quefrency_averaging_window = 0.0005,
                       pitch_floor = 60,
                       pitch_ceiling = 333.3,
                       delta_f0 = 0.05,
                       interpolation = c("parabolic", "none", "cubic", "sinc70", "sinc700"),
                       quefrency_range_start = 0.001,
                       quefrency_range_end = 0.05,
                        trend_line_type = c("straight", "exponential decay"),
                        fit_method = c("robust", "least squares", "robust slow")) {
      
      interpolation <- match.arg(interpolation)
      trend_line_type <- match.arg(trend_line_type)
      fit_method <- match.arg(fit_method)
      
      # Map to Praat enum values (from Vector_enums.h and Cepstrum_enums.h)
      interp_map <- c(
        "none" = 0,
        "parabolic" = 1,
        "cubic" = 2,
        "sinc70" = 3,
        "sinc700" = 4
      )
      
      # kCepstrum_trendType: 1=LINEAR, 2=EXPONENTIAL_DECAY
      trend_map <- c(
        "straight" = 1,
        "exponential decay" = 2
      )
      
      # kCepstrum_trendFit: 1=ROBUST_FAST, 2=LEAST_SQUARES, 3=ROBUST_SLOW
      fit_map <- c(
        "robust" = 1,
        "least squares" = 2,
        "robust slow" = 3
      )
      
      .powercepstrogram_get_cpps(
        private$ptr,
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
    
    #' @description
    #' Smooth the power cepstrogram
    #' @param time_averaging_window Numeric. Time smoothing window (seconds)
    #' @param quefrency_averaging_window Numeric. Quefrency smoothing window (seconds)
    #' @return New PowerCepstrogram object
    smooth = function(time_averaging_window, quefrency_averaging_window) {
      xptr <- .powercepstrogram_smooth(
        private$ptr,
        time_averaging_window = time_averaging_window,
        quefrency_averaging_window = quefrency_averaging_window
      )
      PowerCepstrogram$new(xptr)
    }
  ),

  private = list(
    ptr = NULL
  )
)
