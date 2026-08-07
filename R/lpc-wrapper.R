#' @title Praat LPC Object
#' @description
#' Praat LPC object with direct C++ module binding for linear predictive coding analysis.
#'
#' @details
#' LPC (Linear Predictive Coding) is a method for estimating the spectral
#' envelope of a sound by modeling it as an autoregressive process. The LPC
#' coefficients describe the vocal tract filter and can be converted to
#' formants, spectra, or other representations.
#'
#' ## Creating LPC Objects
#'
#' LPC objects are created from Sound objects using one of several methods:
#' - `sound$to_lpc_burg()` - Burg method (fastest, most robust)
#' - `sound$to_lpc_auto()` - Autocorrelation method
#' - `sound$to_lpc_covariance()` - Covariance method
#' - `sound$to_lpc_marple()` - Marple method (slowest, most accurate)
#'
#' ## Querying LPC Properties
#'
#' - `$get_number_of_frames()` - Number of analysis frames
#' - `$get_time_step()` - Time step between frames
#' - `$get_sampling_period()` - Sampling period of original sound
#' - `$get_max_num_coefficients()` - Maximum number of LPC coefficients
#' - `$get_gain_at_frame(frame)` - Gain value for specific frame
#' - `$get_coefficients_at_frame(frame)` - LPC coefficients for specific frame
#' - `$get_all_gains()` - Vector of all gain values
#' - `$get_all_coefficients()` - Matrix of all LPC coefficients
#'
#' ## Converting to Other Objects
#'
#' - `$to_formant(margin)` - Convert to Formant object
#' - `$to_spectrum(time, ...)` - Convert to Spectrum at specific time
#' - `$to_matrix()` - Convert to Matrix object
#'
#' ## Voice Source Extraction (Inverse Filtering)
#'
#' - `$filter_inverse(sound)` - Extract glottal flow by inverse filtering
#' - `$filter_inverse_at_time(sound, time, channel)` - Use filter from specific time
#'
#' These methods remove vocal tract resonances to reveal the voice source (glottal
#' flow waveform). Essential for voice quality research and vocal fold dynamics.
#'
#' @seealso \code{\link{Sound}}, \code{\link{Formant}}, \code{\link{Spectrum}}, \code{\link{LFCC}}
#'
#' @return An \code{LPC} object with methods for linear predictive coding analysis and inverse filtering.
#'
#' @examples
#' # Load sound
#' sound <- Sound$create_tone(frequency = 150, duration = 0.3)
#'
#' # Compute LPC (Burg method is recommended)
#' lpc <- sound$to_lpc_burg(
#'   prediction_order = 16,
#'   analysis_width = 0.025,
#'   time_step = 0.005,
#'   pre_emphasis_frequency = 50.0
#' )
#'
#' # Query properties
#' n_frames <- lpc$get_number_of_frames()
#' gains <- lpc$get_all_gains()
#' coeffs <- lpc$get_all_coefficients()
#'
#' # Get coefficients for a specific frame
#' coef_frame1 <- lpc$get_coefficients_at_frame(1)
#'
#' # Convert to other representations
#' spectrum <- lpc$to_spectrum(time = 0.15, df_min = 20)
#'
#' # Extract voice source (glottal flow) via inverse filtering at a given time
#' midpoint <- sound$get_duration() / 2
#' glottal_flow <- lpc$filter_inverse_at_time(sound, time = midpoint)
#'
#' @name LPC
NULL

# ============================================================================
# Shared Method Dispatch Table
# ============================================================================

.lpc_methods <- new.env(hash = TRUE, parent = emptyenv())

# Query - Basic properties
.lpc_methods$get_number_of_frames <- function(.self) .self$.cpp$get_number_of_frames()
.lpc_methods$get_time_step <- function(.self) .self$.cpp$get_time_step()
.lpc_methods$get_sampling_period <- function(.self) .self$.cpp$get_sampling_period()
.lpc_methods$get_max_num_coefficients <- function(.self) .self$.cpp$get_max_num_coefficients()

# Query - LPC values
.lpc_methods$get_gain_at_frame <- function(.self, frame_number) {
  .self$.cpp$get_gain_at_frame(as.integer(frame_number))
}
.lpc_methods$get_coefficients_at_frame <- function(.self, frame_number) {
  .self$.cpp$get_coefficients_at_frame(as.integer(frame_number))
}
.lpc_methods$get_all_gains <- function(.self) .self$.cpp$get_all_gains()
.lpc_methods$get_all_coefficients <- function(.self) .self$.cpp$get_all_coefficients()

# Conversion methods
.lpc_methods$to_formant <- function(.self, margin = 50.0) {
  stop("LPC$to_formant() is not available in this build (requires CLAPACK).\n",
       "Use Sound$to_formant_burg() for formant extraction instead.")
}

.lpc_methods$to_spectrum <- function(.self, time, df_min = 20.0,
                                      bandwidth_reduction = 0.0,
                                      de_emphasis_frequency = 50.0) {
  spectrum_ptr <- .lpc_to_spectrum(
    .self$.xptr, time, df_min, bandwidth_reduction, de_emphasis_frequency
  )
  Spectrum(.xptr = spectrum_ptr)
}

.lpc_methods$to_matrix <- function(.self) {
  matrix_ptr <- .lpc_to_matrix(.self$.xptr)
  Matrix(.xptr = matrix_ptr)
}

.lpc_methods$to_spectrogram <- function(.self, df_min = 20.0, bandwidth_reduction = 0.0,
                                         de_emphasis_frequency = 50.0) {
  spec_ptr <- .lpc_to_spectrogram(
    .self$.xptr, df_min, bandwidth_reduction, de_emphasis_frequency
  )
  Spectrogram(.xptr = spec_ptr)
}

# LFCC extraction
.lpc_methods$to_lfcc <- function(.self, num_coefficients = 12) {
  mfcc_mod <- get_module("mfcc_module")
  lfcc_ptr <- mfcc_mod$LPC_to_LFCC(.self$.xptr, as.integer(num_coefficients))
  LFCC(.xptr = lfcc_ptr)
}

# Inverse Filtering
.lpc_methods$filter_inverse <- function(.self, sound) {
  if (!inherits(sound, "Sound")) stop("sound must be a Sound object")
  source_ptr <- .lpc_sound_filter_inverse_r6(.self$.xptr, sound)
  Sound(.xptr = source_ptr)
}

.lpc_methods$filter_inverse_at_time <- function(.self, sound, time, channel = 1) {
  if (!inherits(sound, "Sound")) stop("sound must be a Sound object")
  if (!is.numeric(time) || length(time) != 1) stop("time must be a single numeric value")
  if (!is.numeric(channel) || length(channel) != 1 || channel < 1) {
    stop("channel must be a positive integer")
  }
  source_ptr <- .lpc_sound_filter_inverse_at_time(
    .self$.xptr, sound$get_xptr(), as.integer(channel), as.numeric(time)
  )
  Sound(.xptr = source_ptr)
}

# Utility
.lpc_methods$get_xptr <- function(.self) .self$.xptr

# Display
.lpc_methods$print <- function(.self) {
  cat("<Praat LPC>\n")
  cat(sprintf("  Number of frames: %d\n", .self$.cpp$get_number_of_frames()))
  cat(sprintf("  Time step: %.6f s\n", .self$.cpp$get_time_step()))
  cat(sprintf("  Max coefficients: %d\n", .self$.cpp$get_max_num_coefficients()))
  cat(sprintf("  Sampling period: %.6f s\n", .self$.cpp$get_sampling_period()))
  invisible(.self)
}

.lpc_methods$is_valid <- function(.self) .self$.cpp$is_valid()
lockEnvironment(.lpc_methods, bindings = TRUE)

# ============================================================================
# S3 Dispatch
# ============================================================================

#' @method $ LPC
#' @export
`$.LPC` <- function(x, name) {
  val <- .subset2(x, name)
  if (!is.null(val)) return(val)
  method <- .lpc_methods[[name]]
  if (is.null(method)) return(NULL)
  function(...) method(x, ...)
}

# ============================================================================
# Constructor
# ============================================================================

#' @export
LPC <- function(.xptr = NULL) {
  if (is.null(.xptr)) {
    stop("LPC objects must be created from a Sound object using sound$to_lpc_burg() or similar methods")
  }
  
  lpc_mod <- get_module("lpc_module")
  cpp_obj <- lpc_mod$RLPC$new(.xptr)
  
  structure(list(
    .cpp = cpp_obj,
    .xptr = .xptr
  ), class = c("LPC", "PraatObject"))
}

#' @export
print.LPC <- function(x, ...) {
  x$print()
}
