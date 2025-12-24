#' Spectrum R6 Class
#'
#' @description
#' R6 class representing a Praat Spectrum object (complex FFT spectrum).
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
Spectrum <- R6::R6Class("Spectrum",
  inherit = PraatObject,
  
  public = list(
    #' @description Create a new Spectrum object
    #' @param .xptr External pointer to Praat Spectrum object
    initialize = function(.xptr = NULL) {
      if (is.null(.xptr)) {
        stop("Spectrum objects must be created from Sound using to_spectrum()")
      }
      private$ptr <- .xptr
      private$type <- "Spectrum"
    },
    
    # Query: Basic info
    
    #' @description Get lowest frequency
    #' @return Lowest frequency in Hz
    get_lowest_frequency = function() {
      .spectrum_get_lowest_frequency(private$ptr)
    },
    
    #' @description Get highest frequency
    #' @return Highest frequency in Hz
    get_highest_frequency = function() {
      .spectrum_get_highest_frequency(private$ptr)
    },
    
    #' @description Get number of frequency bins
    #' @return Number of bins
    get_number_of_bins = function() {
      .spectrum_get_number_of_bins(private$ptr)
    },
    
    #' @description Get frequency step
    #' @return Frequency step in Hz
    get_frequency_step = function() {
      .spectrum_get_frequency_step(private$ptr)
    },
    
    #' @description Get frequency for bin number
    #' @param bin Bin number (1-indexed)
    #' @return Frequency in Hz
    get_frequency_from_bin = function(bin) {
      .spectrum_get_frequency_from_bin(private$ptr, as.integer(bin))
    },
    
    #' @description Get bin number for frequency
    #' @param frequency Frequency in Hz
    #' @return Bin number (may be fractional)
    get_bin_from_frequency = function(frequency) {
      .spectrum_get_bin_from_frequency(private$ptr, as.numeric(frequency))
    },
    
    # Query: Values
    
    #' @description Get real part at bin
    #' @param bin Bin number (1-indexed)
    #' @return Real value
    get_real_value_in_bin = function(bin) {
      .spectrum_get_real_value_in_bin(private$ptr, as.integer(bin))
    },
    
    #' @description Get imaginary part at bin
    #' @param bin Bin number (1-indexed)
    #' @return Imaginary value
    get_imaginary_value_in_bin = function(bin) {
      .spectrum_get_imaginary_value_in_bin(private$ptr, as.integer(bin))
    },
    
    # Query: Band statistics
    
    #' @description Get power density in frequency band
    #' @param fmin Minimum frequency (Hz)
    #' @param fmax Maximum frequency (Hz)
    #' @return Power density (Pa²/Hz²)
    get_band_density = function(fmin, fmax) {
      .spectrum_get_band_density(private$ptr, as.numeric(fmin), as.numeric(fmax))
    },
    
    #' @description Get energy in frequency band
    #' @param fmin Minimum frequency (Hz)
    #' @param fmax Maximum frequency (Hz)
    #' @return Energy (Pa²·s)
    get_band_energy = function(fmin, fmax) {
      .spectrum_get_band_energy(private$ptr, as.numeric(fmin), as.numeric(fmax))
    },
    
    # Query: Spectral moments
    
    #' @description Get spectral centre of gravity
    #' @param power Power to raise power density to (default: 2.0)
    #' @return Centre of gravity in Hz
    get_centre_of_gravity = function(power = 2.0) {
      .spectrum_get_centre_of_gravity(private$ptr, as.numeric(power))
    },
    
    #' @description Get spectral standard deviation
    #' @param power Power to raise power density to (default: 2.0)
    #' @return Standard deviation in Hz
    get_standard_deviation = function(power = 2.0) {
      .spectrum_get_standard_deviation(private$ptr, as.numeric(power))
    },
    
    #' @description Get spectral skewness
    #' @param power Power to raise power density to (default: 2.0)
    #' @return Skewness
    get_skewness = function(power = 2.0) {
      .spectrum_get_skewness(private$ptr, as.numeric(power))
    },
    
    #' @description Get spectral kurtosis
    #' @param power Power to raise power density to (default: 2.0)
    #' @return Kurtosis
    get_kurtosis = function(power = 2.0) {
      .spectrum_get_kurtosis(private$ptr, as.numeric(power))
    },
    
    #' @description Get spectral central moment
    #' @param moment Moment order
    #' @param power Power to raise power density to (default: 2.0)
    #' @return Central moment
    get_central_moment = function(moment, power = 2.0) {
      .spectrum_get_central_moment(private$ptr, as.numeric(moment), as.numeric(power))
    },
    
    # Modification
    
    #' @description Apply Hann band-pass filter
    #' @param fmin Minimum frequency (Hz)
    #' @param fmax Maximum frequency (Hz)
    #' @param smooth Smoothing width (Hz, default: 100)
    #' @return Self (invisibly)
    pass_hann_band = function(fmin, fmax, smooth = 100) {
      .spectrum_pass_hann_band(private$ptr, as.numeric(fmin), as.numeric(fmax), as.numeric(smooth))
      invisible(self)
    },
    
    #' @description Apply Hann band-stop filter
    #' @param fmin Minimum frequency (Hz)
    #' @param fmax Maximum frequency (Hz)
    #' @param smooth Smoothing width (Hz, default: 100)
    #' @return Self (invisibly)
    stop_hann_band = function(fmin, fmax, smooth = 100) {
      .spectrum_stop_hann_band(private$ptr, as.numeric(fmin), as.numeric(fmax), as.numeric(smooth))
      invisible(self)
    },
    
    #' @description Smooth spectrum using cepstral method
    #' @param bandwidth Bandwidth (Hz)
    #' @return New smoothed Spectrum
    cepstral_smoothing = function(bandwidth) {
      ptr <- .spectrum_cepstral_smoothing(private$ptr, as.numeric(bandwidth))
      Spectrum$new(.xptr = ptr)
    },
    
    #' @description
    #' Apply formula to modify spectrum values (NOT AVAILABLE)
    #'
    #' Note: This method is not available because it requires Praat's script
    #' interpreter which is not integrated. Use apply_pre_emphasis() instead
    #' for pre-emphasis filtering, or manipulate values via as_matrix().
    #'
    #' @param formula Character string with formula
    #' @return Error - use alternative methods
    formula = function(formula) {
      stop("Spectrum$formula() is not available (requires Praat interpreter). ",
           "Use apply_pre_emphasis() for pre-emphasis, or get values with as_matrix(), ",
           "modify in R, then create new Sound from modified spectrum.")
    },

    #' @description
    #' Apply pre-emphasis filter (boost high frequencies)
    #'
    #' Multiplies spectrum values by frequency for frequencies >= from_frequency.
    #' This is equivalent to Praat formula: "if x >= from_frequency then self*x else self fi"
    #' Used in voice quality analysis to compensate for spectral tilt.
    #'
    #' @param from_frequency Frequency (Hz) above which to apply pre-emphasis (default: 50)
    #' @return Self (invisibly, modifies in place)
    #' @examples
    #' \dontrun{
    #' spectrum <- sound$to_spectrum()
    #' spectrum$apply_pre_emphasis(50)  # Standard pre-emphasis
    #' ltas <- spectrum$to_ltas_1to1()
    #' }
    apply_pre_emphasis = function(from_frequency = 50) {
      .spectrum_apply_pre_emphasis(private$ptr, as.numeric(from_frequency))
      invisible(self)
    },

    #' @description
    #' Multiply spectrum by frequency raised to a power
    #'
    #' Useful for spectral tilt corrections. Multiplies each bin's values
    #' by frequency^power.
    #'
    #' @param power Exponent for frequency (default: 1.0)
    #' @return Self (invisibly, modifies in place)
    multiply_by_frequency = function(power = 1.0) {
      .spectrum_multiply_by_frequency(private$ptr, as.numeric(power))
      invisible(self)
    },
    
    # Transform
    
    #' @description Convert to Sound (inverse FFT)
    #' @return Sound object
    to_sound = function() {
      ptr <- .spectrum_to_sound(private$ptr)
      Sound$new(.xptr = ptr)
    },
    
    #' @description
    #' Convert to LTAS (1-to-1 bin mapping)
    #' Corresponds to Praat: To Ltas (1-to-1)
    #' Creates LTAS with same frequency bins as spectrum
    #' @return Ltas object
    to_ltas_1to1 = function() {
      ptr <- .spectrum_to_ltas_1to1(private$ptr)
      Ltas$new(.xptr = ptr)
    },
    
    #' @description Convert to PowerCepstrum (for voice quality analysis)
    #' @return PowerCepstrum object
    to_powercepstrum = function() {
      ptr <- .spectrum_to_powercepstrum(private$ptr)
      PowerCepstrum$new(.xptr = ptr)
    },
    
    #' @description
    #' Convert to Cepstrum (complex cepstrum with phase)
    #' 
    #' Computes the complex cepstrum from the spectrum. Unlike PowerCepstrum,
    #' this preserves phase information and can be inverted back to Spectrum or Sound.
    #' 
    #' @return Cepstrum object
    to_cepstrum = function() {
      xptr <- .spectrum_to_cepstrum(private$ptr)
      Cepstrum$new(xptr)
    },
    
    #' @description
    #' Convert to Cepstrum using Hillenbrand method
    #' 
    #' Alternative cepstrum computation method based on Hillenbrand's algorithm.
    #' 
    #' @return Cepstrum object
    to_cepstrum_hillenbrand = function() {
      xptr <- .spectrum_to_cepstrum_hillenbrand(private$ptr)
      Cepstrum$new(xptr)
    },
    
    #' @description Convert to Excitation (auditory nerve firing rate)
    #' Corresponds to Praat: To Excitation
    #' Applies ERB-scale auditory filtering and perceptual weighting.
    #' @param erb_density Frequency step in ERB scale (default: 0.1)
    #' @return Excitation object
    to_excitation = function(erb_density = 0.1) {
      if (!is.numeric(erb_density) || length(erb_density) != 1 || erb_density <= 0) {
        stop("erb_density must be a positive number")
      }
      ptr <- .spectrum_to_excitation(private$ptr, as.numeric(erb_density))
      Excitation$new(.xptr = ptr)
    },
    
    # Export
    
    #' @description Export as matrix (row 1 = real, row 2 = imaginary)
    #' @return Numeric matrix (2 × nbins)
    as_matrix = function() {
      .spectrum_as_matrix(private$ptr)
    },
    
    #' @description Export as data frame
    #' @return data.frame with columns: bin, frequency, real, imaginary, power, phase
    as_data_frame = function() {
      mat <- self$as_matrix()
      nbins <- ncol(mat)
      
      freq <- vapply(seq_len(nbins), function(i) self$get_frequency_from_bin(i), numeric(1))
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
    
    #' @description Print spectrum information
    print = function() {
      cat("<Praat Spectrum>\n")
      cat(sprintf("  Frequency range: %.2f - %.2f Hz\n", 
                  self$get_lowest_frequency(), 
                  self$get_highest_frequency()))
      cat(sprintf("  Number of bins: %d\n", self$get_number_of_bins()))
      cat(sprintf("  Frequency step: %.2f Hz\n", self$get_frequency_step()))
      invisible(self)
    }
  ),
  
  private = list(
    ptr = NULL,
    type = "Spectrum"
  )
)
