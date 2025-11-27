#' @title Praat Excitation Object
#' @description
#' R6 class representing a Praat Excitation object. Represents auditory nerve
#' firing rate on an ERB (Equivalent Rectangular Bandwidth) frequency scale.
#'
#' @details
#' An Excitation pattern represents the perceptual loudness distribution across
#' the auditory frequency range, measured in Bark scale. It models the excitation
#' of the auditory nerve fibers at different frequency bands.
#'
#' ## Creating Excitation Objects
#'
#' - `spectrum$to_excitation(erb_density)` - From a Spectrum object
#' - `cochleagram$to_excitation(time)` - Extract from Cochleagram at specific time
#'
#' ## Querying
#'
#' - `$get_loudness()` - Total loudness in sones
#' - `$get_value_at_frequency(freq_bark)` - Excitation at specific frequency
#' - `$get_distance(other)` - Perceptual distance between two excitation patterns
#'
#' ## Transformations
#'
#' - `$to_formant(max_formants)` - Extract formants from excitation pattern
#' - `$as_vector()` - Export to R data frame
#'
#' @examples
#' \dontrun{
#' # Create excitation from spectrum
#' sound <- Sound$new("speech.wav")
#' spectrum <- sound$to_spectrum()
#' excitation <- spectrum$to_excitation(erb_density = 0.1)
#'
#' # Query loudness
#' loudness_sones <- excitation$get_loudness()
#' 
#' # Get excitation at specific frequency
#' exc_1khz <- excitation$get_value_at_frequency(8.5)  # ~1000 Hz in Bark
#'
#' # Compare two excitation patterns
#' sound1 <- Sound$new("vowel_a.wav")
#' sound2 <- Sound$new("vowel_i.wav")
#' exc1 <- sound1$to_spectrum()$to_excitation()
#' exc2 <- sound2$to_spectrum()$to_excitation()
#' perceptual_distance <- exc1$get_distance(exc2)
#'
#' # Extract formants from excitation
#' formant <- excitation$to_formant(max_formants = 5)
#'
#' # Export data
#' exc_data <- excitation$as_vector()
#' plot(exc_data$frequency_bark, exc_data$excitation,
#'      type = "l", xlab = "Frequency (Bark)", ylab = "Excitation")
#' }
#'
#' @export
Excitation <- R6::R6Class("Excitation",
  inherit = PraatObject,
  
  public = list(
    #' @description
    #' Initialize an Excitation object (internal use)
    #' @param .xptr External pointer to Praat Excitation object
    initialize = function(.xptr) {
      if (missing(.xptr) || is.null(.xptr)) {
        stop("Excitation objects should be created via Spectrum$to_excitation() or Cochleagram$to_excitation()")
      }
      super$initialize(.xptr)
    },
    
    #' @description
    #' Get total loudness in sones
    #' @return Loudness value in sones
    get_loudness = function() {
      .excitation_get_loudness(private$ptr)
    },
    
    #' @description
    #' Get excitation value at specific frequency
    #' @param freq_bark Frequency in Bark scale
    #' @return Excitation value
    get_value_at_frequency = function(freq_bark) {
      stopifnot("freq_bark must be numeric" = is.numeric(freq_bark))
      .excitation_get_value_at_frequency(private$ptr, freq_bark)
    },
    
    #' @description
    #' Calculate perceptual distance to another excitation pattern
    #' @param other Another Excitation object
    #' @return Distance value
    get_distance = function(other) {
      stopifnot("other must be an Excitation object" = inherits(other, "Excitation"))
      .excitation_get_distance(private$ptr, other$.__enclos_env__$private$ptr)
    },
    
    #' @description
    #' Extract formants from excitation pattern
    #' @param max_formants Maximum number of formants to extract
    #' @return Formant object
    to_formant = function(max_formants = 5) {
      stopifnot(
        "max_formants must be numeric" = is.numeric(max_formants),
        "max_formants must be positive" = max_formants > 0
      )
      xptr <- .excitation_to_formant(private$ptr, as.integer(max_formants))
      Formant$new(xptr)
    },
    
    #' @description
    #' Export excitation data as R data frame
    #' @return Data frame with frequency_bark and excitation columns
    as_vector = function() {
      .excitation_as_vector(private$ptr)
    },
    
    #' @description
    #' Get excitation information
    #' @return List with frequency domain parameters
    get_info = function() {
      .excitation_get_info(private$ptr)
    },
    
    #' @description
    #' Print excitation information
    #' @param ... Additional arguments (ignored)
    print = function(...) {
      info <- self$get_info()
      loudness <- self$get_loudness()
      cat("Excitation object\n")
      cat(sprintf("  Frequency range: %.1f to %.1f Bark\n", info$xmin, info$xmax))
      cat(sprintf("  Number of frequency bands: %d (df = %.3f Bark)\n", info$nx, info$dx))
      cat(sprintf("  Total loudness: %.2f sones\n", loudness))
      invisible(self)
    }
  )
)
