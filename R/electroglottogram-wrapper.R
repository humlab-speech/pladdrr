#' Electroglottogram
#'
#' Praat Electroglottogram (EGG) object. Measures electrical impedance across
#' the larynx, varying with vocal fold contact during phonation.
#'
#' Electroglottogram inherits from Sound and represents a specialized
#' single-channel sound that records vocal fold contact area.
#'
#' @param .xptr Not for direct use. External pointer to the underlying C++
#'   Electroglottogram object; set internally when a method returns a new
#'   Electroglottogram.
#' @return An \code{Electroglottogram} object (triple-class
#'  \code{c("Electroglottogram",
#' "Sound", "PraatObject")}) that inherits Sound's methods in addition to its
#'  own.
#'
#' @examples
#' egg <- electroglottogram_create(xmin = 0, xmax = 1, nx = 16000, dx = 1 /
#'  16000, x1 = 0)
#' egg$get_duration()
#' egg$get_number_of_samples()
#' egg$is_valid()
#'
#' @name Electroglottogram
NULL

# ============================================================================
# Shared Method Dispatch Table
# ============================================================================

.egg_methods <- new.env(hash = TRUE, parent = emptyenv())

# Query methods (inherited from Sound via module)
.egg_methods$get_xmin <- function(.self) .self$.cpp$get_xmin()
.egg_methods$get_xmax <- function(.self) .self$.cpp$get_xmax()
.egg_methods$get_duration <- function(.self) .self$.cpp$get_duration()
.egg_methods$get_nx <- function(.self) .self$.cpp$get_nx()
.egg_methods$get_dx <- function(.self) .self$.cpp$get_dx()
.egg_methods$get_x1 <- function(.self) .self$.cpp$get_x1()
.egg_methods$get_number_of_samples <- function(
  .self) .self$.cpp$get_number_of_samples()
.egg_methods$get_sample_period <- function(.self) .self$.cpp$get_sample_period()
.egg_methods$get_sample_rate <- function(.self) .self$.cpp$get_sample_rate()
.egg_methods$get_value_at_sample <- function(.self, sample) {
  .self$.cpp$get_value_at_sample(as.integer(sample))
}
.egg_methods$get_value_at_time <- function(.self, time) {
  .self$.cpp$get_value_at_time(as.numeric(time))
}
.egg_methods$get_time_from_sample <- function(.self, sample) {
  .self$.cpp$get_time_from_sample(as.integer(sample))
}
.egg_methods$get_sample_from_time <- function(.self, time) {
  .self$.cpp$get_sample_from_time(as.numeric(time))
}
.egg_methods$is_valid <- function(.self) .self$.cpp$is_valid()

# Closed glottis detection
.egg_methods$to_textgrid_closed_glottis <- function(.self, pitch_floor = 75,
                                                     pitch_ceiling = 500,
                                                     closing_threshold = 0.3,
                                                     peak_threshold = 0.05) {
  ptr <- .self$.cpp$to_textgrid_closed_glottis_ptr(
    as.numeric(pitch_floor), as.numeric(pitch_ceiling),
    as.numeric(closing_threshold), as.numeric(peak_threshold)
  )
  TextGrid(.xptr = ptr)
}

# Amplitude tier levels
.egg_methods$to_amplitude_tier_levels <- function(.self, pitch_floor = 75,
                                                   pitch_ceiling = 500,
                                                   closing_threshold = 0.3) {
  result_list <- .self$.cpp$to_amplitude_tier_levels(
    as.numeric(pitch_floor), as.numeric(pitch_ceiling),
    as.numeric(closing_threshold)
  )
  list(
    levels = AmplitudeTier(.xptr = result_list$levels),
    peaks = AmplitudeTier(.xptr = result_list$peaks),
    valleys = AmplitudeTier(.xptr = result_list$valleys)
  )
}

# Derivative (DEGG)
.egg_methods$derivative <- function(.self, lowpass_freq = 5000,
                                     smoothing = 100, peak_amplitude = 0) {
  ptr <- .self$.cpp$derivative_ptr(
    as.numeric(lowpass_freq), as.numeric(smoothing), as.numeric(peak_amplitude)
  )
  Sound(.xptr = ptr)
}

# First central difference
.egg_methods$first_central_difference <- function(.self, peak_amplitude = 0) {
  ptr <- .self$.cpp$first_central_difference_ptr(as.numeric(peak_amplitude))
  Sound(.xptr = ptr)
}

# High-pass filter
.egg_methods$high_pass_filter <- function(.self, from_freq = 100,
  smoothing = 100) {
  ptr <- .self$.cpp$high_pass_filter_ptr(
    as.numeric(from_freq), as.numeric(smoothing)
  )
  Electroglottogram(.xptr = ptr)
}

# Convert to Sound
.egg_methods$to_sound <- function(.self) {
  ptr <- .self$.cpp$to_sound_ptr()
  Sound(.xptr = ptr)
}

# Export methods
.egg_methods$as_vector <- function(.self) .self$.cpp$as_vector()
.egg_methods$as_data_frame <- function(.self) .self$.cpp$as_data_frame()
.egg_methods$get_info <- function(.self) .self$.cpp$get_info()
.egg_methods$save <- function(.self, path) {
  .self$.cpp$save(as.character(path))
  invisible(.self)
}
.egg_methods$get_xptr <- function(.self) .self$.xptr

# Print
.egg_methods$print <- function(.self) {
  cat("<Praat Electroglottogram>\n")
  cat(sprintf("  Duration: %.3f s\n", .self$.cpp$get_duration()))
  cat(sprintf("  Samples: %d\n", .self$.cpp$get_number_of_samples()))
  cat(sprintf("  Sample rate: %.1f Hz\n", .self$.cpp$get_sample_rate()))
  invisible(.self)
}

lockEnvironment(.egg_methods, bindings = TRUE)

# ============================================================================
# S3 Dispatch
# ============================================================================

#' @method $ Electroglottogram
#' @export
`$.Electroglottogram` <- function(x, name) {
  val <- .subset2(x, name)
  if (!is.null(val)) return(val)
  # Compat alias
  if (name == ".pointer") return(.subset2(x, ".xptr"))
  method <- .egg_methods[[name]]
  if (is.null(method)) return(NULL)
  function(...) method(x, ...)
}

# ============================================================================
# Constructor
# ============================================================================

#' @export
Electroglottogram <- function(.xptr = NULL) {
  if (is.null(.xptr)) {

      stop("Electroglottogram objects must be created using ",
         "sound$extract_electroglottogram() or electroglottogram_create()")
  }
  
  egg_mod <- get_module("electroglottogram_module")
  cpp_obj <- egg_mod$RElectroglottogram$new(.xptr)
  
  structure(list(
    .cpp = cpp_obj,
    .xptr = .xptr
  ), class = c("Electroglottogram", "Sound", "PraatObject"))
}

#' Create an Electroglottogram object
#'
#' @inheritParams pladdrr_shared_params xmin
#' @inheritParams pladdrr_shared_params xmax
#' @param nx Number of samples
#' @param dx Sampling period in seconds
#' @param x1 Time of first sample in seconds
#' @return Electroglottogram object
#' @examples
#' egg <- electroglottogram_create(xmin = 0, xmax = 1, nx = 16000, dx = 1 /
#'  16000, x1 = 0)
#' egg$get_duration()
#' @export
electroglottogram_create <- function(xmin, xmax, nx, dx, x1) {
  ptr <- electroglottogram_create_cpp(xmin, xmax, nx, dx, x1)
  Electroglottogram(.xptr = ptr)
}
