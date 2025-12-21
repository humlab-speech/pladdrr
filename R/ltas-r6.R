#' @title Praat Ltas (Long-term Average Spectrum) Object
#' @description
#' R6 class representing a Praat Ltas object for long-term spectral analysis.
#'
#' @details
#' An Ltas (Long-term Average Spectrum) represents the average spectral energy
#' distribution of a sound over its entire duration. It's useful for voice quality
#' analysis and speaker characterization.
#'
#' ## Creating Ltas Objects
#'
#' - Created from Sound via `sound$to_ltas(bandwidth)`
#' - Created from Spectrum via `spectrum$to_ltas(bandwidth)`
#'
#' ## Querying
#'
#' - `$get_bin_from_frequency(frequency)` - Get bin number for frequency
#' - `$get_frequency_from_bin(bin)` - Get frequency for bin number
#' - `$get_value_at_frequency(frequency, unit)` - Get power at frequency
#' - `$get_minimum(fmin, fmax, unit)` - Minimum in frequency range
#' - `$get_maximum(fmin, fmax, unit)` - Maximum in frequency range
#' - `$get_mean(fmin, fmax, unit)` - Mean in frequency range
#' - `$get_slope(f1min, f1max, f2min, f2max, unit)` - Spectral slope
#'
#' ## Export
#'
#' - `$as_data_frame()` - Convert to R data frame
#' - `$as_matrix()` - Convert to matrix
#'
#' @examples
#' \dontrun{
#' # Create from sound
#' sound <- Sound$new("recording.wav")
#' ltas <- sound$to_ltas(bandwidth = 100)
#'
#' # Query spectral properties
#' mean_1000_2000 <- ltas$get_mean(1000, 2000, unit = "dB")
#' slope <- ltas$get_slope(0, 1000, 1000, 4000, unit = "dB")
#'
#' # Export to R
#' df <- ltas$as_data_frame()
#' }
#'
#' @export
Ltas <- R6::R6Class(
  "Ltas",
  inherit = PraatObject,
  
  public = list(
    
    #' @description
    #' Create an Ltas object
    #' @param .xptr Internal use only - external pointer to C++ Ltas object
    initialize = function(.xptr = NULL) {
      if (is.null(.xptr)) {
        stop("Ltas objects must be created from a Sound or Spectrum object")
      }
      private$ptr <- .xptr
    },
    
    # ========================================================================
    # Query methods - Frequency domain
    # ========================================================================
    
    #' @description
    #' Get the bin number corresponding to a frequency
    #' @param frequency Frequency in Hz
    #' @return Bin number (integer)
    get_bin_from_frequency = function(frequency) {
      .ltas_get_bin_from_frequency(private$ptr, as.numeric(frequency))
    },
    
    #' @description
    #' Get the frequency corresponding to a bin number
    #' @param bin Bin number (1-based)
    #' @return Frequency in Hz
    get_frequency_from_bin = function(bin) {
      .ltas_get_frequency_from_bin(private$ptr, as.integer(bin))
    },
    
    #' @description
    #' Get the number of bins
    #' @return Number of frequency bins
    get_number_of_bins = function() {
      .ltas_get_number_of_bins(private$ptr)
    },
    
    #' @description
    #' Get the bin width
    #' @return Bin width in Hz
    get_bin_width = function() {
      .ltas_get_bin_width(private$ptr)
    },
    
    #' @description
    #' Get the lowest frequency
    #' @return Minimum frequency in Hz
    get_lowest_frequency = function() {
      .ltas_get_lowest_frequency(private$ptr)
    },
    
    #' @description
    #' Get the highest frequency
    #' @return Maximum frequency in Hz
    get_highest_frequency = function() {
      .ltas_get_highest_frequency(private$ptr)
    },
    
    # ========================================================================
    # Query methods - Values
    # ========================================================================
    
    #' @description
    #' Get the power value at a specific frequency
    #' Corresponds to Praat: Get value at frequency: frequency, unit
    #' @param frequency Frequency in Hz
    #' @param unit Averaging method: "energy", "sones", "dB" (default)
    #' @param interpolate Interpolate between bins (default TRUE)
    #' @return Power value in specified unit
    get_value_at_frequency = function(frequency, unit = "dB", interpolate = TRUE) {
      unit_code <- switch(tolower(unit),
        "energy" = 1L,
        "sones" = 2L,
        "db" = 3L,
        stop("Unknown unit: ", unit, ". Must be 'energy', 'sones', or 'dB'")
      )
      .ltas_get_value_at_frequency(private$ptr, as.numeric(frequency), 
                                    unit_code, as.logical(interpolate))
    },
    
    #' @description
    #' Get minimum power in frequency range
    #' Corresponds to Praat: Get minimum: fmin, fmax, unit
    #' @param fmin Minimum frequency (Hz, 0 = start)
    #' @param fmax Maximum frequency (Hz, 0 = end)
    #' @param unit Averaging method: "energy", "sones", "dB" (default)
    #' @param interpolate Interpolate between bins (default TRUE)
    #' @return Minimum power value
    get_minimum = function(fmin = 0, fmax = 0, unit = "dB", interpolate = TRUE) {
      unit_code <- switch(tolower(unit),
        "energy" = 1L,
        "sones" = 2L,
        "db" = 3L,
        stop("Unknown unit: ", unit, ". Must be 'energy', 'sones', or 'dB'")
      )
      .ltas_get_minimum(private$ptr, as.numeric(fmin), as.numeric(fmax), 
                        unit_code, as.logical(interpolate))
    },
    
    #' @description
    #' Get maximum power in frequency range
    #' Corresponds to Praat: Get maximum: fmin, fmax, unit
    #' @param fmin Minimum frequency (Hz, 0 = start)
    #' @param fmax Maximum frequency (Hz, 0 = end)
    #' @param unit Averaging method: "energy", "sones", "dB" (default)
    #' @param interpolate Interpolate between bins (default TRUE)
    #' @return Maximum power value
    get_maximum = function(fmin = 0, fmax = 0, unit = "dB", interpolate = TRUE) {
      unit_code <- switch(tolower(unit),
        "energy" = 1L,
        "sones" = 2L,
        "db" = 3L,
        stop("Unknown unit: ", unit, ". Must be 'energy', 'sones', or 'dB'")
      )
      .ltas_get_maximum(private$ptr, as.numeric(fmin), as.numeric(fmax), 
                        unit_code, as.logical(interpolate))
    },
    
    #' @description
    #' Get frequency of maximum power in frequency range
    #' Corresponds to Praat: Get frequency of maximum: fmin, fmax, interpolation
    #' @param fmin Minimum frequency (Hz, 0 = start)
    #' @param fmax Maximum frequency (Hz, 0 = end)
    #' @param interpolation Interpolation method: "none", "parabolic", "cubic", "sinc70", "sinc700"
    #' @return Frequency of maximum power (Hz)
    get_frequency_of_maximum = function(fmin = 0, fmax = 0, interpolation = "parabolic") {
      interp_code <- switch(tolower(interpolation),
        "none" = 0L,
        "nearest" = 0L,
        "linear" = 1L,
        "parabolic" = 2L,
        "cubic" = 3L,
        "sinc70" = 4L,
        "sinc700" = 5L,
        stop("Unknown interpolation: ", interpolation)
      )
      .ltas_get_frequency_of_maximum(private$ptr, as.numeric(fmin), as.numeric(fmax), interp_code)
    },
    
    #' @description
    #' Get mean power in frequency range
    #' Corresponds to Praat: Get mean: fmin, fmax, unit
    #' @param fmin Minimum frequency (Hz, 0 = start)
    #' @param fmax Maximum frequency (Hz, 0 = end)
    #' @param unit Averaging method: "energy", "sones", "dB" (default)
    #' @return Mean power value
    get_mean = function(fmin = 0, fmax = 0, unit = "dB") {
      unit_code <- switch(tolower(unit),
        "energy" = 1L,
        "sones" = 2L,
        "db" = 3L,
        stop("Unknown unit: ", unit, ". Must be 'energy', 'sones', or 'dB'")
      )
      .ltas_get_mean(private$ptr, as.numeric(fmin), as.numeric(fmax), unit_code)
    },
    
    #' @description
    #' Get spectral slope between two frequency ranges
    #' Corresponds to Praat: Get slope: f1min, f1max, f2min, f2max, unit
    #' @param f1min Low range minimum frequency (Hz)
    #' @param f1max Low range maximum frequency (Hz)
    #' @param f2min High range minimum frequency (Hz)
    #' @param f2max High range maximum frequency (Hz)
    #' @param unit Averaging method: "energy" (default), "sones", "dB"
    #' @return Slope (difference in dB)
    get_slope = function(f1min, f1max, f2min, f2max, unit = "energy") {
      unit_code <- switch(tolower(unit),
        "energy" = 1L,
        "sones" = 2L,
        "db" = 3L,
        stop("Unknown unit: ", unit, ". Must be 'energy', 'sones', or 'dB'")
      )
      .ltas_get_slope(private$ptr, as.numeric(f1min), as.numeric(f1max),
                      as.numeric(f2min), as.numeric(f2max), unit_code)
    },
    
    # ========================================================================
    # Transformation methods
    # ========================================================================
    
    #' @description
    #' Compute trend line (linear regression)
    #' @param fmin Minimum frequency (Hz, 0 = start)
    #' @param fmax Maximum frequency (Hz, 0 = end)
    #' @return New Ltas with trend line
    compute_trend_line = function(fmin = 0, fmax = 0) {
      trend_ptr <- .ltas_compute_trend_line(private$ptr, as.numeric(fmin), as.numeric(fmax))
      Ltas$new(.xptr = trend_ptr)
    },
    
    #' @description
    #' Subtract trend line from Ltas
    #' @param fmin Minimum frequency (Hz, 0 = start)
    #' @param fmax Maximum frequency (Hz, 0 = end)
    #' @return New Ltas with trend removed
    subtract_trend_line = function(fmin = 0, fmax = 0) {
      corrected_ptr <- .ltas_subtract_trend_line(private$ptr, as.numeric(fmin), as.numeric(fmax))
      Ltas$new(.xptr = corrected_ptr)
    },
    
    # ========================================================================
    # Export methods
    # ========================================================================
    
    #' @description
    #' Convert Ltas to R data frame
    #' @return Data frame with columns: frequency (Hz), power_db (dB/Hz)
    as_data_frame = function() {
      .ltas_as_data_frame(private$ptr)
    },
    
    #' @description
    #' Convert Ltas to R matrix
    #' @return Numeric vector of power values
    as_matrix = function() {
      .ltas_as_matrix(private$ptr)
    }
  )
)
