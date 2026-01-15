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
    
    # Transform
    subtract_trend_line = function(fmin = 0, fmax = 0) {
      ptr <- .ltas_subtract_trend_line(.xptr, fmin, fmax)
      Ltas(.xptr = ptr)
    },
    
    compute_trend_line = function(fmin = 0, fmax = 0) {
      ptr <- .ltas_compute_trend_line(.xptr, fmin, fmax)
      Ltas(.xptr = ptr)
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
