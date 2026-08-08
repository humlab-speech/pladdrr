#' @title Praat AmplitudeTier Object
#' @description
#' Praat AmplitudeTier object with direct C++ module binding for amplitude analysis.
#'
#' @details
#' AmplitudeTier represents sound pressure amplitude in Pascals as a function of time,
#' stored as a sequence of (time, value) points with interpolation between points.
#'
#' @return An \code{AmplitudeTier} object with methods for amplitude-over-time
#'   manipulation via time-value points.
#'
#' @examples
#' tier <- amplitude_tier_create(0, 1)
#' tier$add_point(0.25, 0.5)
#' tier$add_point(0.75, 0.8)
#' tier$get_number_of_points()
#' tier$get_value_at_time(0.5)
#'
#' @name AmplitudeTier
NULL

# ============================================================================
# Shared Method Dispatch Table
# ============================================================================

.amplitudetier_methods <- new.env(hash = TRUE, parent = emptyenv())

# Query
.amplitudetier_methods$get_start_time <- function(.self) .self$.cpp$get_xmin()
.amplitudetier_methods$get_end_time <- function(.self) .self$.cpp$get_xmax()
.amplitudetier_methods$get_number_of_points <- function(.self) .self$.cpp$get_number_of_points()
.amplitudetier_methods$get_time_from_index <- function(.self, index) .self$.cpp$get_time(as.integer(index))
.amplitudetier_methods$get_value_at_index <- function(.self, index) .self$.cpp$get_value(as.integer(index))
.amplitudetier_methods$get_value_at_time <- function(.self, time) .self$.cpp$get_value_at_time(as.numeric(time))

# Modification (self-returning)
.amplitudetier_methods$add_point <- function(.self, time, value) {
  .self$.cpp$add_point(as.numeric(time), as.numeric(value))
  invisible(.self)
}
.amplitudetier_methods$remove_point <- function(.self, index) {
  .self$.cpp$remove_point(as.integer(index))
  invisible(.self)
}

# Conversion
.amplitudetier_methods$to_intensity_tier <- function(.self, threshold_db = -200) {
  ptr <- .amplitudetier_to_intensitytier(.self$.xptr, threshold_db)
  IntensityTier(.xptr = ptr)
}

# Shimmer measures
.amplitudetier_methods$get_shimmer_local <- function(.self, period_floor = 0.0001, period_ceiling = 0.02, max_period_factor = 1.3) {
  .amplitudetier_get_shimmer_local(.self$.xptr, period_floor, period_ceiling, max_period_factor)
}
.amplitudetier_methods$get_shimmer_local_db <- function(.self, period_floor = 0.0001, period_ceiling = 0.02, max_period_factor = 1.3) {
  .amplitudetier_get_shimmer_local_db(.self$.xptr, period_floor, period_ceiling, max_period_factor)
}
.amplitudetier_methods$get_shimmer_apq3 <- function(.self, period_floor = 0.0001, period_ceiling = 0.02, max_period_factor = 1.3) {
  .amplitudetier_get_shimmer_apq3(.self$.xptr, period_floor, period_ceiling, max_period_factor)
}
.amplitudetier_methods$get_shimmer_apq5 <- function(.self, period_floor = 0.0001, period_ceiling = 0.02, max_period_factor = 1.3) {
  .amplitudetier_get_shimmer_apq5(.self$.xptr, period_floor, period_ceiling, max_period_factor)
}
.amplitudetier_methods$get_shimmer_apq11 <- function(.self, period_floor = 0.0001, period_ceiling = 0.02, max_period_factor = 1.3) {
  .amplitudetier_get_shimmer_apq11(.self$.xptr, period_floor, period_ceiling, max_period_factor)
}
.amplitudetier_methods$get_shimmer_dda <- function(.self, period_floor = 0.0001, period_ceiling = 0.02, max_period_factor = 1.3) {
  .amplitudetier_get_shimmer_dda(.self$.xptr, period_floor, period_ceiling, max_period_factor)
}

# Export
.amplitudetier_methods$as_data_frame <- function(.self) {
  n_points <- .self$.cpp$get_number_of_points()
  if (n_points == 0) {
    return(data.frame(time = numeric(0), amplitude_pa = numeric(0)))
  }
  times <- numeric(n_points)
  values <- numeric(n_points)
  for (i in seq_len(n_points)) {
    times[i] <- .self$.cpp$get_time(i)
    values[i] <- .self$.cpp$get_value(i)
  }
  data.frame(time = times, amplitude_pa = values)
}
.amplitudetier_methods$save <- function(.self, path) {
  .amplitudetier_save(.self$.xptr, as.character(path))
  invisible(.self)
}

# Utility
.amplitudetier_methods$get_xptr <- function(.self) .self$.xptr

# Display
.amplitudetier_methods$print <- function(.self) {
  cat("<Praat AmplitudeTier>\n")
  cat(sprintf("  Time domain: %.3f to %.3f s\n", .self$.cpp$get_xmin(), .self$.cpp$get_xmax()))
  cat(sprintf("  Number of points: %d\n", .self$.cpp$get_number_of_points()))
  invisible(.self)
}

.amplitudetier_methods$is_valid <- function(.self) .self$.cpp$is_valid()
lockEnvironment(.amplitudetier_methods, bindings = TRUE)

# ============================================================================
# S3 Dispatch
# ============================================================================

#' @method $ AmplitudeTier
#' @export
`$.AmplitudeTier` <- function(x, name) {
  val <- .subset2(x, name)
  if (!is.null(val)) return(val)
  # .pointer compat alias (used by factory functions)
  if (name == ".pointer") return(.subset2(x, ".xptr"))
  method <- .amplitudetier_methods[[name]]
  if (is.null(method)) return(NULL)
  function(...) method(x, ...)
}

# ============================================================================
# Constructor
# ============================================================================

#' @export
AmplitudeTier <- function(.xptr = NULL) {
  if (is.null(.xptr)) {
    stop("AmplitudeTier objects must be created using amplitude_tier_create() or related functions")
  }

  tier_mod <- get_module("amplitudetier_module")
  cpp_obj <- tier_mod$RAmplitudeTier$new(.xptr)

  structure(list(
    .cpp = cpp_obj,
    .xptr = .xptr
  ), class = c("AmplitudeTier", "PraatObject"))
}

# ============================================================================
# S3 Methods
# ============================================================================

#' @export
print.AmplitudeTier <- function(x, ...) x$print()

#' @export
as.data.frame.AmplitudeTier <- function(x, ...) x$as_data_frame()

# ============================================================================
# Factory Functions
# ============================================================================

#' Create an empty AmplitudeTier
#'
#' Creates a new AmplitudeTier object with no points.
#'
#' @param tmin Start time in seconds
#' @param tmax End time in seconds
#' @return An AmplitudeTier object
#' @examples
#' tier <- amplitude_tier_create(0, 1)
#' tier$add_point(0.5, 0.8)
#' @export
amplitude_tier_create <- function(tmin, tmax) {
  ptr <- amplitude_tier_create_cpp(tmin, tmax)
  AmplitudeTier(.xptr = ptr)
}

#' Create AmplitudeTier from PointProcess and Sound
#'
#' Extracts amplitude values from a Sound at the times specified by a PointProcess.
#'
#' @param point_process A PointProcess object
#' @param sound A Sound object
#' @return An AmplitudeTier object with amplitudes at each point time
#' @examples
#' sound <- Sound$create_tone(frequency = 150, duration = 0.5, sampling_rate = 16000)
#' pp <- sound$to_point_process_periodic_cc(75, 600)
#' tier <- amplitude_tier_from_point_process(pp, sound)
#' tier$get_number_of_points()
#' @export
amplitude_tier_from_point_process <- function(point_process, sound) {
  if (!inherits(point_process, "PointProcess")) {
    stop("point_process must be a PointProcess object")
  }
  if (!inherits(sound, "Sound")) {
    stop("sound must be a Sound object")
  }
  ptr <- point_process_sound_to_amplitude_tier_point_cpp(point_process$.pointer, sound$.pointer)
  AmplitudeTier(.xptr = ptr)
}

#' Convert IntensityTier to AmplitudeTier
#'
#' Converts intensity values (dB) to amplitude values.
#'
#' @param intensity_tier An IntensityTier object
#' @return An AmplitudeTier object
#' @export
intensity_tier_to_amplitude_tier <- function(intensity_tier) {
  if (!inherits(intensity_tier, "IntensityTier")) {
    stop("intensity_tier must be an IntensityTier object")
  }
  ptr <- intensity_tier_to_amplitude_tier_cpp(intensity_tier$.pointer)
  AmplitudeTier(.xptr = ptr)
}
