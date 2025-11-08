#' @title Sound Class
#' @description
#' R6 class representing a Praat Sound object. Holds a pointer to a C++
#' Praat Sound object for efficient, zero-copy operations.
#'
#' @details
#' The Sound class wraps Praat's Sound object, providing an object-oriented
#' interface that mirrors Praat's design. Data remains in C++ memory for
#' performance; use `as_data_frame()` to export data to R when needed.
#'
#' @examples
#' \dontrun{
#' # Create from file
#' sound <- Sound$new("audio.wav")
#'
#' # Query properties
#' duration <- sound$get_duration()
#' sr <- sound$get_sampling_frequency()
#'
#' # Transform to other object types
#' pitch <- sound$to_pitch(pitch_floor = 75, pitch_ceiling = 600)
#' formants <- sound$to_formant_burg(max_formant = 5500)
#'
#' # Export to R data.frame
#' df <- sound$as_data_frame()
#' }
#'
#' @export
Sound <- R6::R6Class(
  "Sound",
  inherit = PraatObject,
  
  public = list(
    #' @description
    #' Create a new Sound object
    #' @param path Path to audio file (WAV, AIFF, etc.), or NULL if from_pointer
    #' @param from_pointer Internal: External pointer from C++
    #' @return A new Sound object
    initialize = function(path = NULL, from_pointer = NULL) {
      if (!is.null(from_pointer)) {
        # Internal use: wrapping existing C++ object
        super$initialize(from_pointer)
      } else if (!is.null(path)) {
        # Read from file
        if (!file.exists(path)) {
          stop("File not found: ", path)
        }
        ptr <- .sound_read_from_file(path)
        super$initialize(ptr)
      } else {
        stop("Must provide either 'path' or 'from_pointer'")
      }
    },
    
    #' @description
    #' Get the duration of the sound in seconds
    #' @return numeric Duration in seconds
    get_duration = function() {
      private$check_valid()
      .sound_get_duration(private$ptr)
    },
    
    #' @description
    #' Get the sampling frequency in Hz
    #' @return numeric Sampling frequency in Hz
    get_sampling_frequency = function() {
      private$check_valid()
      .sound_get_sampling_frequency(private$ptr)
    },
    
    #' @description
    #' Get the number of channels
    #' @return integer Number of channels (1 = mono, 2 = stereo)
    get_number_of_channels = function() {
      private$check_valid()
      .sound_get_number_of_channels(private$ptr)
    },
    
    #' @description
    #' Get the total number of samples
    #' @return integer Total number of samples
    get_number_of_samples = function() {
      private$check_valid()
      .sound_get_number_of_samples(private$ptr)
    },
    
    #' @description
    #' Get time value for a specific sample number
    #' @param sample Sample number (1-based indexing)
    #' @return numeric Time in seconds
    get_time_from_sample = function(sample) {
      private$check_valid()
      if (!is.numeric(sample) || sample < 1) {
        stop("sample must be a positive integer")
      }
      .sound_get_time_from_sample(private$ptr, as.integer(sample))
    },
    
    #' @description
    #' Get amplitude value at a specific time
    #' @param time Time in seconds
    #' @param channel Channel number (default: 1)
    #' @return numeric Amplitude value
    get_value_at_time = function(time, channel = 1) {
      private$check_valid()
      if (!is.numeric(time)) {
        stop("time must be numeric")
      }
      if (!is.numeric(channel) || channel < 1) {
        stop("channel must be a positive integer")
      }
      .sound_get_value_at_time(private$ptr, time, as.integer(channel))
    },
    
    #' @description
    #' Transform Sound to Pitch object (fundamental frequency analysis)
    #' @param time_step Time step in seconds (0 = auto: 0.75 / pitch_floor)
    #' @param pitch_floor Minimum pitch in Hz (default: 75)
    #' @param pitch_ceiling Maximum pitch in Hz (default: 600)
    #' @return Pitch object
    to_pitch = function(time_step = 0.0, pitch_floor = 75.0, pitch_ceiling = 600.0) {
      private$check_valid()
      
      # Validate parameters
      if (!is.numeric(time_step) || time_step < 0) {
        stop("time_step must be non-negative")
      }
      if (!is.numeric(pitch_floor) || pitch_floor <= 0) {
        stop("pitch_floor must be positive")
      }
      if (!is.numeric(pitch_ceiling) || pitch_ceiling <= pitch_floor) {
        stop("pitch_ceiling must be greater than pitch_floor")
      }
      
      # Call C++ to create Pitch object
      pitch_ptr <- .sound_to_pitch(private$ptr, time_step, pitch_floor, pitch_ceiling)
      
      # Return new Pitch R6 object
      Pitch$new(from_pointer = pitch_ptr)
    },
    
    #' @description
    #' Extract a portion of the sound
    #' @param from_time Start time in seconds
    #' @param to_time End time in seconds
    #' @return Sound object (subset)
    extract_part = function(from_time, to_time) {
      private$check_valid()
      
      if (!is.numeric(from_time) || !is.numeric(to_time)) {
        stop("from_time and to_time must be numeric")
      }
      if (from_time >= to_time) {
        stop("from_time must be less than to_time")
      }
      
      # Call C++ to extract part
      part_ptr <- .sound_extract_part(private$ptr, from_time, to_time)
      
      # Return new Sound R6 object
      Sound$new(from_pointer = part_ptr)
    },
    
    #' @description
    #' Scale the intensity to a target level (in-place modification)
    #' @param new_average_intensity Target average intensity in dB
    #' @return invisible(self) for method chaining
    scale_intensity = function(new_average_intensity) {
      private$check_valid()
      
      if (!is.numeric(new_average_intensity)) {
        stop("new_average_intensity must be numeric")
      }
      
      # Call C++ to modify in-place
      .sound_scale_intensity(private$ptr, new_average_intensity)
      
      invisible(self)
    },
    
    #' @description
    #' Export sound data to R data.frame
    #' @return data.frame with columns: time, value (and channel if stereo)
    as_data_frame = function() {
      private$check_valid()
      .sound_as_data_frame(private$ptr)
    },
    
    #' @description
    #' Save sound to file
    #' @param path Output file path
    #' @param format File format (default: "WAV")
    #' @return invisible(self)
    save = function(path, format = "WAV") {
      private$check_valid()
      
      if (!is.character(path) || length(path) != 1) {
        stop("path must be a single character string")
      }
      if (!is.character(format) || length(format) != 1) {
        stop("format must be a single character string")
      }
      
      .sound_save(private$ptr, path, format)
      invisible(self)
    },
    
    #' @description
    #' Print method for Sound objects
    print = function() {
      cat("<Praat Sound>\n")
      
      if (!self$is_valid()) {
        cat("  [Invalid or deleted object]\n")
        return(invisible(self))
      }
      
      tryCatch({
        cat(sprintf("  Duration: %.3f s\n", self$get_duration()))
        cat(sprintf("  Sampling frequency: %.0f Hz\n", self$get_sampling_frequency()))
        cat(sprintf("  Channels: %d\n", self$get_number_of_channels()))
        cat(sprintf("  Samples: %d\n", self$get_number_of_samples()))
      }, error = function(e) {
        cat("  [Error retrieving properties]\n")
      })
      
      invisible(self)
    }
  ),
  
  private = list(
    # Check if pointer is still valid before operations
    check_valid = function() {
      if (!self$is_valid()) {
        stop("Sound object is invalid or has been deleted")
      }
    }
  )
)

#' @title Create Sound from Values
#' @description
#' Static factory method to create a Sound object from numeric values
#' @param values Numeric vector of sample values
#' @param sampling_rate Sampling frequency in Hz
#' @return Sound object
#' @export
Sound_from_values <- function(values, sampling_rate) {
  if (!is.numeric(values)) {
    stop("values must be numeric")
  }
  if (!is.numeric(sampling_rate) || sampling_rate <= 0) {
    stop("sampling_rate must be positive")
  }
  
  ptr <- .sound_create_from_values(values, sampling_rate)
  Sound$new(from_pointer = ptr)
}
