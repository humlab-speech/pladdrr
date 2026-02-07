#' @title Praat Ltas (Long-term Average Spectrum) Object
#' @description
#' Praat Ltas object with direct C++ module binding for long-term spectral analysis.
#'
#' @details
#' An Ltas (Long-term Average Spectrum) represents the average spectral energy
#' distribution of a sound over its entire duration. Useful for voice quality
#' analysis and speaker characterization.
#'
#' @export
Ltas <- function(.xptr = NULL) {
  if (is.null(.xptr)) {
    stop("Ltas objects must be created from a Sound or Spectrum object")
  }
  
  ltas_mod <- get_module("ltas_module")
  cpp_obj <- ltas_mod$RLtas$new(.xptr)
  
  # Unit codes - matches Praat's Ltas.cpp:44-60
  # 0 = dB passthrough, 1 = energy (10*log10), 2 = sones (10*log2)
  unit_code <- function(unit) {
    switch(tolower(unit),
      "energy" = 1L,  # Praat: ratio → dB via 10*log10()
      "sones" = 2L,   # Praat: ratio → dB via 10*log2()
      "db" = 0L,      # Praat: dB passthrough
      1L  # default energy (matches Parselmouth behavior)
    )
  }
  
  interpolation_code <- function(method) {
    switch(tolower(method),
      "nearest" = 0,
      "linear" = 1,
      "cubic" = 2,
      "sinc70" = 3,
      "sinc700" = 4,
      2
    )
  }
  
  peak_interpolation_code <- function(method) {
    switch(tolower(method),
      "none" = 0,
      "parabolic" = 1,
      "cubic" = 2,
      "sinc70" = 3,
      "sinc700" = 4,
      1
    )
  }
  
  obj <- structure(list(
    .cpp = cpp_obj,
    .xptr = .xptr,
    
    # Frequency domain
    get_bin_from_frequency = function(frequency) {
      cpp_obj$get_bin_from_frequency(as.numeric(frequency))
    },
    
    get_frequency_from_bin = function(bin) {
      cpp_obj$get_frequency_from_bin(as.integer(bin))
    },
    
    get_number_of_bins = function() {
      cpp_obj$get_number_of_bins()
    },
    
    get_bin_width = function() {
      cpp_obj$get_bandwidth()
    },
    
    get_lowest_frequency = function() {
      cpp_obj$get_fmin()
    },
    
    get_highest_frequency = function() {
      cpp_obj$get_fmax()
    },
    
    # Query values
    get_value_at_frequency = function(frequency, unit = "dB", interpolate = TRUE) {
      cpp_obj$get_value_at_frequency(as.numeric(frequency), 
                                       if(interpolate) 2 else 0)
    },
    
    get_minimum = function(fmin = 0, fmax = 0, unit = "dB", interpolation = "parabolic") {
      cpp_obj$get_minimum(fmin, fmax, peak_interpolation_code(interpolation))
    },
    
    get_maximum = function(fmin = 0, fmax = 0, unit = "dB", interpolation = "parabolic") {
      cpp_obj$get_maximum(fmin, fmax, peak_interpolation_code(interpolation))
    },
    
    get_mean = function(fmin = 0, fmax = 0, unit = "dB") {
      cpp_obj$get_mean(fmin, fmax, unit_code(unit))
    },
    
    get_slope = function(f1min, f1max, f2min, f2max, unit = "dB") {
      cpp_obj$get_slope(f1min, f1max, f2min, f2max, unit_code(unit))
    },
    
    # === Batch Operations (18x speedup for pharyngeal analysis) ===

    #' Get peaks for multiple frequency ranges in a single call
    #' @param fmins Numeric vector of minimum frequencies
    #' @param fmaxs Numeric vector of maximum frequencies
    #' @param interpolation Interpolation method ("none", "parabolic", "cubic", "sinc70", "sinc700")
    #' @return Data frame with fmin, fmax, peak_value, peak_frequency
    get_peaks_batch = function(fmins, fmaxs, interpolation = "parabolic") {
      cpp_obj$get_peaks_batch(
        as.numeric(fmins),
        as.numeric(fmaxs),
        peak_interpolation_code(interpolation)
      )
    },

    #' Get minima for multiple frequency ranges in a single call
    #' @param fmins Numeric vector of minimum frequencies
    #' @param fmaxs Numeric vector of maximum frequencies
    #' @param interpolation Interpolation method
    #' @return Data frame with fmin, fmax, min_value, min_frequency
    get_minima_batch = function(fmins, fmaxs, interpolation = "parabolic") {
      cpp_obj$get_minima_batch(
        as.numeric(fmins),
        as.numeric(fmaxs),
        peak_interpolation_code(interpolation)
      )
    },

    #' Get values at multiple frequencies in a single call
    #' @param frequencies Numeric vector of frequencies
    #' @param interpolation Interpolation method ("nearest", "linear", "cubic", "sinc70", "sinc700")
    #' @return Numeric vector of values at the specified frequencies
    get_values_at_frequencies = function(frequencies, interpolation = "cubic") {
      cpp_obj$get_values_at_frequencies(
        as.numeric(frequencies),
        interpolation_code(interpolation)
      )
    },

    #' Get means for multiple frequency ranges in a single call
    #' @param fmins Numeric vector of minimum frequencies
    #' @param fmaxs Numeric vector of maximum frequencies
    #' @param unit Unit for averaging ("dB", "energy", "sones")
    #' @return Numeric vector of mean values
    get_means_batch = function(fmins, fmaxs, unit = "dB") {
      cpp_obj$get_means_batch(
        as.numeric(fmins),
        as.numeric(fmaxs),
        unit_code(unit)
      )
    },

    #' Get frequency of maximum for a frequency range
    #' @param fmin Minimum frequency
    #' @param fmax Maximum frequency
    #' @param interpolation Interpolation method
    #' @return Frequency of maximum value
    get_frequency_of_maximum = function(fmin = 0, fmax = 0, interpolation = "parabolic") {
      cpp_obj$get_frequency_of_maximum(fmin, fmax, peak_interpolation_code(interpolation))
    },

    #' Get frequency of minimum for a frequency range
    #' @param fmin Minimum frequency
    #' @param fmax Maximum frequency
    #' @param interpolation Interpolation method
    #' @return Frequency of minimum value
    get_frequency_of_minimum = function(fmin = 0, fmax = 0, interpolation = "parabolic") {
      cpp_obj$get_frequency_of_minimum(fmin, fmax, peak_interpolation_code(interpolation))
    },

    # Transform
    subtract_trend_line = function(fmin = 0, fmax = 0) {
      ptr <- .ltas_subtract_trend_line(.xptr, fmin, fmax)
      Ltas(.xptr = ptr)
    },
    
    compute_trend_line = function(fmin = 0, fmax = 0) {
      ptr <- .ltas_compute_trend_line(.xptr, fmin, fmax)
      Ltas(.xptr = ptr)
    },
    
    report_spectral_trend = function(
      fmin = 100, 
      fmax = 5000,
      frequency_scale = c("logarithmic", "linear"),
      fit_method = c("least squares", "robust")
    ) {
      frequency_scale <- match.arg(frequency_scale)
      fit_method <- match.arg(fit_method)
      
      result <- .ltas_report_spectral_trend(
        .xptr, 
        as.numeric(fmin), 
        as.numeric(fmax),
        frequency_scale, 
        fit_method
      )
      
      class(result) <- c("ltas_spectral_trend", "list")
      result
    },
    
    # Export
    as_data_frame = function() {
      df <- cpp_obj$as_data_frame()
      names(df) <- c("frequency", "power_db")
      df
    },
    
    as_matrix = function() {
      mat <- cpp_obj$as_matrix()
      rbind(
        frequency = mat[, 1],
        power_db = mat[, 2]
      )
    },
    
    # Display
    print = function() {
      cat("<Praat Ltas>\n")
      cat(sprintf("  Frequency range: %.2f - %.2f Hz\n", 
                  cpp_obj$get_fmin(), cpp_obj$get_fmax()))
      cat(sprintf("  Number of bins: %d\n", cpp_obj$get_number_of_bins()))
      cat(sprintf("  Bin width: %.2f Hz\n", cpp_obj$get_bandwidth()))
      invisible(obj)
    }
    
  ), class = c("Ltas", "PraatObject"))
  
  obj
}

#' @export
print.Ltas <- function(x, ...) {
  x$print()
}

#' @export
as.data.frame.Ltas <- function(x, ...) {
  x$as_data_frame()
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
  cat(sprintf("  R²:                    %.6f\n", x$r_squared))
  cat(sprintf("  Residual Std Error:    %.4f dB\n\n", x$residual_std_error))
  
  if (x$frequency_scale == "logarithmic") {
    cat("Model: power_dB = intercept + slope * log10(frequency_Hz)\n")
  } else {
    cat("Model: power_dB = intercept + slope * frequency_Hz\n")
  }
  
  cat("\nNote: Use $fitted_values to access predicted values for plotting\n")
  
  invisible(x)
}
