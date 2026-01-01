# sound-operations.R
# R wrappers for standalone Sound operation functions
# Phase 3.1 - Functional interface (no classes)

#' Append two sounds with optional silence
#'
#' @param sound1 First Sound object
#' @param sound2 Second Sound object
#' @param silence_duration Duration of silence to insert between sounds (seconds)
#' @return New Sound object containing sound1, silence, and sound2
#' @export
#' @examples
#' \dontrun{
#' s1 <- Sound("vowel1.wav")
#' s2 <- Sound("vowel2.wav")
#' combined <- sounds_append(s1, s2, silence_duration = 0.1)
#' }
sounds_append <- function(sound1, sound2, silence_duration = 0.0) {
    mod <- get_module("sound_operations_module")
    sound_mod <- get_module("sound_module")
    
    xptr <- mod$sounds_append(
        sound1$get_xptr(),
        silence_duration,
        sound2$get_xptr()
    )
    
    # Wrap in Sound object
    cpp_obj <- sound_mod$RSound$new(xptr)
    sound_mod_construct_sound_object(cpp_obj)
}

#' Extract a time slice from a sound
#'
#' @param sound Sound object
#' @param t1 Start time (seconds)
#' @param t2 End time (seconds)
#' @param window_shape Window shape: 1=rectangular, 2=triangular, 3=parabolic, 4=Hanning, 5=Hamming, 6=Gaussian1, 7=Gaussian2, 8=Gaussian3, 9=Gaussian4, 10=Gaussian5, 11=Kaiser1, 12=Kaiser2
#' @param relative_width Relative width of window (0-1)
#' @param preserve_times Preserve original time domain
#' @return New Sound object
#' @export
sound_extract_part <- function(sound, t1, t2, window_shape = 1L, 
                               relative_width = 1.0, preserve_times = FALSE) {
    sound_mod <- get_module("sound_module")
    
    # Use existing .sound_extract_part from sound_wrappers.cpp
    xptr <- .sound_extract_part(
        sound$get_xptr(),
        t1, t2,
        as.integer(window_shape),
        relative_width,
        preserve_times
    )
    
    cpp_obj <- sound_mod$RSound$new(xptr)
    sound_mod_construct_sound_object(cpp_obj)
}

#' Time-stretch a sound using overlap-add
#'
#' @param sound Sound object
#' @param fmin Minimum pitch (Hz)
#' @param fmax Maximum pitch (Hz)
#' @param factor Lengthening factor (>1 = slower, <1 = faster)
#' @return New Sound object
#' @export
#' @examples
#' \dontrun{
#' sound <- Sound("speech.wav")
#' slower <- sound_lengthen(sound, fmin = 75, fmax = 600, factor = 1.5)  # 50% slower
#' faster <- sound_lengthen(sound, fmin = 75, fmax = 600, factor = 0.8)  # 20% faster
#' }
sound_lengthen <- function(sound, fmin = 75, fmax = 600, factor = 1.5) {
    mod <- get_module("sound_operations_module")
    sound_mod <- get_module("sound_module")
    
    xptr <- mod$sound_lengthen(
        sound$get_xptr(),
        fmin, fmax, factor
    )
    
    cpp_obj <- sound_mod$RSound$new(xptr)
    sound_mod_construct_sound_object(cpp_obj)
}

#' Deepen band modulation (hearing enhancement)
#'
#' @param sound Sound object
#' @param enhancement_db Enhancement in dB
#' @param flow Low frequency bound (Hz)
#' @param fhigh High frequency bound (Hz)
#' @param slow_modulation Slow modulation frequency (Hz)
#' @param fast_modulation Fast modulation frequency (Hz)
#' @param band_smoothing Band smoothing (Hz)
#' @return New Sound object
#' @export
sound_deepen_band_modulation <- function(sound, enhancement_db = 10,
                                         flow = 300, fhigh = 4000,
                                         slow_modulation = 3, fast_modulation = 30,
                                         band_smoothing = 100) {
    mod <- get_module("sound_operations_module")
    sound_mod <- get_module("sound_module")
    
    xptr <- mod$sound_deepen_band_modulation(
        sound$get_xptr(),
        enhancement_db,
        flow, fhigh,
        slow_modulation, fast_modulation,
        band_smoothing
    )
    
    cpp_obj <- sound_mod$RSound$new(xptr)
    sound_mod_construct_sound_object(cpp_obj)
}

#' Convolve two sounds
#'
#' @param sound1 First Sound object
#' @param sound2 Second Sound object (filter/impulse response)
#' @param scaling Scaling: 1=integral, 2=sum, 3=normalize, 4=peak_0.99
#' @param signal_outside Signal outside time domain: 1=zero, 2=similar
#' @return New Sound object
#' @export
sounds_convolve <- function(sound1, sound2, scaling = 4L, signal_outside = 1L) {
    mod <- get_module("sound_operations_module")
    sound_mod <- get_module("sound_module")
    
    xptr <- mod$sounds_convolve(
        sound1$get_xptr(),
        sound2$get_xptr(),
        as.integer(scaling),
        as.integer(signal_outside)
    )
    
    cpp_obj <- sound_mod$RSound$new(xptr)
    sound_mod_construct_sound_object(cpp_obj)
}

#' Cross-correlate two sounds
#'
#' @param sound1 First Sound object
#' @param sound2 Second Sound object
#' @param scaling Scaling: 1=integral, 2=sum, 3=normalize, 4=peak_0.99
#' @param signal_outside Signal outside time domain: 1=zero, 2=similar
#' @return New Sound object (cross-correlation function)
#' @export
sounds_cross_correlate <- function(sound1, sound2, scaling = 4L, signal_outside = 1L) {
    mod <- get_module("sound_operations_module")
    sound_mod <- get_module("sound_module")
    
    xptr <- mod$sounds_cross_correlate(
        sound1$get_xptr(),
        sound2$get_xptr(),
        as.integer(scaling),
        as.integer(signal_outside)
    )
    
    cpp_obj <- sound_mod$RSound$new(xptr)
    sound_mod_construct_sound_object(cpp_obj)
}

#' Auto-correlate a sound with itself
#'
#' @param sound Sound object
#' @param scaling Scaling: 1=integral, 2=sum, 3=normalize, 4=peak_0.99
#' @param signal_outside Signal outside time domain: 1=zero, 2=similar
#' @return New Sound object (auto-correlation function)
#' @export
sound_auto_correlate <- function(sound, scaling = 4L, signal_outside = 1L) {
    mod <- get_module("sound_operations_module")
    sound_mod <- get_module("sound_module")
    
    xptr <- mod$sound_auto_correlate(
        sound$get_xptr(),
        as.integer(scaling),
        as.integer(signal_outside)
    )
    
    cpp_obj <- sound_mod$RSound$new(xptr)
    sound_mod_construct_sound_object(cpp_obj)
}

#' Apply Hann band-pass filter
#'
#' @param sound Sound object
#' @param fmin Low frequency cutoff (Hz)
#' @param fmax High frequency cutoff (Hz)
#' @param smooth Smoothing bandwidth (Hz)
#' @return New Sound object
#' @export
#' @examples
#' \dontrun{
#' sound <- Sound("speech.wav")
#' filtered <- sound_filter_pass_hann_band(sound, fmin = 300, fmax = 3000, smooth = 100)
#' }
sound_filter_pass_hann_band <- function(sound, fmin, fmax, smooth = 100) {
    sound_mod <- get_module("sound_module")
    
    # Use existing .sound_filter_pass_hann_band from sound_wrappers.cpp
    xptr <- .sound_filter_pass_hann_band(
        sound$get_xptr(),
        fmin, fmax, smooth
    )
    
    cpp_obj <- sound_mod$RSound$new(xptr)
    sound_mod_construct_sound_object(cpp_obj)
}

#' Apply Hann band-stop filter
#'
#' @param sound Sound object
#' @param fmin Low frequency cutoff (Hz)
#' @param fmax High frequency cutoff (Hz)
#' @param smooth Smoothing bandwidth (Hz)
#' @return New Sound object
#' @export
sound_filter_stop_hann_band <- function(sound, fmin, fmax, smooth = 100) {
    sound_mod <- get_module("sound_module")
    
    # Use existing .sound_filter_stop_hann_band from sound_wrappers.cpp
    xptr <- .sound_filter_stop_hann_band(
        sound$get_xptr(),
        fmin, fmax, smooth
    )
    
    cpp_obj <- sound_mod$RSound$new(xptr)
    sound_mod_construct_sound_object(cpp_obj)
}

# Helper function to construct Sound object (reused from sound-module.R pattern)
sound_mod_construct_sound_object <- function(cpp_obj) {
    obj <- structure(list(
        .cpp = cpp_obj,
        get_xmin = function() cpp_obj$get_xmin(),
        get_xmax = function() cpp_obj$get_xmax(),
        get_duration = function() cpp_obj$get_duration(),
        get_number_of_channels = function() cpp_obj$get_number_of_channels(),
        get_number_of_samples = function() cpp_obj$get_nx(),
        get_sampling_frequency = function() cpp_obj$get_sampling_frequency(),
        as_matrix = function() cpp_obj$as_matrix(),
        save = function(path) cpp_obj$save(path)
    ), class = c("Sound", "PraatObject"))
    obj
}
