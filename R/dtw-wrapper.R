# dtw-wrapper.R
# R wrapper for DTW (Dynamic Time Warping) module
#
# DTW provides temporal alignment between acoustic signals for:
# - Sound-to-sound alignment
# - TextGrid annotation warping
# - Time mapping between signals

#' DTW
#'
#' Temporal alignment between two acoustic signals.
#'
#' DTW aligns a candidate signal (x-axis) to a prototype or reference
#' (y-axis), computing an optimal path through a distance matrix that
#' minimizes the total distance while respecting slope constraints.
#'
#' @section Creating DTW objects:
#'
#' DTW objects are created by aligning two acoustic objects:
#' \itemize{
#'   \item \code{sounds_to_dtw(reference, candidate)} - align two sounds (most common)
#'   \item \code{mfccs_to_dtw(mfcc1, mfcc2)} - align MFCCs (speech recognition)
#'   \item \code{spectrograms_to_dtw(spec1, spec2)} - align spectrograms
#'   \item \code{pitches_to_dtw(pitch1, pitch2)} - align pitch contours
#' }
#'
#' @section Time mapping:
#'
#' \itemize{
#'   \item \code{$get_y_time_from_x_time(tx)} - map candidate time to reference time
#'   \item \code{$get_x_time_from_y_time(ty)} - map reference time to candidate time
#'   \item \code{$map_times(times, direction)} - vectorized time mapping
#' }
#'
#' @section TextGrid warping:
#'
#' \itemize{
#'   \item \code{$warp_textgrid(textgrid)} - warp annotation times
#' }
#'
#' @section Path analysis:
#'
#' \itemize{
#'   \item \code{$get_weighted_distance()} - global alignment distance
#'   \item \code{$get_path_length()} - number of cells in optimal path
#'   \item \code{$get_path()} - full path as a data.frame
#'   \item \code{$get_maximum_consecutive_steps("x"|"y")} - path regularity
#' }
#'
#' @section Slope constraints:
#' Controls path flexibility:
#' \itemize{
#'   \item 1: No constraint (any slope)
#'   \item 2: 1/3 < slope < 3
#'   \item 3: 1/2 < slope < 2 (recommended)
#'   \item 4: 2/3 < slope < 3/2 (strict)
#' }
#'
#' @return A DTW object wrapping the alignment path and distance matrix.
#'
#' @examples
#' # Basic alignment workflow
#' reference <- Sound$create_tone(frequency = 150, duration = 0.3)
#' candidate <- Sound$create_tone(frequency = 160, duration = 0.3)
#'
#' # Create DTW alignment
#' dtw <- sounds_to_dtw(reference, candidate,
#'   analysis_width = 0.015,
#'   time_step = 0.005,
#'   band = 0.0,
#'   slope = 3
#' )
#'
#' # Check alignment quality
#' cat("Distance:", dtw$get_weighted_distance(), "\n")
#'
#' # Map time point from candidate to reference
#' ref_time <- dtw$get_y_time_from_x_time(0.1)
#'
#' @param .xptr Not for direct use. External pointer to the underlying C++
#'   DTW object; set internally when wrapping an existing alignment.
#' @seealso \code{\link{Sound}}, \code{\link{Pitch}}, \code{\link{Spectrogram}}, \code{\link{MFCC}}
#' @export
.dtw_method_factories <- list(
  get_y_time_from_x_time = function(cpp_obj, .xptr) function(tx) {
      cpp_obj$get_y_time_from_x_time(as.numeric(tx))
    },
  get_x_time_from_y_time = function(cpp_obj, .xptr) function(ty) {
      cpp_obj$get_x_time_from_y_time(as.numeric(ty))
    },
  map_times = function(cpp_obj, .xptr) function(times, direction = c("x_to_y", "y_to_x")) {
      direction <- match.arg(direction)
      times <- as.numeric(times)
      if (direction == "x_to_y") {
        cpp_obj$get_y_times_from_x_times(times)
      } else {
        cpp_obj$get_x_times_from_y_times(times)
      }
    },
  get_maximum_consecutive_steps = function(cpp_obj, .xptr) function(direction = c("x", "y", "horizontal", "vertical")) {
      direction <- match.arg(direction)
      cpp_obj$get_maximum_consecutive_steps(direction)
    },
  get_path = function(cpp_obj, .xptr) function() {
      cpp_obj$get_path()
    },
  swap_axes = function(cpp_obj, .xptr) function() {
      swapped_ptr <- cpp_obj$swap_axes_ptr()
      DTW(.xptr = swapped_ptr)
    },
  to_polygon = function(cpp_obj, .xptr) function(band = 0.0, slope = 1) {
      poly_ptr <- cpp_obj$to_polygon_ptr(as.numeric(band), as.integer(slope))
      Polygon(.xptr = poly_ptr)
    },
  to_matrix_distances = function(cpp_obj, .xptr) function() {
      mat_ptr <- cpp_obj$to_matrix_distances_ptr()
      Matrix(.xptr = mat_ptr)
    },
  to_matrix_cumulative = function(cpp_obj, .xptr) function(band = 0.0, slope = 1) {
      mat_ptr <- cpp_obj$to_matrix_cumulative_distances_ptr(
        as.numeric(band), as.integer(slope))
      Matrix(.xptr = mat_ptr)
    },
  to_duration_tier = function(cpp_obj, .xptr) function() {
      tier_ptr <- cpp_obj$to_duration_tier_ptr()
      DurationTier(.xptr = tier_ptr)
    },
  warp_textgrid = function(cpp_obj, .xptr) function(textgrid, precision = 0.0) {
      if (!inherits(textgrid, "TextGrid")) {
        stop("textgrid must be a TextGrid object")
      }
      warped_ptr <- cpp_obj$warp_textgrid_ptr(textgrid$.xptr, as.numeric(precision))
      TextGrid(.xptr = warped_ptr)
    },
  as_matrix = function(cpp_obj, .xptr) function() {
      cpp_obj$as_matrix()
    },
  get_info = function(cpp_obj, .xptr) function() {
      cpp_obj$get_info()
    },
  save = function(cpp_obj, .xptr) function(path) {
      cpp_obj$save(path)
      invisible(obj)
    },
  print = function(cpp_obj, .xptr) function() {
      info <- cpp_obj$get_info()
      cat("<Praat DTW>\n")
      cat(sprintf("  Candidate (x): %.3f - %.3f s (%.3f s)\n",
                  info$x_domain$min, info$x_domain$max, info$x_domain$duration))
      cat(sprintf("  Reference (y): %.3f - %.3f s (%.3f s)\n",
                  info$y_domain$min, info$y_domain$max, info$y_domain$duration))
      cat(sprintf("  Matrix: %d x %d (step: %.4f x %.4f s)\n",
                  info$matrix$nx, info$matrix$ny, info$matrix$dx, info$matrix$dy))
      cat(sprintf("  Path length: %d cells\n", info$path$length))
      cat(sprintf("  Weighted distance: %.4f\n", info$path$weighted_distance))
      invisible(obj)
    }
)

DTW <- function(.xptr = NULL) {
  if (is.null(.xptr)) {
    stop("DTW objects must be created via sounds_to_dtw(), mfccs_to_dtw(), etc.")
  }

  dtw_mod <- get_module("dtw_module")
  cpp_obj <- dtw_mod$RDTW$new(.xptr)

  obj <- structure(c(
    list(.cpp = cpp_obj,
         .xptr = .xptr,
         get_xmin = function() cpp_obj$get_xmin(),
         get_xmax = function() cpp_obj$get_xmax(),
         get_ymin = function() cpp_obj$get_ymin(),
         get_ymax = function() cpp_obj$get_ymax(),
         get_x_duration = function() cpp_obj$get_x_duration(),
         get_y_duration = function() cpp_obj$get_y_duration(),
         get_nx = function() cpp_obj$get_nx(),
         get_ny = function() cpp_obj$get_ny(),
         get_weighted_distance = function() cpp_obj$get_weighted_distance(),
         get_path_length = function() cpp_obj$get_path_length(),
         get_xptr = function() .xptr),
    lapply(.dtw_method_factories, function(f) f(cpp_obj, .xptr))
  ), class = c("DTW", "PraatObject"))

  obj
}

# ============================================================================
# Factory Functions
# ============================================================================

#' Create DTW from two Sound objects
#'
#' Aligns a candidate sound to a reference sound using MFCC-based
#' dynamic time warping.
#'
#' @param reference Reference sound (prototype, y-axis)
#' @param candidate Candidate sound (test, x-axis)
#' @param analysis_width Window length in seconds (default: 0.015)
#' @param time_step Time step between frames (default: 0.005)
#' @param band Sakoe-Chiba band width in seconds (0 = no constraint)
#' @param slope Slope constraint: 1=none, 2=1/3-3, 3=1/2-2, 4=2/3-3/2
#' @return A DTW object
#'
#' @examples
#' ref <- Sound$create_tone(frequency = 200, duration = 0.3, sampling_rate = 16000)
#' test <- Sound$create_tone(frequency = 220, duration = 0.3, sampling_rate = 16000)
#' dtw <- sounds_to_dtw(ref, test)
#' print(dtw$get_weighted_distance())
#'
#' @export
sounds_to_dtw <- function(reference, candidate,
                          analysis_width = 0.015,
                          time_step = 0.005,
                          band = 0.0,
                          slope = 3) {
  if (!inherits(reference, "Sound")) stop("reference must be a Sound object")
  if (!inherits(candidate, "Sound")) stop("candidate must be a Sound object")

  dtw_mod <- get_module("dtw_module")
  dtw_ptr <- dtw_mod$Sounds_to_DTW(
    candidate$.xptr,
    reference$.xptr,
    as.numeric(analysis_width),
    as.numeric(time_step),
    as.numeric(band),
    as.integer(slope)
  )
  DTW(.xptr = dtw_ptr)
}

#' Create DTW from two MFCC objects
#'
#' @param mfcc1 First MFCC object (candidate, x-axis)
#' @param mfcc2 Second MFCC object (reference, y-axis)
#' @param coefficient_weight Weight for cepstral coefficients (default: 1.0)
#' @param log_energy_weight Weight for log energy (c0) (default: 0.0)
#' @param coefficient_regression_weight Weight for coefficient regression (default: 0.0)
#' @param log_energy_regression_weight Weight for energy regression (default: 0.0)
#' @param regression_window_length Window for regression calculation (default: 0.0)
#' @return A DTW object
#'
#' @examples
#' s1 <- Sound$create_tone(frequency = 200, duration = 0.3, sampling_rate = 16000)
#' s2 <- Sound$create_tone(frequency = 220, duration = 0.3, sampling_rate = 16000)
#' dtw <- mfccs_to_dtw(s1$to_mfcc(), s2$to_mfcc())
#'
#' @export
mfccs_to_dtw <- function(mfcc1, mfcc2,
                         coefficient_weight = 1.0,
                         log_energy_weight = 0.0,
                         coefficient_regression_weight = 0.0,
                         log_energy_regression_weight = 0.0,
                         regression_window_length = 0.0) {
  if (!inherits(mfcc1, "MFCC")) stop("mfcc1 must be an MFCC object")
  if (!inherits(mfcc2, "MFCC")) stop("mfcc2 must be an MFCC object")

  dtw_mod <- get_module("dtw_module")
  dtw_ptr <- dtw_mod$MFCCs_to_DTW(
    mfcc1$.xptr, mfcc2$.xptr,
    as.numeric(coefficient_weight),
    as.numeric(log_energy_weight),
    as.numeric(coefficient_regression_weight),
    as.numeric(log_energy_regression_weight),
    as.numeric(regression_window_length)
  )
  DTW(.xptr = dtw_ptr)
}

#' Create DTW from two Spectrogram objects
#'
#' @param spectrogram1 First spectrogram (candidate)
#' @param spectrogram2 Second spectrogram (reference)
#' @param match_start Force path to start at (1,1)
#' @param match_end Force path to end at (nx,ny)
#' @param slope Slope constraint (1-4)
#' @param metric Distance metric power (default: 2 = Euclidean)
#' @return A DTW object
#'
#' @examples
#' s1 <- Sound$create_tone(frequency = 200, duration = 0.3, sampling_rate = 16000)
#' s2 <- Sound$create_tone(frequency = 220, duration = 0.3, sampling_rate = 16000)
#' dtw <- spectrograms_to_dtw(s1$to_spectrogram(), s2$to_spectrogram())
#'
#' @export
spectrograms_to_dtw <- function(spectrogram1, spectrogram2,
                                match_start = TRUE,
                                match_end = TRUE,
                                slope = 1,
                                metric = 2.0) {
  if (!inherits(spectrogram1, "Spectrogram")) stop("spectrogram1 must be a Spectrogram")
  if (!inherits(spectrogram2, "Spectrogram")) stop("spectrogram2 must be a Spectrogram")

  dtw_mod <- get_module("dtw_module")
  dtw_ptr <- dtw_mod$Spectrograms_to_DTW(
    spectrogram1$.xptr, spectrogram2$.xptr,
    as.logical(match_start), as.logical(match_end),
    as.integer(slope), as.numeric(metric)
  )
  DTW(.xptr = dtw_ptr)
}

#' Create DTW from two Pitch objects
#'
#' @param pitch1 First pitch contour (candidate)
#' @param pitch2 Second pitch contour (reference)
#' @param vuv_costs Cost for voiced-unvoiced mismatches (default: 24)
#' @param time_weight Weight for temporal distance (default: 10)
#' @param match_start Force path to start at (1,1)
#' @param match_end Force path to end at (nx,ny)
#' @param slope Slope constraint (1-4)
#' @return A DTW object
#'
#' @examples
#' sound1 <- Sound$create_tone(frequency = 220, duration = 0.5)
#' sound2 <- Sound$create_tone(frequency = 440, duration = 0.5)
#' pitch1 <- sound1$to_pitch()
#' pitch2 <- sound2$to_pitch()
#' dtw <- pitches_to_dtw(pitch1, pitch2)
#'
#' @export
pitches_to_dtw <- function(pitch1, pitch2,
                           vuv_costs = 24.0,
                           time_weight = 10.0,
                           match_start = TRUE,
                           match_end = TRUE,
                           slope = 1) {
  if (!inherits(pitch1, "Pitch")) stop("pitch1 must be a Pitch object")
  if (!inherits(pitch2, "Pitch")) stop("pitch2 must be a Pitch object")

  dtw_mod <- get_module("dtw_module")
  dtw_ptr <- dtw_mod$Pitches_to_DTW(
    pitch1$.xptr, pitch2$.xptr,
    as.numeric(vuv_costs), as.numeric(time_weight),
    as.logical(match_start), as.logical(match_end),
    as.integer(slope)
  )
  DTW(.xptr = dtw_ptr)
}
