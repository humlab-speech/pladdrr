# spectrum-operations.R
# R wrappers for Spectrum operations
# Phase 3.2 - Reuses existing C++ exports

#' Apply cepstral smoothing to spectrum
#'
#' @param spectrum Spectrum object
#' @param bandwidth Smoothing bandwidth (Hz)
#' @return New Spectrum object with smoothing applied
#' @export
#' @examples
#' sound <- Sound$create_tone(frequency = 150, duration = 0.5)
#' spectrum <- sound$to_spectrum()
#' smoothed <- spectrum_cepstral_smoothing(spectrum, bandwidth = 500)
spectrum_cepstral_smoothing <- function(spectrum, bandwidth = 500) {
    # Use existing .spectrum_cepstral_smoothing from spectrum_wrappers.cpp
    xptr <- .spectrum_cepstral_smoothing(
        spectrum$.xptr,
        bandwidth
    )
    
    # Wrap using Spectrum constructor
    Spectrum(.xptr = xptr)
}

#' Apply Hann band-pass filter to spectrum (in-place)
#'
#' @param spectrum Spectrum object (will be modified)
#' @inheritParams pladdrr_shared_params fmin
#' @inheritParams pladdrr_shared_params fmax
#' @inheritParams pladdrr_shared_params smooth
#' @return NULL (modifies spectrum in place)
#' @export
#' @examples
#' sound <- Sound$create_tone(frequency = 150, duration = 0.5)
#' spectrum <- sound$to_spectrum()
#' spectrum_pass_hann_band(spectrum, fmin = 300, fmax = 3000, smooth = 100)
#' # spectrum is now modified
spectrum_pass_hann_band <- function(spectrum, fmin, fmax, smooth = 100) {
    # Use existing .spectrum_pass_hann_band from spectrum_wrappers.cpp
    # This modifies the spectrum in place
    .spectrum_pass_hann_band(
        spectrum$.xptr,
        fmin, fmax, smooth
    )
    
    invisible(NULL)
}

#' Apply Hann band-stop filter to spectrum (in-place)
#'
#' @param spectrum Spectrum object (will be modified)
#' @inheritParams pladdrr_shared_params fmin
#' @inheritParams pladdrr_shared_params fmax
#' @inheritParams pladdrr_shared_params smooth
#' @return NULL (modifies spectrum in place)
#' @export
#' @examples
#' sound <- Sound$create_tone(frequency = 150, duration = 0.5)
#' spectrum <- sound$to_spectrum()
#' spectrum_stop_hann_band(spectrum, fmin = 50, fmax = 100, smooth = 50)
#' # spectrum is now modified
spectrum_stop_hann_band <- function(spectrum, fmin, fmax, smooth = 100) {
    # Use existing .spectrum_stop_hann_band from spectrum_wrappers.cpp
    # This modifies the spectrum in place
    .spectrum_stop_hann_band(
        spectrum$.xptr,
        fmin, fmax, smooth
    )
    
    invisible(NULL)
}
