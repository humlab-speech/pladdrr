#' Generate a sine wave sound
#'
#' Creates a sine wave sound with specified frequency and duration.
#' This is a convenience function that demonstrates sound generation
#' capabilities.
#'
#' @param frequency Frequency of the sine wave in Hz (default: 440)
#' @param duration Duration in seconds (default: 1.0)
#' @param sampling_frequency Sampling frequency in Hz (default: 44100)
#' @param amplitude Maximum amplitude (default: 0.5)
#'
#' @return A sound object (list) containing the sine wave data
#' @export
#'
#' @examples
#' \dontrun{
#' # Generate a 440 Hz (A4) tone for 1 second
#' sound <- generate_sine_wave(440, 1.0)
#' 
#' # Get the duration
#' duration <- get_sound_duration(sound)
#' 
#' # Calculate statistics
#' stats <- sound_stats(sound$values)
#' }
generate_sine_wave <- function(frequency = 440, 
                               duration = 1.0, 
                               sampling_frequency = 44100,
                               amplitude = 0.5) {
    # Generate time points
    n_samples <- as.integer(duration * sampling_frequency)
    t <- seq(0, duration, length.out = n_samples)
    
    # Generate sine wave
    values <- amplitude * sin(2 * pi * frequency * t)
    
    # Create sound object
    create_sound(values, sampling_frequency)
}

#' Print method for PraatSound objects
#'
#' @param x A PraatSound object
#' @param ... Additional arguments (currently unused)
#' @return The object invisibly
#' @export
print.PraatSound <- function(x, ...) {
    cat("Praat Sound Object\n")
    cat("------------------\n")
    cat(sprintf("Duration: %.4f seconds\n", x$duration))
    cat(sprintf("Sampling frequency: %.1f Hz\n", x$sampling_frequency))
    cat(sprintf("Number of samples: %d\n", x$n_samples))
    invisible(x)
}

#' Check if object is a PraatSound
#'
#' @param x An object to check
#' @return Logical indicating if object is a PraatSound
#' @export
is_praat_sound <- function(x) {
    inherits(x, "PraatSound")
}
