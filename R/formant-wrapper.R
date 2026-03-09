# formant-wrapper.R - Formant object using shared dispatch table (pladdrr 4.8.33)
# Architecture: minimal list + $.Formant S3 dispatch → shared method env

#' Formant Class
#'
#' Praat Formant object with direct C++ module binding. Formant objects represent
#' the resonance frequencies of the vocal tract over time.
#'
#' @examples
#' \dontrun{
#' sound <- Sound("example.wav")
#' formant <- sound$to_formant_burg(
#'   time_step = 0.01, max_number_of_formants = 5,
#'   maximum_formant = 5500, window_length = 0.025, pre_emphasis_from = 50
#' )
#' f1_at_1s <- formant$get_value_at_time(formant_number = 1, time = 1.0, unit = "hertz")
#' mean_f1 <- formant$get_mean(formant_number = 1, from_time = 0, to_time = 0, unit = "hertz")
#' }
#'
#' @name Formant
NULL

# ============================================================================
# Shared Method Dispatch Table
# ============================================================================

.formant_methods <- new.env(hash = TRUE, parent = emptyenv())

# Helper: formant unit code
.formant_unit_code <- function(unit) {
  unit <- match.arg(tolower(unit), c("hertz", "bark"))
  if (unit == "hertz") 0L else 1L
}

# --- Time domain ---
.formant_methods$get_xmin <- function(.self) .self$.cpp$get_xmin()
.formant_methods$get_xmax <- function(.self) .self$.cpp$get_xmax()
.formant_methods$get_start_time <- function(.self) .self$.cpp$get_xmin()
.formant_methods$get_end_time <- function(.self) .self$.cpp$get_xmax()
.formant_methods$get_duration <- function(.self) .self$.cpp$get_xmax() - .self$.cpp$get_xmin()
.formant_methods$get_number_of_frames <- function(.self) .self$.cpp$get_number_of_frames()
.formant_methods$get_time_step <- function(.self) .self$.cpp$get_time_step()
.formant_methods$get_min_num_formants <- function(.self) .self$.cpp$get_min_num_formants()
.formant_methods$get_minimum_number_of_formants <- function(.self) .self$.cpp$get_min_num_formants()
.formant_methods$get_max_num_formants <- function(.self) .self$.cpp$get_max_num_formants()

# --- Query ---
.formant_methods$get_value_at_time <- function(.self, formant_number, time, unit = c("hertz", "bark"),
                                               interpolation = c("linear", "nearest")) {
  unit <- match.arg(unit)
  interpolation <- match.arg(interpolation)
  .self$.cpp$get_value_at_time(as.integer(formant_number), time, .formant_unit_code(unit))
}
.formant_methods$get_bandwidth_at_time <- function(.self, formant_number, time, unit = c("hertz", "bark")) {
  unit <- match.arg(unit)
  .self$.cpp$get_bandwidth_at_time(as.integer(formant_number), time, .formant_unit_code(unit))
}
.formant_methods$get_mean <- function(.self, formant_number, from_time = 0, to_time = 0, unit = c("hertz", "bark")) {
  unit <- match.arg(unit)
  .self$.cpp$get_mean(as.integer(formant_number), from_time, to_time, .formant_unit_code(unit))
}
.formant_methods$get_standard_deviation <- function(.self, formant_number, from_time = 0, to_time = 0,
                                                    unit = c("hertz", "bark")) {
  unit <- match.arg(unit)
  .self$.cpp$get_standard_deviation(as.integer(formant_number), from_time, to_time, .formant_unit_code(unit))
}
.formant_methods$get_quantile <- function(.self, formant_number, quantile, from_time = 0, to_time = 0,
                                          unit = c("hertz", "bark")) {
  unit <- match.arg(unit)
  .self$.cpp$get_quantile(as.integer(formant_number), quantile, from_time, to_time, .formant_unit_code(unit))
}
.formant_methods$get_minimum <- function(.self, formant_number, from_time = 0, to_time = 0,
                                         unit = c("hertz", "bark"), interpolate = FALSE) {
  unit <- match.arg(unit)
  .self$.cpp$get_minimum(as.integer(formant_number), from_time, to_time, .formant_unit_code(unit), interpolate)
}
.formant_methods$get_maximum <- function(.self, formant_number, from_time = 0, to_time = 0,
                                         unit = c("hertz", "bark"), interpolate = FALSE) {
  unit <- match.arg(unit)
  .self$.cpp$get_maximum(as.integer(formant_number), from_time, to_time, .formant_unit_code(unit), interpolate)
}
.formant_methods$get_time_of_minimum <- function(.self, formant_number, from_time = 0, to_time = 0,
                                                  unit = c("hertz", "bark"), interpolate = FALSE) {
  unit <- match.arg(unit)
  .self$.cpp$get_time_of_minimum(as.integer(formant_number), from_time, to_time, .formant_unit_code(unit), interpolate)
}
.formant_methods$get_time_of_maximum <- function(.self, formant_number, from_time = 0, to_time = 0,
                                                  unit = c("hertz", "bark"), interpolate = FALSE) {
  unit <- match.arg(unit)
  .self$.cpp$get_time_of_maximum(as.integer(formant_number), from_time, to_time, .formant_unit_code(unit), interpolate)
}

# --- Batch/Vectorized ---
.formant_methods$get_times_vector <- function(.self) .self$.cpp$get_times_vector()
.formant_methods$get_formant_track <- function(.self, formant_number, unit = c("hertz", "bark")) {
  unit <- match.arg(unit)
  .self$.cpp$get_formant_track(as.integer(formant_number), .formant_unit_code(unit))
}
.formant_methods$get_bandwidth_track <- function(.self, formant_number, unit = c("hertz", "bark")) {
  unit <- match.arg(unit)
  .self$.cpp$get_bandwidth_track(as.integer(formant_number), .formant_unit_code(unit))
}
.formant_methods$get_values_at_times <- function(.self, formant_number, times, unit = c("hertz", "bark"),
                                                  interpolation = c("linear", "nearest")) {
  unit <- match.arg(unit)
  interpolation <- match.arg(interpolation)
  .self$.cpp$get_values_at_times(as.integer(formant_number), as.numeric(times), .formant_unit_code(unit))
}
.formant_methods$get_all_values_at_time <- function(.self, time, max_formants = 5, unit = c("hertz", "bark")) {
  unit <- match.arg(unit)
  uc <- .formant_unit_code(unit)
  vapply(seq_len(max_formants), function(i) {
    .self$.cpp$get_value_at_time(as.integer(i), as.numeric(time), uc)
  }, numeric(1))
}
.formant_methods$get_all_formant_tracks <- function(.self, max_formants = 5, unit = c("hertz", "bark")) {
  unit <- match.arg(unit)
  .self$.cpp$get_all_formant_tracks(as.integer(max_formants), .formant_unit_code(unit))
}

# --- Export ---
.formant_methods$as_data_frame <- function(.self, max_formants = 5) {
  .self$.cpp$as_data_frame(as.integer(max_formants))
}
.formant_methods$save <- function(.self, filepath) {
  .self$.cpp$save(filepath)
  invisible(.self)
}

# --- Advanced ---
.formant_methods$track <- function(.self, number_of_tracks = 3,
                                   ref_f1 = 550.0, ref_f2 = 1650.0, ref_f3 = 2750.0,
                                   ref_f4 = 3850.0, ref_f5 = 4950.0,
                                   frequency_cost = 1.0, bandwidth_cost = 1.0, transition_cost = 1.0) {
  tracked_ptr <- .formant_tracker(
    .self$.xptr, as.integer(number_of_tracks),
    ref_f1, ref_f2, ref_f3, ref_f4, ref_f5,
    frequency_cost, bandwidth_cost, transition_cost
  )
  Formant(.xptr = tracked_ptr)
}
.formant_methods$to_formantgrid <- function(.self) {
  grid_ptr <- .formantgrid_from_formant(.self$.xptr)
  FormantGrid(.xptr = grid_ptr)
}
.formant_methods$down_to_table <- function(.self, include_frame_numbers = TRUE,
                                           include_time = TRUE, time_decimals = 6,
                                           include_intensity = TRUE, intensity_decimals = 3,
                                           include_number_of_formants = TRUE, frequency_decimals = 3,
                                           include_bandwidths = TRUE) {
  table_ptr <- .formant_down_to_table(
    .self$.xptr, include_frame_numbers,
    include_time, as.integer(time_decimals),
    include_intensity, as.integer(intensity_decimals),
    include_number_of_formants, as.integer(frequency_decimals),
    include_bandwidths
  )
  Table(.xptr = table_ptr)
}
.formant_methods$to_formant_modeler <- function(.self, tmin = 0.0, tmax = 0.0, num_tracks = 4, num_params = 5) {
  if (tmax == 0.0) tmax <- .self$.cpp$get_xmax()
  fm_mod <- get_module("formantmodeler_module")
  fm_ptr <- fm_mod$Formant_to_FormantModeler(
    .self$.xptr, tmin, tmax, as.integer(num_tracks), as.integer(num_params)
  )
  FormantModeler(.xptr = fm_ptr)
}

# --- Print ---
.formant_methods$print <- function(.self) {
  cat("<Praat Formant object>\n")
  cat(sprintf("  Number of frames: %d\n", .self$.cpp$get_number_of_frames()))
  cat(sprintf("  Time step: %.6f s\n", .self$.cpp$get_time_step()))
  cat(sprintf("  Min formants: %d\n", .self$.cpp$get_min_num_formants()))
  cat(sprintf("  Max formants: %d\n", .self$.cpp$get_max_num_formants()))
  invisible(.self)
}

.formant_methods$is_valid <- function(.self) .self$.cpp$is_valid()
lockEnvironment(.formant_methods, bindings = TRUE)

# ============================================================================
# Constructor
# ============================================================================

#' @export
Formant <- function(.xptr = NULL) {
  if (is.null(.xptr)) {
    stop("Formant objects must be created from a Sound object using to_formant_burg() or to_formant_keepall()")
  }
  formant_mod <- get_module("formant_module")
  cpp_obj <- formant_mod$RFormant$new(.xptr)
  structure(list(.xptr = .xptr, .cpp = cpp_obj), class = c("Formant", "PraatObject"))
}

# ============================================================================
# S3 Dispatch
# ============================================================================

#' @method $ Formant
#' @export
`$.Formant` <- function(x, name) {
  val <- .subset2(x, name)
  if (!is.null(val)) return(val)
  if (name == ".pointer") return(.subset2(x, ".xptr"))
  method <- .formant_methods[[name]]
  if (is.null(method)) return(NULL)
  function(...) method(x, ...)
}

# S3 methods
#' @export
print.Formant <- function(x, ...) x$print()

#' @export
as.data.frame.Formant <- function(x, ..., max_formants = 5) {
  x$as_data_frame(max_formants)
}
