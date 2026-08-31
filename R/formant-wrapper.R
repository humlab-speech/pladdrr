# formant-wrapper.R - Formant object using shared dispatch table (pladdrr
#  4.8.33)
# Architecture: minimal list + $.Formant S3 dispatch → shared method env

#' Formant
#'
#' Formant objects represent vocal tract resonance frequencies over time.
#' Created from a Sound via formant tracking algorithms (Burg, Split-Levinson,
#' or Willems). Formant frequencies and bandwidths are the primary acoustic
#' correlates of vowel quality in speech.
#'
#' @section Information:
#' \itemize{
#'   \item \code{get_number_of_frames()} - number of analysis frames
#'   \item \code{get_time_step()} - time step between frames (s)
#' \item \code{get_min_num_formants()}, \code{get_max_num_formants()} - formant
#'  count range per frame
#' }
#'
#' @section Point queries (single time):
#' \itemize{
#' \item \code{get_value_at_time(formant_number, time, unit)} - formant
#'  frequency at time
#' \item \code{get_bandwidth_at_time(formant_number, time, unit)} - formant
#'  bandwidth at time
#' \item \code{get_all_values_at_time(time, max_formants, unit)} - all formant
#'  values at a time point
#' }
#'
#' @section Statistics (over time range):
#' \itemize{
#' \item \code{get_mean(formant_number, from_time, to_time, unit)} - mean
#'  formant frequency
#' \item \code{get_standard_deviation(formant_number, from_time, to_time, unit)}
#'  - standard deviation
#' \item \code{get_minimum(formant_number, from_time, to_time, unit)} - minimum
#'  value
#' \item \code{get_maximum(formant_number, from_time, to_time, unit)} - maximum
#'  value
#' \item \code{get_quantile(formant_number, quantile, from_time, to_time, unit)}
#'  - quantile
#' \item \code{get_time_of_minimum(...)}, \code{get_time_of_maximum(...)} - time
#'  of extremum
#' }
#'
#' @section Batch and vectorized:
#' \itemize{
#' \item \code{get_formant_track(formant_number, unit)} - full track for one
#'  formant
#' \item \code{get_bandwidth_track(formant_number, unit)} - full bandwidth track
#' \item \code{get_values_at_times(formant_number, times, unit)} - values at an
#'  arbitrary vector of times
#' \item \code{get_all_formant_tracks(max_formants, unit)} - all formants as a
#'  matrix
#' }
#'
#' @section Export:
#' \itemize{
#' \item \code{as_data_frame(max_formants)} - export as a data.frame, long
#'  format:
#' one row per (frame, formant number), with columns \code{time},
#'  \code{formant},
#'     \code{frequency} (Hz), and \code{bandwidth} (Hz). Matches
#'     \code{FormantPath$as_data_frame()}.
#'   \item \code{save(filepath)} - save to a Praat binary file
#' }
#'
#' @section Transform:
#' \itemize{
#' \item \code{to_formant_tier(formant_number)} - extract one formant as a
#'  FormantTier
#'   \item \code{to_formant_modeler()} - create a polynomial trajectory model
#'   \item \code{down_to_formant_tier()} - extract all formants as a FormantTier
#' }
#'
#' @param .xptr Not for direct use. External pointer to the underlying C++
#'  Formant
#'   object; set internally when a method returns a new Formant.
#' @return A \code{Formant} object with methods for querying formant frequencies
#'   and bandwidths at time points or across the full contour.
#'
#' @examples
#' # Self-contained example with generated tone
#' sound <- Sound$create_tone(duration = 1.0, frequency = 150, sampling_rate =
#'  44100)
#' formant <- sound$to_formant_burg(
#'   time_step = 0.01, max_number_of_formants = 5,
#'   maximum_formant = 5500, window_length = 0.025, pre_emphasis_from = 50
#' )
#' f1 <- formant$get_value_at_time(formant_number = 1, time = 0.5, unit =
#'  "hertz")
#'
#' # The same analysis on a recording read from disk
#' sound <- Sound(system.file("extdata", "test.wav", package = "pladdrr"))
#' formant <- sound$to_formant_burg(
#'   time_step = 0.01, max_number_of_formants = 5,
#'   maximum_formant = 5500, window_length = 0.025, pre_emphasis_from = 50
#' )
#' f1_at_02s <- formant$get_value_at_time(formant_number = 1, time = 0.2, unit =
#'  "hertz")
#' mean_f1 <- formant$get_mean(formant_number = 1, from_time = 0, to_time = 0,
#'  unit = "hertz")
#'
#' @seealso \code{\link{Sound}}, \code{\link{LPC}}, \code{\link{FormantPath}},
#'  \code{\link{FormantModeler}}
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
.formant_methods$get_duration <- function(
  .self) .self$.cpp$get_xmax() - .self$.cpp$get_xmin()
.formant_methods$get_number_of_frames <- function(
  .self) .formant_get_number_of_frames(.self$.xptr)
.formant_methods$get_time_step <- function(
  .self) .formant_get_time_step(.self$.xptr)
.formant_methods$get_min_num_formants <- function(
  .self) .formant_get_min_num_formants(.self$.xptr)
.formant_methods$get_max_num_formants <- function(
  .self) .formant_get_max_num_formants(.self$.xptr)

# --- Query ---
.formant_methods$get_value_at_time <- function(.self, formant_number, time,
  unit = c("hertz", "bark"),
                                               interpolation = c("linear",
                                                 "nearest")) {
  unit <- match.arg(unit)
  interpolation <- match.arg(interpolation)
  .formant_get_value_at_time(.self$.xptr, as.integer(formant_number), time,
    .formant_unit_code(unit))
}
.formant_methods$get_bandwidth_at_time <- function(.self, formant_number,
  time, unit = c("hertz", "bark")) {
  unit <- match.arg(unit)
  .formant_get_bandwidth_at_time(.self$.xptr, as.integer(formant_number),
    time, .formant_unit_code(unit))
}
.formant_methods$get_mean <- function(.self, formant_number, from_time = 0,
  to_time = 0, unit = c("hertz", "bark")) {
  unit <- match.arg(unit)
  .formant_get_mean(.self$.xptr, as.integer(formant_number), from_time,
    to_time, .formant_unit_code(unit))
}
.formant_methods$get_standard_deviation <- function(.self, formant_number,
  from_time = 0, to_time = 0,
                                                    unit = c("hertz", "bark")) {
  unit <- match.arg(unit)
  .formant_get_standard_deviation(.self$.xptr, as.integer(formant_number),
    from_time, to_time, .formant_unit_code(unit))
}
.formant_methods$get_quantile <- function(.self, formant_number, quantile,
  from_time = 0, to_time = 0,
                                          unit = c("hertz", "bark")) {
  unit <- match.arg(unit)
  .formant_get_quantile(.self$.xptr, as.integer(formant_number), quantile,
    from_time, to_time, .formant_unit_code(unit))
}
.formant_methods$get_minimum <- function(.self, formant_number, from_time = 0,
  to_time = 0,
                                         unit = c("hertz",
                                           "bark"), interpolate = FALSE) {
  unit <- match.arg(unit)
  .formant_get_minimum(.self$.xptr, as.integer(formant_number), from_time,
                       to_time, .formant_unit_code(unit), interpolate)
}
.formant_methods$get_maximum <- function(.self, formant_number, from_time = 0,
  to_time = 0,
                                         unit = c("hertz",
                                           "bark"), interpolate = FALSE) {
  unit <- match.arg(unit)
  .formant_get_maximum(.self$.xptr, as.integer(formant_number), from_time,
                       to_time, .formant_unit_code(unit), interpolate)
}
.formant_methods$get_time_of_minimum <- function(.self, formant_number,
  from_time = 0, to_time = 0,
                                                  unit = c("hertz",
                                                    "bark"), interpolate = FALSE) {
  unit <- match.arg(unit)
  .formant_get_time_of_minimum(.self$.xptr, as.integer(formant_number),
    from_time,
                                  to_time, .formant_unit_code(
                                    unit), interpolate)
}
.formant_methods$get_time_of_maximum <- function(.self, formant_number,
  from_time = 0, to_time = 0,
                                                  unit = c("hertz",
                                                    "bark"), interpolate = FALSE) {
  unit <- match.arg(unit)
  .formant_get_time_of_maximum(.self$.xptr, as.integer(formant_number),
    from_time,
                                  to_time, .formant_unit_code(
                                    unit), interpolate)
}

# --- Batch/Vectorized ---
.formant_methods$get_times_vector <- function(
  .self) .self$.cpp$get_times_vector()
.formant_methods$get_formant_track <- function(.self, formant_number,
  unit = c("hertz", "bark")) {
  unit <- match.arg(unit)
  .self$.cpp$get_formant_track(as.integer(formant_number),
    .formant_unit_code(unit))
}
.formant_methods$get_bandwidth_track <- function(.self, formant_number,
  unit = c("hertz", "bark")) {
  unit <- match.arg(unit)
  .self$.cpp$get_bandwidth_track(as.integer(formant_number),
    .formant_unit_code(unit))
}
.formant_methods$get_values_at_times <- function(.self, formant_number, times,
  unit = c("hertz", "bark"),
                                                  interpolation = c("linear",
                                                    "nearest")) {
  unit <- match.arg(unit)
  interpolation <- match.arg(interpolation)
  .self$.cpp$get_values_at_times(as.integer(formant_number),
    as.numeric(times), .formant_unit_code(unit))
}
.formant_methods$get_all_values_at_time <- function(.self, time,
  max_formants = 5, unit = c("hertz", "bark")) {
  unit <- match.arg(unit)
  uc <- .formant_unit_code(unit)
  .formant_get_all_values_at_time(.self$.xptr, as.numeric(time),
    as.integer(max_formants), uc)
}
.formant_methods$get_all_formant_tracks <- function(.self, max_formants = 5,
  unit = c("hertz", "bark")) {
  unit <- match.arg(unit)
  .self$.cpp$get_all_formant_tracks(as.integer(max_formants),
    .formant_unit_code(unit))
}

# --- Export ---
.formant_methods$as_data_frame <- function(.self, max_formants = 5) {
  .formant_as_data_frame(.self$.xptr, as.integer(max_formants))
}
.formant_methods$save <- function(.self, filepath) {
  .formant_save(.self$.xptr, filepath)
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
.formant_methods$to_formant_modeler <- function(.self, tmin = 0.0, tmax = 0.0,
  num_tracks = 4, num_params = 5) {
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
    stop(
      "Formant objects must be created from a Sound object using to_formant_burg() or to_formant_keepall()")
  }
  formant_mod <- get_module("formant_module")
  cpp_obj <- formant_mod$RFormant$new(.xptr)
  structure(list(.xptr = .xptr, .cpp = cpp_obj),
    class = c("Formant", "PraatObject"))
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
# as.data.frame.Formant is defined once, in R/s3-methods.R.
