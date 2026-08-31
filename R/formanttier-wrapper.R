#' FormantTier
#'
#' Praat FormantTier object: formant frequencies and bandwidths at discrete
#' time points, with interpolation between points.
#'
#' The interpolated contour can be used to filter sounds for vowel
#' modification or resynthesis.
#'
#' @section Usage:
#' \preformatted{
#' FormantTier(tmin, tmax)              # create an empty FormantTier
#' FormantTier$from_formant(formant)    # convert from a Formant object
#' }
#'
#' @section Query methods:
#' \itemize{
#' \item \code{get_start_time()}, \code{get_end_time()}, \code{get_duration()} -
#  time range in seconds
#'   \item \code{get_number_of_points()} - number of time points
#' \item \code{get_min_num_formants()}, \code{get_max_num_formants()} - formant
#  count across points
#' \item \code{get_value_at_time(formant_number, time)} - formant frequency in
#  Hz
#'   \item \code{get_bandwidth_at_time(formant_number, time)} - bandwidth in Hz
#' }
#'
#' @section Transformation:
#' \itemize{
#' \item \code{filter_sound(sound, scale = TRUE)} - filter a sound through the
#  formants
#'   \item \code{as_data_frame()} - export to a data frame
#'   \item \code{save(path)} - save to file
#' }
#'
#' @param tmin Start time in seconds. Default 0.
#' @param tmax End time in seconds. Default 1.
#' @param .xptr Not for direct use. External pointer to the underlying C++
#'   FormantTier object; set internally when a method returns a new FormantTier.
#' @return A \code{FormantTier} object with methods for formant frequency and
#'   bandwidth manipulation via time-value points.
#'
#' @examples
#' # Create from Formant analysis
#' sound <- Sound$create_tone(frequency = 150, duration = 0.5)
#' formant <- sound$to_formant_burg()
#' ft <- FormantTier$from_formant(formant)
#'
#' # Query formant values
#' f1 <- ft$get_value_at_time(1, 0.25)  # F1 at 0.25s
#' f2 <- ft$get_value_at_time(2, 0.25)  # F2 at 0.25s
#'
#' # Filter a source sound
#' source <- Sound$create_tone(frequency = 100, duration = 0.5)  # Buzz
#' vowel <- ft$filter_sound(source)
#'
#' @name FormantTier
NULL

# ============================================================================
# Shared Method Dispatch Table
# ============================================================================

.formanttier_methods <- new.env(hash = TRUE, parent = emptyenv())

# Query
.formanttier_methods$get_start_time <- function(.self) .self$.cpp$get_xmin()
.formanttier_methods$get_end_time <- function(.self) .self$.cpp$get_xmax()
.formanttier_methods$get_duration <- function(.self) .self$.cpp$get_duration()
.formanttier_methods$get_number_of_points <- function(
  .self) .self$.cpp$get_number_of_points()
.formanttier_methods$get_min_num_formants <- function(
  .self) .self$.cpp$get_min_num_formants()
.formanttier_methods$get_max_num_formants <- function(
  .self) .self$.cpp$get_max_num_formants()

.formanttier_methods$get_value_at_time <- function(.self, formant_number,
  time) {
  .self$.cpp$get_value_at_time(as.integer(formant_number), as.numeric(time))
}

.formanttier_methods$get_bandwidth_at_time <- function(.self, formant_number,
  time) {
  .self$.cpp$get_bandwidth_at_time(as.integer(formant_number), as.numeric(time))
}

# Transformation
.formanttier_methods$filter_sound <- function(.self, sound, scale = TRUE) {
  if (!inherits(sound, "Sound")) stop("sound must be a Sound object")
  result_ptr <- .self$.cpp$filter_sound_ptr(sound$.xptr, scale)
  Sound(.xptr = result_ptr)
}

# Export
.formanttier_methods$as_data_frame <- function(.self) .self$.cpp$as_data_frame()

.formanttier_methods$save <- function(.self, path) {
  .self$.cpp$save(as.character(path))
  invisible(.self)
}

# Compatibility
.formanttier_methods$is_valid <- function(.self) .self$.cpp$is_valid()
.formanttier_methods$get_ptr <- function(.self) .self$.xptr
.formanttier_methods$get_xptr <- function(.self) .self$.xptr

# Display
.formanttier_methods$print <- function(.self) {
  cat("<Praat FormantTier>\n")
  if (.self$.cpp$is_valid()) {
    cat(sprintf("  Time domain: %.3f - %.3f seconds\n",
                .self$.cpp$get_xmin(), .self$.cpp$get_xmax()))
    cat("  Number of points:", .self$.cpp$get_number_of_points(), "\n")
    nf_min <- .self$.cpp$get_min_num_formants()
    nf_max <- .self$.cpp$get_max_num_formants()
    if (nf_min == nf_max) {
      cat("  Formants per point:", nf_min, "\n")
    } else {
      cat("  Formants per point:", nf_min, "-", nf_max, "\n")
    }
  } else {
    cat("  [Invalid or deleted object]\n")
  }
  invisible(.self)
}

lockEnvironment(.formanttier_methods, bindings = TRUE)

# ============================================================================
# S3 Dispatch
# ============================================================================

#' @method $ FormantTier
#' @export
`$.FormantTier` <- function(x, name) {
  val <- .subset2(x, name)
  if (!is.null(val)) return(val)
  method <- .formanttier_methods[[name]]
  if (is.null(method)) return(NULL)
  function(...) method(x, ...)
}

# ============================================================================
# Constructor
# ============================================================================

#' @export
FormantTier <- function(tmin = 0, tmax = 1, .xptr = NULL) {
  if (!is.null(.xptr)) {
    ptr <- .xptr
  } else {
    ptr <- .formanttier_create(as.numeric(tmin), as.numeric(tmax))
  }

  tier_mod <- get_module("formanttier_module")
  cpp_obj <- tier_mod$RFormantTier$new(ptr)

  structure(list(
    .cpp = cpp_obj,
    .xptr = ptr
  ), class = c("FormantTier", "PraatObject"))
}

# ============================================================================
# Static Methods (backward compatibility: FormantTier$from_formant)
# ============================================================================

#' Create FormantTier from Formant
#' @param formant Formant object to convert
#' @return FormantTier object
#' @export
#' @examples
#' sound <- Sound$create_tone(frequency = 220, duration = 0.5, sampling_rate =
#  16000)
#' formant <- sound$to_formant_burg()
#' ft <- FormantTier$from_formant(formant)
#' print(ft)
formanttier_from_formant <- function(formant) {
  if (!inherits(formant, "Formant")) stop("formant must be a Formant object")
  ptr <- .formanttier_from_formant(formant$.xptr)
  FormantTier(.xptr = ptr)
}

.formanttier_static_env <- new.env(parent = emptyenv())
.formanttier_static_env$from_formant <- formanttier_from_formant
.formanttier_static_env$new <- FormantTier

#' @exportS3Method "$" formanttier_constructor
`$.formanttier_constructor` <- function(x, name) {
  .formanttier_static_env[[name]]
}

class(FormantTier) <- c("formanttier_constructor", "function")

# ============================================================================
# S3 Methods
# ============================================================================
