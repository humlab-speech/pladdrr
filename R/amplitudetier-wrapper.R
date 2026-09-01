#' AmplitudeTier
#'
#' A Praat AmplitudeTier: sound pressure amplitude in Pascals as a function
#' of time.
#'
#' An AmplitudeTier stores amplitude as a sparse sequence of (time, value)
#' points rather than a dense signal, with linear interpolation between
#' points. It's the amplitude counterpart to an IntensityTier (which stores
#' dB instead of Pa), and the two convert into each other. A common use is
#' pulling amplitude at glottal pulse times (from a PointProcess) to compute
#' shimmer.
#'
#' @section Usage:
#' \preformatted{
#' tier <- amplitude_tier_create(0, 1)
#' tier <- amplitude_tier_from_point_process(point_process, sound)
#' tier <- intensity_tier_to_amplitude_tier(intensity_tier)
#' }
#'
#' @section Query methods:
#' \itemize{
#' \item \code{get_start_time()}, \code{get_end_time()} - time domain in seconds
#'   \item \code{get_number_of_points()} - number of (time, value) points
#'   \item \code{get_time_from_index(index)} - time at a 1-based point index
#' \item \code{get_value_at_index(index)} - amplitude at a 1-based point index
#'  (Pa)
#' \item \code{get_value_at_time(time)} - interpolated amplitude at a time (Pa)
#' }
#'
#' @section Modification:
#' \itemize{
#'   \item \code{add_point(time, value)} - add a (time, value) point
#'   \item \code{remove_point(index)} - remove the point at a 1-based index
#' }
#'
#' @section Conversion and export:
#' \itemize{
#' \item \code{to_intensity_tier(threshold_db)} - convert amplitude to an
#'  IntensityTier
#' \item \code{as_data_frame()} - points as a data frame with \code{time} and
#'  \code{amplitude_pa} columns
#'   \item \code{save(path)} - write to file
#' }
#'
#' @param .xptr Not for direct use. External pointer to the underlying C++
#'   AmplitudeTier object; set internally when a method returns a new
#'   AmplitudeTier.
#' @return An \code{AmplitudeTier} object.
#'
#' @examples
#' tier <- amplitude_tier_create(0, 1)
#' tier$add_point(0.25, 0.5)
#' tier$add_point(0.75, 0.8)
#' tier$get_number_of_points()
#' tier$get_value_at_time(0.5)
#'
#' @seealso [amplitude_tier_create], [amplitude_tier_from_point_process],
#'   [intensity_tier_to_amplitude_tier]
#' @name AmplitudeTier
NULL

# ============================================================================
# Shared Method Dispatch Table
# ============================================================================

.amplitudetier_methods <- new.env(hash = TRUE, parent = emptyenv())

# Query
.amplitudetier_methods$get_start_time <- function(.self) .self$.cpp$get_xmin()
.amplitudetier_methods$get_end_time <- function(.self) .self$.cpp$get_xmax()
.amplitudetier_methods$get_number_of_points <- function(
  .self) .self$.cpp$get_number_of_points()
.amplitudetier_methods$get_time_from_index <- function(.self,
  index) .self$.cpp$get_time(as.integer(index))
.amplitudetier_methods$get_value_at_index <- function(.self,
  index) .self$.cpp$get_value(as.integer(index))
.amplitudetier_methods$get_value_at_time <- function(.self,
  time) .self$.cpp$get_value_at_time(as.numeric(time))

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
.amplitudetier_methods$to_intensity_tier <- function(.self,
  threshold_db = -200) {
  ptr <- .self$.cpp$to_intensity_tier_ptr(threshold_db)
  IntensityTier(.xptr = ptr)
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
  .self$.cpp$save(as.character(path))
  invisible(.self)
}

# Utility
.amplitudetier_methods$get_xptr <- function(.self) .self$.xptr

# Display
.amplitudetier_methods$print <- function(.self) {
  cat("<Praat AmplitudeTier>\n")
  cat(
    sprintf("  Time domain: %.3f to %.3f s\n", .self$.cpp$get_xmin(),
      .self$.cpp$get_xmax()))
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
    stop(
      "AmplitudeTier objects must be created using amplitude_tier_create() or ",
        "related functions")
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
as.data.frame.AmplitudeTier <- function(x, ...) x$as_data_frame()

# ============================================================================
# Factory Functions
# ============================================================================

#' Create an empty AmplitudeTier
#'
#' Creates a new AmplitudeTier object with no points.
#'
#' @inheritParams pladdrr_shared_params tmin
#' @inheritParams pladdrr_shared_params tmax
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
#' Extracts amplitude values from a Sound at the times specified by a
#'  PointProcess.
#'
#' @param point_process A PointProcess object
#' @inheritParams pladdrr_shared_sound_a sound
#' @return An AmplitudeTier object with amplitudes at each point time
#' @examples
#' sound <- Sound$create_tone(frequency = 150, duration = 0.5, sampling_rate =
#'  16000)
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
  ptr <- point_process_sound_to_amplitude_tier_point_cpp(point_process$.xptr,
    sound$.xptr)
  AmplitudeTier(.xptr = ptr)
}

#' Convert IntensityTier to AmplitudeTier
#'
#' Converts intensity values (dB) to amplitude values.
#'
#' @param intensity_tier An IntensityTier object
#' @return An AmplitudeTier object
#' @examples
#' it <- IntensityTier(0, 1)
#' it$add_point(0.25, 70)
#' it$add_point(0.75, 60)
#' at <- intensity_tier_to_amplitude_tier(it)
#' at$get_number_of_points()
#' @export
intensity_tier_to_amplitude_tier <- function(intensity_tier) {
  if (!inherits(intensity_tier, "IntensityTier")) {
    stop("intensity_tier must be an IntensityTier object")
  }
  ptr <- intensity_tier_to_amplitude_tier_cpp(intensity_tier$.xptr)
  AmplitudeTier(.xptr = ptr)
}
