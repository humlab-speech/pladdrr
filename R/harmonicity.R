# harmonicity.R - Harmonicity object using shared dispatch table (pladdrr 4.8.33)
# Architecture: minimal list + $.Harmonicity S3 dispatch → shared method env

#' @title Praat Harmonicity Object
#' @description
#' Praat Harmonicity object (Harmonics-to-Noise Ratio).
#' Uses shared dispatch table for minimal memory per object.
#'
#' @details
#' A Harmonicity object represents the degree of acoustic periodicity (HNR)
#' in a sound over time, measured in decibels.
#'
#' @examples
#' \dontrun{
#' sound <- Sound$new("recording.wav")
#' hnr <- sound$to_harmonicity_ac(time_step = 0.01, min_pitch = 75)
#' mean_hnr <- hnr$get_mean()
#' df <- hnr$as_data_frame()
#' }
#'
#' @name Harmonicity
NULL

# ============================================================================
# Helpers
# ============================================================================

.harmonicity_interpolation_code <- function(method) {
  switch(tolower(method),
    "nearest" = 0, "linear" = 1, "cubic" = 2,
    "sinc70" = 3, "sinc700" = 4, 2)
}

.harmonicity_peak_interpolation_code <- function(method) {
  switch(tolower(method),
    "none" = 0, "parabolic" = 1, "cubic" = 2,
    "sinc70" = 3, "sinc700" = 4, 1)
}

# ============================================================================
# Shared Method Dispatch Table
# ============================================================================

.harmonicity_methods <- new.env(hash = TRUE, parent = emptyenv())

# --- Query ---
.harmonicity_methods$get_value_at_time <- function(.self, time, interpolation = "cubic") {
  .self$.cpp$get_value_at_time(time, .harmonicity_interpolation_code(interpolation))
}
.harmonicity_methods$get_mean <- function(.self, from_time = 0, to_time = 0) {
  .self$.cpp$get_mean(from_time, to_time)
}
.harmonicity_methods$get_minimum <- function(.self, from_time = 0, to_time = 0, interpolation = "parabolic") {
  .self$.cpp$get_minimum(from_time, to_time, .harmonicity_peak_interpolation_code(interpolation))
}
.harmonicity_methods$get_maximum <- function(.self, from_time = 0, to_time = 0, interpolation = "parabolic") {
  .self$.cpp$get_maximum(from_time, to_time, .harmonicity_peak_interpolation_code(interpolation))
}
.harmonicity_methods$get_standard_deviation <- function(.self, from_time = 0, to_time = 0) {
  .self$.cpp$get_standard_deviation(from_time, to_time)
}
.harmonicity_methods$get_time_of_minimum <- function(.self, from_time = 0, to_time = 0, interpolation = "parabolic") {
  .self$.cpp$get_time_of_minimum(from_time, to_time, .harmonicity_peak_interpolation_code(interpolation))
}
.harmonicity_methods$get_time_of_maximum <- function(.self, from_time = 0, to_time = 0, interpolation = "parabolic") {
  .self$.cpp$get_time_of_maximum(from_time, to_time, .harmonicity_peak_interpolation_code(interpolation))
}

# --- Batch/Vectorized ---
.harmonicity_methods$get_statistics_batch <- function(.self, from_times, to_times,
                                                      metrics = c("mean", "min", "max", "stdev")) {
  .self$.cpp$get_statistics_batch(as.numeric(from_times), as.numeric(to_times), as.character(metrics))
}
.harmonicity_methods$get_values_vector <- function(.self) .self$.cpp$get_values_vector()
.harmonicity_methods$get_times_vector <- function(.self) .self$.cpp$get_times_vector()
.harmonicity_methods$get_values_at_times <- function(.self, times, interpolation = "cubic") {
  .self$.cpp$get_values_at_times(as.numeric(times), .harmonicity_interpolation_code(interpolation))
}

# --- Time domain ---
.harmonicity_methods$get_number_of_frames <- function(.self) .self$.cpp$get_number_of_frames()
.harmonicity_methods$get_sampling_period <- function(.self) .self$.cpp$get_time_step()
.harmonicity_methods$get_start_time <- function(.self) .self$.cpp$get_xmin()
.harmonicity_methods$get_end_time <- function(.self) .self$.cpp$get_xmax()
.harmonicity_methods$get_time_from_frame <- function(.self, frame) .self$.cpp$get_time_from_frame(frame)
.harmonicity_methods$get_frame_from_time <- function(.self, time) .self$.cpp$get_frame_from_time(time)

# --- Export ---
.harmonicity_methods$as_data_frame <- function(.self) {
  df <- .self$.cpp$as_data_frame()
  names(df) <- c("time", "hnr_db", "voiced")
  df
}
.harmonicity_methods$as_matrix <- function(.self) {
  mat <- .self$.cpp$as_matrix()
  rbind(time = mat[, 1], hnr_db = mat[, 2])
}

# --- Print ---
.harmonicity_methods$print <- function(.self, ...) {
  cat("<Praat Harmonicity>\n")
  cat(sprintf("  Duration: %.3f s\n", .self$.cpp$get_duration()))
  cat(sprintf("  Number of frames: %d\n", .self$.cpp$get_number_of_frames()))
  cat(sprintf("  Time step: %.4f s\n", .self$.cpp$get_time_step()))
  cat(sprintf("  Mean HNR: %.2f dB\n", .self$.cpp$get_mean(0, 0)))
  cat(sprintf("  Range: [%.2f, %.2f] dB\n",
              .self$.cpp$get_minimum(0, 0, 1),
              .self$.cpp$get_maximum(0, 0, 1)))
  invisible(.self)
}

.harmonicity_methods$is_valid <- function(.self) .self$.cpp$is_valid()
lockEnvironment(.harmonicity_methods, bindings = TRUE)

# ============================================================================
# Constructor
# ============================================================================

#' @export
Harmonicity <- function(.xptr = NULL) {
  if (is.null(.xptr)) {
    stop("Harmonicity objects should be created from Sound objects using to_harmonicity_ac() or to_harmonicity_cc()")
  }
  harmonicity_mod <- get_module("harmonicity_module")
  cpp_obj <- harmonicity_mod$RHarmonicity$new(.xptr)
  structure(list(.xptr = .xptr, .cpp = cpp_obj), class = c("Harmonicity", "PraatObject"))
}

# ============================================================================
# S3 Dispatch
# ============================================================================

#' @method $ Harmonicity
#' @export
`$.Harmonicity` <- function(x, name) {
  val <- .subset2(x, name)
  if (!is.null(val)) return(val)
  if (name == ".pointer") return(.subset2(x, ".xptr"))
  method <- .harmonicity_methods[[name]]
  if (is.null(method)) return(NULL)
  function(...) method(x, ...)
}

#' @export
print.Harmonicity <- function(x, ...) {
  x$print(...)
}

#' @export
as.data.frame.Harmonicity <- function(x, ...) {
  x$as_data_frame()
}
