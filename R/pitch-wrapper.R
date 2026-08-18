# pitch-wrapper.R - Pitch object using shared dispatch table (pladdrr 4.8.33)
# Architecture: minimal list + $.Pitch S3 dispatch → shared method env

#' Pitch
#'
#' Fundamental frequency (F0) contour of a sound (a Praat Pitch object).
#'
#' Created from a Sound via autocorrelation or cross-correlation pitch
#' tracking. Supports multiple unit systems: hertz, semitones (re 1 Hz,
#' 100 Hz, or custom), mel, and erb; see the Units section for the full
#' set of codes.
#'
#' @section Information:
#' \itemize{
#'   \item \code{get_number_of_frames()} - number of analysis frames
#'   \item \code{get_time_step()} - time step between frames, in seconds
#'   \item \code{count_voiced_frames()} - number of frames with voiced (non-zero) pitch
#' }
#'
#' @section Point queries:
#' \itemize{
#'   \item \code{get_value_at_time(time, unit, interpolate)} - F0 at a time point
#'   \item \code{get_values_at_times(times, unit, interpolate)} - F0 at a vector of times (batch)
#'   \item \code{get_strength_at_time(time)} - strength (voicing likelihood) at a time
#'   \item \code{get_strengths_at_times(times)} - strengths at a vector of times (batch)
#' }
#'
#' @section Statistics:
#' Computed over a time range.
#' \itemize{
#'   \item \code{get_mean(from_time, to_time, unit)} - mean F0
#'   \item \code{get_standard_deviation(from_time, to_time, unit)} - standard deviation
#'   \item \code{get_minimum(from_time, to_time, unit, interpolate)} - minimum F0
#'   \item \code{get_maximum(from_time, to_time, unit, interpolate)} - maximum F0
#'   \item \code{get_quantile(quantile, from_time, to_time, unit)} - quantile of F0
#'   \item \code{get_time_of_minimum(...)}, \code{get_time_of_maximum(...)} - time of extremum
#' }
#'
#' @section Export:
#' \itemize{
#'   \item \code{as_vector()}, \code{as_data_frame()} - export as vector or data.frame
#'   \item \code{get_times_vector()} - frame time points
#'   \item \code{as_matrix()} - F0 values as a matrix (frames by candidates)
#' }
#'
#' @section Transform:
#' \itemize{
#'   \item \code{to_point_process(voicing_threshold, octave_cost, ...)} - convert to a PointProcess (glottal pulses)
#'   \item \code{down_to_pitch_tier()} - convert to a PitchTier (editable pitch contour)
#' }
#'
#' @section Units:
#' F0 unit codes: \code{"hertz"} (0), \code{"semitones re 1 Hz"} (1),
#' \code{"semitones re 100 Hz"} (2), \code{"semitones re 200 Hz"} (3),
#' \code{"semitones re 440 Hz"} (4), \code{"mel"} (5), \code{"log hertz"} (6),
#' \code{"erb"} (7). Default is \code{"hertz"}.
#'
#' @seealso \code{\link{Sound}}, \code{\link{PointProcess}}, \code{\link{PitchTier}}
#'
#' @param .xptr Not for direct use. External pointer to the underlying C++
#'   Pitch object; set internally when a method returns a new Pitch.
#' @return A Pitch object.
#'
#' @examples
#' sound <- Sound$create_tone(duration = 1.0, frequency = 200, sampling_rate = 44100)
#' pitch <- sound$to_pitch(time_step = 0.01, pitch_floor = 75, pitch_ceiling = 600)
#' mean_f0 <- pitch$get_mean(from_time = 0, to_time = 0, unit = "hertz")
#' min_f0 <- pitch$get_minimum(from_time = 0, to_time = 0, unit = "hertz")
#' df <- as.data.frame(pitch)
#'
#' # The same analysis on a recording read from disk
#' sound <- Sound(system.file("extdata", "test.wav", package = "pladdrr"))
#' pitch <- sound$to_pitch(time_step = 0.01, pitch_floor = 75, pitch_ceiling = 600)
#' n_voiced <- pitch$count_voiced_frames()
#' 
#' @name Pitch
NULL

# ============================================================================
# Shared Method Dispatch Table
# ============================================================================

.pitch_methods <- new.env(hash = TRUE, parent = emptyenv())

# Helper: pitch unit string → integer code
.pitch_unit_code <- function(unit) {
  switch(tolower(unit),
    "hertz" = 0L, "hz" = 0L,
    "semitones" = 1L,
    "mel" = 2L,
    "erb" = 3L,
    stop("Unknown unit: ", unit, ". Use: hertz, semitones, mel, erb")
  )
}

# --- Properties ---
.pitch_methods$is_valid <- function(.self) .self$.cpp$is_valid()
.pitch_methods$xmin <- function(.self) .self$.cpp$get_xmin()
.pitch_methods$xmax <- function(.self) .self$.cpp$get_xmax()
.pitch_methods$get_xmin <- function(.self) .self$.cpp$get_xmin()
.pitch_methods$get_xmax <- function(.self) .self$.cpp$get_xmax()
.pitch_methods$get_start_time <- function(.self) .self$.cpp$get_xmin()
.pitch_methods$get_end_time <- function(.self) .self$.cpp$get_xmax()
.pitch_methods$get_total_duration <- function(.self) .self$.cpp$get_duration()
.pitch_methods$get_duration <- function(.self) .self$.cpp$get_duration()
.pitch_methods$duration <- function(.self) .self$.cpp$get_duration()
.pitch_methods$nx <- function(.self) .self$.cpp$get_nx()
.pitch_methods$dx <- function(.self) .self$.cpp$get_dx()
.pitch_methods$x1 <- function(.self) .self$.cpp$get_x1()
.pitch_methods$ceiling <- function(.self) .self$.cpp$get_ceiling()

# --- Time domain ---
.pitch_methods$get_time_from_frame <- function(.self, frame_number) {
  .self$.cpp$get_time_from_frame(as.integer(frame_number))
}
.pitch_methods$get_frame_from_time <- function(.self, time) {
  .self$.cpp$get_frame_from_time(as.numeric(time))
}
.pitch_methods$get_number_of_frames <- function(.self) .self$.cpp$get_number_of_frames()
.pitch_methods$get_time_step <- function(.self) .self$.cpp$get_time_step()

# --- Pitch value queries ---
.pitch_methods$get_value_at_time <- function(.self, time, unit = "hertz", interpolate = TRUE) {
  .self$.cpp$get_value_at_time(as.numeric(time), .pitch_unit_code(unit), as.logical(interpolate))
}
.pitch_methods$get_mean <- function(.self, from_time = 0, to_time = 0, unit = "hertz") {
  .self$.cpp$get_mean(as.numeric(from_time), as.numeric(to_time), .pitch_unit_code(unit))
}
.pitch_methods$get_standard_deviation <- function(.self, from_time = 0, to_time = 0, unit = "hertz") {
  .self$.cpp$get_standard_deviation(as.numeric(from_time), as.numeric(to_time), .pitch_unit_code(unit))
}
.pitch_methods$get_quantile <- function(.self, from_time = 0, to_time = 0, quantile = 0.5, unit = "hertz") {
  .self$.cpp$get_quantile(as.numeric(from_time), as.numeric(to_time),
                          as.numeric(quantile), .pitch_unit_code(unit))
}
.pitch_methods$get_minimum <- function(.self, from_time = 0, to_time = 0, unit = "hertz", interpolate = TRUE) {
  .self$.cpp$get_minimum(as.numeric(from_time), as.numeric(to_time),
                         .pitch_unit_code(unit), as.logical(interpolate))
}
.pitch_methods$get_maximum <- function(.self, from_time = 0, to_time = 0, unit = "hertz", interpolate = TRUE) {
  .self$.cpp$get_maximum(as.numeric(from_time), as.numeric(to_time),
                         .pitch_unit_code(unit), as.logical(interpolate))
}
.pitch_methods$get_time_of_minimum <- function(.self, from_time = 0, to_time = 0, unit = "hertz", interpolate = TRUE) {
  .self$.cpp$get_time_of_minimum(as.numeric(from_time), as.numeric(to_time),
                                 .pitch_unit_code(unit), as.logical(interpolate))
}
.pitch_methods$get_time_of_maximum <- function(.self, from_time = 0, to_time = 0, unit = "hertz", interpolate = TRUE) {
  .self$.cpp$get_time_of_maximum(as.numeric(from_time), as.numeric(to_time),
                                 .pitch_unit_code(unit), as.logical(interpolate))
}
.pitch_methods$count_voiced_frames <- function(.self) .self$.cpp$count_voiced_frames()

.pitch_methods$get_statistics <- function(.self, from_time = 0, to_time = 0, unit = "hertz",
                                          metrics = c("mean", "stdev", "min", "max", "median", "q1", "q3")) {
  .self$.cpp$get_statistics(as.numeric(from_time), as.numeric(to_time),
                            .pitch_unit_code(unit), as.character(metrics))
}
.pitch_methods$get_adaptive_range <- function(.self, q1_factor = 0.75, q3_factor = 1.5,
                                              from_time = 0, to_time = 0, unit = "hertz") {
  .self$.cpp$get_adaptive_range(as.numeric(q1_factor), as.numeric(q3_factor),
                                as.numeric(from_time), as.numeric(to_time),
                                .pitch_unit_code(unit))
}

# --- Batch/Vectorized ---
.pitch_methods$get_times_vector <- function(.self) .self$.cpp$get_times_vector()
.pitch_methods$get_values_vector <- function(.self, unit = "hertz") {
  .self$.cpp$get_values_vector(.pitch_unit_code(unit))
}
.pitch_methods$get_strength_at_time <- function(.self, time, unit = "hertz", interpolate = TRUE) {
  .self$.cpp$get_strength_at_time(as.numeric(time), .pitch_unit_code(unit), as.logical(interpolate))
}
.pitch_methods$get_mean_strength <- function(.self, from_time = 0, to_time = 0, unit = "hertz") {
  .self$.cpp$get_mean_strength(as.numeric(from_time), as.numeric(to_time), .pitch_unit_code(unit))
}
.pitch_methods$get_intensity_at_time <- function(.self, time) {
  .self$.cpp$get_intensity_at_time(as.numeric(time))
}
.pitch_methods$get_mean_intensity <- function(.self, from_time = 0, to_time = 0) {
  .self$.cpp$get_mean_intensity(as.numeric(from_time), as.numeric(to_time))
}
.pitch_methods$get_voiced_mask <- function(.self) .self$.cpp$get_voiced_mask()
.pitch_methods$get_strengths_vector <- function(.self, unit = "hertz") {
  .self$.cpp$get_strengths_vector(.pitch_unit_code(unit))
}
.pitch_methods$get_values_at_times <- function(.self, times, unit = "hertz", interpolate = TRUE) {
  .self$.cpp$get_values_at_times(as.numeric(times), .pitch_unit_code(unit), as.logical(interpolate))
}
.pitch_methods$get_intensities_vector <- function(.self) .self$.cpp$get_intensities_vector()

# --- Detrending ---
.pitch_methods$subtract_linear_fit <- function(.self, unit = "hertz") {
  pitch_ptr <- .self$.cpp$subtract_linear_fit_ptr(.pitch_unit_code(unit))
  Pitch(.xptr = pitch_ptr)
}
.pitch_methods$get_values_detrended <- function(.self, unit = "hertz") {
  .self$.cpp$get_values_detrended(.pitch_unit_code(unit))
}
.pitch_methods$interpolate <- function(.self) {
  pitch_ptr <- .self$.cpp$interpolate_ptr()
  Pitch(.xptr = pitch_ptr)
}
.pitch_methods$smooth <- function(.self, bandwidth = 10.0) {
  pitch_ptr <- .self$.cpp$smooth_ptr(as.numeric(bandwidth))
  Pitch(.xptr = pitch_ptr)
}
.pitch_methods$kill_octave_jumps <- function(.self) {
  pitch_ptr <- .self$.cpp$kill_octave_jumps_ptr()
  Pitch(.xptr = pitch_ptr)
}

# --- Transformations ---
.pitch_methods$to_point_process <- function(.self) {
  warning(
    "pitch$to_point_process() creates PointProcess from Pitch candidates only.\n",
    "For voice quality analysis (jitter/shimmer), use:\n",
    "  sound$to_point_process_periodic_cc(pitch_floor, pitch_ceiling)\n",
    "This ensures accurate glottal pulse timing with amplitude information.",
    call. = FALSE
  )
  pp_ptr <- .self$.cpp$to_point_process_ptr()
  PointProcess(.xptr = pp_ptr)
}
.pitch_methods$down_to_pitch_tier <- function(.self) {
  tier_ptr <- .self$.cpp$down_to_pitch_tier_ptr()
  PitchTier(.xptr = tier_ptr)
}
.pitch_methods$to_textgrid_vuv <- function(.self, max_period = 0.02, mean_period = 0.01) {
  tg_ptr <- .self$.cpp$to_textgrid_vuv_ptr(as.numeric(max_period), as.numeric(mean_period))
  TextGrid(.xptr = tg_ptr)
}
.pitch_methods$to_textgrid_silences <- function(.self, min_silent_duration = 0.1, min_sounding_duration = 0.1) {
  tg_ptr <- .self$.cpp$to_textgrid_silences_ptr(min_silent_duration, min_sounding_duration)
  TextGrid(.xptr = tg_ptr)
}
.pitch_methods$to_dtw <- function(.self, reference, vuv_costs = 24.0, time_weight = 10.0,
                                  match_start = TRUE, match_end = TRUE, slope = 1) {
  if (!inherits(reference, "Pitch")) stop("reference must be a Pitch object")
  pitches_to_dtw(reference, .self, vuv_costs, time_weight, match_start, match_end, slope)
}

# --- Export ---
.pitch_methods$as_matrix <- function(.self) .self$.cpp$as_matrix()
.pitch_methods$as_data_frame <- function(.self, include_strength = FALSE, include_intensity = FALSE) {
  .self$.cpp$as_data_frame(as.logical(include_strength), as.logical(include_intensity))
}
.pitch_methods$save <- function(.self, path) {
  .self$.cpp$save(as.character(path))
  invisible(.self)
}

# --- Print ---
.pitch_methods$print <- function(.self) {
  cat("<Praat Pitch (Module)>\n")
  if (.self$.cpp$is_valid()) {
    n_frames <- .self$.cpp$get_number_of_frames()
    time_step <- .self$.cpp$get_time_step()
    n_voiced <- .self$.cpp$count_voiced_frames()
    cat(sprintf("  Duration: %.3f s\n", .self$.cpp$get_duration()))
    cat(sprintf("  Frames: %d\n", n_frames))
    cat(sprintf("  Time step: %.4f s\n", time_step))
    cat(sprintf("  Voiced: %d (%.1f%%)\n", n_voiced, 100 * n_voiced / n_frames))
    tryCatch({
      mean_f0 <- .self$.cpp$get_mean(0, 0, 0L)
      if (!is.na(mean_f0) && mean_f0 > 0) {
        min_f0 <- .self$.cpp$get_minimum(0, 0, 0L, TRUE)
        max_f0 <- .self$.cpp$get_maximum(0, 0, 0L, TRUE)
        sd_f0 <- .self$.cpp$get_standard_deviation(0, 0, 0L)
        cat(sprintf("  Mean F0: %.1f Hz\n", mean_f0))
        cat(sprintf("  Range: %.1f - %.1f Hz\n", min_f0, max_f0))
        cat(sprintf("  SD: %.1f Hz\n", sd_f0))
      }
    }, error = function(e) {})
  } else {
    cat("  [Invalid object]\n")
  }
  invisible(.self)
}

lockEnvironment(.pitch_methods, bindings = TRUE)

# ============================================================================
# Constructor
# ============================================================================

#' @export
Pitch <- function(.xptr = NULL) {
  if (is.null(.xptr)) {
    stop("Pitch objects must be created from a Sound object using sound$to_pitch()")
  }
  pitch_mod <- get_module("pitch_module")
  if (is.null(pitch_mod)) {
    stop("pitch_module not available - package installation may be incomplete")
  }
  cpp_obj <- pitch_mod$RPitch$new(.xptr)
  structure(list(.xptr = .xptr, .cpp = cpp_obj), class = c("Pitch", "PraatObject"))
}

# ============================================================================
# S3 Dispatch
# ============================================================================

#' @method $ Pitch
#' @export
`$.Pitch` <- function(x, name) {
  # Fast path: direct field access
  val <- .subset2(x, name)
  if (!is.null(val)) return(val)
  # Compat alias
  if (name == ".pointer") return(.subset2(x, ".xptr"))
  # Method dispatch
  method <- .pitch_methods[[name]]
  if (is.null(method)) return(NULL)
  function(...) method(x, ...)
}

#' @export
print.Pitch <- function(x, ...) {
  x$print()
  invisible(x)
}

#' @export
as.data.frame.Pitch <- function(x, row.names = NULL, optional = FALSE,
                                include_strength = FALSE, include_intensity = FALSE, ...) {
  x$as_data_frame(include_strength = include_strength,
                  include_intensity = include_intensity)
}
