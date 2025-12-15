# Pitch R6 Class
# Fundamental frequency (F0) contour representation
# Mirrors Praat's Pitch object

#' Pitch Object
#'
#' An R6 class representing a Praat Pitch object (fundamental frequency contour).
#' 
#' @description
#' The Pitch class represents the fundamental frequency (F0) contour of a sound.
#' It provides methods for querying pitch values, statistics, and transformations.
#' 
#' @examples
#' \dontrun{
#' # Create a pitch object from a sound
#' sound <- Sound$new(system.file("extdata", "example.wav", package = "speaker"))
#' pitch <- sound$to_pitch(time_step = 0.01, pitch_floor = 75, pitch_ceiling = 600)
#' 
#' # Query pitch statistics
#' mean_f0 <- pitch$get_mean(from_time = 0, to_time = 0, unit = "Hertz")
#' min_f0 <- pitch$get_minimum(from_time = 0, to_time = 0, unit = "Hertz", interpolate = TRUE)
#' max_f0 <- pitch$get_maximum(from_time = 0, to_time = 0, unit = "Hertz", interpolate = TRUE)
#' 
#' # Get pitch at specific time
#' f0_at_1s <- pitch$get_value_at_time(time = 1.0, unit = "Hertz", interpolate = TRUE)
#' 
#' # Count voiced frames
#' n_voiced <- pitch$count_voiced_frames()
#' }
#' 
#' @export
Pitch <- R6::R6Class("Pitch",
  inherit = PraatObject,
  
  public = list(
    
    #' @description
    #' Create a new Pitch object
    #' @param .xptr External pointer to C++ Pitch object (internal use)
    initialize = function(.xptr = NULL) {
      if (is.null(.xptr)) {
        stop("Pitch objects must be created from a Sound object using sound$to_pitch()")
      }
      private$ptr <- .xptr
    },
    
    # ========================================================================
    # Query methods - Time domain
    # ========================================================================
    
    #' @description
    #' Get the time corresponding to a frame number
    #' @param frame_number Frame index (1-based)
    #' @return Time in seconds
    get_time_from_frame = function(frame_number) {
      .pitch_get_time_from_frame(private$ptr, as.integer(frame_number))
    },
    
    #' @description
    #' Get the frame number corresponding to a time
    #' @param time Time in seconds
    #' @return Frame number (integer)
    get_frame_from_time = function(time) {
      .pitch_get_frame_from_time(private$ptr, as.numeric(time))
    },
    
    #' @description
    #' Get the total number of frames
    #' @return Number of frames
    get_number_of_frames = function() {
      .pitch_get_number_of_frames(private$ptr)
    },
    
    #' @description
    #' Get the time step between frames
    #' @return Time step in seconds
    get_time_step = function() {
      .pitch_get_time_step(private$ptr)
    },
    
    # ========================================================================
    # Query methods - Pitch values
    # ========================================================================
    
    #' @description
    #' Get pitch value at a specific time
    #' @param time Time in seconds
    #' @param unit Unit: "hertz" (default), "semitones", "mel", "erb"
    #' @param interpolate Interpolate between frames (default TRUE)
    #' @return Pitch value in specified unit, or NA if unvoiced
    get_value_at_time = function(time, unit = "hertz", interpolate = TRUE) {
      unit_code <- switch(tolower(unit),
        "hertz" = 0L,
        "hz" = 0L,
        "semitones" = 1L,
        "mel" = 2L,
        "erb" = 3L,
        stop("Unknown unit: ", unit)
      )
      .pitch_get_value_at_time(private$ptr, as.numeric(time), unit_code, as.logical(interpolate))
    },
    
    #' @description
    #' Get mean pitch over a time range
    #' @param from_time Start time (default: start of pitch)
    #' @param to_time End time (default: end of pitch)
    #' @param unit Unit: "hertz" (default), "semitones", "mel", "erb"
    #' @return Mean pitch value
    get_mean = function(from_time = 0, to_time = 0, unit = "hertz") {
      unit_code <- switch(tolower(unit),
        "hertz" = 0L,
        "hz" = 0L,
        "semitones" = 1L,
        "mel" = 2L,
        "erb" = 3L,
        stop("Unknown unit: ", unit)
      )
      .pitch_get_mean(private$ptr, as.numeric(from_time), as.numeric(to_time), unit_code)
    },
    
    #' @description
    #' Get standard deviation of pitch over a time range
    #' @param from_time Start time (default: start of pitch)
    #' @param to_time End time (default: end of pitch)
    #' @param unit Unit: "hertz" (default), "semitones", "mel", "erb"
    #' @return Standard deviation
    get_standard_deviation = function(from_time = 0, to_time = 0, unit = "hertz") {
      unit_code <- switch(tolower(unit),
        "hertz" = 0L,
        "hz" = 0L,
        "semitones" = 1L,
        "mel" = 2L,
        "erb" = 3L,
        stop("Unknown unit: ", unit)
      )
      .pitch_get_standard_deviation(private$ptr, as.numeric(from_time), as.numeric(to_time), unit_code)
    },
    
    #' @description
    #' Get quantile of pitch distribution
    #' @param quantile Quantile (0-1)
    #' @param from_time Start time (default: start of pitch)
    #' @param to_time End time (default: end of pitch)
    #' @param unit Unit: "hertz" (default), "semitones", "mel", "erb"
    #' @return Pitch value at quantile
    get_quantile = function(quantile, from_time = 0, to_time = 0, unit = "hertz") {
      unit_code <- switch(tolower(unit),
        "hertz" = 0L,
        "hz" = 0L,
        "semitones" = 1L,
        "mel" = 2L,
        "erb" = 3L,
        stop("Unknown unit: ", unit)
      )
      .pitch_get_quantile(private$ptr, as.numeric(from_time), as.numeric(to_time), 
                          as.numeric(quantile), unit_code)
    },
    
    #' @description
    #' Get minimum pitch value in time range
    #' @param from_time Start time (default: start of pitch)
    #' @param to_time End time (default: end of pitch)
    #' @param unit Unit: "hertz" (default), "semitones", "mel", "erb"
    #' @param interpolate Interpolate between frames (default TRUE)
    #' @return Minimum pitch value
    get_minimum = function(from_time = 0, to_time = 0, unit = "hertz", interpolate = TRUE) {
      unit_code <- switch(tolower(unit),
        "hertz" = 0L,
        "hz" = 0L,
        "semitones" = 1L,
        "mel" = 2L,
        "erb" = 3L,
        stop("Unknown unit: ", unit)
      )
      .pitch_get_minimum(private$ptr, as.numeric(from_time), as.numeric(to_time), 
                         unit_code, as.logical(interpolate))
    },
    
    #' @description
    #' Get maximum pitch value in time range
    #' @param from_time Start time (default: start of pitch)
    #' @param to_time End time (default: end of pitch)
    #' @param unit Unit: "hertz" (default), "semitones", "mel", "erb"
    #' @param interpolate Interpolate between frames (default TRUE)
    #' @return Maximum pitch value
    get_maximum = function(from_time = 0, to_time = 0, unit = "hertz", interpolate = TRUE) {
      unit_code <- switch(tolower(unit),
        "hertz" = 0L,
        "hz" = 0L,
        "semitones" = 1L,
        "mel" = 2L,
        "erb" = 3L,
        stop("Unknown unit: ", unit)
      )
      .pitch_get_maximum(private$ptr, as.numeric(from_time), as.numeric(to_time), 
                         unit_code, as.logical(interpolate))
    },
    
    #' @description
    #' Get time of minimum pitch value
    #' @param from_time Start time (default: start of pitch)
    #' @param to_time End time (default: end of pitch)
    #' @param unit Unit: "hertz" (default), "semitones", "mel", "erb"
    #' @param interpolate Interpolate between frames (default TRUE)
    #' @return Time in seconds
    get_time_of_minimum = function(from_time = 0, to_time = 0, unit = "hertz", interpolate = TRUE) {
      unit_code <- switch(tolower(unit),
        "hertz" = 0L,
        "hz" = 0L,
        "semitones" = 1L,
        "mel" = 2L,
        "erb" = 3L,
        stop("Unknown unit: ", unit)
      )
      .pitch_get_time_of_minimum(private$ptr, as.numeric(from_time), as.numeric(to_time), 
                                  unit_code, as.logical(interpolate))
    },
    
    #' @description
    #' Get time of maximum pitch value
    #' @param from_time Start time (default: start of pitch)
    #' @param to_time End time (default: end of pitch)
    #' @param unit Unit: "hertz" (default), "semitones", "mel", "erb"
    #' @param interpolate Interpolate between frames (default TRUE)
    #' @return Time in seconds
    get_time_of_maximum = function(from_time = 0, to_time = 0, unit = "hertz", interpolate = TRUE) {
      unit_code <- switch(tolower(unit),
        "hertz" = 0L,
        "hz" = 0L,
        "semitones" = 1L,
        "mel" = 2L,
        "erb" = 3L,
        stop("Unknown unit: ", unit)
      )
      .pitch_get_time_of_maximum(private$ptr, as.numeric(from_time), as.numeric(to_time), 
                                  unit_code, as.logical(interpolate))
    },
    
    #' @description
    #' Count the number of voiced frames
    #' @return Number of voiced frames
    count_voiced_frames = function() {
      .pitch_count_voiced_frames(private$ptr)
    },
    
    #' @description
    #' Get pitch strength (periodicity) at a specific time
    #' @param time Time in seconds
    #' @param unit Unit: "hertz" (default), "semitones", "mel", "erb"
    #' @param interpolate Interpolate between frames (default TRUE)
    #' @return Strength value (0-1), or NA if unvoiced
    #' @details
    #' Pitch strength measures the periodicity of the signal at the given time.
    #' Values range from 0 (completely aperiodic) to 1 (perfectly periodic).
    #' This is useful for voice quality assessment and periodicity analysis.
    get_strength_at_time = function(time, unit = "hertz", interpolate = TRUE) {
      unit_code <- switch(tolower(unit),
        "hertz" = 0L,
        "hz" = 0L,
        "semitones" = 1L,
        "mel" = 2L,
        "erb" = 3L,
        stop("Unknown unit: ", unit)
      )
      .pitch_get_strength_at_time(private$ptr, as.numeric(time), unit_code, as.logical(interpolate))
    },
    
    #' @description
    #' Get mean pitch strength over a time range
    #' @param from_time Start time (default: start of pitch)
    #' @param to_time End time (default: end of pitch)
    #' @param unit Unit: "hertz" (default), "semitones", "mel", "erb"
    #' @return Mean strength value (0-1)
    #' @details
    #' Computes the average pitch strength (periodicity) across the specified time range.
    #' Higher values indicate more consistent voicing.
    get_mean_strength = function(from_time = 0, to_time = 0, unit = "hertz") {
      unit_code <- switch(tolower(unit),
        "hertz" = 0L,
        "hz" = 0L,
        "semitones" = 1L,
        "mel" = 2L,
        "erb" = 3L,
        stop("Unknown unit: ", unit)
      )
      .pitch_get_mean_strength(private$ptr, as.numeric(from_time), as.numeric(to_time), unit_code)
    },
    
    #' @description
    #' Get pitch frame intensity at a specific time
    #' @param time Time in seconds
    #' @return Frame intensity value, or NA if no frame
    #' @details
    #' Returns the intensity value stored in the pitch frame at the given time.
    #' This is the raw acoustic intensity (amplitude) of the pitch candidate,
    #' distinct from pitch strength (periodicity). Used for FCoM and ACoM metrics.
    get_intensity_at_time = function(time) {
      .pitch_get_intensity_at_time(private$ptr, as.numeric(time))
    },
    
    #' @description
    #' Get mean pitch frame intensity over a time range
    #' @param from_time Start time (default: start of pitch)
    #' @param to_time End time (default: end of pitch)
    #' @return Mean intensity value
    #' @details
    #' Computes the average frame intensity across the specified time range.
    #' This is the acoustic intensity/amplitude stored in each pitch frame.
    get_mean_intensity = function(from_time = 0, to_time = 0) {
      .pitch_get_mean_intensity(private$ptr, as.numeric(from_time), as.numeric(to_time))
    },
    
    # ========================================================================
    # Transform methods
    # ========================================================================
    
    #' @description
    #' Convert pitch object to PointProcess
    #' @return PointProcess object containing times of voiced pitch candidates
    to_point_process = function() {
      pp_ptr <- .pitch_to_point_process(private$ptr)
      PointProcess$new(.xptr = pp_ptr)
    },
    
    #' @description
    #' Create PointProcess from Pitch and Sound using cross-correlation.
    #' 
    #' This is the TWO-OBJECT COMMAND required for DSI calculation.
    #' Praat equivalent: Select Sound and Pitch, then "To PointProcess (cc)"
    #' 
    #' This method detects glottal pulses by finding the points of maximum
    #' cross-correlation between the sound and a predicted pulse train based
    #' on the pitch contour. This is more accurate than simple zero-crossing
    #' or peak detection, especially for breathy or irregular voices.
    #' 
    #' @param sound Sound object to extract pulses from
    #' @return PointProcess object with glottal pulse times
    #' 
    #' @section Praat Equivalent:
    #' `[Sound, Pitch] → To PointProcess (cc)`
    #' 
    #' @examples
    #' \dontrun{
    #' # DSI workflow requiring accurate pulse detection
    #' sound <- Sound$new("soft_phonation.wav")
    #' pitch <- sound$to_pitch_cc(time_step = 0.001, pitch_floor = 50, pitch_ceiling = 300)
    #' 
    #' # Create PointProcess from BOTH Sound and Pitch (two-object command)
    #' point_process <- pitch$to_pointprocess_cc(sound)
    #' 
    #' # Now can create VUV TextGrid
    #' textgrid <- point_process$to_textgrid_vuv(
    #'   max_voiced_period = 0.02,
    #'   max_unvoiced_period = 0.01
    #' )
    #' }
    to_pointprocess_cc = function(sound) {
      if (!inherits(sound, "Sound")) {
        stop("Argument 'sound' must be a Sound object")
      }
      pp_ptr <- .sound_pitch_to_pointprocess_cc(sound$.__enclos_env__$private$ptr, private$ptr)
      PointProcess$new(.xptr = pp_ptr)
    },
    
    #' @description
    #' Create PointProcess from Pitch and Sound near amplitude peaks.
    #' 
    #' Two-object command: uses existing Pitch object to guide peak detection.
    #' Praat equivalent: Select Sound and Pitch, then "To PointProcess (peaks)..."
    #' 
    #' This method finds points of maximum amplitude in the sound near the times
    #' indicated by the pitch contour. More flexible than cc method - can find
    #' maxima (peaks) or minima (valleys).
    #' 
    #' @param sound Sound object to extract peaks from
    #' @param include_maxima Include positive peaks (default: TRUE)
    #' @param include_minima Include negative valleys (default: FALSE)
    #' @return PointProcess object with detected peak/valley times
    #' 
    #' @section Praat Equivalent:
    #' `[Sound, Pitch] → To PointProcess (peaks)...`
    #' 
    #' @examples
    #' \dontrun{
    #' sound <- Sound$new("voice.wav")
    #' pitch <- sound$to_pitch()
    #' 
    #' # Find positive peaks
    #' pp_peaks <- pitch$to_pointprocess_peaks(sound, 
    #'                                          include_maxima = TRUE, 
    #'                                          include_minima = FALSE)
    #' }
    to_pointprocess_peaks = function(sound, include_maxima = TRUE, include_minima = FALSE) {
      if (!inherits(sound, "Sound")) {
        stop("Argument 'sound' must be a Sound object")
      }
      pp_ptr <- .sound_pitch_to_pointprocess_peaks(
        sound$.__enclos_env__$private$ptr, 
        private$ptr,
        include_maxima,
        include_minima
      )
      PointProcess$new(.xptr = pp_ptr)
    },
    
    #' @description
    #' Convert pitch object to PitchTier
    #' @return PitchTier object with pitch points from voiced frames
    down_to_pitch_tier = function() {
      tier_ptr <- .pitch_down_to_pitch_tier(private$ptr)
      PitchTier$new(.xptr = tier_ptr)
    },
    
    #' @description
    #' Convert pitch to TextGrid marking voiced/unvoiced intervals
    #' @return TextGrid object with voiced (V) and unvoiced (U) intervals
    to_textgrid_vuv = function() {
      tg_ptr <- .pitch_to_textgrid_vuv(private$ptr)
      TextGrid$new(.xptr = tg_ptr)
    },
    
    #' @description
    #' Convert pitch to TextGrid marking silent/sounding intervals
    #' @param min_silent_duration Minimum duration for silent intervals (default: 0.1 s)
    #' @param min_sounding_duration Minimum duration for sounding intervals (default: 0.1 s)
    #' @return TextGrid object with silent and sounding intervals
    to_textgrid_silences = function(min_silent_duration = 0.1, min_sounding_duration = 0.1) {
      tg_ptr <- .pitch_to_textgrid_silences(
        private$ptr,
        min_silent_duration,
        min_sounding_duration
      )
      TextGrid$new(.xptr = tg_ptr)
    },
    
    # ========================================================================
    # Export methods
    # ========================================================================
    
    #' @description
    #' Convert pitch contour to matrix
    #' @return Matrix with columns: time, frequency
    as_matrix = function() {
      .pitch_as_matrix(private$ptr)
    },
    
    #' @description
    #' Convert pitch contour to data frame
    #' @param include_strength Include pitch strength column (default FALSE)
    #' @param include_intensity Include frame intensity column (default FALSE)
    #' @return Data frame with columns: time, frequency, voiced, and optionally strength/intensity
    #' @details
    #' The strength column contains the pitch periodicity measure (0-1) for each frame.
    #' The intensity column contains the raw acoustic intensity/amplitude of each frame.
    #' Both are useful for voice quality and periodicity analysis.
    as_data_frame = function(include_strength = FALSE, include_intensity = FALSE) {
      .pitch_as_data_frame(private$ptr, 
                          include_strength = as.logical(include_strength),
                          include_intensity = as.logical(include_intensity))
    },
    
    #' @description
    #' Save pitch to file
    #' @param path Output file path
    save = function(path) {
      .pitch_save(private$ptr, as.character(path))
      invisible(self)
    },
    
    # ========================================================================
    # Print method
    # ========================================================================
    
    #' @description
    #' Print pitch object summary
    print = function() {
      cat("<Praat Pitch>\n")
      
      n_frames <- self$get_number_of_frames()
      time_step <- self$get_time_step()
      n_voiced <- self$count_voiced_frames()
      
      cat(sprintf("  Frames: %d\n", n_frames))
      cat(sprintf("  Time step: %.4f s\n", time_step))
      cat(sprintf("  Voiced frames: %d (%.1f%%)\n", 
                  n_voiced, 100 * n_voiced / n_frames))
      
      tryCatch({
        mean_f0 <- self$get_mean(unit = "hertz")
        if (!is.na(mean_f0) && mean_f0 > 0) {
          min_f0 <- self$get_minimum(unit = "hertz")
          max_f0 <- self$get_maximum(unit = "hertz")
          sd_f0 <- self$get_standard_deviation(unit = "hertz")
          
          cat(sprintf("  Mean F0: %.1f Hz\n", mean_f0))
          cat(sprintf("  Range: %.1f - %.1f Hz\n", min_f0, max_f0))
          cat(sprintf("  SD: %.1f Hz\n", sd_f0))
        }
      }, error = function(e) {})
      
      invisible(self)
    }
  ),
  
  private = list(
    ptr = NULL
  )
)
