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
#' ## Conversion
#'
#' - `$to_textgrid_vuv(max_voiced_period, max_unvoiced_period)` - Create voiced/unvoiced TextGrid
#'   (required for DSI calculation with soft phonation)
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
#' @export
PointProcess <- function(.xptr = NULL) {
  if (is.null(.xptr)) {
    stop("PointProcess objects must be created from a Sound or Pitch object using to_point_process_*() methods")
  }
  
  # Load Rcpp Module
  pp_mod <- get_module("pointprocess_module")
  cpp_pp <- pp_mod$RPointProcess$new(.xptr)
  
  # Create wrapper
  pp <- structure(list(
    .cpp = cpp_pp,
    .xptr = .xptr,
    
    # === Basic Query Methods (from module) ===
    is_valid = function() cpp_pp$is_valid(),
    get_xmin = function() cpp_pp$get_xmin(),
    get_xmax = function() cpp_pp$get_xmax(),
    get_duration = function() cpp_pp$get_duration(),
    get_number_of_points = function() cpp_pp$get_number_of_points(),
    get_time_from_index = function(index) cpp_pp$get_time(as.integer(index)),
    get_time = function(index) cpp_pp$get_time(as.integer(index)),
    get_nearest_index = function(time) cpp_pp$get_nearest_index(as.numeric(time)),
    get_low_index = function(time) cpp_pp$get_low_index(as.numeric(time)),
    get_high_index = function(time) cpp_pp$get_high_index(as.numeric(time)),
    get_interval = function(time) cpp_pp$get_interval(as.numeric(time)),
    
    # Period statistics (from module)
    get_number_of_periods = function(from_time = 0, to_time = 0, 
                                     period_floor = 0.0001, period_ceiling = 0.02,
                                     max_period_factor = 1.3) {
      cpp_pp$get_number_of_periods(
        as.numeric(from_time), as.numeric(to_time),
        as.numeric(period_floor), as.numeric(period_ceiling),
        as.numeric(max_period_factor)
      )
    },
    get_mean_period = function(from_time = 0, to_time = 0,
                              period_floor = 0.0001, period_ceiling = 0.02,
                              max_period_factor = 1.3) {
      cpp_pp$get_mean_period(
        as.numeric(from_time), as.numeric(to_time),
        as.numeric(period_floor), as.numeric(period_ceiling),
        as.numeric(max_period_factor)
      )
    },
    get_stdev_period = function(from_time = 0, to_time = 0,
                               period_floor = 0.0001, period_ceiling = 0.02,
                               max_period_factor = 1.3) {
      cpp_pp$get_stdev_period(
        as.numeric(from_time), as.numeric(to_time),
        as.numeric(period_floor), as.numeric(period_ceiling),
        as.numeric(max_period_factor)
      )
    },
    get_voice_breaks = function(from_time = 0, to_time = 0,
                                period_floor = 0.0001, period_ceiling = 0.02,
                                max_period_factor = 1.3) {
      cpp_pp$get_voice_breaks(
        as.numeric(from_time), as.numeric(to_time),
        as.numeric(period_floor), as.numeric(period_ceiling),
        as.numeric(max_period_factor)
      )
    },
    
    # === Modification Methods (from module) ===
    add_point = function(time) {
      cpp_pp$add_point(as.numeric(time))
      invisible(pp)
    },
    remove_point = function(index) {
      cpp_pp$remove_point(as.integer(index))
      invisible(pp)
    },
    remove_point_near = function(time) {
      cpp_pp$remove_point_near(as.numeric(time))
      invisible(pp)
    },
    remove_points_between = function(from_time, to_time) {
      cpp_pp$remove_points_between(as.numeric(from_time), as.numeric(to_time))
      invisible(pp)
    },
    fill = function(from_time, to_time, period) {
      cpp_pp$fill(as.numeric(from_time), as.numeric(to_time), as.numeric(period))
      invisible(pp)
    },
    voice = function(period, max_period_factor = 1.3) {
      cpp_pp$voice(as.numeric(period), as.numeric(max_period_factor))
      invisible(pp)
    },
    
    # === Set Operations (from module) ===
    union_with = function(other_pp) {
      if (!inherits(other_pp, "PointProcess")) stop("Argument must be PointProcess")
      cpp_pp$union_with(other_pp$.xptr)
      invisible(pp)
    },
    intersection_with = function(other_pp) {
      if (!inherits(other_pp, "PointProcess")) stop("Argument must be PointProcess")
      cpp_pp$intersection_with(other_pp$.xptr)
      invisible(pp)
    },
    difference_with = function(other_pp) {
      if (!inherits(other_pp, "PointProcess")) stop("Argument must be PointProcess")
      cpp_pp$difference_with(other_pp$.xptr)
      invisible(pp)
    },
    
    # === Conversions (from module) ===
    upto_pitch_tier = function(ceiling = 600) {
      ptr <- cpp_pp$upto_pitch_tier_ptr(as.numeric(ceiling))
      PitchTier(.xptr = ptr)
    },
    upto_intensity_tier = function(intensity = 100) {
      ptr <- cpp_pp$upto_intensity_tier_ptr(as.numeric(intensity))
      IntensityTier(.xptr = ptr)
    },
    
    # === Export (from module) ===
    as_vector = function() cpp_pp$as_vector(),
    as_data_frame = function() cpp_pp$as_data_frame(),
    save = function(path) cpp_pp$save(as.character(path)),
    get_xptr = function() .xptr,
    
    # === Voice Quality Methods (use old [[Rcpp::export]] wrappers) ===
    # These are complex C++ functions not in the module yet
    
    get_jitter_local = function(from_time = 0, to_time = 0,
                               period_floor = 0.0001, period_ceiling = 0.02,
                               max_period_factor = 1.3) {
      .pointprocess_get_jitter_local(
        .xptr, from_time, to_time, period_floor, period_ceiling, max_period_factor
      )
    },
    
    get_jitter_local_absolute = function(from_time = 0, to_time = 0,
                                        period_floor = 0.0001, period_ceiling = 0.02,
                                        max_period_factor = 1.3) {
      .pointprocess_get_jitter_local_absolute(
        .xptr, from_time, to_time, period_floor, period_ceiling, max_period_factor
      )
    },
    
    get_jitter_rap = function(from_time = 0, to_time = 0,
                             period_floor = 0.0001, period_ceiling = 0.02,
                             max_period_factor = 1.3) {
      .pointprocess_get_jitter_rap(
        .xptr, from_time, to_time, period_floor, period_ceiling, max_period_factor
      )
    },
    
    get_jitter_ppq5 = function(from_time = 0, to_time = 0,
                              period_floor = 0.0001, period_ceiling = 0.02,
                              max_period_factor = 1.3) {
      .pointprocess_get_jitter_ppq5(
        .xptr, from_time, to_time, period_floor, period_ceiling, max_period_factor
      )
    },
    
    get_jitter_ddp = function(from_time = 0, to_time = 0,
                             period_floor = 0.0001, period_ceiling = 0.02,
                             max_period_factor = 1.3) {
      .pointprocess_get_jitter_ddp(
        .xptr, from_time, to_time, period_floor, period_ceiling, max_period_factor
      )
    },
    
    get_shimmer_local = function(sound, from_time = 0, to_time = 0,
                                period_floor = 0.0001, period_ceiling = 0.02,
                                max_period_factor = 1.3, max_amplitude_factor = 1.6) {
      if (!inherits(sound, "Sound")) stop("First argument must be a Sound object")
      .pointprocess_get_shimmer_local(
        .xptr, sound$.xptr, from_time, to_time, period_floor, period_ceiling,
        max_period_factor, max_amplitude_factor
      )
    },
    
    get_shimmer_local_db = function(sound, from_time = 0, to_time = 0,
                                   period_floor = 0.0001, period_ceiling = 0.02,
                                   max_period_factor = 1.3, max_amplitude_factor = 1.6) {
      if (!inherits(sound, "Sound")) stop("First argument must be a Sound object")
      .pointprocess_get_shimmer_local_db(
        .xptr, sound$.xptr, from_time, to_time, period_floor, period_ceiling,
        max_period_factor, max_amplitude_factor
      )
    },
    
    get_shimmer_apq3 = function(sound, from_time = 0, to_time = 0,
                               period_floor = 0.0001, period_ceiling = 0.02,
                               max_period_factor = 1.3, max_amplitude_factor = 1.6) {
      if (!inherits(sound, "Sound")) stop("First argument must be a Sound object")
      .pointprocess_get_shimmer_apq3(
        .xptr, sound$.xptr, from_time, to_time, period_floor, period_ceiling,
        max_period_factor, max_amplitude_factor
      )
    },
    
    get_shimmer_apq5 = function(sound, from_time = 0, to_time = 0,
                               period_floor = 0.0001, period_ceiling = 0.02,
                               max_period_factor = 1.3, max_amplitude_factor = 1.6) {
      if (!inherits(sound, "Sound")) stop("First argument must be a Sound object")
      .pointprocess_get_shimmer_apq5(
        .xptr, sound$.xptr, from_time, to_time, period_floor, period_ceiling,
        max_period_factor, max_amplitude_factor
      )
    },
    
    get_shimmer_apq11 = function(sound, from_time = 0, to_time = 0,
                                period_floor = 0.0001, period_ceiling = 0.02,
                                max_period_factor = 1.3, max_amplitude_factor = 1.6) {
      if (!inherits(sound, "Sound")) stop("First argument must be a Sound object")
      .pointprocess_get_shimmer_apq11(
        .xptr, sound$.xptr, from_time, to_time, period_floor, period_ceiling,
        max_period_factor, max_amplitude_factor
      )
    },
    
    get_shimmer_dda = function(sound, from_time = 0, to_time = 0,
                              period_floor = 0.0001, period_ceiling = 0.02,
                              max_period_factor = 1.3, max_amplitude_factor = 1.6) {
      if (!inherits(sound, "Sound")) stop("First argument must be a Sound object")
      .pointprocess_get_shimmer_dda(
        .xptr, sound$.xptr, from_time, to_time, period_floor, period_ceiling,
        max_period_factor, max_amplitude_factor
      )
    },
    
    voice_report = function(sound, pitch,
                           from_time = 0, to_time = 0,
                           pitch_floor = 75, pitch_ceiling = 600,
                           period_floor = 0.0001, period_ceiling = 0.02,
                           max_period_factor = 1.3, max_amplitude_factor = 1.6) {
      if (!inherits(sound, "Sound")) stop("sound argument must be a Sound object")
      if (!inherits(pitch, "Pitch")) stop("pitch argument must be a Pitch object")
      
      .pointprocess_voice_report(
        .xptr, sound$.xptr, pitch$.xptr,
        from_time, to_time,
        pitch_floor, pitch_ceiling,
        period_floor, period_ceiling,
        max_period_factor, max_amplitude_factor
      )
    },
    
    to_textgrid_vuv = function(max_voiced_period, max_unvoiced_period = 0.02) {
      tg_ptr <- .pointprocess_to_textgrid_vuv(
        .xptr,
        as.numeric(max_voiced_period),
        as.numeric(max_unvoiced_period)
      )
      TextGrid(.xptr = tg_ptr)
    },
    
    print = function() {
      cat("<Praat PointProcess>\n")
      cat(sprintf("  Time domain: [%.3f, %.3f] s (%.3f s)\n",
                  cpp_pp$get_xmin(), cpp_pp$get_xmax(), cpp_pp$get_duration()))
      cat(sprintf("  Points: %d\n", cpp_pp$get_number_of_points()))
      invisible(pp)
    }
  ), class = c("PointProcess", "PraatObject"))
  
  pp
}

#' @export
print.PointProcess <- function(x, ...) x$print()

# Note: Old factory/helper functions below preserved
