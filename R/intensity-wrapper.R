# intensity-wrapper.R - Intensity object using shared dispatch table (pladdrr
#  4.8.33)
# Architecture: minimal list + $.Intensity S3 dispatch → shared method env

#' Intensity
#'
#' Intensity objects represent sound power (loudness) over time, measured in
#' decibels (dB) relative to the auditory threshold.
#'
#' Created from a Sound using intensity contour extraction.
#'
#' @section Information methods:
#' \itemize{
#'   \item \code{get_duration()} - duration of the intensity contour (s)
#'   \item \code{get_time_step()} - time step between frames (s)
#' }
#'
#' @section Point query methods:
#' \itemize{
#' \item \code{get_value_at_time(time, interpolation)} - intensity at a time
#  point (dB)
#' \item \code{get_values_at_times(times, interpolation)} - intensity at a
#  vector of times (batch)
#' }
#'
#' @section Statistics methods (over a time range):
#' \itemize{
#' \item \code{get_mean(from_time, to_time, averaging_method)} - mean intensity
#  (dB)
#' \item \code{get_standard_deviation(from_time, to_time)} - standard deviation
#  (dB)
#' \item \code{get_minimum(from_time, to_time, interpolation)} - minimum
#  intensity
#' \item \code{get_maximum(from_time, to_time, interpolation)} - maximum
#  intensity
#'   \item \code{get_quantile(quantile, from_time, to_time)} - quantile
#' \item \code{get_time_of_minimum(...)}, \code{get_time_of_maximum(...)} - time
#  of extremum
#' }
#'
#' @section Export methods:
#' \itemize{
#'   \item \code{as_vector()} - raw intensity values (dB)
#'   \item \code{as_data_frame()} - export as a data.frame (time, intensity)
#'   \item \code{save(filepath)} - save to a Praat binary file
#' }
#'
#' @section Interpolation:
#' Codes: \code{"nearest"} (0), \code{"linear"} (1), \code{"cubic"} (2,
#  default),
#' \code{"sinc70"} (3), \code{"sinc700"} (4).
#' Averaging methods: \code{"energy"} (0, default), \code{"sones"} (1),
#  \code{"db"} (2).
#'
#' @param .xptr Not for direct use. External pointer to the underlying C++
#'   Intensity object; set internally when a method returns a new Intensity.
#' @seealso \code{\link{Sound}}, \code{\link{Pitch}},
#  \code{\link{IntensityTier}}
#'
#' @examples
#' sound <- Sound$create_tone(duration = 1.0, frequency = 200, sampling_rate =
#  44100)
#' intensity <- sound$to_intensity(minimum_pitch = 100, time_step = 0.0)
#' mean_int <- intensity$get_mean()
#' df <- intensity$as_data_frame()
#'
#' # The same analysis on a recording read from disk
#' sound <- Sound(system.file("extdata", "test.wav", package = "pladdrr"))
#' intensity <- sound$to_intensity(minimum_pitch = 100, time_step = 0.0)
#' int_at_02s <- intensity$get_value_at_time(0.2)
#'
#' @return An \code{Intensity} object with methods for querying intensity values
#'   (in dB) at time points or across the full contour.
#'
#' @name Intensity
NULL

# ============================================================================
# Shared Method Dispatch Table
# ============================================================================

.intensity_methods <- new.env(hash = TRUE, parent = emptyenv())

# Helpers
.intensity_avg_code <- function(method) {
  switch(tolower(method),
    "energy" = 0, "sones" = 1, "db" = 2, 0)
}

# --- Query ---
.intensity_methods$get_value_at_time <- function(.self, time,
  interpolation = "cubic") {
  .self$.cpp$get_value_at_time(time, .praat_interpolation_code(interpolation))
}
.intensity_methods$get_mean <- function(.self, from_time = 0, to_time = 0,
  averaging_method = "energy") {
  .self$.cpp$get_mean(from_time, to_time, .intensity_avg_code(averaging_method))
}
.intensity_methods$get_minimum <- function(.self, from_time = 0, to_time = 0,
  interpolation = "parabolic") {
  .self$.cpp$get_minimum(from_time, to_time,
    .praat_peak_interpolation_code(interpolation))
}
.intensity_methods$get_maximum <- function(.self, from_time = 0, to_time = 0,
  interpolation = "parabolic") {
  .self$.cpp$get_maximum(from_time, to_time,
    .praat_peak_interpolation_code(interpolation))
}
.intensity_methods$get_standard_deviation <- function(.self, from_time = 0,
  to_time = 0) {
  .self$.cpp$get_standard_deviation(from_time, to_time)
}
.intensity_methods$get_quantile <- function(.self, from_time = 0, to_time = 0,
  quantile = 0.5) {
  .self$.cpp$get_quantile(from_time, to_time, quantile)
}
.intensity_methods$get_time_of_minimum <- function(.self, from_time = 0,
  to_time = 0, interpolation = "parabolic") {
  .self$.cpp$get_time_of_minimum(from_time, to_time,
    .praat_peak_interpolation_code(interpolation))
}
.intensity_methods$get_time_of_maximum <- function(.self, from_time = 0,
  to_time = 0, interpolation = "parabolic") {
  .self$.cpp$get_time_of_maximum(from_time, to_time,
    .praat_peak_interpolation_code(interpolation))
}

# --- Time domain ---
.intensity_methods$get_time_from_frame <- function(.self,
  frame) .self$.cpp$get_time_from_frame(frame)
.intensity_methods$get_frame_from_time <- function(.self,
  time) .self$.cpp$get_frame_from_time(time)
.intensity_methods$get_number_of_frames <- function(
  .self) .self$.cpp$get_number_of_frames()
.intensity_methods$get_sampling_period <- function(
  .self) .self$.cpp$get_time_step()
.intensity_methods$get_start_time <- function(.self) .self$.cpp$get_xmin()
.intensity_methods$get_end_time <- function(.self) .self$.cpp$get_xmax()
.intensity_methods$get_xmin <- function(.self) .self$.cpp$get_xmin()
.intensity_methods$get_xmax <- function(.self) .self$.cpp$get_xmax()

# --- Transform ---
.intensity_methods$down_to_intensity_tier <- function(.self) {
  tier_ptr <- .self$.cpp$down_to_intensity_tier_ptr()
  IntensityTier(.xptr = tier_ptr)
}

# --- Batch ---
.intensity_methods$get_values_at_times <- function(.self, times,
  interpolation = "cubic") {
  .self$.cpp$get_values_at_times(as.numeric(times),
    .praat_interpolation_code(interpolation))
}
.intensity_methods$get_times_vector <- function(
  .self) .self$.cpp$get_times_vector()
.intensity_methods$get_values_vector <- function(
  .self) .self$.cpp$get_values_vector()
.intensity_methods$get_statistics <- function(.self, from_time = 0, to_time = 0,
                                              metrics = c("mean", "stdev",
                                                "min", "max", "median")) {
  .self$.cpp$get_statistics(as.numeric(from_time), as.numeric(to_time),
    as.character(metrics))
}

# --- Export ---
.intensity_methods$as_data_frame <- function(.self) {
  df <- .self$.cpp$as_data_frame()
  names(df) <- c("time", "intensity_db")
  df
}
.intensity_methods$as_matrix <- function(.self) {
  df <- .self$.cpp$as_data_frame()
  rbind(time = df$time, intensity_db = df$intensity)
}

# --- Silence detection ---
.intensity_methods$to_textgrid_silences <- function(.self,
  silence_threshold = -25,
                                                     min_silence_duration = 0.3, min_sounding_duration = 0.1,
                                                     silent_label = "silent", sounding_label = "sounding") {
  tg_ptr <- .intensity_to_textgrid_silences(
    .self$.xptr, silence_threshold, min_silence_duration,
    min_sounding_duration, silent_label, sounding_label
  )
  TextGrid(.xptr = tg_ptr)
}

# --- Print ---
.intensity_methods$print <- function(.self, ...) {
  cat("<Praat Intensity>\n")
  cat(sprintf("  Duration: %.3f s\n", .self$.cpp$get_duration()))
  cat(sprintf("  Number of frames: %d\n", .self$.cpp$get_number_of_frames()))
  cat(sprintf("  Time step: %.4f s\n", .self$.cpp$get_time_step()))
  cat(sprintf("  Mean intensity: %.2f dB\n", .self$.cpp$get_mean(0, 0, 0)))
  cat(sprintf("  Range: [%.2f, %.2f] dB\n",
              .self$.cpp$get_minimum(0, 0, 1), .self$.cpp$get_maximum(0, 0, 1)))
  invisible(.self)
}

.intensity_methods$is_valid <- function(.self) .self$.cpp$is_valid()
lockEnvironment(.intensity_methods, bindings = TRUE)

# ============================================================================
# Constructor
# ============================================================================

#' @export
Intensity <- function(.xptr = NULL) {
  if (is.null(.xptr)) {
    stop(
      "Intensity objects should be created from Sound objects using to_intensity()")
  }
  intensity_mod <- get_module("intensity_module")
  cpp_obj <- intensity_mod$RIntensity$new(.xptr)
  structure(list(.xptr = .xptr, .cpp = cpp_obj),
    class = c("Intensity", "PraatObject"))
}

# ============================================================================
# S3 Dispatch
# ============================================================================

#' @method $ Intensity
#' @export
`$.Intensity` <- function(x, name) {
  val <- .subset2(x, name)
  if (!is.null(val)) return(val)
  if (name == ".pointer") return(.subset2(x, ".xptr"))
  method <- .intensity_methods[[name]]
  if (is.null(method)) return(NULL)
  function(...) method(x, ...)
}

#' @export
as.data.frame.Intensity <- function(x, ...) x$as_data_frame()
