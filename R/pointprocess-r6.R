#' @title Praat PointProcess Object
#' @description
#' R6 class representing a Praat PointProcess object. A PointProcess is a sequence
#' of time points, typically representing events such as glottal pulses, peaks,
#' zero crossings, or other temporal landmarks in a sound.
#'
#' @details
#' PointProcess objects are essential for voice quality analysis. They represent
#' discrete time points and are used to calculate voice quality measures like
#' jitter (period perturbation) and shimmer (amplitude perturbation).
#'
#' ## Creating PointProcess Objects
#'
#' PointProcess objects are typically created from Sound or Pitch objects:
#' - `sound$to_point_process_periodic_cc(...)` - Extract glottal pulses
#' - `sound$to_point_process_extrema(...)` - Extract peaks/valleys
#' - `pitch$to_point_process()` - Convert pitch candidates to points
#'
#' ## Querying Points
#'
#' - `$get_number_of_points()` - Number of points
#' - `$get_time_from_index(i)` - Time of point i
#' - `$get_nearest_index(time)` - Find nearest point to time
#' - `$get_low_index(time)` - Find point before or at time
#' - `$get_high_index(time)` - Find point after or at time
#' - `$get_interval(time)` - Duration between points around time
#'
#' ## Voice Quality Metrics
#'
#' **Comprehensive Voice Report** (NEW - for AVQI/DSI):
#' - `$voice_report(sound, pitch, ...)` - Complete voice quality analysis with all
#'   jitter, shimmer, and harmonicity measures in a single call. Essential for
#'   computing AVQI and DSI voice quality indices.
#'
#' Individual Jitter measures (period perturbation):
#' - `$get_jitter_local(...)` - Local jitter (relative)
#' - `$get_jitter_local_absolute(...)` - Local jitter (absolute)
#' - `$get_jitter_rap(...)` - Relative Average Perturbation
#' - `$get_jitter_ppq5(...)` - Five-point Period Perturbation Quotient
#' - `$get_jitter_ddp(...)` - Difference of Differences of Periods
#'
#' Individual Shimmer measures (amplitude perturbation, require Sound object):
#' - `$get_shimmer_local(sound, ...)` - Local shimmer (relative)
#' - `$get_shimmer_local_db(sound, ...)` - Local shimmer (dB)
#' - `$get_shimmer_apq3(sound, ...)` - 3-point Amplitude Perturbation Quotient
#' - `$get_shimmer_apq5(sound, ...)` - 5-point Amplitude Perturbation Quotient
#' - `$get_shimmer_apq11(sound, ...)` - 11-point Amplitude Perturbation Quotient
#' - `$get_shimmer_dda(sound, ...)` - Difference of Differences of Amplitudes
#'
#' Period statistics:
#' - `$get_mean_period(...)` - Mean period
#' - `$get_stdev_period(...)` - Standard deviation of periods
#'
#' ## Modification
#'
#' - `$add_point(time)` - Add time point
#' - `$remove_point(index)` - Remove point by index
#' - `$remove_point_near(time)` - Remove nearest point to time
#' - `$remove_points_between(t1, t2)` - Remove all points in range
#'
#' ## Export
#'
#' - `$as_data_frame()` - Export points to data frame
#' - `$save(path)` - Write to file
#'
#' @examples
#' \dontrun{
#' # Extract glottal pulses from sound
#' sound <- Sound$new("voice.wav")
#' pp <- sound$to_point_process_periodic_cc(
#'   pitch_floor = 75,
#'   pitch_ceiling = 600
#' )
#'
#' # Query points
#' n_points <- pp$get_number_of_points()
#' first_time <- pp$get_time_from_index(1)
#'
#' # Calculate jitter (period perturbation)
#' jitter_local <- pp$get_jitter_local(
#'   from_time = 0,
#'   to_time = 0,  # 0 means entire duration
#'   period_floor = 0.0001,
#'   period_ceiling = 0.02,
#'   max_period_factor = 1.3
#' )
#'
#' # Calculate shimmer (amplitude perturbation)
#' shimmer_local <- pp$get_shimmer_local(
#'   sound = sound,
#'   from_time = 0,
#'   to_time = 0,
#'   period_floor = 0.0001,
#'   period_ceiling = 0.02,
#'   max_period_factor = 1.3,
#'   max_amplitude_factor = 1.6
#' )
#'
#' # Get period statistics
#' mean_period <- pp$get_mean_period(
#'   from_time = 0,
#'   to_time = 0,
#'   period_floor = 0.0001,
#'   period_ceiling = 0.02,
#'   max_period_factor = 1.3
#' )
#'
#' # Export to R
#' df <- pp$as_data_frame()
#' }
#'
#' @export
PointProcess <- R6::R6Class(
  "PointProcess",
  inherit = PraatObject,
  
  public = list(
    
    #' @description
    #' Create a PointProcess object (internal use - typically created from Sound/Pitch)
    #' @param .xptr External pointer to C++ PointProcess object
    #' @return A new PointProcess object
    initialize = function(.xptr = NULL) {
      if (is.null(.xptr)) {
        stop("PointProcess objects must be created from a Sound or Pitch object using to_point_process_*() methods")
      }
      super$initialize(.xptr)
    },
    
    # ========================================================================
    # Query Methods - Basic
    # ========================================================================
    
    #' @description
    #' Get the number of points in the PointProcess
    #' @return Integer number of points
    get_number_of_points = function() {
      .pointprocess_get_number_of_points(private$ptr)
    },
    
    #' @description
    #' Get the time of a specific point
    #' @param index Point index (1-based)
    #' @return Time in seconds
    get_time_from_index = function(index) {
      .pointprocess_get_time_from_index(private$ptr, as.integer(index))
    },
    
    #' @description
    #' Get the index of the nearest point to a given time
    #' @param time Time in seconds
    #' @return Point index (1-based), or 0 if no points
    get_nearest_index = function(time) {
      .pointprocess_get_nearest_index(private$ptr, as.numeric(time))
    },
    
    #' @description
    #' Get the index of the last point before or at a given time
    #' @param time Time in seconds
    #' @return Point index (1-based), or 0 if no such point
    get_low_index = function(time) {
      .pointprocess_get_low_index(private$ptr, as.numeric(time))
    },
    
    #' @description
    #' Get the index of the first point at or after a given time
    #' @param time Time in seconds
    #' @return Point index (1-based), or 0 if no such point
    get_high_index = function(time) {
      .pointprocess_get_high_index(private$ptr, as.numeric(time))
    },
    
    #' @description
    #' Get the interval (duration) between the points around a given time
    #' @param time Time in seconds
    #' @return Interval duration in seconds, or NA if undefined
    get_interval = function(time) {
      .pointprocess_get_interval(private$ptr, as.numeric(time))
    },
    
    # ========================================================================
    # Voice Quality - Jitter (Period Perturbation)
    # ========================================================================
    
    #' @description
    #' Get local jitter (relative average absolute difference between consecutive periods)
    #' @param from_time Start time (0 = start of object)
    #' @param to_time End time (0 = end of object)
    #' @param period_floor Minimum period (default 0.0001 s)
    #' @param period_ceiling Maximum period (default 0.02 s)
    #' @param max_period_factor Maximum ratio between consecutive periods (default 1.3)
    #' @return Local jitter (dimensionless ratio, typically 0.01 = 1%)
    get_jitter_local = function(from_time = 0, to_time = 0, 
                                period_floor = 0.0001, period_ceiling = 0.02, 
                                max_period_factor = 1.3) {
      .pointprocess_get_jitter_local(
        private$ptr, 
        as.numeric(from_time), 
        as.numeric(to_time),
        as.numeric(period_floor), 
        as.numeric(period_ceiling), 
        as.numeric(max_period_factor)
      )
    },
    
    #' @description
    #' Get local absolute jitter (average absolute difference between consecutive periods)
    #' @param from_time Start time (0 = start of object)
    #' @param to_time End time (0 = end of object)
    #' @param period_floor Minimum period (default 0.0001 s)
    #' @param period_ceiling Maximum period (default 0.02 s)
    #' @param max_period_factor Maximum ratio between consecutive periods (default 1.3)
    #' @return Local absolute jitter in seconds
    get_jitter_local_absolute = function(from_time = 0, to_time = 0, 
                                         period_floor = 0.0001, period_ceiling = 0.02, 
                                         max_period_factor = 1.3) {
      .pointprocess_get_jitter_local_absolute(
        private$ptr, 
        as.numeric(from_time), 
        as.numeric(to_time),
        as.numeric(period_floor), 
        as.numeric(period_ceiling), 
        as.numeric(max_period_factor)
      )
    },
    
    #' @description
    #' Get RAP jitter (Relative Average Perturbation - 3-point smoothing)
    #' @param from_time Start time (0 = start of object)
    #' @param to_time End time (0 = end of object)
    #' @param period_floor Minimum period (default 0.0001 s)
    #' @param period_ceiling Maximum period (default 0.02 s)
    #' @param max_period_factor Maximum ratio between consecutive periods (default 1.3)
    #' @return RAP jitter (dimensionless ratio)
    get_jitter_rap = function(from_time = 0, to_time = 0, 
                             period_floor = 0.0001, period_ceiling = 0.02, 
                             max_period_factor = 1.3) {
      .pointprocess_get_jitter_rap(
        private$ptr, 
        as.numeric(from_time), 
        as.numeric(to_time),
        as.numeric(period_floor), 
        as.numeric(period_ceiling), 
        as.numeric(max_period_factor)
      )
    },
    
    #' @description
    #' Get PPQ5 jitter (5-point Period Perturbation Quotient)
    #' @param from_time Start time (0 = start of object)
    #' @param to_time End time (0 = end of object)
    #' @param period_floor Minimum period (default 0.0001 s)
    #' @param period_ceiling Maximum period (default 0.02 s)
    #' @param max_period_factor Maximum ratio between consecutive periods (default 1.3)
    #' @return PPQ5 jitter (dimensionless ratio)
    get_jitter_ppq5 = function(from_time = 0, to_time = 0, 
                               period_floor = 0.0001, period_ceiling = 0.02, 
                               max_period_factor = 1.3) {
      .pointprocess_get_jitter_ppq5(
        private$ptr, 
        as.numeric(from_time), 
        as.numeric(to_time),
        as.numeric(period_floor), 
        as.numeric(period_ceiling), 
        as.numeric(max_period_factor)
      )
    },
    
    #' @description
    #' Get DDP jitter (Difference of Differences of Periods - 3 × RAP)
    #' @param from_time Start time (0 = start of object)
    #' @param to_time End time (0 = end of object)
    #' @param period_floor Minimum period (default 0.0001 s)
    #' @param period_ceiling Maximum period (default 0.02 s)
    #' @param max_period_factor Maximum ratio between consecutive periods (default 1.3)
    #' @return DDP jitter (dimensionless ratio)
    get_jitter_ddp = function(from_time = 0, to_time = 0, 
                             period_floor = 0.0001, period_ceiling = 0.02, 
                             max_period_factor = 1.3) {
      .pointprocess_get_jitter_ddp(
        private$ptr, 
        as.numeric(from_time), 
        as.numeric(to_time),
        as.numeric(period_floor), 
        as.numeric(period_ceiling), 
        as.numeric(max_period_factor)
      )
    },
    
    # ========================================================================
    # Voice Quality - Shimmer (Amplitude Perturbation - requires Sound)
    # ========================================================================
    
    #' @description
    #' Get local shimmer (relative average absolute difference between consecutive peak amplitudes)
    #' @param sound Sound object for amplitude extraction
    #' @param from_time Start time (0 = start of object)
    #' @param to_time End time (0 = end of object)
    #' @param period_floor Minimum period (default 0.0001 s)
    #' @param period_ceiling Maximum period (default 0.02 s)
    #' @param max_period_factor Maximum ratio between consecutive periods (default 1.3)
    #' @param max_amplitude_factor Maximum ratio between consecutive amplitudes (default 1.6)
    #' @return Local shimmer (dimensionless ratio, typically 0.05 = 5%)
    get_shimmer_local = function(sound, from_time = 0, to_time = 0, 
                                 period_floor = 0.0001, period_ceiling = 0.02, 
                                 max_period_factor = 1.3, max_amplitude_factor = 1.6) {
      if (!inherits(sound, "Sound")) {
        stop("sound must be a Sound object")
      }
      .pointprocess_sound_get_shimmer_local(
        private$ptr,
        sound$.__enclos_env__$private$ptr,
        as.numeric(from_time), 
        as.numeric(to_time),
        as.numeric(period_floor), 
        as.numeric(period_ceiling), 
        as.numeric(max_period_factor),
        as.numeric(max_amplitude_factor)
      )
    },
    
    #' @description
    #' Get local shimmer in dB
    #' @param sound Sound object for amplitude extraction
    #' @param from_time Start time (0 = start of object)
    #' @param to_time End time (0 = end of object)
    #' @param period_floor Minimum period (default 0.0001 s)
    #' @param period_ceiling Maximum period (default 0.02 s)
    #' @param max_period_factor Maximum ratio between consecutive periods (default 1.3)
    #' @param max_amplitude_factor Maximum ratio between consecutive amplitudes (default 1.6)
    #' @return Local shimmer in dB
    get_shimmer_local_db = function(sound, from_time = 0, to_time = 0, 
                                    period_floor = 0.0001, period_ceiling = 0.02, 
                                    max_period_factor = 1.3, max_amplitude_factor = 1.6) {
      if (!inherits(sound, "Sound")) {
        stop("sound must be a Sound object")
      }
      .pointprocess_sound_get_shimmer_local_db(
        private$ptr,
        sound$.__enclos_env__$private$ptr,
        as.numeric(from_time), 
        as.numeric(to_time),
        as.numeric(period_floor), 
        as.numeric(period_ceiling), 
        as.numeric(max_period_factor),
        as.numeric(max_amplitude_factor)
      )
    },
    
    #' @description
    #' Get APQ3 shimmer (3-point Amplitude Perturbation Quotient)
    #' @param sound Sound object for amplitude extraction
    #' @param from_time Start time (0 = start of object)
    #' @param to_time End time (0 = end of object)
    #' @param period_floor Minimum period (default 0.0001 s)
    #' @param period_ceiling Maximum period (default 0.02 s)
    #' @param max_period_factor Maximum ratio between consecutive periods (default 1.3)
    #' @param max_amplitude_factor Maximum ratio between consecutive amplitudes (default 1.6)
    #' @return APQ3 shimmer (dimensionless ratio)
    get_shimmer_apq3 = function(sound, from_time = 0, to_time = 0, 
                                period_floor = 0.0001, period_ceiling = 0.02, 
                                max_period_factor = 1.3, max_amplitude_factor = 1.6) {
      if (!inherits(sound, "Sound")) {
        stop("sound must be a Sound object")
      }
      .pointprocess_sound_get_shimmer_apq3(
        private$ptr,
        sound$.__enclos_env__$private$ptr,
        as.numeric(from_time), 
        as.numeric(to_time),
        as.numeric(period_floor), 
        as.numeric(period_ceiling), 
        as.numeric(max_period_factor),
        as.numeric(max_amplitude_factor)
      )
    },
    
    #' @description
    #' Get APQ5 shimmer (5-point Amplitude Perturbation Quotient)
    #' @param sound Sound object for amplitude extraction
    #' @param from_time Start time (0 = start of object)
    #' @param to_time End time (0 = end of object)
    #' @param period_floor Minimum period (default 0.0001 s)
    #' @param period_ceiling Maximum period (default 0.02 s)
    #' @param max_period_factor Maximum ratio between consecutive periods (default 1.3)
    #' @param max_amplitude_factor Maximum ratio between consecutive amplitudes (default 1.6)
    #' @return APQ5 shimmer (dimensionless ratio)
    get_shimmer_apq5 = function(sound, from_time = 0, to_time = 0, 
                                period_floor = 0.0001, period_ceiling = 0.02, 
                                max_period_factor = 1.3, max_amplitude_factor = 1.6) {
      if (!inherits(sound, "Sound")) {
        stop("sound must be a Sound object")
      }
      .pointprocess_sound_get_shimmer_apq5(
        private$ptr,
        sound$.__enclos_env__$private$ptr,
        as.numeric(from_time), 
        as.numeric(to_time),
        as.numeric(period_floor), 
        as.numeric(period_ceiling), 
        as.numeric(max_period_factor),
        as.numeric(max_amplitude_factor)
      )
    },
    
    #' @description
    #' Get APQ11 shimmer (11-point Amplitude Perturbation Quotient)
    #' @param sound Sound object for amplitude extraction
    #' @param from_time Start time (0 = start of object)
    #' @param to_time End time (0 = end of object)
    #' @param period_floor Minimum period (default 0.0001 s)
    #' @param period_ceiling Maximum period (default 0.02 s)
    #' @param max_period_factor Maximum ratio between consecutive periods (default 1.3)
    #' @param max_amplitude_factor Maximum ratio between consecutive amplitudes (default 1.6)
    #' @return APQ11 shimmer (dimensionless ratio)
    get_shimmer_apq11 = function(sound, from_time = 0, to_time = 0, 
                                 period_floor = 0.0001, period_ceiling = 0.02, 
                                 max_period_factor = 1.3, max_amplitude_factor = 1.6) {
      if (!inherits(sound, "Sound")) {
        stop("sound must be a Sound object")
      }
      .pointprocess_sound_get_shimmer_apq11(
        private$ptr,
        sound$.__enclos_env__$private$ptr,
        as.numeric(from_time), 
        as.numeric(to_time),
        as.numeric(period_floor), 
        as.numeric(period_ceiling), 
        as.numeric(max_period_factor),
        as.numeric(max_amplitude_factor)
      )
    },
    
    #' @description
    #' Get DDA shimmer (Difference of Differences of Amplitudes - 3 × APQ3)
    #' @param sound Sound object for amplitude extraction
    #' @param from_time Start time (0 = start of object)
    #' @param to_time End time (0 = end of object)
    #' @param period_floor Minimum period (default 0.0001 s)
    #' @param period_ceiling Maximum period (default 0.02 s)
    #' @param max_period_factor Maximum ratio between consecutive periods (default 1.3)
    #' @param max_amplitude_factor Maximum ratio between consecutive amplitudes (default 1.6)
    #' @return DDA shimmer (dimensionless ratio)
    get_shimmer_dda = function(sound, from_time = 0, to_time = 0, 
                               period_floor = 0.0001, period_ceiling = 0.02, 
                               max_period_factor = 1.3, max_amplitude_factor = 1.6) {
      if (!inherits(sound, "Sound")) {
        stop("sound must be a Sound object")
      }
      .pointprocess_sound_get_shimmer_dda(
        private$ptr,
        sound$.__enclos_env__$private$ptr,
        as.numeric(from_time), 
        as.numeric(to_time),
        as.numeric(period_floor), 
        as.numeric(period_ceiling), 
        as.numeric(max_period_factor),
        as.numeric(max_amplitude_factor)
      )
    },
    
    # ========================================================================
    # Period Statistics
    # ========================================================================
    
    #' @description
    #' Get mean period
    #' @param from_time Start time (0 = start of object)
    #' @param to_time End time (0 = end of object)
    #' @param period_floor Minimum period (default 0.0001 s)
    #' @param period_ceiling Maximum period (default 0.02 s)
    #' @param max_period_factor Maximum ratio between consecutive periods (default 1.3)
    #' @return Mean period in seconds
    get_mean_period = function(from_time = 0, to_time = 0, 
                               period_floor = 0.0001, period_ceiling = 0.02, 
                               max_period_factor = 1.3) {
      .pointprocess_get_mean_period(
        private$ptr, 
        as.numeric(from_time), 
        as.numeric(to_time),
        as.numeric(period_floor), 
        as.numeric(period_ceiling), 
        as.numeric(max_period_factor)
      )
    },
    
    #' @description
    #' Get standard deviation of period
    #' @param from_time Start time (0 = start of object)
    #' @param to_time End time (0 = end of object)
    #' @param period_floor Minimum period (default 0.0001 s)
    #' @param period_ceiling Maximum period (default 0.02 s)
    #' @param max_period_factor Maximum ratio between consecutive periods (default 1.3)
    #' @return Standard deviation of period in seconds
    get_stdev_period = function(from_time = 0, to_time = 0, 
                                period_floor = 0.0001, period_ceiling = 0.02, 
                                max_period_factor = 1.3) {
      .pointprocess_get_stdev_period(
        private$ptr, 
        as.numeric(from_time), 
        as.numeric(to_time),
        as.numeric(period_floor), 
        as.numeric(period_ceiling), 
        as.numeric(max_period_factor)
      )
    },
    
    # ========================================================================
    # Modification Methods
    # ========================================================================
    
    #' @description
    #' Add a point at the specified time
    #' @param time Time in seconds
    #' @return Invisible self (for method chaining)
    add_point = function(time) {
      .pointprocess_add_point(private$ptr, as.numeric(time))
      invisible(self)
    },
    
    #' @description
    #' Remove a point by index
    #' @param index Point index (1-based)
    #' @return Invisible self (for method chaining)
    remove_point = function(index) {
      .pointprocess_remove_point(private$ptr, as.integer(index))
      invisible(self)
    },
    
    #' @description
    #' Remove the point nearest to the specified time
    #' @param time Time in seconds
    #' @return Invisible self (for method chaining)
    remove_point_near = function(time) {
      .pointprocess_remove_point_near(private$ptr, as.numeric(time))
      invisible(self)
    },
    
    #' @description
    #' Remove all points between two times
    #' @param from_time Start time
    #' @param to_time End time
    #' @return Invisible self (for method chaining)
    remove_points_between = function(from_time, to_time) {
      .pointprocess_remove_points_between(
        private$ptr, 
        as.numeric(from_time), 
        as.numeric(to_time)
      )
      invisible(self)
    },
    
    # ========================================================================
    # Export Methods
    # ========================================================================
    
    #' @description
    #' Convert to R data frame
    #' @return Data frame with columns: time (seconds)
    as_data_frame = function() {
      n <- self$get_number_of_points()
      if (n == 0) {
        return(data.frame(time = numeric(0)))
      }
      
      times <- numeric(n)
      for (i in seq_len(n)) {
        times[i] <- self$get_time_from_index(i)
      }
      
      data.frame(time = times)
    },
    
    #' @description
    #' Save PointProcess to file
    #' @param path Output file path
    #' @return Invisible self
    save = function(path) {
      .pointprocess_save(private$ptr, path)
      invisible(self)
    },
    
    # ========================================================================
    # Print Method
    # ========================================================================
    # Voice Analysis
    # ========================================================================
    
    #' @description
    #' Generate comprehensive voice report with jitter, shimmer, and harmonicity measures.
    #' 
    #' This function computes all standard voice quality metrics as provided by Praat's
    #' Voice Report. It requires a Sound object and a Pitch object to compute the complete
    #' set of measurements.
    #' 
    #' @param sound Sound object
    #' @param pitch Pitch object
    #' @param from_time Start time (0 = start of sound)
    #' @param to_time End time (0 = end of sound)
    #' @param pitch_floor Minimum pitch for period calculations (Hz)
    #' @param pitch_ceiling Maximum pitch for period calculations (Hz)
    #' @param maximum_period_factor Maximum allowed period factor for jitter
    #' @param maximum_amplitude_factor Maximum allowed amplitude factor for shimmer
    #' @param silence_threshold Silence threshold (fraction of global peak)
    #' @param voicing_threshold Voicing threshold (fraction between 0 and 1)
    #' 
    #' @return Named list with voice quality measurements:
    #' \describe{
    #'   \item{jitter_local}{Local jitter (period-to-period variation)}
    #'   \item{jitter_local_absolute}{Local jitter in seconds}
    #'   \item{jitter_rap}{Relative Average Perturbation}
    #'   \item{jitter_ppq5}{5-point Period Perturbation Quotient (required for DSI)}
    #'   \item{jitter_ddp}{Difference of Differences of Periods}
    #'   \item{shimmer_local}{Local shimmer (amplitude variation, required for AVQI)}
    #'   \item{shimmer_local_db}{Local shimmer in dB (required for AVQI)}
    #'   \item{shimmer_apq3}{3-point Amplitude Perturbation Quotient}
    #'   \item{shimmer_apq5}{5-point Amplitude Perturbation Quotient}
    #'   \item{shimmer_apq11}{11-point Amplitude Perturbation Quotient}
    #'   \item{shimmer_dda}{Difference of Differences of Amplitudes}
    #'   \item{mean_harmonics_to_noise_ratio}{Mean HNR in dB}
    #'   \item{mean_autocorrelation}{Mean autocorrelation coefficient}
    #'   \item{mean_noise_to_harmonics_ratio}{Mean NHR}
    #'   \item{median_pitch}{Median pitch in Hz}
    #'   \item{mean_pitch}{Mean pitch in Hz}
    #'   \item{stdev_pitch}{Standard deviation of pitch}
    #'   \item{minimum_pitch}{Minimum pitch}
    #'   \item{maximum_pitch}{Maximum pitch}
    #'   \item{number_of_pulses}{Total number of detected pulses}
    #'   \item{number_of_periods}{Number of valid periods}
    #'   \item{mean_period}{Mean period in seconds}
    #'   \item{stdev_period}{Standard deviation of periods}
    #'   \item{fraction_unvoiced_frames}{Fraction of unvoiced frames}
    #'   \item{number_of_voice_breaks}{Count of voice breaks}
    #'   \item{degree_of_voice_breaks}{Fraction of time in voice breaks}
    #' }
    #' 
    #' @examples
    #' \dontrun{
    #' sound <- Sound$new("audio.wav")
    #' pitch <- sound$to_pitch_cc()
    #' pp <- sound$to_point_process_cc(pitch)
    #' 
    #' # Get complete voice report
    #' report <- pp$voice_report(sound, pitch)
    #' 
    #' # Extract specific measures for AVQI
    #' shimmer_local <- report$shimmer_local * 100  # Convert to percentage
    #' shimmer_local_db <- report$shimmer_local_db
    #' 
    #' # Extract jitter ppq5 for DSI
    #' jitter_ppq5 <- report$jitter_ppq5 * 100  # Convert to percentage
    #' }
    voice_report = function(sound, pitch,
                           from_time = 0,
                           to_time = 0,
                           pitch_floor = 75,
                           pitch_ceiling = 600,
                           maximum_period_factor = 1.3,
                           maximum_amplitude_factor = 1.6,
                           silence_threshold = 0.03,
                           voicing_threshold = 0.45) {
      
      if (!inherits(sound, "Sound")) {
        stop("sound must be a Sound object")
      }
      if (!inherits(pitch, "Pitch")) {
        stop("pitch must be a Pitch object")
      }
      
      .pointprocess_voice_report(
        sound$.xptr,
        pitch$.xptr,
        private$ptr,
        from_time,
        to_time,
        pitch_floor,
        pitch_ceiling,
        maximum_period_factor,
        maximum_amplitude_factor,
        silence_threshold,
        voicing_threshold
      )
    },
    
    # ========================================================================
    # Print
    # ========================================================================
    
    #' @description
    #' Print method for PointProcess objects
    print = function() {
      cat("<Praat PointProcess>\n")
      n_points <- self$get_number_of_points()
      cat(sprintf("  Number of points: %d\n", n_points))
      
      if (n_points > 0) {
        first_time <- self$get_time_from_index(1)
        last_time <- self$get_time_from_index(n_points)
        duration <- last_time - first_time
        cat(sprintf("  Time range: %.6f - %.6f s (%.3f s)\n", 
                    first_time, last_time, duration))
        
        if (n_points >= 2) {
          mean_interval <- duration / (n_points - 1)
          mean_freq <- 1.0 / mean_interval
          cat(sprintf("  Mean interval: %.6f s (%.1f Hz)\n", 
                      mean_interval, mean_freq))
        }
      }
      
      invisible(self)
    }
  )
)
