#' Spectrum Object
#'
#' @description
#' Praat Spectrum object with direct C++ module binding (complex FFT spectrum).
#' Spectrum objects represent frequency-domain representations of sounds.
#'
#' @section Methods:
#'
#' **Query Methods:**
#' * `get_lowest_frequency()` - Get lowest frequency (Hz)
#' * `get_highest_frequency()` - Get highest frequency (Hz)
#' * `get_number_of_bins()` - Get number of frequency bins
#' * `get_frequency_step()` - Get frequency step (Hz)
#' * `get_real_value_in_bin(bin)` - Get real part at bin
#' * `get_imaginary_value_in_bin(bin)` - Get imaginary part at bin
#' * `get_frequency_from_bin(bin)` - Get frequency for bin number
#' * `get_bin_from_frequency(freq)` - Get bin number for frequency
#' * `get_band_density(fmin, fmax)` - Get power density in band (Pa²/Hz²)
#' * `get_band_energy(fmin, fmax)` - Get energy in band (Pa²·s)
#' * `get_centre_of_gravity(power = 2.0)` - Get spectral center of gravity
#' * `get_standard_deviation(power = 2.0)` - Get spectral standard deviation
#' * `get_skewness(power = 2.0)` - Get spectral skewness
#' * `get_kurtosis(power = 2.0)` - Get spectral kurtosis
#' * `get_central_moment(moment, power = 2.0)` - Get central moment
#'
#' **Modification Methods:**
#' * `pass_hann_band(fmin, fmax, smooth = 100)` - Apply Hann band-pass filter
#' * `stop_hann_band(fmin, fmax, smooth = 100)` - Apply Hann band-stop filter
#' * `cepstral_smoothing(bandwidth)` - Smooth using cepstral method
#'
#' **Transform Methods:**
#' * `to_sound()` - Convert to Sound (inverse FFT)
#' * `to_ltas(bandwidth)` - Convert to long-term average spectrum
#' * `to_spectrogram(...)` - Convert to Spectrogram
#' * `to_excitation(erb_density)` - Convert to Excitation (auditory representation)
#'
#' **Export Methods:**
#' * `as_matrix()` - Export as numeric matrix (real + imaginary)
#' * `as_data_frame()` - Export as data.frame (freq, real, imag, power)
#' * `save(path)` - Save to file
#'
#' @examples
#' \dontrun{
#' # Create spectrum from sound
#' sound <- Sound$new(system.file("extdata", "example.wav", package = "speaker"))
#' spectrum <- sound$to_spectrum(fast = TRUE)
#' 
#' # Query spectral properties
#' cog <- spectrum$get_centre_of_gravity(power = 2.0)
#' sd <- spectrum$get_standard_deviation(power = 2.0)
#' 
#' # Get energy in frequency band
#' energy_500_2000 <- spectrum$get_band_energy(fmin = 500, fmax = 2000)
#' 
#' # Export to data frame
#' spec_df <- spectrum$as_data_frame()
#' }
#'
#' @export
Spectrum <- function(.xptr = NULL) {
  if (is.null(.xptr)) {
    stop("Spectrum objects must be created from Sound using to_spectrum()")
  }
  
  # Load module
  spectrum_mod <- get_module("spectrum_module")
  cpp_obj <- spectrum_mod$RSpectrum$new(.xptr)
  
  obj <- structure(list(
    .cpp = cpp_obj,
    .xptr = .xptr,  # Keep for legacy exports
    
    # Query: Basic info
    get_lowest_frequency = function() {
      cpp_obj$get_fmin()
    },
    
    get_highest_frequency = function() {
      cpp_obj$get_fmax()
    },
    
    get_number_of_bins = function() {
      cpp_obj$get_n_bins()
    },
    
    get_frequency_step = function() {
      cpp_obj$get_df()
    },
    
    get_frequency_from_bin = function(bin) {
      cpp_obj$get_frequency_from_bin(as.integer(bin))
    },
    
    get_bin_from_frequency = function(frequency) {
      cpp_obj$get_bin_from_frequency(as.numeric(frequency))
    },
    
    # Query: Values
    get_real_value_in_bin = function(bin) {
      cpp_obj$get_real_value_at_bin(as.integer(bin))
    },
    
    get_imaginary_value_in_bin = function(bin) {
      cpp_obj$get_imaginary_value_at_bin(as.integer(bin))
    },
    
    # Query: Band statistics
    get_band_density = function(fmin, fmax) {
      cpp_obj$get_band_density(as.numeric(fmin), as.numeric(fmax))
    },
    
    get_band_energy = function(fmin, fmax) {
      cpp_obj$get_band_energy(as.numeric(fmin), as.numeric(fmax))
    },
    
    # Query: Spectral moments
    get_centre_of_gravity = function(power = 2.0) {
      cpp_obj$get_centre_of_gravity(as.numeric(power))
    },
    
    get_standard_deviation = function(power = 2.0) {
      cpp_obj$get_standard_deviation(as.numeric(power))
    },
    
    get_skewness = function(power = 2.0) {
      cpp_obj$get_skewness(as.numeric(power))
    },
    
    get_kurtosis = function(power = 2.0) {
      cpp_obj$get_kurtosis(as.numeric(power))
    },
    
    get_central_moment = function(moment, power = 2.0) {
      cpp_obj$get_central_moment(as.numeric(moment), as.numeric(power))
    },
    
    # Modification
    pass_hann_band = function(fmin, fmax, smooth = 100) {
      .spectrum_pass_hann_band(.xptr, as.numeric(fmin), as.numeric(fmax), as.numeric(smooth))
      invisible(obj)
    },
    
    stop_hann_band = function(fmin, fmax, smooth = 100) {
      .spectrum_stop_hann_band(.xptr, as.numeric(fmin), as.numeric(fmax), as.numeric(smooth))
      invisible(obj)
    },
    
    cepstral_smoothing = function(bandwidth) {
      ptr <- .spectrum_cepstral_smoothing(.xptr, as.numeric(bandwidth))
      Spectrum(.xptr = ptr)
    },
    
    formula = function(formula) {
      .spectrum_formula(.xptr, formula)
      invisible(obj)
    },
    
    apply_pre_emphasis = function(from_frequency = 50) {
      .spectrum_apply_pre_emphasis(.xptr, as.numeric(from_frequency))
      invisible(obj)
    },
    
    multiply_by_frequency = function(power = 1.0) {
      .spectrum_multiply_by_frequency(.xptr, as.numeric(power))
      invisible(obj)
    },
    
    # Transform
    to_sound = function() {
      ptr <- .spectrum_to_sound(.xptr)
      Sound$new(.xptr = ptr)
    },
    
    to_ltas_1to1 = function() {
      ptr <- .spectrum_to_ltas_1to1(.xptr)
      Ltas(.xptr = ptr)
    },
    
    to_powercepstrum = function() {
      ptr <- .spectrum_to_powercepstrum(.xptr)
      PowerCepstrum$new(.xptr = ptr)
    },
    
    to_cepstrum = function() {
      xptr <- .spectrum_to_cepstrum(.xptr)
      Cepstrum$new(xptr)
    },
    
    to_cepstrum_hillenbrand = function() {
      xptr <- .spectrum_to_cepstrum_hillenbrand(.xptr)
      Cepstrum$new(xptr)
    },
    
    to_excitation = function(erb_density = 0.1) {
      stopifnot(
        "erb_density must be a positive number" = is.numeric(erb_density) && length(erb_density) == 1 && erb_density > 0
      )
      ptr <- .spectrum_to_excitation(.xptr, as.numeric(erb_density))
      Excitation$new(.xptr = ptr)
    },
    
    # Export
    as_matrix = function() {
      .spectrum_as_matrix(.xptr)
    },
    
    as_data_frame = function() {
      mat <- obj$as_matrix()
      nbins <- ncol(mat)
      
      freq <- vapply(seq_len(nbins), function(i) obj$get_frequency_from_bin(i), numeric(1))
      real_vals <- mat[1, ]
      imag_vals <- mat[2, ]
      
      power <- real_vals^2 + imag_vals^2
      phase <- atan2(imag_vals, real_vals)
      
      data.frame(
        bin = seq_len(nbins),
        frequency = freq,
        real = real_vals,
        imaginary = imag_vals,
        power = power,
        phase = phase,
        stringsAsFactors = FALSE
      )
    },
    
    # Display
    print = function() {
      cat("<Praat Spectrum>\n")
      cat(sprintf("  Frequency range: %.2f - %.2f Hz\n", 
                  cpp_obj$get_fmin(), 
                  cpp_obj$get_fmax()))
      cat(sprintf("  Number of bins: %d\n", cpp_obj$get_n_bins()))
      cat(sprintf("  Frequency step: %.2f Hz\n", cpp_obj$get_df()))
      invisible(obj)
    }
    
  ), class = c("Spectrum", "PraatObject"))
  
  obj
}

# S3 methods
#' @export
print.Spectrum <- function(x, ...) {
  x$print()
}

#' @export
as.data.frame.Spectrum <- function(x, ...) {
  x$as_data_frame()
}
