# sound-operations.R
# R wrappers for standalone Sound operation functions
# Phase 3.1 - Functional interface (no classes)

#' Append two sounds with optional silence
#'
#' @inheritParams pladdrr_shared_params sound1
#' @param sound2 Second Sound object
#' @param silence_duration Duration of silence to insert between sounds
#'  (seconds)
#' @return New Sound object containing sound1, silence, and sound2
#' @export
#' @examples
#' s1 <- Sound$create_tone(frequency = 220, duration = 0.2)
#' s2 <- Sound$create_tone(frequency = 440, duration = 0.2)
#' combined <- sounds_append(s1, s2, silence_duration = 0.1)
sounds_append <- function(sound1, sound2, silence_duration = 0.0) {
    mod <- get_module("sound_operations_module")
    
    xptr <- mod$sounds_append(
        sound1$get_xptr(),
        silence_duration,
        sound2$get_xptr()
    )
    
    # Wrap in Sound object
    Sound(.xptr = xptr)
}

#' Extract part of Sound with optional windowing
#'
#' Extracts time range from Sound, applying optional window function.
#' Implements Praat's "Sound: Extract part..." with full window shape support.
#'
#' @inheritParams pladdrr_shared_sound sound
#' @param t1 Start time (seconds)
#' @param t2 End time (seconds)
#' @param window_shape Window shape code or name:
#'   * 0 or "rectangular" - Rectangular (no tapering)
#'   * 1 or "triangular" - Triangular (Bartlett)
#'   * 2 or "parabolic" - Parabolic (Welch)
#'   * 3 or "hanning" - Hanning
#'   * 4 or "hamming" - Hamming
#'   * 5 or "gaussian1" - Gaussian with sd=0.42466 (relative to duration)
#' * 6 or "gaussian2" - Gaussian with sd=0.21233 (narrower, use
#'  relative_width=2.0)
#'   * 7 or "gaussian3" - Gaussian with sd=0.14155 (use relative_width=3.0)
#'   * 8 or "gaussian4" - Gaussian with sd=0.10616 (use relative_width=4.0)
#'   * 9 or "gaussian5" - Gaussian with sd=0.08493 (use relative_width=5.0)
#'   * 10 or "kaiser1" - Kaiser-Bessel with alpha=20.7
#'   * 11 or "kaiser2" - Kaiser-Bessel with alpha=40.5 (use relative_width=2.0)
#'
#' @param relative_width Relative width for windowing (default: 1.0).
#'   For gaussian2/kaiser2, use 2.0 to maintain effective window duration.
#'   For gaussian3, use 3.0. For gaussian4, use 4.0. For gaussian5, use 5.0.
#' This extends physical extraction beyond [t1,t2] while keeping effective
#'  duration.
#'
#' @param preserve_times If TRUE, preserve original time domain (result spans t1
#'  to t2).
#'   If FALSE, time-shift result to start at 0.
#'
#' @return New Sound object with extracted and windowed portion
#'
#' @details
#' Window shapes with higher numbers (gaussian2-5, kaiser2) have narrower
#'  effective
#' windows. To maintain comparable effective duration to gaussian1/kaiser1, use
#' relative_width > 1.0, which extracts a longer physical segment while applying
#' a more aggressive taper.
#'
#' For spectral analysis, Kaiser2 and Gaussian2 with relative_width=2.0 are
#'  commonly
#' used (e.g., in Praat's "To Spectrogram..." and "To Pitch (ac)... Very
#'  accurate").
#'
#' @references
#' Praat documentation:
#'  \url{https://www.fon.hum.uva.nl/praat/manual/Sound__Extract_part___.html}
#'
#' @examples
#' sound <- Sound$create_tone(frequency = 220, duration = 3.0)
#'
#' # Rectangular window (no tapering)
#' rect <- sound_extract_part(sound, 1.0, 2.0, window_shape = 0L)
#'
#' # Gaussian1 window (standard)
#' gauss1 <- sound_extract_part(sound, 1.0, 2.0, window_shape = 5L,
#'  relative_width = 1.0)
#'
#' # Gaussian2 with wider physical extraction
#' gauss2 <- sound_extract_part(sound, 1.0, 2.0, window_shape = 6L,
#'  relative_width = 2.0)
#'
#' # Kaiser2 for spectral analysis
#' kaiser <- sound_extract_part(sound, 1.0, 2.0, window_shape = 11L,
#'  relative_width = 2.0)
#' @export
sound_extract_part <- function(sound, t1, t2, window_shape = 1L, 
                               relative_width = 1.0, preserve_times = FALSE) {
    
    # Use existing .sound_extract_part from sound_wrappers.cpp
    xptr <- .sound_extract_part(
        sound$get_xptr(),
        t1, t2,
        as.integer(window_shape),
        relative_width,
        preserve_times
    )
    
    Sound(.xptr = xptr)
}

#' Time-stretch a sound using overlap-add
#'
#' @inheritParams pladdrr_shared_sound sound
#' @param fmin Minimum pitch (Hz)
#' @param fmax Maximum pitch (Hz)
#' @param factor Lengthening factor (>1 = slower, <1 = faster)
#' @return New Sound object
#' @export
#' @examples
#' sound <- Sound$create_tone(frequency = 150, duration = 1.0)
#' slower <- sound_lengthen(sound, fmin = 75, fmax = 600, factor = 1.5)
#' faster <- sound_lengthen(sound, fmin = 75, fmax = 600, factor = 0.8)
sound_lengthen <- function(sound, fmin = 75, fmax = 600, factor = 1.5) {
    mod <- get_module("sound_operations_module")
    
    xptr <- mod$sound_lengthen(
        sound$get_xptr(),
        fmin, fmax, factor
    )
    
    Sound(.xptr = xptr)
}

#' Deepen band modulation (hearing enhancement)
#'
#' @inheritParams pladdrr_shared_sound sound
#' @param enhancement_db Enhancement in dB
#' @param flow Low frequency bound (Hz)
#' @param fhigh High frequency bound (Hz)
#' @param slow_modulation Slow modulation frequency (Hz)
#' @param fast_modulation Fast modulation frequency (Hz)
#' @param band_smoothing Band smoothing (Hz)
#' @return New Sound object
#' @export
#' @examples
#' sound <- Sound$create_tone(frequency = 150, duration = 1.0)
#' enhanced <- sound_deepen_band_modulation(sound, enhancement_db = 10)
sound_deepen_band_modulation <- function(sound, enhancement_db = 10,
                                         flow = 300, fhigh = 4000,
                                         slow_modulation = 3, fast_modulation =
                                             30,
                                         band_smoothing = 100) {
    mod <- get_module("sound_operations_module")
    
    xptr <- mod$sound_deepen_band_modulation(
        sound$get_xptr(),
        enhancement_db,
        flow, fhigh,
        slow_modulation, fast_modulation,
        band_smoothing
    )
    
    Sound(.xptr = xptr)
}

#' Convolve two sounds
#'
#' @inheritParams pladdrr_shared_params sound1
#' @param sound2 Second Sound object (filter/impulse response)
#' @inheritParams pladdrr_shared_params scaling
#' @inheritParams pladdrr_shared_params signal_outside
#' @return New Sound object
#' @export
#' @examples
#' s1 <- Sound$create_tone(frequency = 220, duration = 0.2)
#' s2 <- Sound$create_tone(frequency = 440, duration = 0.05)
#' conv <- sounds_convolve(s1, s2)
sounds_convolve <- function(sound1, sound2, scaling = 4L, signal_outside = 1L) {
    mod <- get_module("sound_operations_module")
    
    xptr <- mod$sounds_convolve(
        sound1$get_xptr(),
        sound2$get_xptr(),
        as.integer(scaling),
        as.integer(signal_outside)
    )
    
    Sound(.xptr = xptr)
}

#' Cross-correlate two sounds
#'
#' @inheritParams pladdrr_shared_params sound1
#' @param sound2 Second Sound object
#' @inheritParams pladdrr_shared_params scaling
#' @inheritParams pladdrr_shared_params signal_outside
#' @return New Sound object (cross-correlation function)
#' @export
#' @examples
#' s1 <- Sound$create_tone(frequency = 220, duration = 0.2)
#' s2 <- Sound$create_tone(frequency = 220, duration = 0.2)
#' xcorr <- sounds_cross_correlate(s1, s2)
sounds_cross_correlate <- function(sound1, sound2, scaling = 4L,
  signal_outside = 1L) {
    mod <- get_module("sound_operations_module")
    
    xptr <- mod$sounds_cross_correlate(
        sound1$get_xptr(),
        sound2$get_xptr(),
        as.integer(scaling),
        as.integer(signal_outside)
    )
    
    Sound(.xptr = xptr)
}

#' Auto-correlate a sound with itself
#'
#' @inheritParams pladdrr_shared_sound sound
#' @inheritParams pladdrr_shared_params scaling
#' @inheritParams pladdrr_shared_params signal_outside
#' @return New Sound object (auto-correlation function)
#' @examples
#' sound <- Sound$create_tone(frequency = 220, duration = 0.5)
#' ac <- sound_auto_correlate(sound)
#' @export
sound_auto_correlate <- function(sound, scaling = 4L, signal_outside = 1L) {
    mod <- get_module("sound_operations_module")
    
    xptr <- mod$sound_auto_correlate(
        sound$get_xptr(),
        as.integer(scaling),
        as.integer(signal_outside)
    )
    
    Sound(.xptr = xptr)
}

#' Apply Hann band-pass filter
#'
#' @inheritParams pladdrr_shared_sound sound
#' @inheritParams pladdrr_shared_params fmin
#' @inheritParams pladdrr_shared_params fmax
#' @inheritParams pladdrr_shared_params smooth
#' @return New Sound object
#' @export
#' @examples
#' sound <- Sound$create_tone(frequency = 1000, duration = 0.5)
#' filtered <- sound_filter_pass_hann_band(sound, fmin = 300, fmax = 3000,
#'  smooth = 100)
sound_filter_pass_hann_band <- function(sound, fmin, fmax, smooth = 100) {
    
    # Use existing .sound_filter_pass_hann_band from sound_wrappers.cpp
    xptr <- .sound_filter_pass_hann_band(
        sound$get_xptr(),
        fmin, fmax, smooth
    )
    
    Sound(.xptr = xptr)
}

#' Apply Hann band-stop filter
#'
#' @inheritParams pladdrr_shared_sound sound
#' @inheritParams pladdrr_shared_params fmin
#' @inheritParams pladdrr_shared_params fmax
#' @inheritParams pladdrr_shared_params smooth
#' @return New Sound object
#' @export
#' @examples
#' sound <- Sound$create_tone(frequency = 1000, duration = 0.5)
#' filtered <- sound_filter_stop_hann_band(sound, fmin = 300, fmax = 3000,
#'  smooth = 100)
sound_filter_stop_hann_band <- function(sound, fmin, fmax, smooth = 100) {
    
    # Use existing .sound_filter_stop_hann_band from sound_wrappers.cpp
    xptr <- .sound_filter_stop_hann_band(
        sound$get_xptr(),
        fmin, fmax, smooth
    )
    
    Sound(.xptr = xptr)
}
