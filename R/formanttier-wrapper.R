#' @title Praat FormantTier Object
#' @description
#' Praat FormantTier object with direct C++ module binding for formant manipulation.
#'
#' @details
#' A FormantTier stores formant frequencies and bandwidths at discrete time points,
#' with interpolation between points. This allows for smooth formant contours
#' that can be used to filter sounds for vowel modification or resynthesis.
#'
#' ## Creating FormantTier Objects
#'
#' - `FormantTier(tmin, tmax)` - Create empty FormantTier
#' - `FormantTier$from_formant(formant)` - Convert from Formant object
#'
#' ## Querying
#'
#' - `$get_start_time()` - Start time in seconds
#' - `$get_end_time()` - End time in seconds
#' - `$get_duration()` - Duration in seconds
#' - `$get_number_of_points()` - Number of time points
#' - `$get_min_num_formants()` - Min formants across points
#' - `$get_max_num_formants()` - Max formants across points
#' - `$get_value_at_time(formant_number, time)` - Formant frequency (Hz)
#' - `$get_bandwidth_at_time(formant_number, time)` - Bandwidth (Hz)
#'
#' ## Transformation
#'
#' - `$filter_sound(sound, scale=TRUE)` - Filter sound through formants
#' - `$as_data_frame()` - Export to data frame
#' - `$save(path)` - Save to file
#'
#' @examples
#' \dontrun{
#' # Create from Formant analysis
#' sound <- Sound$read("vowel.wav")
#' formant <- sound$to_formant_burg()
#' ft <- FormantTier$from_formant(formant)
#'
#' # Query formant values
#' f1 <- ft$get_value_at_time(1, 0.5)  # F1 at 0.5s
#' f2 <- ft$get_value_at_time(2, 0.5)  # F2 at 0.5s
#'
#' # Filter a source sound
#' source <- Sound$create_tone(100, duration = 1.0)  # Buzz
#' vowel <- ft$filter_sound(source)
#' }
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
.formanttier_methods$get_number_of_points <- function(.self) .self$.cpp$get_number_of_points()
.formanttier_methods$get_min_num_formants <- function(.self) .self$.cpp$get_min_num_formants()
.formanttier_methods$get_max_num_formants <- function(.self) .self$.cpp$get_max_num_formants()

.formanttier_methods$get_value_at_time <- function(.self, formant_number, time) {
  .self$.cpp$get_value_at_time(as.integer(formant_number), as.numeric(time))
}

.formanttier_methods$get_bandwidth_at_time <- function(.self, formant_number, time) {
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
  if (!.self$.cpp$is_valid()) {
    cat("  [Invalid or deleted object]\n")
  } else {
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
#' \dontrun{
#' sound <- Sound$read("vowel.wav")
#' formant <- sound$to_formant_burg()
#' ft <- FormantTier$from_formant(formant)
#' print(ft)
#' }
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

#' @export
print.FormantTier <- function(x, ...) {
  x$print()
}

#' @export
as.data.frame.FormantTier <- function(x, ...) {
  x$as_data_frame()
}
