#' Smoothed Cepstral Peak Prominence (CPPS) in one call
#'
#' @description
#' Computes the smoothed cepstral peak prominence (CPPS, in dB) of a `Sound` —
#' a widely used acoustic measure of voice quality/breathiness. It performs the
#' whole PowerCepstrogram-then-CPPS pipeline in a single call and returns the
#' same value as `sound$to_powercepstrogram(...)$get_cpps(...)` with matching
#' parameters. You supply the analysis parameters directly and are responsible
#' for passing valid values (see the arguments below).
#'
#' @section Defaults differ from Praat's:
#' These defaults follow the AVQI/clinical convention, **not** the defaults of
#' Praat's `PowerCepstrogram: Get CPPS...` dialog. On a 1 s test signal the two
#' parameter sets give 9.92 dB and 4.82 dB respectively — a different
#' measurement, not a rounding difference. Pass the Praat values explicitly to
#' reproduce a Praat run:
#'
#' | parameter | Praat default | pladdrr default |
#' |---|---|---|
#' | `time_averaging_window` | 0.02 | 0.001 |
#' | `quefrency_averaging_window` | 0.0005 | 0.0005 |
#' | `pitch_floor` | 60 | 60 |
#' | `pitch_ceiling` | 330 | 333.3 |
#' | `qstart_fit` | 0.001 | 0.003 |
#' | `qend_fit` | 0.05 | 0.04 |
#' | `trend_line_type` | `"exponential"` | `"straight"` |
#' | `fit_method` | `"robust slow"` | `"robust"` |
#'
#' The `fit_method` difference is deliberate beyond convention: Praat's
#' `"robust slow"` (Theil-Sen) is not reproducible — see the `fit_method`
#' argument.
#'
#' @param sound Sound object or external pointer
#' @param subtract_tilt Logical, subtract tilt before calculating CPPS (default TRUE)
#' @param time_averaging_window Numeric, time averaging window in seconds (default 0.001)
#' @param quefrency_averaging_window Numeric, quefrency averaging window in seconds (default 0.0005)
#' @param pitch_floor Numeric, minimum F0 in Hz (default 60)
#' @param pitch_ceiling Numeric, maximum F0 in Hz (default 333.3)
#' @param delta_f0 Numeric, F0 fractional precision (default 0.05)
#' @param interpolation Character, one of "parabolic", "none", "cubic", "sinc70", "sinc700" (default "parabolic")
#' @param qstart_fit Numeric, quefrency range start for fitting in seconds (default 0.003)
#' @param qend_fit Numeric, quefrency range end in seconds (default 0.04)
#' @param trend_line_type Character, "straight" or "exponential" (default "straight")
#' @param fit_method Character, "robust" (Siegel repeated median), "least_squares",
#'   or "robust slow" (Theil-Sen). Default "robust". **"robust slow" is not
#'   reproducible**: it samples randomly inside Praat's slope selection, so repeated
#'   runs on the same input differ (~0.8 dB observed) and can return values on the
#'   order of 1e290. That is an upstream Praat defect, reproduced faithfully here;
#'   pladdrr warns once per session when you select it.
#' @param cepstrogram_pitch_floor Numeric, pitch floor for cepstrogram creation (default 60)
#' @param time_step Numeric, time step for cepstrogram in seconds (default 0.002)
#' @param max_frequency Numeric, max frequency for cepstrogram in Hz (default 5000)
#' @param pre_emphasis_from Numeric, pre-emphasis frequency in Hz (default 50)
#'
#' @return A single numeric CPPS value in dB.
#'
#' @details
#' Use this when analysing many files in a loop. For interactive or one-off
#' use, the object API (`sound$to_powercepstrogram(...)$get_cpps(...)`) is
#' equivalent and validates its inputs more forgivingly; this function skips
#' that validation, so pass well-formed parameters.
#'
#' This is a **CPPS** helper: it builds a whole-sound PowerCepstrogram and then
#' computes a smoothed peak-prominence summary. If you need a single-interval
#' **CPP** value that matches Praat's `To PowerCepstrum` workflow, extract the
#' interval, convert it to a Spectrum, and call
#' `to_power_cepstrum()$get_peak_prominence()` instead. That path is much
#' cheaper and is not the same metric.
#'
#' @examples
#' sound <- Sound(system.file("extdata", "test.wav", package = "pladdrr"))
#'
#' # One-call CPPS with the default (AVQI-convention) parameters
#' calculate_cpps_fast(sound)
#'
#' # The object API gives the identical value
#' pcep <- sound$to_powercepstrogram(60, 0.002, 5000, 50)
#' pcep$get_cpps()
#'
#' # Reproduce Praat's own "Get CPPS..." defaults
#' calculate_cpps_fast(sound,
#'   time_averaging_window = 0.02, pitch_ceiling = 330,
#'   qstart_fit = 0.001, qend_fit = 0.05,
#'   trend_line_type = "exponential", fit_method = "least_squares"
#' )
#'
#' \dontrun{
#' # Single-interval CPP is a different, cheaper path
#' segment <- sound$extract_part(0, 0.5)
#' cpp <- segment$to_spectrum()$to_power_cepstrum()$get_peak_prominence(
#'   60, 333.3, "parabolic", 0.001, 0.05, "exponential decay", "robust slow"
#' )
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
  interpolation <- match.arg(interpolation, names(.interp_map))
  trend_line_type <- match.arg(trend_line_type, names(.cpps_trend_map))
  fit_method <- match.arg(fit_method, names(.trend_fit_map))
  .check_trend_fit_method(fit_method)
  .check_quefrency_range(qstart_fit, qend_fit)

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
    as.integer(.interp_map[[interpolation]]),
    as.numeric(qstart_fit),
    as.numeric(qend_fit),
    as.integer(.cpps_trend_map[[trend_line_type]]),
    as.integer(.trend_fit_map[[fit_method]])
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
#' sound <- Sound(system.file("extdata", "test.wav", package = "pladdrr"))
#'
#' # Fast path: returns an external pointer, no wrapper object built
#' pcep_ptr <- to_powercepstrogram_fast(sound, 60, 0.002, 5000, 50)
#'
#' # Wrap it when you want the method API
#' pcep <- PowerCepstrogram(.xptr = pcep_ptr)
#' pcep$get_cpps()
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
#' @param fit_method Character, "robust" (Siegel repeated median), "least_squares",
#'   or "robust slow" (Theil-Sen). Default "robust". **"robust slow" is not
#'   reproducible**: it samples randomly inside Praat's slope selection, so repeated
#'   runs on the same input differ (~0.8 dB observed) and can return values on the
#'   order of 1e290. That is an upstream Praat defect, reproduced faithfully here;
#'   pladdrr warns once per session when you select it.
#'
#' @return Numeric CPPS value in dB
#'
#' @details
#' **ADVANCED API** - Takes the external pointer returned by
#' `to_powercepstrogram_fast()` instead of a `PowerCepstrogram` R6 object.
#'
#' Useful when you need to calculate CPPS multiple times with different parameters
#' from the same PowerCepstrogram object.
#'
#' @examples
#' sound <- Sound$create_tone(frequency = 150, duration = 0.5, sampling_rate = 16000)
#'
#' # Create cepstrogram once
#' pcep_ptr <- to_powercepstrogram_fast(sound)
#'
#' # Calculate CPPS with different parameters
#' cpps1 <- get_cpps_fast(pcep_ptr, subtract_tilt = FALSE, pitch_floor = 60)
#' cpps2 <- get_cpps_fast(pcep_ptr, subtract_tilt = TRUE, pitch_floor = 80)
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
  interpolation <- match.arg(interpolation, names(.interp_map))
  trend_line_type <- match.arg(trend_line_type, names(.cpps_trend_map))
  fit_method <- match.arg(fit_method, names(.trend_fit_map))
  .check_trend_fit_method(fit_method)
  .check_quefrency_range(qstart_fit, qend_fit)

  .powercepstrogram_get_cpps(
    powercepstrogram,
    as.logical(subtract_tilt),
    as.numeric(time_averaging_window),
    as.numeric(quefrency_averaging_window),
    as.numeric(pitch_floor),
    as.numeric(pitch_ceiling),
    as.numeric(delta_f0),
    as.integer(.interp_map[[interpolation]]),
    as.numeric(qstart_fit),
    as.numeric(qend_fit),
    as.integer(.cpps_trend_map[[trend_line_type]]),
    as.integer(.trend_fit_map[[fit_method]])
  )
}


# =============================================================================
# Advanced Performance API: XPtr Window Functions
# Requires RcppXPtrUtils package for compilation
# =============================================================================

#' Apply Compiled Window Function (Advanced Performance API)
#'
#' @description
#' Apply a user-defined C++ window function to a Sound object, compiled via
#' RcppXPtrUtils, instead of calling an R callback per sample. Requires the
#' RcppXPtrUtils package.
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
#' \donttest{
#' # NOTE: currently errors — apply_window_xptr() looks up the internal
#' # Sound Rcpp module incorrectly ("attempt to apply non-function").
#' # Compiling a C++ window function takes a few seconds
#' if (requireNamespace("RcppXPtrUtils", quietly = TRUE)) {
#'   gauss_window <- RcppXPtrUtils::cppXPtr(
#'     "double gauss(double t) {
#'       double x = t - 0.5;
#'       return exp(-18.0 * x * x);
#'     }",
#'     depends = character()
#'   )
#'
#'   # Verify signature (optional but recommended)
#'   RcppXPtrUtils::checkXPtr(gauss_window, "double", "double")
#'
#'   sound <- Sound$create_tone(frequency = 220, duration = 0.3, sampling_rate = 16000)
#'   windowed <- apply_window_xptr(sound, gauss_window)
#' }
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
#' Apply a user-defined C++ transform function to sample values, compiled via
#' RcppXPtrUtils, instead of calling an R callback per sample. Requires the
#' RcppXPtrUtils package.
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
#' \donttest{
#' # NOTE: currently errors — apply_transform_xptr() looks up the internal
#' # Sound Rcpp module incorrectly ("attempt to apply non-function").
#' # Compiling a C++ transform function takes a few seconds
#' if (requireNamespace("RcppXPtrUtils", quietly = TRUE)) {
#'   soft_clip <- RcppXPtrUtils::cppXPtr(
#'     "double softclip(double x) { return tanh(x * 2.0); }",
#'     depends = character()
#'   )
#'
#'   sound <- Sound$create_tone(frequency = 220, duration = 0.3, sampling_rate = 16000)
#'   clipped <- apply_transform_xptr(sound, soft_clip)
#' }
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
#' \donttest{
#' # NOTE: currently errors — create_window_xptr() prepends #include lines
#' # before the function body, which breaks RcppXPtrUtils::cppXPtr()'s own
#' # function-signature detection ("isFunction(code) is not TRUE").
#' # Compiling a C++ window function takes a few seconds
#' if (requireNamespace("RcppXPtrUtils", quietly = TRUE)) {
#'   hamming <- create_window_xptr("hamming")
#'
#'   sound <- Sound$create_tone(frequency = 220, duration = 0.3, sampling_rate = 16000)
#'   windowed <- apply_window_xptr(sound, hamming)
#' }
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


# =============================================================================
# Tier 4 Ultra Functions for AVQI/VQ Optimization
# =============================================================================

#' Calculate CPPS with Optimized Single-Call (Tier 4 Ultra)
#'
#' @description
#' Computes CPPS from a `Sound` in a single C++ call, building the
#' PowerCepstrogram internally so no intermediate R object is created.
#'
#' Returns the same value as \code{calculate_cpps_fast()} and as
#' \code{sound$to_powercepstrogram(...)$get_cpps(...)}. The three paths cost
#' about the same: the R/C++ boundary crossing is negligible next to the
#' per-frame trend fit, so pick whichever reads best at the call site.
#'
#' @param sound Sound object or external pointer
#' @param time_averaging_window Time averaging window in seconds (default 0.001)
#' @param quefrency_averaging_window Quefrency averaging window in seconds (default 0.0005)
#' @param pitch_floor Minimum F0 in Hz (default 60)
#' @param pitch_ceiling Maximum F0 in Hz (default 333.3)
#' @param subtract_trend Logical, subtract tilt before smoothing (default TRUE)
#' @param time_step Time step for cepstrogram in seconds (default 0.002)
#' @param max_quefrency End of the trend-fit quefrency window in seconds (default
#'   0.04); 0 means autowindow to the full quefrency range (Praat convention).
#' @param tolerance Tolerance for peak detection (default 0.05)
#' @param interpolation Peak interpolation: "none", "parabolic", "cubic", "sinc70", "sinc700" (default "parabolic")
#' @param tilt_line_quefrency Start of the trend-fit quefrency window in seconds
#'   (default 0.003).
#' @param line_type Trend line type: "straight" or "exponential" (default "straight")
#' @param fit_method Fitting method: "robust" (Siegel repeated median),
#'   "least_squares", or "robust slow" (Theil-Sen). Default "robust".
#'   **"robust slow" is not reproducible** — see `calculate_cpps_fast()`.
#'
#' @return Numeric CPPS value in dB
#'
#' @details
#' Implements the complete CPPS pipeline in one C++ call, following the approach
#' used in AVQI v2.03 and v3.01: PowerCepstrogram creation and CPPS extraction
#' are consolidated, and no intermediate R object is allocated.
#'
#' This does **not** make it meaningfully cheaper than the other CPPS entry
#' points: the per-frame robust trend fit (`SlopeSelector::getSlope_Siegel`)
#' dominates CPPS runtime and is shared by every path; consolidating the
#' PowerCepstrogram creation only removes the R/C++ boundary crossing, which
#' is a small fraction of the total cost. Treat the choice as a matter of
#' call-site convenience, not performance.
#'
#' The defaults here match \code{calculate_cpps_fast()} and therefore also
#' deviate from Praat's dialog defaults — see the "Defaults differ from Praat's"
#' section of \code{\link{calculate_cpps_fast}}.
#'
#' This is still a **CPPS** helper. For a single-interval **CPP** measurement,
#' use the segment's `Spectrum -> PowerCepstrum -> get_peak_prominence()` path
#' instead of `calculate_cpps_ultra()`. It is both cheaper and closer to the
#' Praat workflow used by voice-quality scripts that query one interval at a time.
#'
#' **Use Cases:**
#' - AVQI v2.03/v3.01 implementation
#' - High-throughput voice quality analysis
#' - CPPS monitoring in latency-sensitive pipelines
#'
#' @section Algorithm choice:
#' Not applicable — this function is pitch-independent. It builds a
#' `PowerCepstrogram` directly from the Sound (`Sound_to_PowerCepstrogram()`)
#' and never extracts a `Pitch` object, so there is no AC/CC or
#' `veryAccurate` choice to document here. See the CPPS parameter default
#' table in `/CLAUDE.md` for the (non-pitch) parameters that do vary by
#' caller, and the Tier 4 Ultra algorithm table in
#' `inst/agents/AGENT_GUIDE.md` for how this compares to the pitch-based
#' Ultra functions.
#'
#' @examples
#' sound <- Sound$create_tone(frequency = 150, duration = 0.5, sampling_rate = 16000)
#'
#' # Tier 4 Ultra (same defaults as calculate_cpps_fast)
#' cpps <- calculate_cpps_ultra(sound)
#'
#' # Should match calculate_cpps_fast() within 0.01 dB
#' cpps_fast <- calculate_cpps_fast(sound)
#' all.equal(cpps, cpps_fast, tolerance = 0.01)
#'
#' @param pre_emphasis_from Pre-emphasis frequency in Hz for the cepstrogram (default 50).
#' @param max_frequency Maximum frequency in Hz for the cepstrogram (default 5000).
#' @export
calculate_cpps_ultra <- function(
  sound,
  time_averaging_window = 0.001,        # BUG FIX v4.6.4: match calculate_cpps_fast (was 0.01)
  quefrency_averaging_window = 0.0005,  # BUG FIX v4.6.4: match calculate_cpps_fast (was 0.001)
  pitch_floor = 60,
  pitch_ceiling = 333.3,                # BUG FIX v4.6.4: match calculate_cpps_fast (was 330)
  subtract_trend = TRUE,
  time_step = 0.002,
  max_quefrency = 0.04,                 # BUG FIX v4.9.10: was 0.05, C++ ignored it and hardcoded 0.04
  tolerance = 0.05,
  interpolation = "parabolic",
  tilt_line_quefrency = 0.003,
  line_type = "straight",
  fit_method = "robust",
  pre_emphasis_from = 50,
  max_frequency = 5000
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
  interpolation <- match.arg(interpolation, names(.interp_map))
  line_type <- match.arg(line_type, names(.cpps_trend_map))
  fit_method <- match.arg(fit_method, names(.trend_fit_map))
  .check_trend_fit_method(fit_method)
  .check_quefrency_range(tilt_line_quefrency, max_quefrency,
                         "tilt_line_quefrency", "max_quefrency")

  # Single C++ call for entire CPPS calculation
  # BUG FIX (v4.6.4): Added pre_emphasis_from and max_frequency parameters
  # Previously the function used tilt_line_quefrency (0.001 sec) as pre-emphasis,
  # which should be a frequency in Hz (50), not a quefrency in seconds.
  .calculate_cpps_ultra_cpp(
    sound_ptr,
    as.numeric(time_averaging_window),
    as.numeric(quefrency_averaging_window),
    as.numeric(pitch_floor),
    as.numeric(pitch_ceiling),
    as.logical(subtract_trend),
    as.numeric(time_step),
    as.numeric(max_quefrency),
    as.numeric(tolerance),
    as.integer(.interp_map[[interpolation]]),
    as.numeric(tilt_line_quefrency),
    as.integer(.cpps_trend_map[[line_type]]),
    as.integer(.trend_fit_map[[fit_method]]),
    as.numeric(pre_emphasis_from),
    as.numeric(max_frequency)
  )
}


#' Extract Voiced Segments with AVQI Filtering (Tier 4 Ultra)
#'
#' @description
#' Complete AVQI voiced segment extraction pipeline in a single C++ call.
#' Supports both AVQI v2.03 (simple intensity-based) and v3.01 (with ZCR filtering).
#' Performs: Sound -> TextGrid (silence) -> Extract sounding -> Concatenate ->
#' [v3.01: Window power/ZCR filtering] -> Final concatenation, in a single
#' C++ call instead of a multi-step R implementation.
#'
#' @param sound Sound object or external pointer
#' @param version AVQI version: "v2.03" (simple) or "v3.01" (ZCR filtering, default)
#' @param min_pitch Minimum pitch for silence detection in Hz (default 50)
#' @param silence_threshold_db Silence threshold in dB (default -25)
#' @param min_silent_duration Minimum silent interval duration in seconds (default 0.1)
#' @param min_sounding_duration Minimum sounding interval duration in seconds (default 0.1)
#' @param power_threshold_factor Power threshold as fraction of global power (default 0.3)
#' @param max_zcr Maximum zero-crossing rate for voiced segments (default 3000)
#' @param window_width Window width for v3.01 filtering in seconds (default 0.03)
#'
#' @return Sound object containing only voiced segments (concatenated)
#'
#' @details
#' **TIER 4 ULTRA API**
#'
#' This function implements the exact AVQI voiced extraction algorithm in a
#' single C++ call. It replaces the R loops and multiple boundary crossings
#' of the standard multi-step approach.
#'
#' **Algorithm (AVQI v3.01):**
#' 1. Detect silences using intensity-based TextGrid creation
#' 2. Extract all "sounding" intervals
#' 3. Concatenate sounding intervals -> "loud_sound"
#' 4. Slide 30ms windows through loud_sound
#' 5. Filter windows by: power > 30% global power AND ZCR < 3000
#' 6. Concatenate passing windows -> final voiced sound
#'
#' **Algorithm (AVQI v2.03):**
#' Steps 1-3 only (no window filtering)
#'
#' **Version Differences:**
#' - v2.03: Simpler, keeps most voiced content (~37s from 37s input)
#' - v3.01: Aggressive ZCR filtering, removes fricatives (~25-30s from 37s input)
#'
#' @section Algorithm choice:
#' No pitch algorithm is used here — voiced/silence segmentation is
#' Intensity-threshold based (`Sound_to_Intensity()` + `silence_threshold_db`
#' relative to the maximum), not derived from a `Pitch` object. `min_pitch`
#' only controls the Intensity analysis window length (via
#' `Sound_to_Intensity`'s own floor parameter), not a pitch-detection
#' algorithm choice. See the Tier 4 Ultra algorithm table in
#' `inst/agents/AGENT_GUIDE.md`.
#'
#' @examples
#' sound <- Sound$create_tone(frequency = 150, duration = 1, sampling_rate = 16000)
#'
#' # AVQI v3.01 (default, with ZCR filtering)
#' voiced_v3 <- extract_voiced_segments_ultra(sound, version = "v3.01")
#'
#' # AVQI v2.03 (simple intensity-based)
#' voiced_v2 <- extract_voiced_segments_ultra(sound, version = "v2.03")
#'
#' voiced_v3$get_total_duration()
#' voiced_v2$get_total_duration()
#'
#' @references
#' - AVQI v3.01: Maryn et al. (2017) - with ZCR filtering
#' - AVQI v2.03: Original Praat script - intensity-based only
#'
#' @export
extract_voiced_segments_ultra <- function(
  sound,
  version = "v3.01",
  min_pitch = 50,
  silence_threshold_db = -25,
  min_silent_duration = 0.1,
  min_sounding_duration = 0.1,
  power_threshold_factor = 0.3,
  max_zcr = 3000,
  window_width = 0.03
) {
  # Validate version
  version <- match.arg(version, c("v2.03", "v3.01"))

  # Extract pointer if R6 object
  sound_ptr <- if (inherits(sound, "Sound")) {
    sound$.xptr
  } else if (inherits(sound, "externalptr")) {
    sound
  } else {
    stop("sound must be a Sound object or external pointer")
  }

  # Single C++ call for entire voiced extraction pipeline
  result_ptr <- .extract_voiced_segments_ultra_cpp(
    sound_ptr,
    version,
    as.numeric(min_pitch),
    as.numeric(silence_threshold_db),
    as.numeric(min_silent_duration),
    as.numeric(min_sounding_duration),
    as.numeric(power_threshold_factor),
    as.numeric(max_zcr),
    as.numeric(window_width)
  )

  # Wrap result in R6 Sound object
  Sound$new(.xptr = result_ptr)
}


#' Build reusable multi-band Harmonicity objects
#'
#' @description
#' Compute the 5 Harmonicity objects used by VQ's multiband HNR workflow once,
#' then reuse them across repeated interval queries with
#' [multiband_hnr_stats()].
#'
#' @param sound Sound object or external pointer
#' @param bands Numeric vector of upper frequency limits in Hz (default
#'   `c(0, 500, 1500, 2500, 3500)`)
#' @param time_step Time step for harmonicity in seconds (default `0.005`)
#' @param min_pitch Minimum pitch in Hz (default `75`)
#'
#' @return Named list of 5 `Harmonicity` objects: `full`, `band500`,
#'   `band1500`, `band2500`, `band3500` (or names derived from custom bands).
#'
#' @details
#' Use this when the same `Sound` is queried over many `[from_time, to_time]`
#' windows, e.g. a TextGrid with multiple voiced intervals. The expensive
#' band-pass filtering and Harmonicity computation are done once; only the
#' summary stats are repeated.
#'
#' @examples
#' sound <- Sound$create_tone(frequency = 150, duration = 0.5, sampling_rate = 16000)
#'
#' built <- build_multiband_harmonicity(sound)
#' hnr_full <- multiband_hnr_stats(built)
#'
#' @references
#' - VQ_measurements_V2.praat (Voice Quality measurements)
#' - Maryn & Weenink (2015) - Multi-band HNR for voice quality
#'
#' @seealso [multiband_hnr_stats()] and [calculate_multiband_hnr_ultra()]
#'
#' @export
build_multiband_harmonicity <- function(
  sound,
  bands = c(0, 500, 1500, 2500, 3500),
  time_step = 0.005,
  min_pitch = 75
) {
  if (length(bands) != 5) {
    stop("bands parameter must have exactly 5 elements (e.g., c(0, 500, 1500, 2500, 3500))")
  }

  sound_ptr <- extract_xptr(sound, "Sound")
  built <- .build_multiband_harmonicity_cpp(
    sound_ptr,
    as.numeric(bands),
    as.numeric(time_step),
    as.numeric(min_pitch)
  )

  lapply(built, function(ptr) Harmonicity(.xptr = ptr))
}

.coerce_multiband_harmonicity <- function(multiband) {
  if (!is.list(multiband) || length(multiband) != 5L) {
    stop("multiband must be a named list of 5 Harmonicity objects")
  }
  if (is.null(names(multiband)) || any(is.na(names(multiband))) ||
      any(names(multiband) == "") || anyDuplicated(names(multiband))) {
    stop("multiband must be a named list with unique band names")
  }

  lapply(multiband, function(entry) {
    if (inherits(entry, "Harmonicity")) {
      return(entry)
    }
    if (inherits(entry, "externalptr")) {
      return(Harmonicity(.xptr = entry))
    }
    stop("multiband entries must be Harmonicity objects or external pointers")
  })
}

#' Query reusable multiband HNR statistics
#'
#' @description
#' Extract mean and standard deviation from a reusable set of multiband
#' `Harmonicity` objects built by [build_multiband_harmonicity()]. This is the
#' cheap query step for repeated interval workflows.
#'
#' @param multiband Named list of 5 `Harmonicity` objects (or Harmonicity
#'   external pointers), typically returned by [build_multiband_harmonicity()].
#' @param from_time Start time for statistics extraction (default `0`)
#' @param to_time End time for statistics extraction (default `0`)
#'
#' @return Named list with the same `*_mean` / `*_sd` fields as
#'   [calculate_multiband_hnr_ultra()].
#'
#' @examples
#' \dontrun{
#' sound <- Sound(system.file("extdata", "test.wav", package = "pladdrr"))
#'
#' built <- build_multiband_harmonicity(sound)
#' hnr_interval1 <- multiband_hnr_stats(built, 0, 0.5)
#' hnr_interval2 <- multiband_hnr_stats(built, 0.5, 1.0)
#' }
#'
#' @export
multiband_hnr_stats <- function(multiband, from_time = 0, to_time = 0) {
  multiband <- .coerce_multiband_harmonicity(multiband)

  if (!is.numeric(from_time) || !is.numeric(to_time) ||
      length(from_time) != 1L || length(to_time) != 1L ||
      is.na(from_time) || is.na(to_time)) {
    stop("from_time and to_time must be single numeric values")
  }

  if (to_time <= from_time) {
    from_time <- 0
    to_time <- 0
  }

  result <- vector("list", length(multiband) * 2L)
  names(result) <- as.vector(rbind(
    paste0(names(multiband), "_mean"),
    paste0(names(multiband), "_sd")
  ))

  out_i <- 1L
  for (name in names(multiband)) {
    harmonicity <- multiband[[name]]
    result[[out_i]] <- harmonicity$get_mean(from_time, to_time)
    result[[out_i + 1L]] <- harmonicity$get_standard_deviation(from_time, to_time)
    out_i <- out_i + 2L
  }

  result
}

#' Calculate multi-band HNR in a single call
#'
#' @description
#' Optimized multi-band HNR calculation for VQ (Voice Quality) measurements.
#' Computes HNR (mean + standard deviation) for 5 frequency bands in a single
#' call: full spectrum, 0-500 Hz, 0-1500 Hz, 0-2500 Hz, 0-3500 Hz.
#'
#' @param sound Sound object or external pointer
#' @param bands Numeric vector of upper frequency limits in Hz
#'   (default `c(0, 500, 1500, 2500, 3500)`, where `0` = full spectrum)
#' @param time_step Time step for harmonicity in seconds (default `0.005`)
#' @param min_pitch Minimum pitch in Hz (default `75`)
#' @param from_time Start time for statistics extraction (default `0`)
#' @param to_time End time for statistics extraction (default `0`)
#'
#' @return Named list with `*_mean` and `*_sd` values for each band.
#'
#' @details
#' Use this when you only need one interval or whole-sound summary. For
#' repeated interval queries on the same `Sound`, use
#' [build_multiband_harmonicity()] once and then
#' [multiband_hnr_stats()] for each interval.
#'
#' @section Algorithm choice:
#' Harmonicity is always computed with `Sound_to_Harmonicity_cc()` (the CC
#' method) for every band — there is no AC alternative and no way to
#' configure it. This matches VQ_measurements_V2.praat lines 102-122. See the
#' Tier 4 Ultra algorithm table in `inst/agents/AGENT_GUIDE.md`.
#'
#' @examples
#' sound <- Sound$create_tone(frequency = 150, duration = 0.5, sampling_rate = 16000)
#'
#' hnr_results <- calculate_multiband_hnr_ultra(sound)
#' hnr_results$full_mean
#'
#' @references
#' - VQ_measurements_V2.praat (Voice Quality measurements)
#' - Maryn & Weenink (2015) - Multi-band HNR for voice quality
#'
#' @seealso [build_multiband_harmonicity()] and [multiband_hnr_stats()] for
#'   the reusable multi-interval path
#'
#' @export
calculate_multiband_hnr_ultra <- function(
  sound,
  bands = c(0, 500, 1500, 2500, 3500),
  time_step = 0.005,
  min_pitch = 75,
  from_time = 0,
  to_time = 0
) {
  # Validate bands parameter
  if (length(bands) != 5) {
    stop("bands parameter must have exactly 5 elements (e.g., c(0, 500, 1500, 2500, 3500))")
  }

  sound_ptr <- extract_xptr(sound, "Sound")

  # Single C++ call for all 5 bands
  .calculate_multiband_hnr_ultra_cpp(
    sound_ptr,
    as.numeric(bands),
    as.numeric(time_step),
    as.numeric(min_pitch),
    as.numeric(from_time),
    as.numeric(to_time)
  )
}
