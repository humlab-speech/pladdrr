#' @title Praat IntensityTier Object
#' @description
#' Praat IntensityTier object with direct C++ module binding for intensity manipulation.
#'
#' @details
#' IntensityTiers contain discrete time-value pairs representing intensity in dB SPL.
#' They can be used to modify the amplitude envelope of sounds.
#'
#' @return An \code{IntensityTier} object with methods for intensity (dB SPL) manipulation via time-value points.
#'
#' @examples
#' it <- IntensityTier(0, 1)
#' it$add_point(0.25, 70)
#' it$add_point(0.75, 60)
#' it$get_number_of_points()
#' it$get_value_at_time(0.5)
#'
#' @name IntensityTier
NULL

# ============================================================================
# Shared Method Dispatch Table
# ============================================================================

.intensitytier_methods <- new.env(hash = TRUE, parent = emptyenv())

# Query
.intensitytier_methods$get_start_time <- function(.self) .self$.cpp$get_xmin()
.intensitytier_methods$get_end_time <- function(.self) .self$.cpp$get_xmax()
.intensitytier_methods$get_number_of_points <- function(.self) .self$.cpp$get_number_of_points()
.intensitytier_methods$get_time_from_index <- function(.self, index) .self$.cpp$get_time(as.integer(index))
.intensitytier_methods$get_value_at_index <- function(.self, index) .self$.cpp$get_value(as.integer(index))
.intensitytier_methods$get_value_at_time <- function(.self, time) .self$.cpp$get_value_at_time(as.numeric(time))

.intensitytier_methods$get_mean <- function(.self, tmin = NULL, tmax = NULL) {
  if (is.null(tmin)) tmin <- .self$.cpp$get_xmin()
  if (is.null(tmax)) tmax <- .self$.cpp$get_xmax()
  .self$.cpp$get_mean_curve(as.numeric(tmin), as.numeric(tmax))
}

# Modification (self-returning)
.intensitytier_methods$add_point <- function(.self, time, value) {
  .self$.cpp$add_point(as.numeric(time), as.numeric(value))
  invisible(.self)
}
.intensitytier_methods$remove_point <- function(.self, index) {
  .self$.cpp$remove_point(as.integer(index))
  invisible(.self)
}

# Export
.intensitytier_methods$as_data_frame <- function(.self) {
  df <- .self$.cpp$as_data_frame()
  names(df) <- c("time", "intensity_db")
  df
}
.intensitytier_methods$save <- function(.self, path) {
  .self$.cpp$save(as.character(path))
  invisible(.self)
}

# Utility
.intensitytier_methods$get_xptr <- function(.self) .self$.xptr

# Display
.intensitytier_methods$print <- function(.self) {
  cat("<Praat IntensityTier>\n")
  cat(sprintf("  Time domain: %.3f to %.3f s\n", .self$.cpp$get_xmin(), .self$.cpp$get_xmax()))
  n_points <- .self$.cpp$get_number_of_points()
  cat(sprintf("  Number of points: %d\n", n_points))
  if (n_points > 0) {
    mean_int <- .self$.cpp$get_mean_curve(.self$.cpp$get_xmin(), .self$.cpp$get_xmax())
    cat(sprintf("  Mean intensity: %.1f dB\n", mean_int))
  }
  invisible(.self)
}

.intensitytier_methods$is_valid <- function(.self) .self$.cpp$is_valid()
lockEnvironment(.intensitytier_methods, bindings = TRUE)

# ============================================================================
# S3 Dispatch
# ============================================================================

#' @method $ IntensityTier
#' @export
`$.IntensityTier` <- function(x, name) {
  val <- .subset2(x, name)
  if (!is.null(val)) return(val)
  method <- .intensitytier_methods[[name]]
  if (is.null(method)) return(NULL)
  function(...) method(x, ...)
}

# ============================================================================
# Constructor
# ============================================================================

#' @export
IntensityTier <- function(tmin = NULL, tmax = NULL, .xptr = NULL) {
  if (!is.null(.xptr)) {
    ptr <- .xptr
  } else if (!is.null(tmin) && !is.null(tmax)) {
    ptr <- .intensitytier_create(as.numeric(tmin), as.numeric(tmax))
  } else {
    stop("Must provide either (tmin, tmax) or .xptr")
  }

  tier_mod <- get_module("intensitytier_module")
  cpp_obj <- tier_mod$RIntensityTier$new(ptr)

  structure(list(
    .cpp = cpp_obj,
    .xptr = ptr
  ), class = c("IntensityTier", "PraatObject"))
}

# ============================================================================
# S3 Methods
# ============================================================================

#' @export
as.data.frame.IntensityTier <- function(x, ...) x$as_data_frame()
