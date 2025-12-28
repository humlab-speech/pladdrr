# Low-level batch operations that minimize R→C boundary crossings
# These functions work directly with xptrs for maximum performance

#' Concatenate Multiple Sounds in Single C++ Call
#'
#' Concatenates a list of Sound objects at the C++ level, avoiding the O(n)
#' R→C boundary crossings that occur with `Reduce(function(a,b) a$concatenate(b), sounds)`.
#'
#' @param sounds List of Sound objects (R6) or external pointers
#' @param overlap Numeric. Overlap duration in seconds (default: 0)
#' @param return_r6 Logical. Return R6 Sound object (TRUE) or raw xptr (FALSE)
#'
#' @return Sound object (R6 or xptr depending on return_r6)
#'
#' @examples
#' \dontrun{
#' # Instead of slow R6 approach:
#' # result <- Reduce(function(a, b) a$concatenate(b), sound_list)
#'
#' # Use fast batch operation:
#' result <- sound_concatenate_all(sound_list)
#' }
#'
#' @export
sound_concatenate_all <- function(sounds, overlap = 0, return_r6 = TRUE) {
  if (length(sounds) == 0) {
    stop("Cannot concatenate empty list")
  }

  # Extract xptrs from R6 objects if needed
  xptrs <- lapply(sounds, function(s) {
    if (inherits(s, "Sound")) {
      s$.__enclos_env__$private$ptr
    } else if (inherits(s, "externalptr")) {
      s
    } else {
      stop("sounds must be a list of Sound objects or external pointers")
    }
  })

  result_ptr <- .sound_concatenate_all(xptrs, overlap)

  if (return_r6) {
    Sound$new(.xptr = result_ptr)
  } else {
    result_ptr
  }
}


# Note: sound_extract_parts is now defined in vad.R with the efficient C++ backend


#' Extract Pitch from Multiple Sounds in Single C++ Call
#'
#' Processes multiple Sound objects and extracts Pitch at the C++ level,
#' avoiding O(n) R→C boundary crossings from calling `$to_pitch()` in a loop.
#'
#' @param sounds List of Sound objects (R6) or external pointers
#' @param time_step Numeric. Time step (0 = automatic)
#' @param pitch_floor Numeric. Pitch floor in Hz (default: 75)
#' @param pitch_ceiling Numeric. Pitch ceiling in Hz (default: 600)
#' @param return_r6 Logical. Return R6 Pitch objects (TRUE) or raw xptrs (FALSE)
#'
#' @return List of Pitch objects (R6 or xptr depending on return_r6)
#'
#' @export
sound_to_pitch_batch <- function(sounds,
                                 time_step = 0,
                                 pitch_floor = 75,
                                 pitch_ceiling = 600,
                                 return_r6 = TRUE) {
  # Extract xptrs
  xptrs <- lapply(sounds, function(s) {
    if (inherits(s, "Sound")) {
      s$.__enclos_env__$private$ptr
    } else {
      s
    }
  })

  result_ptrs <- .sound_to_pitch_batch(xptrs, time_step, pitch_floor, pitch_ceiling)

  if (return_r6) {
    lapply(result_ptrs, function(ptr) Pitch$new(.xptr = ptr))
  } else {
    result_ptrs
  }
}


#' Extract Formants from Multiple Sounds in Single C++ Call
#'
#' @param sounds List of Sound objects (R6) or external pointers
#' @param time_step Numeric. Time step in seconds (default: 0.005)
#' @param max_formants Numeric. Maximum number of formants (default: 5)
#' @param max_frequency Numeric. Maximum frequency in Hz (default: 5500)
#' @param window_length Numeric. Window length in seconds (default: 0.025)
#' @param pre_emphasis_from Numeric. Pre-emphasis from frequency (default: 50)
#' @param return_r6 Logical. Return R6 Formant objects (TRUE) or raw xptrs (FALSE)
#'
#' @return List of Formant objects (R6 or xptr depending on return_r6)
#'
#' @export
sound_to_formant_batch <- function(sounds,
                                   time_step = 0.005,
                                   max_formants = 5,
                                   max_frequency = 5500,
                                   window_length = 0.025,
                                   pre_emphasis_from = 50,
                                   return_r6 = TRUE) {
  xptrs <- lapply(sounds, function(s) {
    if (inherits(s, "Sound")) {
      s$.__enclos_env__$private$ptr
    } else {
      s
    }
  })

  result_ptrs <- .sound_to_formant_batch(
    xptrs, time_step, max_formants,
    max_frequency, window_length, pre_emphasis_from
  )

  if (return_r6) {
    lapply(result_ptrs, function(ptr) Formant$new(.xptr = ptr))
  } else {
    result_ptrs
  }
}


#' Extract Intensity from Multiple Sounds in Single C++ Call
#'
#' @param sounds List of Sound objects (R6) or external pointers
#' @param minimum_pitch Numeric. Minimum pitch for analysis (default: 100)
#' @param time_step Numeric. Time step (0 = automatic)
#' @param subtract_mean Logical. Subtract mean pressure (default: TRUE)
#' @param return_r6 Logical. Return R6 Intensity objects (TRUE) or raw xptrs (FALSE)
#'
#' @return List of Intensity objects (R6 or xptr depending on return_r6)
#'
#' @export
sound_to_intensity_batch <- function(sounds,
                                     minimum_pitch = 100,
                                     time_step = 0,
                                     subtract_mean = TRUE,
                                     return_r6 = TRUE) {
  xptrs <- lapply(sounds, function(s) {
    if (inherits(s, "Sound")) {
      s$.__enclos_env__$private$ptr
    } else {
      s
    }
  })

  result_ptrs <- .sound_to_intensity_batch(xptrs, minimum_pitch, time_step, subtract_mean)

  if (return_r6) {
    lapply(result_ptrs, function(ptr) Intensity$new(.xptr = ptr))
  } else {
    result_ptrs
  }
}


#' Extract Parts and Analyze Pitch in Single C++ Call
#'
#' The most efficient way to analyze multiple intervals from a sound.
#' Combines extraction and analysis in a single C++ call, avoiding all
#' intermediate R6 object creation.
#'
#' @param sound Sound object (R6) or external pointer
#' @param from_times Numeric vector of start times
#' @param to_times Numeric vector of end times
#' @param time_step Numeric. Pitch time step (0 = automatic)
#' @param pitch_floor Numeric. Pitch floor in Hz (default: 75)
#' @param pitch_ceiling Numeric. Pitch ceiling in Hz (default: 600)
#' @param return_r6 Logical. Return R6 Pitch objects (TRUE) or raw xptrs (FALSE)
#'
#' @return List of Pitch objects (R6 or xptr depending on return_r6)
#'
#' @examples
#' \dontrun{
#' # Instead of the slow pattern:
#' # parts <- lapply(1:n, function(i) sound$extract_part(from[i], to[i]))
#' # pitches <- lapply(parts, function(p) p$to_pitch())
#'
#' # Use combined operation:
#' pitches <- sound_extract_and_pitch(sound, from_times, to_times)
#' }
#'
#' @export
sound_extract_and_pitch <- function(sound, from_times, to_times,
                                    time_step = 0,
                                    pitch_floor = 75,
                                    pitch_ceiling = 600,
                                    return_r6 = TRUE) {
  xptr <- if (inherits(sound, "Sound")) {
    sound$.__enclos_env__$private$ptr
  } else {
    sound
  }

  result_ptrs <- .sound_extract_and_pitch_batch(
    xptr, from_times, to_times,
    time_step, pitch_floor, pitch_ceiling
  )

  if (return_r6) {
    lapply(result_ptrs, function(ptr) Pitch$new(.xptr = ptr))
  } else {
    result_ptrs
  }
}


#' Extract Parts and Analyze Formants in Single C++ Call
#'
#' @param sound Sound object (R6) or external pointer
#' @param from_times Numeric vector of start times
#' @param to_times Numeric vector of end times
#' @param time_step Numeric. Formant time step (default: 0.005)
#' @param max_formants Numeric. Maximum number of formants (default: 5)
#' @param max_frequency Numeric. Maximum frequency (default: 5500)
#' @param window_length Numeric. Window length (default: 0.025)
#' @param pre_emphasis_from Numeric. Pre-emphasis frequency (default: 50)
#' @param return_r6 Logical. Return R6 Formant objects (TRUE) or raw xptrs (FALSE)
#'
#' @return List of Formant objects (R6 or xptr depending on return_r6)
#'
#' @export
sound_extract_and_formant <- function(sound, from_times, to_times,
                                      time_step = 0.005,
                                      max_formants = 5,
                                      max_frequency = 5500,
                                      window_length = 0.025,
                                      pre_emphasis_from = 50,
                                      return_r6 = TRUE) {
  xptr <- if (inherits(sound, "Sound")) {
    sound$.__enclos_env__$private$ptr
  } else {
    sound
  }

  result_ptrs <- .sound_extract_and_formant_batch(
    xptr, from_times, to_times,
    time_step, max_formants, max_frequency,
    window_length, pre_emphasis_from
  )

  if (return_r6) {
    lapply(result_ptrs, function(ptr) Formant$new(.xptr = ptr))
  } else {
    result_ptrs
  }
}


#' Get Pitch Values at Multiple Times in Single C++ Call
#'
#' Vectorized extraction of pitch values, avoiding O(n) R→C boundary crossings.
#'
#' @param pitch Pitch object (R6) or external pointer
#' @param times Numeric vector of times
#' @param unit Character. Unit: "hertz", "hertz_logarithmic", "mel", "logHertz",
#'   "semitones_re_1hz", "semitones_re_100hz", "semitones_re_200hz",
#'   "semitones_re_440hz", "erb" (default: "hertz")
#' @param interpolate Logical. Whether to interpolate (default: TRUE)
#'
#' @return Numeric vector of pitch values
#'
#' @export
pitch_get_values_at_times <- function(pitch, times,
                                      unit = "hertz",
                                      interpolate = TRUE) {
  xptr <- if (inherits(pitch, "Pitch")) {
    pitch$.__enclos_env__$private$ptr
  } else {
    pitch
  }

  unit_int <- switch(
    tolower(unit),
    hertz = 0L,
    hertz_logarithmic = 1L,
    mel = 2L,
    loghertz = 3L,
    semitones_re_1hz = 4L,
    semitones_re_100hz = 5L,
    semitones_re_200hz = 6L,
    semitones_re_440hz = 7L,
    erb = 8L,
    0L
  )

  .pitch_get_values_at_times(xptr, times, unit_int, interpolate)
}


#' Get Formant Values at Multiple Times in Single C++ Call
#'
#' Vectorized extraction of formant values, avoiding O(n) R→C boundary crossings.
#'
#' @param formant Formant object (R6) or external pointer
#' @param times Numeric vector of times
#' @param formant_number Integer. Which formant (1-5, default: 1)
#' @param unit Character. Unit: "hertz" or "bark" (default: "hertz")
#'
#' @return Numeric vector of formant values
#'
#' @export
formant_get_values_at_times <- function(formant, times,
                                        formant_number = 1,
                                        unit = "hertz") {
  xptr <- if (inherits(formant, "Formant")) {
    formant$.__enclos_env__$private$ptr
  } else {
    formant
  }

  unit_int <- switch(tolower(unit), hertz = 0L, bark = 1L, 0L)

  .formant_get_values_at_times(xptr, times, as.integer(formant_number), unit_int)
}


#' Get Intensity Values at Multiple Times in Single C++ Call
#'
#' Vectorized extraction of intensity values, avoiding O(n) R→C boundary crossings.
#'
#' @param intensity Intensity object (R6) or external pointer
#' @param times Numeric vector of times
#' @param interpolation Character. Interpolation: "nearest", "linear", "cubic",
#'   "sinc70", "sinc700" (default: "linear")
#'
#' @return Numeric vector of intensity values
#'
#' @export
intensity_get_values_at_times <- function(intensity, times,
                                          interpolation = "linear") {
  xptr <- if (inherits(intensity, "Intensity")) {
    intensity$.__enclos_env__$private$ptr
  } else {
    intensity
  }

  interp_int <- switch(
    tolower(interpolation),
    nearest = 0L,
    linear = 1L,
    cubic = 2L,
    sinc70 = 3L,
    sinc700 = 4L,
    1L
  )

  .intensity_get_values_at_times(xptr, times, interp_int)
}
