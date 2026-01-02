# ComplexSpectrogram R6 wrapper
# Phase-preserving spectrogram analysis with complex FFT

#' ComplexSpectrogram Constructor
#'
#' Create a ComplexSpectrogram object from a Sound
#'
#' @param sound Sound object
#' @param window_length Window length in seconds (default: 0.005)
#' @param maximum_frequency Maximum frequency to analyze in Hz (default: 5000)
#' @return ComplexSpectrogram object
#' @export
ComplexSpectrogram <- function(sound, window_length = 0.005, maximum_frequency = 5000.0) {
    if (!inherits(sound, "Sound")) {
        stop("First argument must be a Sound object")
    }
    
    # Get the XPtr from Sound object
    sound_ptr <- if (!is.null(sound$.xptr)) {
        sound$.xptr
    } else if (!is.null(sound$.cpp)) {
        sound$.cpp$ptr
    } else {
        stop("Cannot extract XPtr from Sound object")
    }
    
    # Get module and create ComplexSpectrogram
    cs_mod <- get_module("complexspectrogram_module")
    xptr <- cs_mod$complexspectrogram_create_from_sound(
        sound_ptr,
        window_length,
        maximum_frequency
    )
    cpp_obj <- cs_mod$RComplexSpectrogram$new(xptr)
    
    # Create wrapper with convenience methods
    obj <- structure(list(
        .cpp = cpp_obj,
        
        # Validation
        is_valid = function() cpp_obj$is_valid(),
        
        # Time properties
        xmin = function() cpp_obj$get_xmin(),
        xmax = function() cpp_obj$get_xmax(),
        nx = function() cpp_obj$get_nx(),
        dx = function() cpp_obj$get_dx(),
        x1 = function() cpp_obj$get_x1(),
        
        # Frequency properties
        ymin = function() cpp_obj$get_ymin(),
        ymax = function() cpp_obj$get_ymax(),
        ny = function() cpp_obj$get_ny(),
        dy = function() cpp_obj$get_dy(),
        y1 = function() cpp_obj$get_y1(),
        
        # Query methods
        get_amplitude = function(time, frequency) {
            cpp_obj$get_amplitude(time, frequency)
        },
        
        get_phase = function(time, frequency) {
            cpp_obj$get_phase(time, frequency)
        },
        
        # Conversion methods
        to_sound = function(stretch_factor = 1.0) {
            sound_ptr <- cpp_obj$to_sound(stretch_factor)
            Sound(.xptr = sound_ptr)
        },
        
        to_spectrogram = function() {
            spec_ptr <- cpp_obj$to_spectrogram()
            Spectrogram(.xptr = spec_ptr)
        },
        
        to_spectrum = function(time) {
            spectrum_ptr <- cpp_obj$to_spectrum(time)
            Spectrum(.xptr = spectrum_ptr)
        }
    ), class = c("ComplexSpectrogram", "PraatObject"))
    
    obj
}

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
