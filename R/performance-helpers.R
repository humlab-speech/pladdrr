#' Fast CPPS Calculation (Advanced Performance API)
#'
#' @description
#' Bypass R6 method dispatch for maximum performance in CPPS calculation.
#' This function is 1.5-2x faster than the standard PowerCepstrogram$get_cpps()
#' method but requires manual parameter management.
#'
#' @param sound Sound object or external pointer
#' @param subtract_tilt Logical, subtract tilt before calculating CPPS (default FALSE)
#' @param time_averaging_window Numeric, time averaging window in seconds (default 0.01)
#' @param quefrency_averaging_window Numeric, quefrency averaging window in seconds (default 0.001)
#' @param pitch_floor Numeric, minimum F0 in Hz (default 60)
#' @param pitch_ceiling Numeric, maximum F0 in Hz (default 330)
#' @param delta_f0 Numeric, F0 fractional precision (default 0.05)
#' @param interpolation Character, one of "parabolic", "none", "cubic", "sinc70", "sinc700" (default "parabolic")
#' @param qstart_fit Numeric, quefrency range start for fitting in seconds (default 0.001)
#' @param qend_fit Numeric, quefrency range end in seconds (default 0, means auto)
#' @param trend_line_type Character, "straight" or "exponential" (default "straight")
#' @param fit_method Character, "robust", "least_squares", or "robust slow" (default "robust")
#' @param cepstrogram_pitch_floor Numeric, pitch floor for cepstrogram creation (default 60)
#' @param time_step Numeric, time step for cepstrogram in seconds (default 0.002)
#' @param max_frequency Numeric, max frequency for cepstrogram in Hz (default 5000)
#' @param pre_emphasis_from Numeric, pre-emphasis frequency in Hz (default 50)
#'
#' @return Numeric CPPS value in dB
#'
#' @details
#' **ADVANCED API - Use with caution!**
#'
#' This function bypasses R6 method dispatch by calling internal C++ functions
#' directly. It's 1.5-2x faster than the standard API but:
#' - Direct pointer access (must ensure valid Sound object)
#' - Less forgiving of invalid parameters
#' - No automatic validation beyond basic type checking
#'
#' **When to use:**
#' - Batch processing >100 files
#' - Performance-critical applications (e.g., AVQI v3.01)
#' - Real-time analysis scenarios
#'
#' **Standard API (slower, user-friendly):**
#' ```r
#' pcep <- sound$to_powercepstrogram(60, 0.002, 5000, 50)
#' cpps <- pcep$get_cpps(subtract_tilt = FALSE, ...)
#' ```
#'
#' **Fast API (this function):**
#' ```r
#' cpps <- calculate_cpps_fast(sound, subtract_tilt = FALSE, ...)
#' ```
#'
#' @examples
#' \dontrun{
#' sound <- Sound(system.file("signalfiles", "sound.wav", package = "pladdrr"))
#'
#' # Standard API
#' cpps_standard <- {
#'   pcep <- sound$to_powercepstrogram(60, 0.002, 5000, 50)
#'   pcep$get_cpps(subtract_tilt = FALSE, time_averaging_window = 0.01,
#'                 quefrency_averaging_window = 0.001, pitch_floor = 60,
#'                 pitch_ceiling = 330)
#' }
#'
#' # Fast API (1.5-2x faster)
#' cpps_fast <- calculate_cpps_fast(sound, subtract_tilt = FALSE,
#'                                   time_averaging_window = 0.01,
#'                                   quefrency_averaging_window = 0.001,
#'                                   pitch_floor = 60, pitch_ceiling = 330)
#'
#' # Results should be identical
#' all.equal(cpps_standard, cpps_fast)
#' }
#'
#' @export
calculate_cpps_fast <- function(
  sound,
  subtract_tilt = TRUE,
  time_averaging_window = 0.001,
  quefrency_averaging_window = 0.0005,
  pitch_floor = 60,
  pitch_ceiling = 333.3,
  delta_f0 = 0.05,
  interpolation = "parabolic",
  qstart_fit = 0.003,
  qend_fit = 0.04,
  trend_line_type = "straight",
  fit_method = "robust",
  cepstrogram_pitch_floor = 60,
  time_step = 0.002,
  max_frequency = 5000,
  pre_emphasis_from = 50
) {
  # Extract pointer if R6 object
  sound_ptr <- if (inherits(sound, "Sound")) {
    sound$.xptr
  } else if (inherits(sound, "externalptr")) {
    sound
  } else {
    stop("sound must be a Sound object or external pointer")
  }

  # Map string arguments to integer codes (Praat convention)
  interp_map <- c("none" = 0, "parabolic" = 1, "cubic" = 2,
                  "sinc70" = 3, "sinc700" = 4)
  # Praat enum: kCepstrum_trendType: LINEAR=1, EXPONENTIAL_DECAY=2
  trend_map <- c("straight" = 1, "exponential" = 2, "exponential decay" = 2)
  # Praat enum: kCepstrum_trendFit: ROBUST_FAST=1, LEAST_SQUARES=2, ROBUST_SLOW=3
  fit_map <- c("robust" = 1, "least_squares" = 2, "robust slow" = 3)

  interpolation <- match.arg(interpolation, names(interp_map))
  trend_line_type <- match.arg(trend_line_type, names(trend_map))
  fit_method <- match.arg(fit_method, names(fit_map))

  # Direct Sound → CPPS path (v4.1.0 optimization)
  # Keeps PowerCepstrogram entirely in C++, no R/C++ boundary crossing
  cpps <- .sound_to_cpps_direct(
    sound_ptr,
    # PowerCepstrogram creation params
    as.numeric(cepstrogram_pitch_floor),
    as.numeric(time_step),
    as.numeric(max_frequency),
    as.numeric(pre_emphasis_from),
    # CPPS calculation params
    as.logical(subtract_tilt),
    as.numeric(time_averaging_window),
    as.numeric(quefrency_averaging_window),
    as.numeric(pitch_floor),
    as.numeric(pitch_ceiling),
    as.numeric(delta_f0),
    as.integer(interp_map[[interpolation]]),
    as.numeric(qstart_fit),
    as.numeric(qend_fit),
    as.integer(trend_map[[trend_line_type]]),
    as.integer(fit_map[[fit_method]])
  )

  return(cpps)
}


#' Fast PowerCepstrogram Creation (Advanced Performance API)
#'
#' @description
#' Create a PowerCepstrogram object bypassing R6 method dispatch for maximum performance.
#' Returns an external pointer that can be used with other fast path functions.
#'
#' @param sound Sound object or external pointer
#' @param pitch_floor Numeric, minimum pitch in Hz (default 60)
#' @param time_step Numeric, time step in seconds (default 0.002)
#' @param max_frequency Numeric, maximum frequency in Hz (default 5000)
#' @param pre_emphasis_from Numeric, pre-emphasis frequency in Hz (default 50)
#'
#' @return External pointer to PowerCepstrogram object
#'
#' @details
#' **ADVANCED API** - Returns raw external pointer, not R6 object.
#'
#' Use this when you need to create multiple PowerCepstrogram objects in a loop
#' and want to minimize R6 overhead. The returned pointer can be:
#' - Passed to other fast path functions
#' - Wrapped in R6 PowerCepstrogram object if needed
#'
#' @examples
#' \dontrun{
#' sound <- Sound(system.file("signalfiles", "sound.wav", package = "pladdrr"))
#'
#' # Fast path: returns external pointer
#' pcep_ptr <- to_powercepstrogram_fast(sound, 60, 0.002, 5000, 50)
#'
#' # Can wrap in R6 object if needed
#' pcep <- PowerCepstrogram$new(xptr = pcep_ptr)
#' }
#'
#' @export
to_powercepstrogram_fast <- function(sound,
                                     pitch_floor = 60,
                                     time_step = 0.002,
                                     max_frequency = 5000,
                                     pre_emphasis_from = 50) {
  sound_ptr <- if (inherits(sound, "Sound")) {
    sound$.xptr
  } else if (inherits(sound, "externalptr")) {
    sound
  } else {
    stop("sound must be a Sound object or external pointer")
  }

  .sound_to_powercepstrogram(
    sound_ptr,
    pitch_floor,
    time_step,
    max_frequency,
    pre_emphasis_from
  )
}


#' Get CPPS from PowerCepstrogram Pointer (Advanced Performance API)
#'
#' @description
#' Calculate CPPS from a PowerCepstrogram external pointer, bypassing R6 dispatch.
#'
#' @param powercepstrogram External pointer to PowerCepstrogram object
#' @param subtract_tilt Logical, subtract tilt before calculating CPPS (default FALSE)
#' @param time_averaging_window Numeric, time averaging window in seconds (default 0.01)
#' @param quefrency_averaging_window Numeric, quefrency averaging window in seconds (default 0.001)
#' @param pitch_floor Numeric, minimum F0 in Hz (default 60)
#' @param pitch_ceiling Numeric, maximum F0 in Hz (default 330)
#' @param delta_f0 Numeric, F0 fractional precision (default 0.05)
#' @param interpolation Character, one of "parabolic", "none", "cubic", "sinc70", "sinc700" (default "parabolic")
#' @param qstart_fit Numeric, quefrency range start for fitting in seconds (default 0.001)
#' @param qend_fit Numeric, quefrency range end in seconds (default 0, means auto)
#' @param trend_line_type Character, "straight" or "exponential" (default "straight")
#' @param fit_method Character, "robust", "least_squares", or "robust slow" (default "robust")
#'
#' @return Numeric CPPS value in dB
#'
#' @details
#' **ADVANCED API** - Use with `to_powercepstrogram_fast()` for maximum performance.
#'
#' Useful when you need to calculate CPPS multiple times with different parameters
#' from the same PowerCepstrogram object.
#'
#' @examples
#' \dontrun{
#' sound <- Sound(system.file("signalfiles", "sound.wav", package = "pladdrr"))
#'
#' # Create cepstrogram once
#' pcep_ptr <- to_powercepstrogram_fast(sound)
#'
#' # Calculate CPPS with different parameters
#' cpps1 <- get_cpps_fast(pcep_ptr, subtract_tilt = FALSE, pitch_floor = 60)
#' cpps2 <- get_cpps_fast(pcep_ptr, subtract_tilt = TRUE, pitch_floor = 80)
#' }
#'
#' @export
get_cpps_fast <- function(
  powercepstrogram,
  subtract_tilt = FALSE,
  time_averaging_window = 0.01,
  quefrency_averaging_window = 0.001,
  pitch_floor = 60,
  pitch_ceiling = 330,
  delta_f0 = 0.05,
  interpolation = "parabolic",
  qstart_fit = 0.001,
  qend_fit = 0,
  trend_line_type = "straight",
  fit_method = "robust"
) {
  if (!inherits(powercepstrogram, "externalptr")) {
    stop("powercepstrogram must be an external pointer from to_powercepstrogram_fast()")
  }

  # Map string arguments to integer codes
  interp_map <- c("none" = 0, "parabolic" = 1, "cubic" = 2,
                  "sinc70" = 3, "sinc700" = 4)
  # Praat enum: kCepstrum_trendType: LINEAR=1, EXPONENTIAL_DECAY=2
  trend_map <- c("straight" = 1, "exponential" = 2, "exponential decay" = 2)
  # Praat enum: kCepstrum_trendFit: ROBUST_FAST=1, LEAST_SQUARES=2, ROBUST_SLOW=3
  fit_map <- c("robust" = 1, "least_squares" = 2, "robust slow" = 3)

  interpolation <- match.arg(interpolation, names(interp_map))
  trend_line_type <- match.arg(trend_line_type, names(trend_map))
  fit_method <- match.arg(fit_method, names(fit_map))

  .powercepstrogram_get_cpps(
    powercepstrogram,
    as.logical(subtract_tilt),
    as.numeric(time_averaging_window),
    as.numeric(quefrency_averaging_window),
    as.numeric(pitch_floor),
    as.numeric(pitch_ceiling),
    as.numeric(delta_f0),
    as.integer(interp_map[[interpolation]]),
    as.numeric(qstart_fit),
    as.numeric(qend_fit),
    as.integer(trend_map[[trend_line_type]]),
    as.integer(fit_map[[fit_method]])
  )
}


# =============================================================================
# Advanced Performance API: XPtr Window Functions
# Requires RcppXPtrUtils package for compilation
# =============================================================================

#' Apply Compiled Window Function (Advanced Performance API)
#'
#' @description
#' Apply a user-defined C++ window function to a Sound object with 70x speedup
#' over R function callbacks. Requires the RcppXPtrUtils package.
#'
#' @param sound Sound object or external pointer
#' @param window_func External pointer from RcppXPtrUtils::cppXPtr()
#'
#' @return Sound object with window function applied
#'
#' @details
#' **ADVANCED API** - Requires RcppXPtrUtils package.
#'
#' The window function receives normalized time (0 to 1) and returns a
#' multiplier. Common window functions:
#'
#' \itemize{
#'   \item Hamming: `0.54 - 0.46 * cos(2 * M_PI * t)`
#'   \item Hanning: `0.5 * (1 - cos(2 * M_PI * t))`
#'   \item Gaussian: `exp(-18 * (t - 0.5)^2)`
#'   \item Triangular: `1 - fabs(2*t - 1)`
#' }
#'
#' @examples
#' \dontrun{
#' library(RcppXPtrUtils)
#'
#' # Create compiled Gaussian window function
#' gauss_window <- cppXPtr(
#'   "double gauss(double t) {
#'     double x = t - 0.5;
#'     return exp(-18.0 * x * x);
#'   }",
#'   depends = character()
#' )
#'
#' # Verify signature (optional but recommended)
#' checkXPtr(gauss_window, "double", "double")
#'
#' # Apply to sound (70x faster than R function)
#' sound <- Sound(system.file("signalfiles", "sound.wav", package = "pladdrr"))
#' windowed <- apply_window_xptr(sound, gauss_window)
#' }
#'
#' @export
apply_window_xptr <- function(sound, window_func) {
  if (!requireNamespace("RcppXPtrUtils", quietly = TRUE)) {
    stop("RcppXPtrUtils package required for apply_window_xptr(). ",
         "Install with: install.packages('RcppXPtrUtils')")
  }

  # Extract pointer if R6 object
  sound_ptr <- if (inherits(sound, "Sound")) {
    sound$.xptr
  } else if (inherits(sound, "externalptr")) {
    sound
  } else {
    stop("sound must be a Sound object or external pointer")
  }

  # Get internal RSound module
  ns <- asNamespace("pladdrr")
  sound_module <- ns$sound_module

  # Create RSound wrapper and call method
  rsound <- sound_module$RSound$new(sound_ptr)
  result_ptr <- rsound$apply_window_xptr(window_func)

  # Wrap result in R6 Sound object
  Sound$new(.xptr = result_ptr)
}


#' Apply Compiled Transform Function (Advanced Performance API)
#'
#' @description
#' Apply a user-defined C++ transform function to sample values with 70x speedup
#' over R function callbacks. Requires the RcppXPtrUtils package.
#'
#' @param sound Sound object or external pointer
#' @param transform_func External pointer from RcppXPtrUtils::cppXPtr()
#'
#' @return Sound object with transform function applied
#'
#' @details
#' **ADVANCED API** - Requires RcppXPtrUtils package.
#'
#' The transform function receives sample amplitude and returns transformed
#' amplitude. Common transforms:
#'
#' \itemize{
#'   \item Clipping: `x > threshold ? threshold : (x < -threshold ? -threshold : x)`
#'   \item Soft clipping: `tanh(x * gain)`
#'   \item Rectification: `fabs(x)`
#'   \item Squaring: `x * x`
#' }
#'
#' @examples
#' \dontrun{
#' library(RcppXPtrUtils)
#'
#' # Create compiled soft clipping function
#' soft_clip <- cppXPtr(
#'   "double softclip(double x) { return tanh(x * 2.0); }",
#'   depends = character()
#' )
#'
#' # Apply to sound (70x faster than R function)
#' sound <- Sound(system.file("signalfiles", "sound.wav", package = "pladdrr"))
#' clipped <- apply_transform_xptr(sound, soft_clip)
#' }
#'
#' @export
apply_transform_xptr <- function(sound, transform_func) {
  if (!requireNamespace("RcppXPtrUtils", quietly = TRUE)) {
    stop("RcppXPtrUtils package required for apply_transform_xptr(). ",
         "Install with: install.packages('RcppXPtrUtils')")
  }

  # Extract pointer if R6 object
  sound_ptr <- if (inherits(sound, "Sound")) {
    sound$.xptr
  } else if (inherits(sound, "externalptr")) {
    sound
  } else {
    stop("sound must be a Sound object or external pointer")
  }

  # Get internal RSound module
  ns <- asNamespace("pladdrr")
  sound_module <- ns$sound_module

  # Create RSound wrapper and call method
  rsound <- sound_module$RSound$new(sound_ptr)
  result_ptr <- rsound$apply_transform_xptr(transform_func)

  # Wrap result in R6 Sound object
  Sound$new(.xptr = result_ptr)
}


#' Create Common Window Function XPtr
#'
#' @description
#' Convenience function to create pre-defined window functions as compiled XPtrs.
#' Requires the RcppXPtrUtils package.
#'
#' @param type Character, one of "hamming", "hanning", "gaussian", "triangular",
#'   "blackman", "rectangular"
#' @param sigma Numeric, standard deviation for Gaussian window (default 0.25)
#'
#' @return External pointer to compiled window function
#'
#' @examples
#' \dontrun{
#' library(RcppXPtrUtils)
#'
#' # Create Hamming window (pre-compiled)
#' hamming <- create_window_xptr("hamming")
#'
#' # Apply to sound
#' sound <- Sound(system.file("signalfiles", "sound.wav", package = "pladdrr"))
#' windowed <- apply_window_xptr(sound, hamming)
#' }
#'
#' @export
create_window_xptr <- function(type = c("hamming", "hanning", "gaussian",
                                         "triangular", "blackman", "rectangular"),
                               sigma = 0.25) {
  if (!requireNamespace("RcppXPtrUtils", quietly = TRUE)) {
    stop("RcppXPtrUtils package required for create_window_xptr(). ",
         "Install with: install.packages('RcppXPtrUtils')")
  }

  type <- match.arg(type)

  # C++ window function implementations
  window_code <- switch(type,
    hamming = "double window(double t) {
      return 0.54 - 0.46 * cos(2.0 * M_PI * t);
    }",
    hanning = "double window(double t) {
      return 0.5 * (1.0 - cos(2.0 * M_PI * t));
    }",
    gaussian = sprintf("double window(double t) {
      double x = t - 0.5;
      double sigma = %f;
      return exp(-0.5 * (x * x) / (sigma * sigma));
    }", sigma),
    triangular = "double window(double t) {
      return 1.0 - fabs(2.0 * t - 1.0);
    }",
    blackman = "double window(double t) {
      return 0.42 - 0.5 * cos(2.0 * M_PI * t) + 0.08 * cos(4.0 * M_PI * t);
    }",
    rectangular = "double window(double t) {
      return 1.0;
    }"
  )

  # Add required includes
  full_code <- paste0("#include <cmath>\n#ifndef M_PI\n#define M_PI 3.14159265358979323846\n#endif\n", window_code)

  RcppXPtrUtils::cppXPtr(full_code, depends = character())
}
