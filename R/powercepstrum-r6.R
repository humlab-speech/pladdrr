#' PowerCepstrum R6 Class
#'
#' Represents a power cepstrum object from Praat.
#' Used for voice quality analysis, particularly Cepstral Peak Prominence (CPP).
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
      self$.xptr <- .xptr
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
      
      praat_powercepstrum_get_peak_prominence(
        self$.xptr, 
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
      
      praat_powercepstrum_get_quefrency_of_peak(
        self$.xptr,
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
      
      praat_powercepstrum_get_value_at_quefrency(
        self$.xptr,
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
      xptr <- praat_powercepstrum_smooth(
        self$.xptr,
        averaging_window = averaging_window,
        nsamples = as.integer(nsamples)
      )
      PowerCepstrum$new(xptr)
    },
    
    #' @description
    #' Convert to Matrix
    #' @return Matrix object
    to_matrix = function() {
      xptr <- praat_powercepstrum_to_matrix(self$.xptr)
      Matrix$new(xptr)
    },
    
    #' @description
    #' Convert to R matrix
    #' @return Numeric matrix
    as_matrix = function() {
      praat_powercepstrum_as_matrix(self$.xptr)
    }
  )
)


#' PowerCepstrogram R6 Class
#'
#' Represents a time-varying power cepstrum (PowerCepstrogram) from Praat.
#' Allows analysis of CPP over time.
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
      self$.xptr <- .xptr
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
      
      praat_powercepstrogram_get_cpp_at_time(
        self$.xptr,
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
      
      praat_powercepstrogram_get_mean_cpp(
        self$.xptr,
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
      xptr <- praat_powercepstrogram_to_powercepstrum_slice(self$.xptr, time = time)
      PowerCepstrum$new(xptr)
    },
    
    #' @description
    #' Convert to Matrix
    #' @return Matrix object
    to_matrix = function() {
      xptr <- praat_powercepstrogram_to_matrix(self$.xptr)
      Matrix$new(xptr)
    },
    
    #' @description
    #' Convert to R matrix
    #' @return Numeric matrix (quefrency × time)
    as_matrix = function() {
      praat_powercepstrogram_as_matrix(self$.xptr)
    },
    
    #' @description
    #' Smooth the power cepstrogram
    #' @param time_averaging_window Numeric. Time smoothing window (seconds)
    #' @param quefrency_averaging_window Numeric. Quefrency smoothing window (seconds)
    #' @return New PowerCepstrogram object
    smooth = function(time_averaging_window, quefrency_averaging_window) {
      xptr <- praat_powercepstrogram_smooth(
        self$.xptr,
        time_averaging_window = time_averaging_window,
        quefrency_averaging_window = quefrency_averaging_window
      )
      PowerCepstrogram$new(xptr)
    }
  )
)
