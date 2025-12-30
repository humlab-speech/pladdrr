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
PowerCepstrum <- R6::R6Class(
  "PowerCepstrum",
  public = list(
    #' @field .xptr External pointer to Praat PowerCepstrum object
    .xptr = NULL,
    
    #' @description
    #' Create a new PowerCepstrum object (internal use)
    #' @param .xptr External pointer to Praat object
    initialize = function(.xptr) {
      if (!inherits(.xptr, "externalptr")) {
        stop(".xptr must be an external pointer")
      }
      private$ptr <- .xptr
    },
    
    #' @description
    #' Get peak prominence (CPP - Cepstral Peak Prominence)
    #' @param interpolation Character. Interpolation method: "none", "parabolic", "cubic", "sinc70", "sinc700"
    #' @param qmin Numeric. Minimum quefrency for peak search (seconds)
    #' @param qmax Numeric. Maximum quefrency for peak search (seconds)
    #' @param fit_method Character. Fit method for trend line: "straight", "exponential decay", "parabolic"
    #' @param tolerance Numeric. Tolerance for fit (default: 0.05)
    #' @return Numeric. CPP value in dB
    get_peak_prominence = function(interpolation = c("parabolic", "none", "cubic", "sinc70", "sinc700"),
                                   qmin = 0.001,
                                   qmax = 0,
                                   fit_method = c("straight", "exponential decay", "parabolic"),
                                   tolerance = 0.05) {
      interpolation <- match.arg(interpolation)
      fit_method <- match.arg(fit_method)
      
      .powercepstrum_get_peak_prominence(
        private$ptr, 
        interpolation = interpolation,
        qmin = qmin,
        qmax = qmax,
        fit_method = fit_method,
        tolerance = tolerance
      )
    },
    
    #' @description
    #' Get quefrency of peak
    #' @param interpolation Character. Interpolation method
    #' @param qmin Numeric. Minimum quefrency
    #' @param qmax Numeric. Maximum quefrency
    #' @return Numeric. Quefrency in seconds
    get_quefrency_of_peak = function(interpolation = c("parabolic", "none", "cubic"),
                                     qmin = 0.001,
                                     qmax = 0) {
      interpolation <- match.arg(interpolation)
      
      .powercepstrum_get_quefrency_of_peak(
        private$ptr,
        interpolation = interpolation,
        qmin = qmin,
        qmax = qmax
      )
    },
    
    #' @description
    #' Get value at quefrency
    #' @param quefrency Numeric. Quefrency in seconds
    #' @param interpolation Character. Interpolation method
    #' @param unit Character. Unit: "dB" or "linear"
    #' @return Numeric. Value at quefrency
    get_value_at_quefrency = function(quefrency, 
                                     interpolation = c("linear", "cubic"),
                                     unit = c("dB", "linear")) {
      interpolation <- match.arg(interpolation)
      unit <- match.arg(unit)
      
      .powercepstrum_get_value_at_quefrency(
        private$ptr,
        quefrency = quefrency,
        interpolation = interpolation,
        unit = unit
      )
    },
    
    #' @description
    #' Smooth the power cepstrum
    #' @param averaging_window Numeric. Window length in seconds
    #' @param nsamples Integer. Number of samples
    #' @return New PowerCepstrum object
    smooth = function(averaging_window, nsamples = 100) {
      xptr <- .powercepstrum_smooth(
        private$ptr,
        averaging_window = averaging_window,
        nsamples = as.integer(nsamples)
      )
      PowerCepstrum$new(xptr)
    },
    
    #' @description
    #' Convert to Matrix
    #' @return Matrix object
    to_matrix = function() {
      xptr <- .powercepstrum_to_matrix(private$ptr)
      Matrix(.xptr = xptr)
    },
    
    #' @description
    #' Convert to R matrix
    #' @return Numeric matrix
    as_matrix = function() {
      .powercepstrum_as_matrix(private$ptr)
    },
    
    #' @description
    #' Convert PowerCepstrum to Spectrum
    #' 
    #' Converts the power cepstrum back to a spectrum representation.
    #' Since phase information is lost in PowerCepstrum, you can optionally
    #' generate random phases.
    #' 
    #' @param random_phases Logical. If TRUE, generate random phases (default: FALSE)
    #' @return Spectrum object
    to_spectrum = function(random_phases = FALSE) {
      xptr <- .powercepstrum_to_spectrum(private$ptr, random_phases = random_phases)
      Spectrum(xptr)
    },
    
    #' @description
    #' Get peak prominence using Hillenbrand method
    #' 
    #' Computes peak prominence using the standard Hillenbrand algorithm,
    #' which is an alternative to the general getPeakProminence method.
    #' 
    #' @param pitch_floor Numeric. Minimum pitch in Hz (default: 60)
    #' @param pitch_ceiling Numeric. Maximum pitch in Hz (default: 333.3)
    #' @return List with 'prominence' (dB) and 'quefrency' (seconds)
    get_peak_prominence_hillenbrand = function(pitch_floor = 60, pitch_ceiling = 333.3) {
      .powercepstrum_get_peak_prominence_hillenbrand(
        private$ptr,
        pitch_floor = pitch_floor,
        pitch_ceiling = pitch_ceiling
      )
    },
    
    #' @description
    #' Get RNR (Rahmonic-to-Noise Ratio)
    #' 
    #' Computes the Rahmonic-to-Noise Ratio, a voice quality measure
    #' that quantifies the ratio of periodic to aperiodic energy in the cepstrum.
    #' 
    #' @param pitch_floor Numeric. Minimum pitch in Hz (default: 60)
    #' @param pitch_ceiling Numeric. Maximum pitch in Hz (default: 333.3)
    #' @param f0_fractional_width Numeric. Fractional bandwidth around F0 (default: 0.05)
    #' @return Numeric. RNR value in dB
    get_rnr = function(pitch_floor = 60, pitch_ceiling = 333.3, f0_fractional_width = 0.05) {
      .powercepstrum_get_rnr(
        private$ptr,
        pitch_floor = pitch_floor,
        pitch_ceiling = pitch_ceiling,
        f0_fractional_width = f0_fractional_width
      )
    },
    
    #' @description
    #' Tabulate rhamonics (quefrency peaks)
    #' 
    #' Creates a table of rhamonics (peaks in the cepstrum corresponding to
    #' harmonics in the original signal). The table contains quefrency values
    #' and their corresponding power.
    #' 
    #' @param pitch_floor Numeric. Minimum pitch in Hz (default: 60)
    #' @param pitch_ceiling Numeric. Maximum pitch in Hz (default: 333.3)
    #' @param interpolation Character. Peak interpolation method
    #' @return Table object with quefrency and power columns
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
        private$ptr,
        pitch_floor = pitch_floor,
        pitch_ceiling = pitch_ceiling,
        interpolation = interp_map[[interpolation]]
      )
      Table$new(xptr)
    },
    
    #' @description
    #' Fit trend line to cepstrum
    #' 
    #' Fits a trend line (linear or exponential decay) to the power cepstrum
    #' and returns the slope and intercept parameters.
    #' 
    #' @param qmin Numeric. Minimum quefrency for fit (default: 0.001)
    #' @param qmax Numeric. Maximum quefrency for fit (default: 0.05)
    #' @param trend_type Character. Type of trend line
    #' @param fit_method Character. Fitting method
    #' @return List with 'slope' and 'intercept'
    fit_trend_line = function(qmin = 0.001, qmax = 0.05,
                             trend_type = c("straight", "exponential decay", "parabolic"),
                             fit_method = c("least squares", "robust", "robust slow")) {
      trend_type <- match.arg(trend_type)
      fit_method <- match.arg(fit_method)
      
      trend_map <- c("straight" = 1, "exponential decay" = 2, "parabolic" = 3)
      fit_map <- c("least squares" = 1, "robust" = 2, "robust slow" = 3)
      
      .powercepstrum_fit_trend_line(
        private$ptr,
        qmin = qmin,
        qmax = qmax,
        trend_type = trend_map[[trend_type]],
        fit_method = fit_map[[fit_method]]
      )
    },
    
    #' @description
    #' Get trend line value at quefrency
    #' 
    #' Returns the value of the fitted trend line at a specific quefrency.
    #' 
    #' @param quefrency Numeric. Quefrency in seconds
    #' @param qstart_fit Numeric. Start of fitting range (default: 0.001)
    #' @param qend_fit Numeric. End of fitting range (default: 0.05)
    #' @param trend_type Character. Type of trend line
    #' @param fit_method Character. Fitting method
    #' @return Numeric. Trend line value at quefrency
    get_trend_line_value = function(quefrency, qstart_fit = 0.001, qend_fit = 0.05,
                                    trend_type = c("straight", "exponential decay", "parabolic"),
                                    fit_method = c("least squares", "robust", "robust slow")) {
      trend_type <- match.arg(trend_type)
      fit_method <- match.arg(fit_method)
      
      trend_map <- c("straight" = 1, "exponential decay" = 2, "parabolic" = 3)
      fit_map <- c("least squares" = 1, "robust" = 2, "robust slow" = 3)
      
      .powercepstrum_get_trend_line_value(
        private$ptr,
        quefrency = quefrency,
        qstart_fit = qstart_fit,
        qend_fit = qend_fit,
        trend_type = trend_map[[trend_type]],
        fit_method = fit_map[[fit_method]]
      )
    },
    
    #' @description
    #' Subtract trend line from cepstrum
    #' 
    #' Creates a new PowerCepstrum with the trend line subtracted. This is
    #' useful for removing low-frequency trends before analysis.
    #' 
    #' @param qstart_fit Numeric. Start of fitting range (default: 0.001)
    #' @param qend_fit Numeric. End of fitting range (default: 0.05)
    #' @param trend_type Character. Type of trend line
    #' @param fit_method Character. Fitting method
    #' @return New PowerCepstrum object with trend removed
    subtract_trend = function(qstart_fit = 0.001, qend_fit = 0.05,
                             trend_type = c("straight", "exponential decay", "parabolic"),
                             fit_method = c("least squares", "robust", "robust slow")) {
      trend_type <- match.arg(trend_type)
      fit_method <- match.arg(fit_method)
      
      trend_map <- c("straight" = 1, "exponential decay" = 2, "parabolic" = 3)
      fit_map <- c("least squares" = 1, "robust" = 2, "robust slow" = 3)
      
      xptr <- .powercepstrum_subtract_trend(
        private$ptr,
        qstart_fit = qstart_fit,
        qend_fit = qend_fit,
        trend_type = trend_map[[trend_type]],
        fit_method = fit_map[[fit_method]]
      )
      PowerCepstrum$new(xptr)
    },
    
    #' @description
    #' Subtract trend line in-place
    #' 
    #' Modifies this PowerCepstrum by subtracting the trend line.
    #' Unlike subtract_trend(), this modifies the object in-place.
    #' 
    #' @param qstart_fit Numeric. Start of fitting range (default: 0.001)
    #' @param qend_fit Numeric. End of fitting range (default: 0.05)
    #' @param trend_type Character. Type of trend line
    #' @param fit_method Character. Fitting method
    #' @return NULL (modifies object in-place)
    subtract_trend_inplace = function(qstart_fit = 0.001, qend_fit = 0.05,
                                     trend_type = c("straight", "exponential decay", "parabolic"),
                                     fit_method = c("least squares", "robust", "robust slow")) {
      trend_type <- match.arg(trend_type)
      fit_method <- match.arg(fit_method)
      
      trend_map <- c("straight" = 1, "exponential decay" = 2, "parabolic" = 3)
      fit_map <- c("least squares" = 1, "robust" = 2, "robust slow" = 3)
      
      .powercepstrum_subtract_trend_inplace(
        private$ptr,
        qstart_fit = qstart_fit,
        qend_fit = qend_fit,
        trend_type = trend_map[[trend_type]],
        fit_method = fit_map[[fit_method]]
      )
      invisible(self)
    }
  ),

  private = list(
    ptr = NULL
  )
)


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
      PowerCepstrum$new(xptr)
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
