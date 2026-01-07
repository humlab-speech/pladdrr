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
  if (!inherits(formant, "formant_constructor")) {
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
  if (!inherits(formant, "formant_constructor")) {
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
  if (!inherits(pitch, "pitch_constructor")) {
    stop("pitch must be a Pitch object")
  }
  
  if (!is.numeric(times) || length(times) == 0) {
    stop("times must be a non-empty numeric vector")
  }
  
  unit_code <- switch(tolower(unit),
    "hertz" = 0L,
    "hz" = 0L,
    "mel" = 1L,
    "loghertz" = 2L,
    "semitones" = 3L,
    "erb" = 4L,
    stop("Unknown unit: ", unit)
  )
  
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
  if (!inherits(pitch, "pitch_constructor")) {
    stop("pitch must be a Pitch object")
  }
  
  unit_code <- switch(tolower(unit),
    "hertz" = 0L,
    "mel" = 1L,
    "loghertz" = 2L,
    "semitones" = 3L,
    "erb" = 4L,
    stop("Unknown unit: ", unit)
  )
  
  pitch_get_strengths_at_times(
    pitch$.xptr,
    times,
    unit_code,
    as.logical(interpolate)
  )
}

#' Batch Query Intensity Values at Multiple Times
#'
#' Query intensity (amplitude in dB) at multiple time points in a single call.
#'
#' @param intensity An Intensity object
#' @param times Numeric vector of time points (in seconds)
#' @param interpolate Interpolation method: "nearest", "linear", "cubic" (default),
#'   or "sinc70"
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
get_intensity_at_times <- function(intensity, times, interpolate = "cubic") {
  if (!inherits(intensity, "intensity_constructor")) {
    stop("intensity must be an Intensity object")
  }
  
  if (!is.numeric(times) || length(times) == 0) {
    stop("times must be a non-empty numeric vector")
  }
  
  interp_code <- switch(tolower(interpolate),
    "nearest" = 0L,
    "linear" = 1L,
    "cubic" = 4L,
    "sinc70" = 6L,
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
  if (!inherits(pointprocess, "pointprocess_constructor")) {
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
  if (!inherits(pointprocess, "pointprocess_constructor")) {
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
  if (!inherits(pointprocess, "pointprocess_constructor")) {
    stop("pointprocess must be a PointProcess object")
  }
  
  if (!is.numeric(times) || length(times) == 0) {
    stop("times must be a non-empty numeric vector")
  }
  
  pointprocess_get_nearest_indices(pointprocess$.xptr, times)
}
