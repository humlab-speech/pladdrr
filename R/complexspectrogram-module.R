# ComplexSpectrogram wrapper
# Phase-preserving spectrogram analysis with complex FFT

#' ComplexSpectrogram
#'
#' Create a ComplexSpectrogram object from a Sound: a phase-preserving
#' spectrogram computed with a complex FFT.
#'
#' @param sound Sound object.
#' @param window_length Window length in seconds. Default 0.005.
#' @param maximum_frequency Maximum frequency to analyze, in Hz. Default 5000.
#' @return An object of class \code{ComplexSpectrogram} (a list with methods,
#'   dispatched via the shared \code{PraatObject} pattern).
#'
#' @examples
#' sound <- Sound$create_tone(frequency = 150, duration = 0.3)
#' cs <- ComplexSpectrogram(sound)
#' cs$get_amplitude(0.15, 150)
#'
#' @name ComplexSpectrogram
NULL

# ============================================================================
# Shared Method Dispatch Table
# ============================================================================

.complexspectrogram_methods <- new.env(hash = TRUE, parent = emptyenv())

# Validation
.complexspectrogram_methods$is_valid <- function(.self) .self$.cpp$is_valid()

# Time properties
.complexspectrogram_methods$xmin <- function(.self) .self$.cpp$get_xmin()
.complexspectrogram_methods$xmax <- function(.self) .self$.cpp$get_xmax()
.complexspectrogram_methods$nx <- function(.self) .self$.cpp$get_nx()
.complexspectrogram_methods$dx <- function(.self) .self$.cpp$get_dx()
.complexspectrogram_methods$x1 <- function(.self) .self$.cpp$get_x1()

# Frequency properties
.complexspectrogram_methods$ymin <- function(.self) .self$.cpp$get_ymin()
.complexspectrogram_methods$ymax <- function(.self) .self$.cpp$get_ymax()
.complexspectrogram_methods$ny <- function(.self) .self$.cpp$get_ny()
.complexspectrogram_methods$dy <- function(.self) .self$.cpp$get_dy()
.complexspectrogram_methods$y1 <- function(.self) .self$.cpp$get_y1()

# Query
.complexspectrogram_methods$get_amplitude <- function(.self, time, frequency) {
  .self$.cpp$get_amplitude(time, frequency)
}
.complexspectrogram_methods$get_phase <- function(.self, time, frequency) {
  .self$.cpp$get_phase(time, frequency)
}

# Conversion
.complexspectrogram_methods$to_sound <- function(.self, stretch_factor = 1.0) {
  sound_ptr <- .self$.cpp$to_sound(stretch_factor)
  Sound(.xptr = sound_ptr)
}
.complexspectrogram_methods$to_spectrogram <- function(.self) {
  spec_ptr <- .self$.cpp$to_spectrogram()
  Spectrogram(.xptr = spec_ptr)
}
.complexspectrogram_methods$to_spectrum <- function(.self, time) {
  spectrum_ptr <- .self$.cpp$to_spectrum(time)
  Spectrum(.xptr = spectrum_ptr)
}

lockEnvironment(.complexspectrogram_methods, bindings = TRUE)

# ============================================================================
# S3 Dispatch
# ============================================================================

#' @method $ ComplexSpectrogram
#' @export
`$.ComplexSpectrogram` <- function(x, name) {
  val <- .subset2(x, name)
  if (!is.null(val)) return(val)
  method <- .complexspectrogram_methods[[name]]
  if (is.null(method)) return(NULL)
  function(...) method(x, ...)
}

# ============================================================================
# Constructor
# ============================================================================

#' @export
ComplexSpectrogram <- function(sound, window_length = 0.005,
  maximum_frequency = 5000.0) {
  if (!inherits(sound, "Sound")) {
    stop("First argument must be a Sound object")
  }

  sound_ptr <- if (!is.null(sound$.xptr)) {
    sound$.xptr
  } else if (!is.null(sound$.cpp)) {
    sound$.cpp$ptr
  } else {
    stop("Cannot extract XPtr from Sound object")
  }

  cs_mod <- get_module("complexspectrogram_module")
  xptr <- cs_mod$complexspectrogram_create_from_sound(
    sound_ptr, window_length, maximum_frequency
  )
  cpp_obj <- cs_mod$RComplexSpectrogram$new(xptr)

  structure(list(
    .cpp = cpp_obj
  ), class = c("ComplexSpectrogram", "PraatObject"))
}

# ============================================================================
# S3 Methods
# ============================================================================

#' @export
as.data.frame.ComplexSpectrogram <- function(x, ...) {
  x$.cpp$as_data_frame()
}

#' @export
print.ComplexSpectrogram <- function(x, ...) {
  if (!x$is_valid()) {
    cat("Invalid ComplexSpectrogram object\n")
    return(invisible(x))
  }
  cat("ComplexSpectrogram:\n")
  cat(sprintf("  Time domain: [%.3f, %.3f] s\n", x$xmin(), x$xmax()))
  cat(sprintf("  Frequency domain: [%.1f, %.1f] Hz\n", x$ymin(), x$ymax()))
  cat(sprintf("  Time frames: %d (dx = %.6f s)\n", x$nx(), x$dx()))
  cat(sprintf("  Frequency bins: %d (df = %.3f Hz)\n", x$ny(), x$dy()))
  invisible(x)
}
