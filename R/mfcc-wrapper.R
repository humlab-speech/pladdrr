#' @title Praat MFCC Object
#' @description
#' Mel Frequency Cepstral Coefficients for speech/speaker recognition.
#'
#' @details
#' MFCCs are widely used features in speech and speaker recognition systems.
#' They represent the short-term power spectrum of a sound on a mel scale,
#' which approximates human auditory perception.
#'
#' ## Creating MFCC Objects
#'
#' MFCC objects are created from Sound objects:
#' - `sound$to_mfcc()` - Extract MFCCs with default parameters
#'
#' ## Querying MFCC Properties
#'
#' - `$get_number_of_frames()` - Number of analysis frames
#' - `$get_time_step()` - Time step between frames
#' - `$get_max_num_coefficients()` - Maximum number of coefficients
#' - `$get_fmin()` / `$get_fmax()` - Frequency range (mel)
#' - `$get_c0_at_frame(frame)` - C0 (energy) for specific frame
#' - `$get_value_in_frame(frame, coef)` - Coefficient value at frame
#' - `$get_coefficients_at_frame(frame)` - All coefficients for frame
#' - `$get_all_coefficients()` - Matrix of all coefficients
#' - `$get_all_c0()` - Vector of all C0 values
#'
#' ## Liftering
#'
#' - `$lifter(L)` - Apply cepstral liftering (weighting)
#'
#' ## Export
#'
#' - `$as_data_frame(include_c0)` - Convert to data.frame/data.table
#' - `$to_matrix()` - Convert to Matrix object
#'
#' @examples
#' \dontrun{
#' # Load sound
#' sound <- Sound("audio.wav")
#'
#' # Extract MFCCs (13 coefficients typical for speech recognition)
#' mfcc <- sound$to_mfcc(
#'   num_coefficients = 13,
#'   analysis_width = 0.025,
#'   time_step = 0.01,
#'   f1_mel = 100,
#'   fmax_mel = 7800,
#'   df_mel = 100
#' )
#'
#' # Query properties
#' n_frames <- mfcc$get_number_of_frames()
#' coefs <- mfcc$get_all_coefficients()
#'
#' # Get coefficients for specific frame
#' frame_coefs <- mfcc$get_coefficients_at_frame(10)
#'
#' # Apply liftering for feature normalization
#' mfcc$lifter(22)
#'
#' # Export to data.frame
#' df <- mfcc$as_data_frame(include_c0 = TRUE)
#' }
#'
#' @export
MFCC <- function(.xptr = NULL) {
  if (is.null(.xptr)) {
    stop("MFCC objects must be created from a Sound object using sound$to_mfcc()")
  }

  mfcc_mod <- get_module("mfcc_module")
  cpp_obj <- mfcc_mod$RMFCC$new(.xptr)

  obj <- structure(list(
    .cpp = cpp_obj,
    .xptr = .xptr,

    # Query - Basic properties
    get_number_of_frames = function() {
      cpp_obj$get_number_of_frames()
    },

    get_time_step = function() {
      cpp_obj$get_time_step()
    },

    get_max_num_coefficients = function() {
      cpp_obj$get_max_num_coefficients()
    },

    get_fmin = function() {
      cpp_obj$get_fmin()
    },

    get_fmax = function() {
      cpp_obj$get_fmax()
    },

    get_xmin = function() {
      cpp_obj$get_xmin()
    },

    get_xmax = function() {
      cpp_obj$get_xmax()
    },

    get_duration = function() {
      cpp_obj$get_duration()
    },

    # Query - Frame-level
    get_c0_at_frame = function(frame_number) {
      cpp_obj$get_c0_at_frame(as.integer(frame_number))
    },

    get_num_coefficients_at_frame = function(frame_number) {
      cpp_obj$get_num_coefficients_at_frame(as.integer(frame_number))
    },

    get_value_in_frame = function(frame_number, coeff_number) {
      cpp_obj$get_value_in_frame(as.integer(frame_number), as.integer(coeff_number))
    },

    get_value_at_time = function(time, coeff_number) {
      cpp_obj$get_value_at_time(as.numeric(time), as.integer(coeff_number))
    },

    get_coefficients_at_frame = function(frame_number) {
      cpp_obj$get_coefficients_at_frame(as.integer(frame_number))
    },

    get_all_c0 = function() {
      cpp_obj$get_all_c0()
    },

    get_all_coefficients = function() {
      cpp_obj$get_all_coefficients()
    },

    # Frame/time conversion
    get_time_from_frame = function(frame_number) {
      cpp_obj$get_time_from_frame(as.integer(frame_number))
    },

    get_frame_from_time = function(time) {
      cpp_obj$get_frame_from_time(as.numeric(time))
    },

    # Liftering
    lifter = function(lifter_coefficient = 22) {
      cpp_obj$lifter(as.integer(lifter_coefficient))
      invisible(obj)
    },

    # Conversion
    to_matrix = function() {
      matrix_ptr <- cpp_obj$to_matrix_ptr()
      Matrix(.xptr = matrix_ptr)
    },

    to_dtw = function(reference, coefficient_weight = 1.0,
                      log_energy_weight = 0.0,
                      coefficient_regression_weight = 0.0,
                      log_energy_regression_weight = 0.0,
                      regression_window_length = 0.0) {
      if (!inherits(reference, "MFCC")) {
        stop("reference must be an MFCC object")
      }
      mfccs_to_dtw(reference, obj, coefficient_weight, log_energy_weight,
                   coefficient_regression_weight, log_energy_regression_weight,
                   regression_window_length)
    },

    # Export
    as_data_frame = function(include_c0 = TRUE) {
      cpp_obj$as_data_frame(include_c0)
    },

    get_info = function() {
      cpp_obj$get_info()
    },

    # Utility
    get_xptr = function() {
      .xptr
    },

    save = function(path) {
      cpp_obj$save(path)
      invisible(obj)
    },

    # Display
    print = function() {
      info <- cpp_obj$get_info()
      cat("<Praat MFCC>\n")
      cat(sprintf("  Time: %.3f - %.3f s (%.3f s)\n", info$xmin, info$xmax, info$xmax - info$xmin))
      cat(sprintf("  Frames: %d (step: %.4f s)\n", info$nx, info$dx))
      cat(sprintf("  Coefficients: %d (max %d used)\n", info$max_n_coefficients, info$max_n_coefficients_used))
      cat(sprintf("  Mel range: %.1f - %.1f mel\n", info$fmin_mel, info$fmax_mel))
      invisible(obj)
    }

  ), class = c("MFCC", "PraatObject"))

  obj
}

#' @export
print.MFCC <- function(x, ...) {
  x$print()
}

#' @title Praat LFCC Object
#' @description
#' Linear Frequency Cepstral Coefficients for speaker recognition.
#'
#' @details
#' LFCCs are similar to MFCCs but use a linear frequency scale instead of
#' the mel scale. They are derived from LPC analysis and are useful for
#' speaker recognition tasks.
#'
#' ## Creating LFCC Objects
#'
#' LFCC objects are created from LPC objects:
#' - `lpc$to_lfcc()` - Extract LFCCs from LPC
#'
#' ## Querying LFCC Properties
#'
#' - `$get_number_of_frames()` - Number of analysis frames
#' - `$get_max_num_coefficients()` - Maximum number of coefficients
#' - `$get_c0_at_frame(frame)` - C0 for specific frame
#' - `$get_coefficients_at_frame(frame)` - All coefficients for frame
#' - `$get_all_coefficients()` - Matrix of all coefficients
#'
#' ## Conversion
#'
#' - `$to_lpc(num_coefficients)` - Convert back to LPC
#' - `$to_matrix()` - Convert to Matrix
#' - `$as_data_frame()` - Export to data.frame
#'
#' @examples
#' \dontrun{
#' # Load sound and compute LPC
#' sound <- Sound("audio.wav")
#' lpc <- sound$to_lpc_burg(prediction_order = 16)
#'
#' # Extract LFCCs
#' lfcc <- lpc$to_lfcc(num_coefficients = 12)
#'
#' # Query properties
#' coefs <- lfcc$get_all_coefficients()
#'
#' # Convert back to LPC
#' lpc2 <- lfcc$to_lpc(num_coefficients = 16)
#' }
#'
#' @export
LFCC <- function(.xptr = NULL) {
  if (is.null(.xptr)) {
    stop("LFCC objects must be created from an LPC object using lpc$to_lfcc()")
  }

  mfcc_mod <- get_module("mfcc_module")
  cpp_obj <- mfcc_mod$RLFCC$new(.xptr)

  obj <- structure(list(
    .cpp = cpp_obj,
    .xptr = .xptr,

    # Query - Basic properties
    get_number_of_frames = function() {
      cpp_obj$get_number_of_frames()
    },

    get_time_step = function() {
      cpp_obj$get_time_step()
    },

    get_max_num_coefficients = function() {
      cpp_obj$get_max_num_coefficients()
    },

    get_fmin = function() {
      cpp_obj$get_fmin()
    },

    get_fmax = function() {
      cpp_obj$get_fmax()
    },

    get_xmin = function() {
      cpp_obj$get_xmin()
    },

    get_xmax = function() {
      cpp_obj$get_xmax()
    },

    get_duration = function() {
      cpp_obj$get_duration()
    },

    # Query - Frame-level
    get_c0_at_frame = function(frame_number) {
      cpp_obj$get_c0_at_frame(as.integer(frame_number))
    },

    get_num_coefficients_at_frame = function(frame_number) {
      cpp_obj$get_num_coefficients_at_frame(as.integer(frame_number))
    },

    get_value_in_frame = function(frame_number, coeff_number) {
      cpp_obj$get_value_in_frame(as.integer(frame_number), as.integer(coeff_number))
    },

    get_value_at_time = function(time, coeff_number) {
      cpp_obj$get_value_at_time(as.numeric(time), as.integer(coeff_number))
    },

    get_coefficients_at_frame = function(frame_number) {
      cpp_obj$get_coefficients_at_frame(as.integer(frame_number))
    },

    get_all_coefficients = function() {
      cpp_obj$get_all_coefficients()
    },

    # Frame/time conversion
    get_time_from_frame = function(frame_number) {
      cpp_obj$get_time_from_frame(as.integer(frame_number))
    },

    get_frame_from_time = function(time) {
      cpp_obj$get_frame_from_time(as.numeric(time))
    },

    # Conversion
    to_lpc = function(num_coefficients = 16) {
      lpc_ptr <- cpp_obj$to_lpc_ptr(as.integer(num_coefficients))
      LPC(.xptr = lpc_ptr)
    },

    to_matrix = function() {
      matrix_ptr <- cpp_obj$to_matrix_ptr()
      Matrix(.xptr = matrix_ptr)
    },

    # Export
    as_data_frame = function(include_c0 = TRUE) {
      cpp_obj$as_data_frame(include_c0)
    },

    get_info = function() {
      cpp_obj$get_info()
    },

    # Utility
    get_xptr = function() {
      .xptr
    },

    save = function(path) {
      cpp_obj$save(path)
      invisible(obj)
    },

    # Display
    print = function() {
      info <- cpp_obj$get_info()
      cat("<Praat LFCC>\n")
      cat(sprintf("  Time: %.3f - %.3f s (%.3f s)\n", info$xmin, info$xmax, info$xmax - info$xmin))
      cat(sprintf("  Frames: %d (step: %.4f s)\n", info$nx, info$dx))
      cat(sprintf("  Coefficients: %d (max %d used)\n", info$max_n_coefficients, info$max_n_coefficients_used))
      cat(sprintf("  Frequency range: %.1f - %.1f Hz\n", info$fmin, info$fmax))
      invisible(obj)
    }

  ), class = c("LFCC", "PraatObject"))

  obj
}

#' @export
print.LFCC <- function(x, ...) {
  x$print()
}
