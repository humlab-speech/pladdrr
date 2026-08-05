# batch-queries.R
# R wrappers for batch query operations (Phase 5 Performance Enhancement)
# pladdrr v2.0.9

#' Batch Query Formant Frequencies at Multiple Times
#'
#' Query formant frequencies (F1, F2, F3, F4, etc.) at multiple time points
#' in a single function call. This is significantly faster than calling
#' `get_value_at_time()` repeatedly in a loop.
#'
#' @param formant A Formant object
#' @param times Numeric vector of time points (in seconds)
#' @param formant_numbers Integer vector specifying which formants to extract
#'   (e.g., `1:4` for F1-F4). Default is `1:4`.
#' @param unit Unit for formant values: "hertz" (default) or "bark"
#'
#' @return A list with one element per formant number (e.g., `F1`, `F2`, ...),
#'   each containing a numeric vector of formant frequencies at the specified times.
#'
#' @section Performance:
#' This function reduces R<->C++ boundary crossings from `4n` calls
#' (for 4 formants at n times) to just 1 call. Expected speedup: **3-5x** for
#' typical vowel analysis workflows.
#'
#' @examples
#' \dontrun{
#' sound <- Sound(system.file("signalfiles/DSI/input/fh1.wav", package = "pladdrr"))
#' formant <- sound$to_formant()
#'
#' # Extract F1-F4 at 5 time points
#' times <- seq(1, 2, length.out = 5)
#' result <- get_formants_at_times(formant, times, formant_numbers = 1:4)
#'
#' # Access individual formants
#' f1_vals <- result$F1
#' f2_vals <- result$F2
#' }
#'
#' @export
get_formants_at_times <- function(formant, times, formant_numbers = 1:4, unit = "hertz") {
  if (!inherits(formant, "Formant")) {
    stop("formant must be a Formant object")
  }
  
  if (!is.numeric(times) || length(times) == 0) {
    stop("times must be a non-empty numeric vector")
  }
  
  if (!is.numeric(formant_numbers) || length(formant_numbers) == 0) {
    stop("formant_numbers must be a non-empty integer vector")
  }
  
  # Convert unit to integer code
  unit_code <- switch(tolower(unit),
    "hertz" = 0L,
    "hz" = 0L,
    "bark" = 1L,
    stop("Unknown unit: ", unit, ". Use 'hertz' or 'bark'")
  )
  
  # Call C++ implementation
  formant_get_multiple_formants_at_times(
    formant$.xptr,
    times,
    as.integer(formant_numbers),
    unit_code
  )
}

#' Batch Query Formant Bandwidths at Multiple Times
#'
#' Query formant bandwidths at multiple time points in a single function call.
#'
#' @param formant A Formant object
#' @param times Numeric vector of time points (in seconds)
#' @param formant_numbers Integer vector specifying which formants (default `1:4`)
#' @param unit Unit for bandwidth values: "hertz" (default) or "bark"
#'
#' @return A list with one element per formant number (e.g., `B1`, `B2`, ...),
#'   each containing a numeric vector of bandwidths.
#'
#' @examples
#' \dontrun{
#' sound <- Sound(system.file("signalfiles/DSI/input/fh1.wav", package = "pladdrr"))
#' formant <- sound$to_formant()
#' times <- seq(1, 2, length.out = 5)
#' bandwidths <- get_formant_bandwidths_at_times(formant, times, 1:4)
#' }
#'
#' @export
get_formant_bandwidths_at_times <- function(formant, times, formant_numbers = 1:4, unit = "hertz") {
  if (!inherits(formant, "Formant")) {
    stop("formant must be a Formant object")
  }
  
  if (!is.numeric(times) || length(times) == 0) {
    stop("times must be a non-empty numeric vector")
  }
  
  unit_code <- switch(tolower(unit),
    "hertz" = 0L,
    "hz" = 0L,
    "bark" = 1L,
    stop("Unknown unit: ", unit)
  )
  
  formant_get_multiple_bandwidths_at_times(
    formant$.xptr,
    times,
    as.integer(formant_numbers),
    unit_code
  )
}

#' Batch Query Pitch Values at Multiple Times
#'
#' Query pitch (F0) values at multiple time points in a single function call.
#' Significantly faster than repeated calls to `get_value_at_time()`.
#'
#' @param pitch A Pitch object
#' @param times Numeric vector of time points (in seconds)
#' @param unit Unit for pitch values: "hertz" (default), "mel", "loghertz",
#'   "semitones", or "erb"
#' @param interpolate Logical; whether to interpolate between frames (default TRUE)
#'
#' @return Numeric vector of pitch values at the specified times
#'
#' @section Performance:
#' This function uses existing optimized C++ code. Expected speedup: **2-3x** 
#' for pitch contour extraction compared to R loops.
#'
#' @examples
#' \dontrun{
#' sound <- Sound(system.file("signalfiles/DSI/input/fh1.wav", package = "pladdrr"))
#' pitch <- sound$to_pitch()
#' times <- seq(pitch$get_xmin(), pitch$get_xmax(), length.out = 100)
#' f0_contour <- get_pitch_at_times(pitch, times)
#' }
#'
#' @export
get_pitch_at_times <- function(pitch, times, unit = "hertz", interpolate = TRUE) {
  if (!inherits(pitch, "Pitch")) {
    stop("pitch must be a Pitch object")
  }
  
  if (!is.numeric(times) || length(times) == 0) {
    stop("times must be a non-empty numeric vector")
  }
  
  
  unit_code <- unit_to_code(unit, "pitch")
  # Use existing optimized function from sound_wrappers.cpp
  .pitch_get_values_at_times(
    pitch$.xptr,
    times,
    unit_code,
    as.logical(interpolate)
  )
}

#' Batch Query Pitch Strengths at Multiple Times
#'
#' Query pitch strength (voicing confidence) at multiple time points.
#'
#' @param pitch A Pitch object
#' @param times Numeric vector of time points (in seconds)
#' @param unit Unit for pitch (used internally by Praat)
#' @param interpolate Logical; whether to interpolate (default TRUE)
#'
#' @return Numeric vector of pitch strengths (0-1) at the specified times
#'
#' @examples
#' \dontrun{
#' sound <- Sound(system.file("signalfiles/DSI/input/fh1.wav", package = "pladdrr"))
#' pitch <- sound$to_pitch()
#' times <- seq(pitch$get_xmin(), pitch$get_xmax(), length.out = 100)
#' strengths <- get_pitch_strengths_at_times(pitch, times)
#' }
#'
#' @export
get_pitch_strengths_at_times <- function(pitch, times, unit = "hertz", interpolate = TRUE) {
  if (!inherits(pitch, "Pitch")) {
    stop("pitch must be a Pitch object")
  }
  
  
  pitch_get_strengths_at_times(
    pitch$.xptr,
    times,
    unit_code,
    as.logical(interpolate)
  )
}

#' Get Multiple Pitch Quantiles in Single Call (NEW for VUV Performance)
#'
#' @description
#' Extract multiple quantiles (e.g., Q1, Q3) from a Pitch object in a single
#' C++ call. This is significantly faster than calling `get_quantile()` multiple
#' times and is specifically designed for VUV analysis workflows where adaptive
#' pitch ranges are calculated from quartiles.
#'
#' @param pitch A Pitch object
#' @param quantiles Numeric vector of quantile values (e.g., c(0.25, 0.75) for Q1 and Q3)
#' @param from_time Start time (0 = beginning of pitch object)
#' @param to_time End time (0 = end of pitch object)
#' @param unit Unit for pitch values: "hertz" (default), "mel", "loghertz",
#'   "semitones", or "erb"
#'
#' @return Named numeric vector with quantile values (names like "q0.25", "q0.75")
#'
#' @section Performance:
#' Reduces R<->C++ boundary crossings from n separate calls to 1 call.
#' Expected speedup: **2-3x** for VUV workflows that need Q1 and Q3.
#'
#' @section Use Case - VUV Analysis:
#' ```r
#' # Extract adaptive pitch range for refined pitch analysis
#' quantiles <- get_pitch_quantiles_batch(pitch_rough, c(0.25, 0.75))
#' pitch_refined <- to_pitch_cc_direct(
#'   sound,
#'   pitch_floor = quantiles["q0.25"] * 0.75,
#'   pitch_ceiling = quantiles["q0.75"] * 1.5
#' )
#' ```
#'
#' @examples
#' \dontrun{
#' sound <- Sound("voice.wav")
#' pitch <- sound$to_pitch()
#'
#' # Get Q1, median, Q3 in one call
#' quartiles <- get_pitch_quantiles_batch(pitch, c(0.25, 0.5, 0.75))
#' 
#' # Access by name
#' q1 <- quartiles["q0.25"]
#' median <- quartiles["q0.5"]
#' q3 <- quartiles["q0.75"]
#' }
#'
#' @export
get_pitch_quantiles_batch <- function(pitch, quantiles,
                                       from_time = 0, to_time = 0,
                                       unit = "hertz") {
  if (!inherits(pitch, "Pitch")) {
    stop("pitch must be a Pitch object")
  }
  
  if (!is.numeric(quantiles) || length(quantiles) == 0) {
    stop("quantiles must be a non-empty numeric vector")
  }
  
  if (any(quantiles < 0 | quantiles > 1)) {
    stop("quantiles must be between 0 and 1")
  }
  
  unit_code <- unit_to_code(unit, "pitch")

  pitch_get_quantiles_batch(
    pitch$.xptr,
    quantiles,
    as.numeric(from_time),
    as.numeric(to_time),
    unit_code
  )
}
#' Batch Query Intensity Values at Multiple Times
#'
#' Query intensity (amplitude in dB) at multiple time points in a single call.
#'
#' @param intensity An Intensity object
#' @param times Numeric vector of time points (in seconds)
#' @param interpolate Interpolation method: "nearest", "linear", "cubic" (default),
#'   or "sinc70". Kept for backward compatibility; prefer `interpolation`.
#' @param interpolation Alias for `interpolate` (consistent with R6 method naming).
#'   When provided, supersedes `interpolate`.
#'
#' @return Numeric vector of intensity values (in dB) at the specified times
#'
#' @section Performance:
#' Uses existing optimized C++ code. Expected speedup: **2-3x** compared to R loops.
#'
#' @examples
#' \dontrun{
#' sound <- Sound(system.file("signalfiles/DSI/input/fh1.wav", package = "pladdrr"))
#' intensity <- sound$to_intensity()
#' times <- seq(intensity$get_xmin(), intensity$get_xmax(), length.out = 100)
#' intensities <- get_intensity_at_times(intensity, times)
#' }
#'
#' @export
get_intensity_at_times <- function(intensity, times, interpolate = "cubic",
                                   interpolation = NULL) {
  if (!inherits(intensity, "Intensity")) {
    stop("intensity must be an Intensity object")
  }

  if (!is.numeric(times) || length(times) == 0) {
    stop("times must be a non-empty numeric vector")
  }

  # interpolation alias supersedes interpolate when provided
  if (!is.null(interpolation)) {
    interpolate <- interpolation
  }

  interp_code <- switch(tolower(interpolate),
    "nearest" = 0L,
    "linear" = 1L,
    "cubic" = 2L,
    "sinc70" = 3L,
    "sinc700" = 4L,
    stop("Unknown interpolation method: ", interpolate)
  )
  
  # Use existing optimized function from sound_wrappers.cpp
  .intensity_get_values_at_times(
    intensity$.xptr,
    times,
    interp_code
  )
}

#' Get All Point Times from PointProcess
#'
#' Extract all point times from a PointProcess object as a numeric vector.
#' This is faster than calling `get_time(i)` in a loop.
#'
#' @param pointprocess A PointProcess object
#'
#' @return Numeric vector of all point times (in seconds)
#'
#' @section Performance:
#' Reduces R<->C++ calls from `n` to 1. Expected speedup: **5-10x** for
#' large PointProcess objects.
#'
#' @examples
#' \dontrun{
#' sound <- Sound(system.file("signalfiles/DSI/input/fh1.wav", package = "pladdrr"))
#' pitch <- sound$to_pitch()
#' pp <- pitch$to_point_process()
#' times <- get_pointprocess_times(pp)
#' }
#'
#' @export
get_pointprocess_times <- function(pointprocess) {
  if (!inherits(pointprocess, "PointProcess")) {
    stop("pointprocess must be a PointProcess object")
  }
  
  pointprocess_get_all_times(pointprocess$.xptr)
}

#' Get Inter-Point Intervals from PointProcess
#'
#' Compute the time intervals between consecutive points in a PointProcess.
#' Useful for jitter analysis and prosody studies.
#'
#' @param pointprocess A PointProcess object
#'
#' @return Numeric vector of intervals (in seconds). Length is `n_points - 1`.
#'
#' @section Performance:
#' Computes all intervals in C++ without R<->C++ overhead. Expected speedup:
#' **5-10x** compared to R-based loops.
#'
#' @examples
#' \dontrun{
#' sound <- Sound(system.file("signalfiles/DSI/input/fh1.wav", package = "pladdrr"))
#' pitch <- sound$to_pitch()
#' pp <- pitch$to_point_process()
#' intervals <- get_pointprocess_intervals(pp)
#' jitter <- sd(intervals) / mean(intervals)
#' }
#'
#' @export
get_pointprocess_intervals <- function(pointprocess) {
  if (!inherits(pointprocess, "PointProcess")) {
    stop("pointprocess must be a PointProcess object")
  }
  
  pointprocess_get_intervals(pointprocess$.xptr)
}

#' Query PointProcess Nearest Indices at Multiple Times
#'
#' Find the nearest point index for each of multiple query times.
#'
#' @param pointprocess A PointProcess object
#' @param times Numeric vector of query times (in seconds)
#'
#' @return Integer vector of nearest point indices (1-based)
#'
#' @examples
#' \dontrun{
#' sound <- Sound(system.file("signalfiles/DSI/input/fh1.wav", package = "pladdrr"))
#' pitch <- sound$to_pitch()
#' pp <- pitch$to_point_process()
#' query_times <- seq(1, 2, by = 0.1)
#' indices <- get_pointprocess_nearest_indices(pp, query_times)
#' }
#'
#' @export
get_pointprocess_nearest_indices <- function(pointprocess, times) {
  if (!inherits(pointprocess, "PointProcess")) {
    stop("pointprocess must be a PointProcess object")
  }

  if (!is.numeric(times) || length(times) == 0) {
    stop("times must be a non-empty numeric vector")
  }

  pointprocess_get_nearest_indices(pointprocess$.xptr, times)
}


# =============================================================================
# Voice Quality Batch Operations
# =============================================================================

#' Get All Jitter and Shimmer Measures in One Call
#'
#' @description
#' Returns 11 voice quality measures (5 jitter, 6 shimmer) in a single C++ call.
#' Much faster than calling individual methods when you need multiple measures.
#'
#' **Jitter measures** (period perturbation):
#' - `jitter_local`: Local jitter (relative, fraction)
#' - `jitter_local_abs`: Local absolute jitter (seconds)
#' - `jitter_rap`: Relative average perturbation
#' - `jitter_ppq5`: 5-point period perturbation quotient
#' - `jitter_ddp`: Difference of differences of periods
#'
#' **Shimmer measures** (amplitude perturbation):
#' - `shimmer_local`: Local shimmer (relative, fraction)
#' - `shimmer_local_db`: Local shimmer (dB)
#' - `shimmer_apq3`: 3-point amplitude perturbation quotient
#' - `shimmer_apq5`: 5-point amplitude perturbation quotient
#' - `shimmer_apq11`: 11-point amplitude perturbation quotient
#' - `shimmer_dda`: Difference of differences of amplitudes
#'
#' @param pointprocess PointProcess object or external pointer (glottal pulses)
#' @param sound Sound object or external pointer (required for shimmer)
#' @param from_time Start time (0 = beginning)
#' @param to_time End time (0 = end)
#' @param period_floor Minimum period in seconds (default 0.0001 = 10000 Hz)
#' @param period_ceiling Maximum period in seconds (default 0.02 = 50 Hz)
#' @param max_period_factor Maximum period factor (default 1.3)
#' @param max_amplitude_factor Maximum amplitude factor (default 1.6)
#'
#' @return Named list with 11 voice quality measures
#'
#' @section Performance:
#' This function reduces R<->C++ boundary crossings from 11 calls to 1 call.
#' Expected speedup: **5-10x** for typical voice quality workflows.
#'
#' @section Workflow:
#' For accurate voice quality analysis, use `to_point_process_from_sound_and_pitch()`
#' which uses the refined pitch contour to guide period detection:
#' ```r
#' # Recommended workflow
#' sound <- Sound("voice.wav")
#' pitch <- sound$to_pitch_cc(voicing_threshold = 0.45)
#' pp <- to_point_process_from_sound_and_pitch(sound, pitch)
#' metrics <- get_jitter_shimmer_batch(pp, sound)
#' ```
#'
#' @examples
#' \dontrun{
#' sound <- Sound(system.file("signalfiles/DSI/input/fh1.wav", package = "pladdrr"))
#'
#' # Two-pass adaptive pitch for robust extraction
#' result <- two_pass_adaptive_pitch(sound)
#' pitch <- Pitch(.xptr = result$pitch)
#'
#' # Accurate pulse detection using Sound+Pitch
#' pp <- to_point_process_from_sound_and_pitch(sound, pitch)
#'
#' # Get all voice quality measures at once
#' metrics <- get_jitter_shimmer_batch(pp, sound)
#'
#' # Access individual measures
#' cat("Jitter (local):", metrics$jitter_local * 100, "%\n")
#' cat("Shimmer (local):", metrics$shimmer_local * 100, "%\n")
#' cat("Shimmer (dB):", metrics$shimmer_local_db, "dB\n")
#' }
#'
#' @seealso
#' [two_pass_adaptive_pitch()] for robust pitch extraction
#' [to_point_process_from_sound_and_pitch()] for accurate pulse detection
#'
#' @export
get_jitter_shimmer_batch <- function(pointprocess, sound,
                                      from_time = 0, to_time = 0,
                                      period_floor = 0.0001,
                                      period_ceiling = 0.02,
                                      max_period_factor = 1.3,
                                      max_amplitude_factor = 1.6) {
  # Extract pointers
  pp_ptr <- if (inherits(pointprocess, "PointProcess")) {
    pointprocess$.xptr
  } else if (inherits(pointprocess, "externalptr")) {
    pointprocess
  } else {
    stop("pointprocess must be a PointProcess object or external pointer")
  }

  sound_ptr <- if (inherits(sound, "Sound")) {
    sound$.xptr
  } else if (inherits(sound, "externalptr")) {
    sound
  } else {
    stop("sound must be a Sound object or external pointer")
  }

  get_jitter_shimmer_batch_cpp(
    pp_ptr, sound_ptr,
    as.numeric(from_time), as.numeric(to_time),
    as.numeric(period_floor), as.numeric(period_ceiling),
    as.numeric(max_period_factor), as.numeric(max_amplitude_factor)
  )
}


# =============================================================================
# Tier 4 "Ultra" API - DSI Performance Optimization (v4.4.0)
# =============================================================================

#' Get Audio File Durations Efficiently via WAV Header Reading
#'
#' @description
#' Reads only the 44-byte WAV header to calculate duration, avoiding full file
#' loading. This is **77x faster** than `LongSound$from_file()$get_total_duration()`.
#'
#' This is a **Tier 4 "Ultra"** function designed for maximum performance in
#' batch DSI (Dysphonia Severity Index) calculations where file duration is the
#' MPT (Maximum Phonation Time) component.
#'
#' @param file_paths Character vector of .wav file paths
#'
#' @return Numeric vector of durations (seconds). Returns `NA` for files that
#'   cannot be read or are not valid WAV files.
#'
#' @section Performance:
#' This function achieves 77x speedup over the standard LongSound approach by:
#' \itemize{
#'   \item Reading only the first 44-100 bytes of the WAV header
#'   \item Avoiding memory allocation for audio samples
#'   \item Skipping all Praat object construction
#' }
#'
#' @section API Tier:
#' This is a **Tier 4 "Ultra"** function. Tier 4 functions keep entire workflows
#' in the C++ layer to minimize R<->C++ boundary crossings, returning only final
#' scalar or simple vector results.
#'
#' @examples
#' \dontrun{
#' # Single file
#' duration <- get_durations_batch("voice.wav")
#'
#' # Multiple files (DSI workflow)
#' mpt_files <- c("sustained_a_1.wav", "sustained_a_2.wav", "sustained_a_3.wav")
#' durations <- get_durations_batch(mpt_files)
#' max_mpt <- max(durations, na.rm = TRUE)
#'
#' # Benchmark comparison
#' bench::mark(
#'   tier4 = get_durations_batch(files),
#'   longsound = sapply(files, function(f) LongSound(f)$get_total_duration())
#' )
#' # Expected: tier4 ~77x faster
#' }
#'
#' @seealso
#' [LongSound()] for full audio file access when you need more than duration
#'
#' @export
get_durations_batch <- function(file_paths) {
  if (!is.character(file_paths)) {
    stop("file_paths must be a character vector")
  }
  get_durations_batch_cpp(file_paths)
}


#' Calculate F0 Statistic in Single Call (Tier 4 Ultra)
#'
#' @description
#' Performs pitch extraction AND statistic calculation entirely in C++,
#' avoiding intermediate R6 object creation. This is **5x faster** than
#' using separate `to_pitch_cc()` and `get_maximum()` calls.
#'
#' This is a **Tier 4 "Ultra"** function designed for maximum performance in
#' batch DSI (Dysphonia Severity Index) calculations where maximum F0 is
#' the FH (Highest Frequency) component.
#'
#' @param sound A Sound object
#' @param stat Statistic to compute: "max", "min", "mean", "median", or "sd"
#' @param min_pitch Pitch floor in Hz (default: 75)
#' @param max_pitch Pitch ceiling in Hz (default: 600)
#' @param time_step Time step for pitch extraction (0 = auto)
#' @param voicing_threshold Voicing threshold (default: 0.45)
#'
#' @return Single numeric value of the requested statistic in Hz
#'
#' @section API Tier:
#' This is a **Tier 4 "Ultra"** function. The entire pitch extraction and
#' statistic computation happens in C++ with no intermediate R6 objects.
#'
#' @section Algorithm choice:
#' Pitch is always extracted with `Sound_to_Pitch_rawCc()`,
#' `veryAccurate = TRUE`, `silenceThreshold = 0.03` (matching DSI201.praat's
#' `To Pitch (cc)...` step). Only `voicing_threshold` is configurable; the
#' AC/CC choice and `veryAccurate` are not. See the Tier 4 Ultra algorithm
#' table in `inst/agents/AGENT_GUIDE.md` for how this compares to the other
#' Ultra functions.
#'
#' @examples
#' \dontrun{
#' sound <- Sound("voice.wav")
#'
#' # Get maximum F0 (DSI FH component)
#' max_f0 <- calculate_f0_stats_ultra(sound, stat = "max", min_pitch = 75, max_pitch = 600)
#'
#' # Get mean F0
#' mean_f0 <- calculate_f0_stats_ultra(sound, stat = "mean")
#'
#' # Compare with traditional approach
#' bench::mark(
#'   tier4 = calculate_f0_stats_ultra(sound, "max"),
#'   tier2 = sound$to_pitch_cc()$get_maximum(0, 0, "hertz", TRUE)
#' )
#' # Expected: tier4 ~5x faster
#' }
#'
#' @seealso
#' [Sound] for creating Sound objects
#' [get_durations_batch()] for MPT component of DSI
#'
#' @export
calculate_f0_stats_ultra <- function(sound, stat,
                                      min_pitch = 75,
                                      max_pitch = 600,
                                      time_step = 0,
                                      voicing_threshold = 0.45) {
  if (!inherits(sound, "Sound")) {
    stop("sound must be a Sound object")
  }

  valid_stats <- c("max", "min", "mean", "median", "sd")
  if (!stat %in% valid_stats) {
    stop("stat must be one of: ", paste(valid_stats, collapse = ", "))
  }

  calculate_f0_stats_ultra_cpp(
    sound$.xptr,
    stat,
    as.numeric(time_step),
    as.numeric(min_pitch),
    as.numeric(max_pitch),
    as.numeric(voicing_threshold)
  )
}


#' Calculate Minimum Intensity in Voiced Regions (Tier 4 Ultra)
#'
#' @description
#' Complete intensity pipeline in C++: Sound -> Pitch -> PointProcess ->
#' TextGrid (VUV) -> Intensity -> Minimum in voiced regions. This is **6x
#' faster** than the equivalent Tier 2/3 workflow.
#'
#' This is a **Tier 4 "Ultra"** function designed for maximum performance in
#' batch DSI (Dysphonia Severity Index) calculations where minimum intensity
#' is the IM (Intensity Minimum) component.
#'
#' @param sound A Sound object
#' @param min_pitch Pitch floor in Hz (default: 75)
#' @param max_pitch Pitch ceiling in Hz (default: 600)
#' @param time_step Time step for analysis (0 = auto)
#' @param subtract_mean Whether to subtract mean for intensity calculation (default: TRUE)
#'
#' @return Minimum intensity in dB (in voiced regions only). Returns `NA` if
#'   no voiced regions are detected.
#'
#' @section API Tier:
#' This is a **Tier 4 "Ultra"** function. The entire workflow (pitch extraction,
#' PointProcess creation, VUV segmentation, intensity calculation, and minimum
#' finding in voiced regions) happens in C++ with no intermediate R objects.
#'
#' @section Algorithm choice:
#' Pitch is always extracted with `Sound_to_Pitch_rawCc()`,
#' `veryAccurate = FALSE`, `silenceThreshold = 0.03`,
#' `voicingThreshold = 0.8` — matching DSI201.praat's IM component, which
#' uses a stricter voicing threshold than the jitter block. None of these are
#' exposed as parameters (including `voicing_threshold`, unlike
#' `calculate_f0_stats_ultra()`). See the Tier 4 Ultra algorithm table in
#' `inst/agents/AGENT_GUIDE.md`.
#'
#' @examples
#' \dontrun{
#' sound <- Sound("voice.wav")
#'
#' # Get minimum intensity in voiced regions (DSI IM component)
#' min_int <- calculate_minimum_intensity_ultra(sound, min_pitch = 75)
#'
#' # Compare with traditional approach
#' bench::mark(
#'   tier4 = calculate_minimum_intensity_ultra(sound),
#'   tier2 = {
#'     pitch <- sound$to_pitch_cc()
#'     pp <- to_point_process_from_sound_and_pitch(sound, pitch)
#'     tg <- pp$to_textgrid_vuv()
#'     intensity <- sound$to_intensity()
#'     # ... find min in voiced regions
#'   }
#' )
#' # Expected: tier4 ~6x faster
#' }
#'
#' @seealso
#' [Sound] for creating Sound objects
#' [calculate_f0_stats_ultra()] for FH component of DSI
#'
#' @export
calculate_minimum_intensity_ultra <- function(sound,
                                               min_pitch = 75,
                                               max_pitch = 600,
                                               time_step = 0,
                                               subtract_mean = TRUE) {
  if (!inherits(sound, "Sound")) {
    stop("sound must be a Sound object")
  }

  calculate_minimum_intensity_ultra_cpp(
    sound$.xptr,
    as.numeric(min_pitch),
    as.numeric(max_pitch),
    as.numeric(time_step),
    as.logical(subtract_mean)
  )
}


#' Get Voice Quality Metrics in Single Call (Tier 4 Ultra)
#'
#' @description
#' Complete voice quality pipeline in C++: Sound -> Pitch -> PointProcess ->
#' Jitter/Shimmer/HNR metrics. This is **3.6x faster** than the equivalent
#' Tier 2/3 workflow using separate function calls.
#'
#' This is a **Tier 4 "Ultra"** function designed for maximum performance in
#' batch DSI (Dysphonia Severity Index) calculations where jitter PPQ5 is
#' the PPQ component.
#'
#' By default, this keeps the existing Tier 4 pitch path
#' (`pitch_method = "cc"`, `very_accurate = TRUE`). If your reference workflow
#' uses Praat's plain `To Pitch...` command before `To PointProcess (cc)` (for
#' example the DSI jitter block), call this with
#' `pitch_method = "ac", very_accurate = FALSE` — or the equivalent shorthand
#' `pitch_method = "periodic_cc"` (see below).
#'
#' @section Algorithm choice — \code{pitch_method = "periodic_cc"}:
#' Praat's `Sound: To PointProcess (periodic, cc)...` command is, per Praat's
#' own source (`Sound_to_PointProcess.cpp`) and manual, exactly
#' `Sound_to_Pitch(sound, 0, floor, ceiling)` (i.e. `Sound_to_Pitch_rawAc`
#' with `veryAccurate = FALSE` and Praat's raw defaults
#' `0.03, 0.45, 0.01, 0.35, 0.14`) followed by `Sound_Pitch_to_PointProcess_cc`.
#' That is byte-for-byte what this function already computes when called with
#' `pitch_method = "ac", very_accurate = FALSE`. `pitch_method = "periodic_cc"`
#' is a pure alias for that combination (it forces `very_accurate = FALSE`
#' regardless of the `very_accurate` argument), so callers porting a Praat
#' script that uses `To PointProcess (periodic, cc)...` can request the
#' matching Tier 4 fast path by name instead of having to know the two are
#' equivalent.
#'
#' @param sound A Sound object
#' @param metrics Character vector of metrics to compute: "jitter", "shimmer",
#'   "hnr", or "all" for all metrics
#' @param min_pitch Pitch floor in Hz for pitch extraction (default: 75).
#'   Note: HNR always uses 75 Hz as minimum pitch (Praat's CC harmonicity default),
#'   independent of this parameter.
#' @param max_pitch Pitch ceiling in Hz (default: 600)
#' @param time_step Time step for pitch/HNR (0 = auto; HNR auto uses 0.01 s)
#' @param pitch_method Pitch algorithm for the jitter/shimmer pitch object:
#'   `"cc"` (default, preserves existing Tier 4 behaviour), `"ac"`, or
#'   `"periodic_cc"` — an alias for `"ac"` with `very_accurate` forced to
#'   `FALSE`, matching Praat's `To PointProcess (periodic, cc)...` command
#'   (see Algorithm choice section below).
#' @param very_accurate Logical; whether to use Praat's very accurate pitch
#'   path for jitter/shimmer pitch extraction (default: `TRUE` to preserve the
#'   existing Tier 4 output). Use `FALSE` with `pitch_method = "ac"` to match
#'   Praat's plain `To Pitch...` command. Ignored (forced `FALSE`) when
#'   `pitch_method = "periodic_cc"`.
#'
#' @return Named list with requested voice quality metrics:
#' \describe{
#'   \item{jitter_local}{Local jitter (relative, fraction)}
#'   \item{jitter_local_abs}{Local absolute jitter (seconds)}
#'   \item{jitter_rap}{Relative average perturbation}
#'   \item{jitter_ppq5}{5-point period perturbation quotient (DSI PPQ component)}
#'   \item{jitter_ddp}{Difference of differences of periods}
#'   \item{shimmer_local}{Local shimmer (relative, fraction)}
#'   \item{shimmer_local_db}{Local shimmer (dB)}
#'   \item{shimmer_apq3}{3-point amplitude perturbation quotient}
#'   \item{shimmer_apq5}{5-point amplitude perturbation quotient}
#'   \item{shimmer_apq11}{11-point amplitude perturbation quotient}
#'   \item{shimmer_dda}{Difference of differences of amplitudes}
#'   \item{hnr_mean}{Mean harmonics-to-noise ratio (dB)}
#'   \item{hnr_sd}{Standard deviation of HNR}
#' }
#'
#' @section API Tier:
#' This is a **Tier 4 "Ultra"** function. The entire workflow (pitch extraction,
#' PointProcess creation, and all voice quality calculations) happens in C++
#' with no intermediate R objects.
#'
#' @examples
#' \dontrun{
#' sound <- Sound("voice.wav")
#'
#' # Get all voice quality metrics
#' vq <- get_voice_quality_ultra(sound, metrics = "all", min_pitch = 75)
#'
#' # Get only jitter metrics (DSI PPQ component)
#' vq <- get_voice_quality_ultra(sound, metrics = "jitter")
#' ppq5 <- vq$jitter_ppq5
#'
#' # Match Praat's plain To Pitch... + To PointProcess (cc) DSI path
#' vq_praat <- get_voice_quality_ultra(
#'   sound,
#'   metrics = "jitter",
#'   pitch_method = "ac",
#'   very_accurate = FALSE
#' )
#'
#' # Equivalent shorthand for Praat's `To PointProcess (periodic, cc)...`
#' vq_periodic_cc <- get_voice_quality_ultra(
#'   sound,
#'   metrics = "jitter",
#'   pitch_method = "periodic_cc"
#' )
#'
#' # Compare with traditional approach
#' bench::mark(
#'   tier4 = get_voice_quality_ultra(sound, "jitter"),
#'   tier2 = {
#'     pitch <- sound$to_pitch_cc(very_accurate = TRUE)
#'     pp <- to_point_process_from_sound_and_pitch(sound, pitch)
#'     get_jitter_shimmer_batch(pp, sound)
#'   }
#' )
#' # Expected: tier4 ~3.6x faster
#' }
#'
#' @seealso
#' [Sound] for creating Sound objects
#' [get_jitter_shimmer_batch()] for Tier 2/3 voice quality analysis
#'
#' @export
get_voice_quality_ultra <- function(sound,
                                     metrics = "all",
                                     min_pitch = 75,
                                     max_pitch = 600,
                                     time_step = 0,
                                     pitch_method = c("cc", "ac", "periodic_cc"),
                                     very_accurate = TRUE) {
  if (!inherits(sound, "Sound")) {
    stop("sound must be a Sound object")
  }

  valid_metrics <- c("jitter", "shimmer", "hnr", "all")
  if (!all(metrics %in% valid_metrics)) {
    stop("metrics must be one or more of: ", paste(valid_metrics, collapse = ", "))
  }

  pitch_method <- match.arg(pitch_method)
  if (pitch_method == "periodic_cc") {
    # Praat's `To PointProcess (periodic, cc)...` == Sound_to_Pitch (rawAc,
    # veryAccurate = FALSE) + Sound_Pitch_to_PointProcess_cc. See the
    # "Algorithm choice" roxygen section above for the source-level proof.
    pitch_method <- "ac"
    very_accurate <- FALSE
  }

  get_voice_quality_ultra_cpp(
    sound$.xptr,
    as.character(metrics),
    as.numeric(min_pitch),
    as.numeric(max_pitch),
    as.numeric(time_step),
    pitch_method,
    as.logical(very_accurate)
  )
}


#' Get spectral moments for all frames of a Spectrogram
#'
#' Computes centre of gravity, standard deviation, skewness, and kurtosis for
#' every frame in a Spectrogram in a single C++ pass, eliminating the ~14×
#' R-loop overhead of calling per-frame Spectrum methods.
#'
#' @param spectrogram A \code{Spectrogram} object
#' @param power Numeric. Power for moment weighting (default 2.0, matching Praat)
#'
#' @return \code{data.frame} with columns \code{time}, \code{cog}, \code{sd},
#'   \code{skewness}, \code{kurtosis} (one row per frame; \code{NA} where undefined)
#'
#' @export
get_spectral_moments_batch <- function(spectrogram, power = 2.0) {
  if (!inherits(spectrogram, "Spectrogram"))
    stop("spectrogram must be a Spectrogram object")
  result <- .get_spectral_moments_batch(spectrogram$.xptr, as.numeric(power))
  as.data.frame(result)
}
