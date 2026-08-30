#' DurationTier
#'
#' Praat DurationTier object for duration manipulation, created via direct
#' C++ module binding.
#'
#' DurationTiers are used together with Manipulation objects to modify the
#' duration/tempo of sounds. Values represent duration multiplication factors:
#' \itemize{
#'   \item 1.0 - normal speed
#'   \item 2.0 - half speed (doubled duration)
#'   \item 0.5 - double speed (halved duration)
#' }
#'
#' @param tmin Start time in seconds. Used with \code{tmax} to create a new, empty DurationTier.
#' @param tmax End time in seconds. Used with \code{tmin} to create a new, empty DurationTier.
#' @param .xptr Not for direct use. External pointer to the underlying C++
#'   DurationTier object; set internally when a method returns a new DurationTier.
#' @return A \code{DurationTier} object with methods for duration and tempo manipulation via time-value points.
#'
#' @examples
#' dt <- DurationTier(0, 1)
#' dt$add_point(0.25, 1.0)
#' dt$add_point(0.75, 1.5)
#' dt$get_number_of_points()
#' dt$get_value_at_time(0.5)
#'
#' @name DurationTier
NULL

# ============================================================================
# Shared Method Dispatch Table
# ============================================================================

.durationtier_methods <- new.env(hash = TRUE, parent = emptyenv())

# Query
.durationtier_methods$get_start_time <- function(.self) .self$.cpp$get_xmin()
.durationtier_methods$get_end_time <- function(.self) .self$.cpp$get_xmax()
.durationtier_methods$get_number_of_points <- function(.self) .self$.cpp$get_number_of_points()
.durationtier_methods$get_time_from_index <- function(.self, index) .self$.cpp$get_time(as.integer(index))
.durationtier_methods$get_value_at_index <- function(.self, index) .self$.cpp$get_value(as.integer(index))
.durationtier_methods$get_value_at_time <- function(.self, time) .self$.cpp$get_value_at_time(as.numeric(time))

.durationtier_methods$get_mean <- function(.self, tmin = NULL, tmax = NULL) {
  if (is.null(tmin)) tmin <- .self$.cpp$get_xmin()
  if (is.null(tmax)) tmax <- .self$.cpp$get_xmax()
  .self$.cpp$get_mean_curve(as.numeric(tmin), as.numeric(tmax))
}

# Modification (self-returning)
.durationtier_methods$add_point <- function(.self, time, value) {
  .self$.cpp$add_point(as.numeric(time), as.numeric(value))
  invisible(.self)
}
.durationtier_methods$remove_point <- function(.self, index) {
  .self$.cpp$remove_point(as.integer(index))
  invisible(.self)
}

# Export
.durationtier_methods$as_data_frame <- function(.self) {
  n_points <- .self$.cpp$get_number_of_points()
  if (n_points == 0) {
    return(data.frame(time = numeric(0), duration_factor = numeric(0)))
  }
  times <- numeric(n_points)
  values <- numeric(n_points)
  for (i in seq_len(n_points)) {
    times[i] <- .self$.cpp$get_time(i)
    values[i] <- .self$.cpp$get_value(i)
  }
  data.frame(time = times, duration_factor = values)
}
.durationtier_methods$save <- function(.self, path) {
  .durationtier_save(.self$.xptr, as.character(path))
  invisible(.self)
}

# Utility
.durationtier_methods$get_xptr <- function(.self) .self$.xptr

# Display
.durationtier_methods$print <- function(.self) {
  cat("<Praat DurationTier>\n")
  cat(sprintf("  Time domain: %.3f to %.3f s\n", .self$.cpp$get_xmin(), .self$.cpp$get_xmax()))
  cat(sprintf("  Number of points: %d\n", .self$.cpp$get_number_of_points()))
  invisible(.self)
}

.durationtier_methods$is_valid <- function(.self) .self$.cpp$is_valid()
lockEnvironment(.durationtier_methods, bindings = TRUE)

# ============================================================================
# S3 Dispatch
# ============================================================================

#' @method $ DurationTier
#' @export
`$.DurationTier` <- function(x, name) {
  val <- .subset2(x, name)
  if (!is.null(val)) return(val)
  method <- .durationtier_methods[[name]]
  if (is.null(method)) return(NULL)
  function(...) method(x, ...)
}

# ============================================================================
# Constructor
# ============================================================================

#' @export
DurationTier <- function(tmin = NULL, tmax = NULL, .xptr = NULL) {
  if (!is.null(.xptr)) {
    ptr <- .xptr
  } else if (!is.null(tmin) && !is.null(tmax)) {
    ptr <- .durationtier_create(as.numeric(tmin), as.numeric(tmax))
  } else {
    stop("Must provide either (tmin, tmax) or .xptr")
  }

  tier_mod <- get_module("durationtier_module")
  cpp_obj <- tier_mod$RDurationTier$new(ptr)

  structure(list(
    .cpp = cpp_obj,
    .xptr = ptr
  ), class = c("DurationTier", "PraatObject"))
}

# ============================================================================
# S3 Methods
# ============================================================================

#' @export
as.data.frame.DurationTier <- function(x, ...) x$as_data_frame()
