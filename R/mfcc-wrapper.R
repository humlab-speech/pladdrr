# mfcc-wrapper.R - MFCC and LFCC objects using shared dispatch tables (pladdrr 4.8.33)
# Architecture: minimal list + $.MFCC / $.LFCC S3 dispatch → shared method env

#' MFCC
#'
#' Mel-frequency cepstral coefficients for speech and speaker recognition.
#'
#' MFCCs are widely used features in speech and speaker recognition systems.
#' They represent the short-term power spectrum of a sound on a mel scale,
#' which approximates human auditory perception. Uses a shared dispatch table
#' for minimal memory per object.
#'
#' @section Creating MFCC objects:
#' \itemize{
#'   \item \code{sound$to_mfcc()} - extract MFCCs with default parameters
#' }
#'
#' @section Query methods:
#' \itemize{
#'   \item \code{get_number_of_frames()} - number of analysis frames
#'   \item \code{get_time_step()} - time step between frames
#'   \item \code{get_max_num_coefficients()} - maximum number of coefficients
#'   \item \code{get_fmin()}, \code{get_fmax()} - frequency range (mel)
#'   \item \code{get_c0_at_frame(frame)} - C0 (energy) for a specific frame
#'   \item \code{get_value_in_frame(frame, coef)} - coefficient value at a frame
#'   \item \code{get_coefficients_at_frame(frame)} - all coefficients for a frame
#'   \item \code{get_all_coefficients()} - matrix of all coefficients
#'   \item \code{get_all_c0()} - vector of all C0 values
#' }
#'
#' @section Liftering:
#' \itemize{
#'   \item \code{lifter(L)} - apply cepstral liftering (weighting)
#' }
#'
#' @section Export:
#' \itemize{
#'   \item \code{as_data_frame(include_c0)} - convert to a data.frame/data.table
#'   \item \code{to_matrix()} - convert to a Matrix object
#' }
#'
#' @param .xptr Not for direct use. External pointer to the underlying C++ MFCC
#'   object; set internally when a method returns a new MFCC.
#' @return An \code{MFCC} object with methods for Mel-frequency cepstral coefficient analysis.
#'
#' @examples
#' sound <- Sound$create_tone(frequency = 150, duration = 0.3)
#' mfcc <- sound$to_mfcc(
#'   num_coefficients = 13,
#'   analysis_width = 0.025,
#'   time_step = 0.01,
#'   f1_mel = 100,
#'   fmax_mel = 7800,
#'   df_mel = 100
#' )
#' n_frames <- mfcc$get_number_of_frames()
#' coefs <- mfcc$get_all_coefficients()
#' mfcc$lifter(22)
#' df <- mfcc$as_data_frame(include_c0 = TRUE)
#'
#' @seealso \code{\link{Sound}}, \code{\link{MelSpectrogram}}
#' @name MFCC
NULL

# ============================================================================
# MFCC Shared Method Dispatch Table
# ============================================================================

.mfcc_methods <- new.env(hash = TRUE, parent = emptyenv())

# --- Properties ---
.mfcc_methods$get_number_of_frames <- function(.self) .self$.cpp$get_number_of_frames()
.mfcc_methods$get_time_step <- function(.self) .self$.cpp$get_time_step()
.mfcc_methods$get_max_num_coefficients <- function(.self) .self$.cpp$get_max_num_coefficients()
.mfcc_methods$get_fmin <- function(.self) .self$.cpp$get_fmin()
.mfcc_methods$get_fmax <- function(.self) .self$.cpp$get_fmax()
.mfcc_methods$get_xmin <- function(.self) .self$.cpp$get_xmin()
.mfcc_methods$get_xmax <- function(.self) .self$.cpp$get_xmax()
.mfcc_methods$get_duration <- function(.self) .self$.cpp$get_duration()

# --- Frame-level ---
.mfcc_methods$get_c0_at_frame <- function(.self, frame_number) {
  .self$.cpp$get_c0_at_frame(as.integer(frame_number))
}
.mfcc_methods$get_num_coefficients_at_frame <- function(.self, frame_number) {
  .self$.cpp$get_num_coefficients_at_frame(as.integer(frame_number))
}
.mfcc_methods$get_value_in_frame <- function(.self, frame_number, coeff_number) {
  .self$.cpp$get_value_in_frame(as.integer(frame_number), as.integer(coeff_number))
}
.mfcc_methods$get_value_at_time <- function(.self, time, coeff_number) {
  .self$.cpp$get_value_at_time(as.numeric(time), as.integer(coeff_number))
}
.mfcc_methods$get_coefficients_at_frame <- function(.self, frame_number) {
  .self$.cpp$get_coefficients_at_frame(as.integer(frame_number))
}
.mfcc_methods$get_all_c0 <- function(.self) .self$.cpp$get_all_c0()
.mfcc_methods$get_all_coefficients <- function(.self) .self$.cpp$get_all_coefficients()

# --- Frame/time conversion ---
.mfcc_methods$get_time_from_frame <- function(.self, frame_number) {
  .self$.cpp$get_time_from_frame(as.integer(frame_number))
}
.mfcc_methods$get_frame_from_time <- function(.self, time) {
  .self$.cpp$get_frame_from_time(as.numeric(time))
}

# --- Liftering ---
.mfcc_methods$lifter <- function(.self, lifter_coefficient = 22) {
  .self$.cpp$lifter(as.integer(lifter_coefficient))
  invisible(.self)
}

# --- Conversion ---
.mfcc_methods$to_matrix <- function(.self) {
  matrix_ptr <- .self$.cpp$to_matrix_ptr()
  Matrix(.xptr = matrix_ptr)
}
.mfcc_methods$to_mel_spectrogram <- function(.self, first_coefficient = 1, last_coefficient = 0,
                                             include_c0 = FALSE) {
  if (last_coefficient == 0) last_coefficient <- .self$.cpp$get_max_num_coefficients()
  mel_ptr <- .mfcc_to_mel_spectrogram(
    .self$.xptr, as.integer(first_coefficient),
    as.integer(last_coefficient), include_c0
  )
  MelSpectrogram(.xptr = mel_ptr)
}
.mfcc_methods$to_dtw <- function(.self, reference, coefficient_weight = 1.0,
                                 log_energy_weight = 0.0,
                                 coefficient_regression_weight = 0.0,
                                 log_energy_regression_weight = 0.0,
                                 regression_window_length = 0.0) {
  if (!inherits(reference, "MFCC")) {
    stop("reference must be an MFCC object")
  }
  mfccs_to_dtw(reference, .self, coefficient_weight, log_energy_weight,
               coefficient_regression_weight, log_energy_regression_weight,
               regression_window_length)
}

# --- Export ---
.mfcc_methods$as_data_frame <- function(.self, include_c0 = TRUE) {
  .self$.cpp$as_data_frame(include_c0)
}
.mfcc_methods$get_info <- function(.self) .self$.cpp$get_info()
.mfcc_methods$get_xptr <- function(.self) .self$.xptr
.mfcc_methods$save <- function(.self, path) {
  .self$.cpp$save(path)
  invisible(.self)
}

# --- Print ---
.mfcc_methods$print <- function(.self) {
  info <- .self$.cpp$get_info()
  cat("<Praat MFCC>\n")
  cat(sprintf("  Time: %.3f - %.3f s (%.3f s)\n", info$xmin, info$xmax, info$xmax - info$xmin))
  cat(sprintf("  Frames: %d (step: %.4f s)\n", info$nx, info$dx))
  cat(sprintf("  Coefficients: %d (max %d used)\n", info$max_n_coefficients, info$max_n_coefficients_used))
  cat(sprintf("  Mel range: %.1f - %.1f mel\n", info$fmin_mel, info$fmax_mel))
  invisible(.self)
}

.mfcc_methods$is_valid <- function(.self) .self$.cpp$is_valid()
lockEnvironment(.mfcc_methods, bindings = TRUE)

# ============================================================================
# MFCC Constructor
# ============================================================================

#' @export
MFCC <- function(.xptr = NULL) {
  if (is.null(.xptr)) {
    stop("MFCC objects must be created from a Sound object using sound$to_mfcc()")
  }
  mfcc_mod <- get_module("mfcc_module")
  cpp_obj <- mfcc_mod$RMFCC$new(.xptr)
  structure(list(.xptr = .xptr, .cpp = cpp_obj), class = c("MFCC", "PraatObject"))
}

# ============================================================================
# MFCC S3 Dispatch
# ============================================================================

#' @method $ MFCC
#' @export
`$.MFCC` <- function(x, name) {
  val <- .subset2(x, name)
  if (!is.null(val)) return(val)
  if (name == ".pointer") return(.subset2(x, ".xptr"))
  method <- .mfcc_methods[[name]]
  if (is.null(method)) return(NULL)
  function(...) method(x, ...)
}

#' @export
print.MFCC <- function(x, ...) {
  x$print()
}

# ============================================================================
# LFCC Shared Method Dispatch Table
# ============================================================================

#' LFCC
#'
#' Linear-frequency cepstral coefficients for speaker recognition.
#'
#' LFCCs are similar to MFCCs but use a linear frequency scale instead of
#' the mel scale. They are derived from LPC analysis and are useful for
#' speaker recognition tasks. Uses a shared dispatch table for minimal memory
#' per object.
#'
#' @param .xptr Not for direct use. External pointer to the underlying C++ LFCC
#'   object; set internally when a method returns a new LFCC.
#' @return An \code{LFCC} object with methods for linear-frequency cepstral coefficient analysis.
#'
#' @examples
#' sound <- Sound$create_tone(frequency = 150, duration = 0.3)
#' lpc <- sound$to_lpc_burg(prediction_order = 16)
#' lfcc <- lpc$to_lfcc(num_coefficients = 12)
#' coefs <- lfcc$get_all_coefficients()
#' lpc2 <- lfcc$to_lpc(num_coefficients = 16)
#'
#' @seealso \code{\link{Sound}}, \code{\link{LPC}}
#' @name LFCC
NULL

.lfcc_methods <- new.env(hash = TRUE, parent = emptyenv())

# --- Properties ---
.lfcc_methods$get_number_of_frames <- function(.self) .self$.cpp$get_number_of_frames()
.lfcc_methods$get_time_step <- function(.self) .self$.cpp$get_time_step()
.lfcc_methods$get_max_num_coefficients <- function(.self) .self$.cpp$get_max_num_coefficients()
.lfcc_methods$get_fmin <- function(.self) .self$.cpp$get_fmin()
.lfcc_methods$get_fmax <- function(.self) .self$.cpp$get_fmax()
.lfcc_methods$get_xmin <- function(.self) .self$.cpp$get_xmin()
.lfcc_methods$get_xmax <- function(.self) .self$.cpp$get_xmax()
.lfcc_methods$get_duration <- function(.self) .self$.cpp$get_duration()

# --- Frame-level ---
.lfcc_methods$get_c0_at_frame <- function(.self, frame_number) {
  .self$.cpp$get_c0_at_frame(as.integer(frame_number))
}
.lfcc_methods$get_num_coefficients_at_frame <- function(.self, frame_number) {
  .self$.cpp$get_num_coefficients_at_frame(as.integer(frame_number))
}
.lfcc_methods$get_value_in_frame <- function(.self, frame_number, coeff_number) {
  .self$.cpp$get_value_in_frame(as.integer(frame_number), as.integer(coeff_number))
}
.lfcc_methods$get_value_at_time <- function(.self, time, coeff_number) {
  .self$.cpp$get_value_at_time(as.numeric(time), as.integer(coeff_number))
}
.lfcc_methods$get_coefficients_at_frame <- function(.self, frame_number) {
  .self$.cpp$get_coefficients_at_frame(as.integer(frame_number))
}
.lfcc_methods$get_all_coefficients <- function(.self) .self$.cpp$get_all_coefficients()

# --- Frame/time conversion ---
.lfcc_methods$get_time_from_frame <- function(.self, frame_number) {
  .self$.cpp$get_time_from_frame(as.integer(frame_number))
}
.lfcc_methods$get_frame_from_time <- function(.self, time) {
  .self$.cpp$get_frame_from_time(as.numeric(time))
}

# --- Conversion ---
.lfcc_methods$to_lpc <- function(.self, num_coefficients = 16) {
  lpc_ptr <- .self$.cpp$to_lpc_ptr(as.integer(num_coefficients))
  LPC(.xptr = lpc_ptr)
}
.lfcc_methods$to_matrix <- function(.self) {
  matrix_ptr <- .self$.cpp$to_matrix_ptr()
  Matrix(.xptr = matrix_ptr)
}

# --- Export ---
.lfcc_methods$as_data_frame <- function(.self, include_c0 = TRUE) {
  .self$.cpp$as_data_frame(include_c0)
}
.lfcc_methods$get_info <- function(.self) .self$.cpp$get_info()
.lfcc_methods$get_xptr <- function(.self) .self$.xptr
.lfcc_methods$save <- function(.self, path) {
  .self$.cpp$save(path)
  invisible(.self)
}

# --- Print ---
.lfcc_methods$print <- function(.self) {
  info <- .self$.cpp$get_info()
  cat("<Praat LFCC>\n")
  cat(sprintf("  Time: %.3f - %.3f s (%.3f s)\n", info$xmin, info$xmax, info$xmax - info$xmin))
  cat(sprintf("  Frames: %d (step: %.4f s)\n", info$nx, info$dx))
  cat(sprintf("  Coefficients: %d (max %d used)\n", info$max_n_coefficients, info$max_n_coefficients_used))
  cat(sprintf("  Frequency range: %.1f - %.1f Hz\n", info$fmin, info$fmax))
  invisible(.self)
}

.lfcc_methods$is_valid <- function(.self) .self$.cpp$is_valid()
lockEnvironment(.lfcc_methods, bindings = TRUE)

# ============================================================================
# LFCC Constructor
# ============================================================================

#' @export
LFCC <- function(.xptr = NULL) {
  if (is.null(.xptr)) {
    stop("LFCC objects must be created from an LPC object using lpc$to_lfcc()")
  }
  mfcc_mod <- get_module("mfcc_module")
  cpp_obj <- mfcc_mod$RLFCC$new(.xptr)
  structure(list(.xptr = .xptr, .cpp = cpp_obj), class = c("LFCC", "PraatObject"))
}

# ============================================================================
# LFCC S3 Dispatch
# ============================================================================

#' @method $ LFCC
#' @export
`$.LFCC` <- function(x, name) {
  val <- .subset2(x, name)
  if (!is.null(val)) return(val)
  if (name == ".pointer") return(.subset2(x, ".xptr"))
  method <- .lfcc_methods[[name]]
  if (is.null(method)) return(NULL)
  function(...) method(x, ...)
}

#' @export
print.LFCC <- function(x, ...) {
  x$print()
}
