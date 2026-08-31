# formantpath-module.R
# R wrapper for FormantPath Rcpp module
# Phase 2.2 - Robust formant tracking with multiple candidates

#' Create a FormantPath object from a Sound
#'
#' A FormantPath object represents multiple formant tracking candidates with
#' different ceiling frequencies, allowing for robust formant analysis by
#' automatically selecting the optimal tracking path.
#'
#' @param sound A Sound object or path to audio file
#' @param time_step Time step for analysis in seconds (must be > 0, typically
#'  0.005)
#' @param max_num_formants Maximum number of formants to track (typically 5)
#' @param formant_ceiling Maximum formant frequency in Hz (typically 5000-5500)
#' @param window_length Analysis window length in seconds (typically 0.025)
#' @param preemphasis_from Preemphasis frequency in Hz (typically 50)
#' @param ceiling_step_fraction Step size for ceiling frequency variation
#'  (0.05-0.1)
#' @param num_steps_up_down Number of steps above/below ceiling (typically 2-4)
#'
#' @return An object of class \code{FormantPath} wrapping the set of candidate
#' formant tracks (list with methods; dispatched via the shared
#'  \code{PraatObject} pattern).
#'
#' @examples
#' sound <- Sound$create_tone(frequency = 150, duration = 0.3)
#' fp <- FormantPath(sound)
#' fp$get_duration()
#'
#' @name FormantPath
NULL

# ============================================================================
# Shared Method Dispatch Table
# ============================================================================

.formantpath_methods <- new.env(hash = TRUE, parent = emptyenv())

# Validation
.formantpath_methods$is_valid <- function(.self) .self$.cpp$is_valid()

# Time domain properties
.formantpath_methods$get_xmin <- function(.self) .self$.cpp$get_xmin()
.formantpath_methods$get_xmax <- function(.self) .self$.cpp$get_xmax()
.formantpath_methods$get_duration <- function(.self) .self$.cpp$get_duration()
.formantpath_methods$get_nx <- function(.self) .self$.cpp$get_nx()
.formantpath_methods$get_dx <- function(.self) .self$.cpp$get_dx()
.formantpath_methods$get_x1 <- function(.self) .self$.cpp$get_x1()

# Candidate/track properties
.formantpath_methods$get_number_of_candidates <- function(
  .self) .self$.cpp$get_number_of_candidates()
.formantpath_methods$get_number_of_formant_tracks <- function(
  .self) .self$.cpp$get_number_of_formant_tracks()
.formantpath_methods$get_ceiling_frequency <- function(.self, candidate) {
  .self$.cpp$get_ceiling_frequency(as.integer(candidate))
}
.formantpath_methods$get_all_ceiling_frequencies <- function(
  .self) .self$.cpp$get_all_ceiling_frequencies()

# Path query
.formantpath_methods$get_candidate_in_frame <- function(.self, frame_number) {
  .self$.cpp$get_candidate_in_frame(as.integer(frame_number))
}

# Stress and optimization
.formantpath_methods$get_stress_of_candidate <- function(.self, tmin = NULL,
  tmax = NULL,
                                                          from_formant = 1L, to_formant = 5L,
                                                          parameters = c(1L,
                                                            1L, 1L, 1L, 1L),
                                                          powerf = 1.25, candidate = 1L) {
  if (is.null(tmin)) tmin <- .self$.cpp$get_xmin()
  if (is.null(tmax)) tmax <- .self$.cpp$get_xmax()
  .self$.cpp$get_stress_of_candidate(
    tmin, tmax, as.integer(from_formant), as.integer(to_formant),
    as.numeric(parameters), powerf, as.integer(candidate)
  )
}

.formantpath_methods$get_optimal_ceiling <- function(.self, tmin = NULL,
  tmax = NULL,
                                                      parameters = c(1L, 1L,
                                                        1L, 1L, 1L),
                                                      powerf = 1.25) {
  if (is.null(tmin)) tmin <- .self$.cpp$get_xmin()
  if (is.null(tmax)) tmax <- .self$.cpp$get_xmax()
  .self$.cpp$get_optimal_ceiling(tmin, tmax, as.numeric(parameters), powerf)
}

# Path manipulation
.formantpath_methods$set_path <- function(.self, tmin = NULL, tmax = NULL,
  selected_candidate = 1L) {
  if (is.null(tmin)) tmin <- .self$.cpp$get_xmin()
  if (is.null(tmax)) tmax <- .self$.cpp$get_xmax()
  .self$.cpp$set_path(tmin, tmax, as.integer(selected_candidate))
  invisible(.self)
}

.formantpath_methods$set_optimal_path <- function(.self, tmin = NULL,
  tmax = NULL,
                                                   parameters = c(1L, 1L, 1L,
                                                     1L, 1L),
                                                   powerf = 1.25) {
  if (is.null(tmin)) tmin <- .self$.cpp$get_xmin()
  if (is.null(tmax)) tmax <- .self$.cpp$get_xmax()
  .self$.cpp$set_optimal_path(tmin, tmax, as.numeric(parameters), powerf)
  invisible(.self)
}

.formantpath_methods$path_finder <- function(.self, q_weight = 1.0,
                                              frequency_change_weight = 1.0,
                                              stress_weight = 1.0,
                                              ceiling_change_weight = 1.0,
                                              intensity_modulation_step_size = 5.0,
                                              window_length = 0.035,
                                              parameters = c(1L, 1L, 1L, 1L,
                                                1L),
                                              powerf = 1.25) {
  .self$.cpp$path_finder(
    q_weight, frequency_change_weight, stress_weight,
    ceiling_change_weight, intensity_modulation_step_size,
    window_length, as.numeric(parameters), powerf
  )
  invisible(.self)
}

# Extraction
.formantpath_methods$extract_formant <- function(.self) {
  formant_xptr <- .self$.cpp$extract_formant()
  Formant(.xptr = formant_xptr)
}

# Export
.formantpath_methods$as_data_frame <- function(.self, max_formants = 5L) {
  .self$.cpp$as_data_frame(as.integer(max_formants))
}

# I/O
.formantpath_methods$save <- function(.self, path) {
  .self$.cpp$save(path)
  invisible(.self)
}

# Print
.formantpath_methods$print <- function(.self) {
  cat("FormantPath object\n")
  cat(sprintf("  Time domain: %.3f - %.3f s (duration: %.3f s)\n",
             .self$.cpp$get_xmin(
               ), .self$.cpp$get_xmax(), .self$.cpp$get_duration()))
  cat(sprintf("  Number of frames: %d\n", .self$.cpp$get_nx()))
  cat(sprintf("  Time step: %.6f s\n", .self$.cpp$get_dx()))
  cat(
    sprintf("  Number of candidates: %d\n",
      .self$.cpp$get_number_of_candidates()))
  ceilings <- .self$.cpp$get_all_ceiling_frequencies()
  cat(
    sprintf("  Ceiling frequencies: %.0f - %.0f Hz\n", min(ceilings),
      max(ceilings)))
  invisible(.self)
}

lockEnvironment(.formantpath_methods, bindings = TRUE)

# ============================================================================
# S3 Dispatch
# ============================================================================

#' @method $ FormantPath
#' @export
`$.FormantPath` <- function(x, name) {
  val <- .subset2(x, name)
  if (!is.null(val)) return(val)
  method <- .formantpath_methods[[name]]
  if (is.null(method)) return(NULL)
  function(...) method(x, ...)
}

# ============================================================================
# Constructor
# ============================================================================

#' @export
FormantPath <- function(sound,
                        time_step = 0.005,
                        max_num_formants = 5.0,
                        formant_ceiling = 5500.0,
                        window_length = 0.025,
                        preemphasis_from = 50.0,
                        ceiling_step_fraction = 0.05,
                        num_steps_up_down = 4L) {
    
    mod <- get_module("formantpath_module")
    
    if (is.character(sound)) sound <- Sound(sound)
    if (
      !inherits(sound,
        "Sound")) stop("sound must be a Sound object or path to audio file")
    
    sound_ptr <- sound$.xptr
    
    xptr <- mod$formantpath_create_from_sound_burg(
        sound_ptr, time_step, max_num_formants, formant_ceiling,
        window_length, preemphasis_from, ceiling_step_fraction,
        as.integer(num_steps_up_down)
    )
    
    cpp_obj <- mod$RFormantPath$new(xptr)
    
    structure(list(
        .cpp = cpp_obj
    ), class = c("FormantPath", "PraatObject"))
}

#' @export
as.data.frame.FormantPath <- function(x, row.names = NULL, optional = FALSE,
                                      max_formants = 5L, ...) {
    x$as_data_frame(max_formants = max_formants)
}
