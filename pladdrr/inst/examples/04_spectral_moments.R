#' Spectral Moments Analysis
#'
#' Re-implementation of praat_spectral_moments.py using speaker package.
#' This demonstrates the migration from Parselmouth (Python) to speaker (R).
#'
#' Spectral moments characterize the shape of the spectrum:
#' - Center of Gravity (Moment 1): Average frequency weighted by amplitude
#' - Standard Deviation (Moment 2): Spread of energy across frequencies
#' - Skewness (Moment 3): Asymmetry of the spectral distribution
#' - Kurtosis (Moment 4): "Peakedness" of the spectral distribution
#'
#' Python (Parselmouth):
#' ```python
#' import parselmouth as pm
#' sound = pm.Sound("audio.wav")
#' spectrogram = pm.praat.call(sound, "To Spectrogram", 0.005, 5000, 0.005, 20, "Gaussian")
#' spectrum = pm.praat.call(spectrogram, "To Spectrum (slice)", time)
#' cog = pm.praat.call(spectrum, "Get centre of gravity", 2.0)
#' ```
#'
#' R (speaker):
#' ```r
#' library(speaker)
#' sound <- Sound$new("audio.wav")
#' spectrogram <- sound$to_spectrogram(window_length = 0.005, max_frequency = 5000,
#'                                      time_step = 0.005, frequency_step = 20)
#' spectrum <- spectrogram$to_spectrum(time = 0.5)
#' cog <- spectrum$get_centre_of_gravity(power = 2.0)
#' ```
#'
#' Key differences:
#' - R6 methods instead of pm.praat.call()
#' - Named parameters in snake_case
#' - Direct method calls on objects
#' - No separate praat.call() function needed
#' - Returns R data.frame instead of pandas DataFrame

library(speaker)

#' Compute Spectral Moments from Sound
#'
#' @param sound A Sound object
#' @param begin_time Start time for analysis (0.0 for full file)
#' @param end_time End time for analysis (0.0 for full file)
#' @param window_length Analysis window length (in seconds)
#' @param maximum_frequency Maximum frequency to analyze (Hz). If 0.0, uses Nyquist frequency
#' @param time_step Time step between frames (in seconds)
#' @param frequency_step Frequency resolution (in Hz)
#' @param power Power for moment calculation (typically 2)
#'
#' @return data.frame with columns: time, centre_of_gravity, standard_deviation, skewness, kurtosis
#'
#' @export
#' @examples
#' \dontrun{
#' sound <- Sound$new("audio.wav")
#' moments <- praat_spectral_moments(sound)
#' 
#' # Plot center of gravity over time
#' plot(moments$time, moments$centre_of_gravity, type = "l",
#'      xlab = "Time (s)", ylab = "Center of Gravity (Hz)",
#'      main = "Spectral Center of Gravity")
#' }
praat_spectral_moments <- function(
    sound,
    begin_time = 0.0,
    end_time = 0.0,
    window_length = 0.005,
    maximum_frequency = 0.0,
    time_step = 0.005,
    frequency_step = 20.0,
    power = 2.0
) {
  
  # Validate input
  if (!inherits(sound, "Sound")) {
    stop("Input must be a Sound object")
  }
  
  # Get sound properties
  duration <- sound$get_total_duration()
  sampling_frequency <- sound$get_sampling_frequency()
  
  # Set maximum frequency to Nyquist if not specified
  if (maximum_frequency == 0.0) {
    maximum_frequency <- sampling_frequency / 2.0
  }
  
  # Handle time windowing if needed
  snd <- sound
  if (begin_time > 0.0 && end_time > 0.0 && 
      begin_time >= 0.0 && end_time <= duration) {
    snd <- sound$extract_part(from_time = begin_time, 
                               to_time = end_time,
                               preserve_times = TRUE)
  }
  
  # Create spectrogram
  spectrogram <- snd$to_spectrogram(
    window_length = window_length,
    max_frequency = maximum_frequency,
    time_step = time_step,
    frequency_step = frequency_step,
    window_shape = "Gaussian"
  )
  
  # Get number of frames
  num_frames <- spectrogram$get_number_of_frames()
  
  # Initialize result vectors
  times <- numeric(num_frames)
  cogs <- numeric(num_frames)
  sds <- numeric(num_frames)
  skewnesses <- numeric(num_frames)
  kurtoses <- numeric(num_frames)
  
  # Process each frame
  for (i in 1:num_frames) {
    # Get time for this frame
    curr_time <- spectrogram$get_time_from_frame(frame = i)
    
    # Extract spectrum slice at this time
    spectrum <- spectrogram$to_spectrum(time = curr_time)
    
    # Compute spectral moments
    cog <- spectrum$get_centre_of_gravity(power = power)
    sd <- spectrum$get_standard_deviation(power = power)
    skew <- spectrum$get_skewness(power = power)
    kurt <- spectrum$get_kurtosis(power = power)
    
    # Store results
    times[i] <- curr_time
    cogs[i] <- cog
    sds[i] <- sd
    skewnesses[i] <- skew
    kurtoses[i] <- kurt
    
    # Note: No explicit cleanup needed - XPtr finalizers handle memory
  }
  
  # Return as data frame
  data.frame(
    time = times,
    centre_of_gravity = cogs,
    standard_deviation = sds,
    skewness = skewnesses,
    kurtosis = kurtoses,
    stringsAsFactors = FALSE
  )
}


# Example usage and demonstration
if (interactive()) {
  
  cat("\n=== Spectral Moments Analysis Example ===\n\n")
  
  # Example 1: Analyze a vowel sound
  cat("Example 1: Vowel Analysis\n")
  cat("-------------------------\n")
  
  # Create a synthetic vowel (e.g., /a/)
  sound_vowel <- Sound$create_simple(
    duration = 1.0,
    sampling_frequency = 44100
  )
  
  # Compute spectral moments
  moments <- praat_spectral_moments(
    sound = sound_vowel,
    window_length = 0.005,
    maximum_frequency = 5000,
    time_step = 0.01,
    frequency_step = 20,
    power = 2.0
  )
  
  cat(sprintf("Computed %d frames\n", nrow(moments)))
  cat(sprintf("Mean COG: %.1f Hz\n", mean(moments$centre_of_gravity)))
  cat(sprintf("Mean SD: %.1f Hz\n", mean(moments$standard_deviation)))
  cat(sprintf("Mean Skewness: %.3f\n", mean(moments$skewness)))
  cat(sprintf("Mean Kurtosis: %.3f\n\n", mean(moments$kurtosis)))
  
  # Example 2: Real audio file (if available)
  audio_file <- "test_audio.wav"
  if (file.exists(audio_file)) {
    cat("Example 2: Real Audio File\n")
    cat("--------------------------\n")
    
    sound <- Sound$new(audio_file)
    
    # Analyze specific time window
    moments <- praat_spectral_moments(
      sound = sound,
      begin_time = 0.5,
      end_time = 1.5,
      window_length = 0.005,
      maximum_frequency = 5000,
      time_step = 0.01
    )
    
    cat(sprintf("Analysis window: 0.5 - 1.5 seconds\n"))
    cat(sprintf("Number of frames: %d\n", nrow(moments)))
    cat(sprintf("COG range: %.1f - %.1f Hz\n", 
                min(moments$centre_of_gravity), 
                max(moments$centre_of_gravity)))
    
    # Plot results
    par(mfrow = c(2, 2))
    
    plot(moments$time, moments$centre_of_gravity, type = "l",
         xlab = "Time (s)", ylab = "Frequency (Hz)",
         main = "Center of Gravity", col = "blue", lwd = 2)
    
    plot(moments$time, moments$standard_deviation, type = "l",
         xlab = "Time (s)", ylab = "Frequency (Hz)",
         main = "Standard Deviation", col = "red", lwd = 2)
    
    plot(moments$time, moments$skewness, type = "l",
         xlab = "Time (s)", ylab = "Skewness",
         main = "Skewness", col = "green", lwd = 2)
    abline(h = 0, lty = 2, col = "gray")
    
    plot(moments$time, moments$kurtosis, type = "l",
         xlab = "Time (s)", ylab = "Kurtosis",
         main = "Kurtosis", col = "purple", lwd = 2)
    abline(h = 3, lty = 2, col = "gray")  # Normal distribution reference
    
    par(mfrow = c(1, 1))
  }
  
  # Example 3: Comparison of different sounds
  cat("\nExample 3: Comparing Different Sounds\n")
  cat("-------------------------------------\n")
  
  # Create different synthetic sounds
  sound_low <- Sound$create_tone(
    frequency = 200,
    duration = 0.5,
    sampling_frequency = 44100
  )
  
  sound_high <- Sound$create_tone(
    frequency = 800,
    duration = 0.5,
    sampling_frequency = 44100
  )
  
  # Analyze both
  moments_low <- praat_spectral_moments(sound_low, time_step = 0.05)
  moments_high <- praat_spectral_moments(sound_high, time_step = 0.05)
  
  cat(sprintf("Low frequency (200 Hz):\n"))
  cat(sprintf("  Mean COG: %.1f Hz\n", mean(moments_low$centre_of_gravity)))
  cat(sprintf("  Mean SD: %.1f Hz\n", mean(moments_low$standard_deviation)))
  
  cat(sprintf("\nHigh frequency (800 Hz):\n"))
  cat(sprintf("  Mean COG: %.1f Hz\n", mean(moments_high$centre_of_gravity)))
  cat(sprintf("  Mean SD: %.1f Hz\n\n", mean(moments_high$standard_deviation)))
  
  # Example 4: Integration with tidyverse
  if (requireNamespace("ggplot2", quietly = TRUE) && 
      requireNamespace("dplyr", quietly = TRUE)) {
    
    library(ggplot2)
    library(dplyr)
    
    cat("Example 4: Tidyverse Integration\n")
    cat("--------------------------------\n")
    
    # Create complex sound
    sound_complex <- Sound$create_tone(
      frequency = 440,
      duration = 1.0,
      sampling_frequency = 44100
    )
    
    # Compute moments
    moments <- praat_spectral_moments(sound_complex, time_step = 0.01)
    
    # Tidy workflow
    moments_summary <- moments %>%
      summarise(
        mean_cog = mean(centre_of_gravity),
        sd_cog = sd(centre_of_gravity),
        mean_spread = mean(standard_deviation),
        mean_skewness = mean(skewness),
        mean_kurtosis = mean(kurtosis)
      )
    
    print(moments_summary)
    
    # ggplot visualization
    p <- ggplot(moments, aes(x = time)) +
      geom_line(aes(y = centre_of_gravity, color = "COG"), size = 1) +
      geom_ribbon(aes(ymin = centre_of_gravity - standard_deviation,
                      ymax = centre_of_gravity + standard_deviation),
                  alpha = 0.2) +
      labs(title = "Spectral Moments Over Time",
           x = "Time (s)", y = "Frequency (Hz)",
           color = "Measure") +
      theme_minimal()
    
    print(p)
  }
  
  cat("\n=== Analysis Complete ===\n")
}


#' Python to R Translation Notes
#'
#' Key API differences between Parselmouth and speaker:
#'
#' 1. Object creation:
#'    Python: sound = pm.Sound("file.wav")
#'    R:      sound <- Sound$new("file.wav")
#'
#' 2. Method calls:
#'    Python: pm.praat.call(obj, "Method name", params)
#'    R:      obj$method_name(params)
#'
#' 3. Spectrogram creation:
#'    Python: pm.praat.call(sound, "To Spectrogram", 0.005, 5000, 0.005, 20, "Gaussian")
#'    R:      sound$to_spectrogram(window_length = 0.005, max_frequency = 5000,
#'                                   time_step = 0.005, frequency_step = 20,
#'                                   window_shape = "Gaussian")
#'
#' 4. Spectrum extraction:
#'    Python: pm.praat.call(spectrogram, "To Spectrum (slice)", time)
#'    R:      spectrogram$to_spectrum(time = time)
#'
#' 5. Spectral moments:
#'    Python: pm.praat.call(spectrum, "Get centre of gravity", power)
#'    R:      spectrum$get_centre_of_gravity(power = power)
#'
#' 6. Memory management:
#'    Python: pm.praat.call(obj, "Remove")  # Explicit cleanup
#'    R:      # Automatic via XPtr finalizers
#'
#' 7. Return types:
#'    Python: Returns pandas DataFrame
#'    R:      Returns R data.frame (directly compatible with tidyverse)
#'
#' Advantages of R approach:
#' - More intuitive object-oriented syntax
#' - Better IDE autocomplete support
#' - Automatic memory management
#' - Native R data structures
#' - No intermediate string parsing
#' - Type safety via R6 validation
