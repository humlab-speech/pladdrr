#' FormantModeler
#'
#' Robust formant trajectory modeling using polynomial fits with outlier
#'  detection.
#'
#' FormantModeler provides polynomial modeling of formant trajectories over
#'  time.
#' It automatically identifies outliers and can find the optimal formant ceiling
#' for a given sound, making it useful for robust formant analysis in noisy
#'  speech.
#'
#' @param .xptr Not for direct use. External pointer to the underlying C++
#'   FormantModeler object; set internally when a method returns a new
#'   FormantModeler.
#' @return A \code{FormantModeler} object with methods for polynomial modeling
#'  of
#'   formant trajectories with outlier detection.
#'
#' @examples
#' sound <- Sound$create_tone(frequency = 150, duration = 0.5)
#' formant <- sound$to_formant_burg()
#' modeler <- formant$to_formant_modeler(tmin = 0, tmax = 0, num_tracks = 3,
#'  num_params = 3)
#' r2 <- modeler$get_coefficient_of_determination(1, 3)
#' f1_modeled <- modeler$get_track_model_values(1)
#'
#' @name FormantModeler
NULL

# ============================================================================
# Shared Method Dispatch Table
# ============================================================================

.formantmodeler_methods <- new.env(hash = TRUE, parent = emptyenv())

# Query - Basic properties
.formantmodeler_methods$get_xmin <- function(.self) .self$.cpp$get_xmin()
.formantmodeler_methods$get_xmax <- function(.self) .self$.cpp$get_xmax()
.formantmodeler_methods$get_duration <- function(
  .self) .self$.cpp$get_duration()
.formantmodeler_methods$get_number_of_tracks <- function(
  .self) .self$.cpp$get_number_of_tracks()
.formantmodeler_methods$get_number_of_data_points <- function(
  .self) .self$.cpp$get_number_of_data_points()
.formantmodeler_methods$get_number_of_parameters <- function(.self, track) {
  .self$.cpp$get_number_of_parameters(as.integer(track))
}
.formantmodeler_methods$get_number_of_invalid_data_points <- function(.self,
  track) {
  .self$.cpp$get_number_of_invalid_data_points(as.integer(track))
}

# Quality metrics
.formantmodeler_methods$get_coefficient_of_determination <- function(.self,
  from_track = 1, to_track = 0) {
  if (to_track == 0) to_track <- .self$.cpp$get_number_of_tracks()
  .self$.cpp$get_coefficient_of_determination(as.integer(from_track),
    as.integer(to_track))
}
.formantmodeler_methods$get_r_squared <- function(.self, from_track = 1,
  to_track = 0) {
  if (to_track == 0) to_track <- .self$.cpp$get_number_of_tracks()
  .self$.cpp$get_coefficient_of_determination(as.integer(from_track),
    as.integer(to_track))
}
.formantmodeler_methods$get_standard_deviation <- function(.self, track) {
  .self$.cpp$get_standard_deviation(as.integer(track))
}
.formantmodeler_methods$get_residual_sum_of_squares <- function(.self, track) {
  .self$.cpp$get_residual_sum_of_squares(as.integer(track))
}
.formantmodeler_methods$get_stress <- function(.self, from_track = 1,
  to_track = 0,
                                                num_params_per_track = 5, power = 1.25) {
  if (to_track == 0) to_track <- .self$.cpp$get_number_of_tracks()
  .self$.cpp$get_stress(as.integer(from_track), as.integer(to_track),
                        as.integer(num_params_per_track), power)
}
.formantmodeler_methods$get_weighted_mean <- function(.self, track) {
  .self$.cpp$get_weighted_mean(as.integer(track))
}

# Value queries
.formantmodeler_methods$get_model_value_at_time <- function(.self, track,
  time) {
  .self$.cpp$get_model_value_at_time(as.integer(track), as.numeric(time))
}
.formantmodeler_methods$get_estimated_value_at_time <- function(.self, track,
  time) {
  .self$.cpp$get_estimated_value_at_time(as.integer(track), as.numeric(time))
}
.formantmodeler_methods$get_data_point_value <- function(.self, track, index) {
  .self$.cpp$get_data_point_value(as.integer(track), as.integer(index))
}
.formantmodeler_methods$get_data_point_sigma <- function(.self, track, index) {
  .self$.cpp$get_data_point_sigma(as.integer(track), as.integer(index))
}
.formantmodeler_methods$get_track_model_values <- function(.self, track) {
  .self$.cpp$get_track_model_values(as.integer(track))
}

# Operations
.formantmodeler_methods$fit <- function(.self) {
  .self$.cpp$fit()
  invisible(.self)
}
.formantmodeler_methods$to_formant <- function(.self, estimate = TRUE,
  estimate_undefined = TRUE) {
  formant_ptr <- .self$.cpp$to_formant_ptr(estimate, estimate_undefined)
  Formant(.xptr = formant_ptr)
}
.formantmodeler_methods$process_outliers <- function(.self, num_sigmas = 3.0) {
  new_ptr <- .self$.cpp$process_outliers_ptr(num_sigmas)
  FormantModeler(.xptr = new_ptr)
}

# Export
.formantmodeler_methods$as_data_frame <- function(
  .self) .self$.cpp$as_data_frame()
.formantmodeler_methods$get_info <- function(.self) .self$.cpp$get_info()

# Utility
.formantmodeler_methods$get_xptr <- function(.self) .self$.xptr
.formantmodeler_methods$save <- function(.self, path) {
  .self$.cpp$save(path)
  invisible(.self)
}

# Display
.formantmodeler_methods$print <- function(.self) {
  info <- .self$.cpp$get_info()
  cat("<Praat FormantModeler>\n")
  cat(
    sprintf("  Time: %.3f - %.3f s (%.3f s)\n", info$xmin, info$xmax,
      info$xmax - info$xmin))
  cat(
    sprintf("  Tracks: %d, Data points: %d\n", info$n_tracks,
      info$n_data_points))
  cat("  Track R-squared: ")
  cat(sprintf("%.3f", info$track_r2), sep = ", ")
  cat("\n")
  invisible(.self)
}

.formantmodeler_methods$is_valid <- function(.self) .self$.cpp$is_valid()
lockEnvironment(.formantmodeler_methods, bindings = TRUE)

# ============================================================================
# S3 Dispatch
# ============================================================================

#' @method $ FormantModeler
#' @export
`$.FormantModeler` <- function(x, name) {
  val <- .subset2(x, name)
  if (!is.null(val)) return(val)
  method <- .formantmodeler_methods[[name]]
  if (is.null(method)) return(NULL)
  function(...) method(x, ...)
}

# ============================================================================
# Constructor
# ============================================================================

#' @export
FormantModeler <- function(.xptr = NULL) {
  if (is.null(.xptr)) {
    stop(
      "FormantModeler objects must be created from a Formant object using formant$to_formant_modeler()")
  }

  fm_mod <- get_module("formantmodeler_module")
  cpp_obj <- fm_mod$RFormantModeler$new(.xptr)

  structure(list(
    .cpp = cpp_obj,
    .xptr = .xptr
  ), class = c("FormantModeler", "PraatObject"))
}
