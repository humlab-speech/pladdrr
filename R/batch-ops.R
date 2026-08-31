# Low-level batch operations that minimize R→C boundary crossings
# These functions work directly with xptrs for maximum performance

#' Concatenate Multiple Sounds in Single C++ Call
#'
#' Concatenates a list of Sound objects at the C++ level, avoiding the O(n)
#' R→C boundary crossings that occur with `Reduce(function(a,b) a$concatenate(b), sounds)`.
#'
#' @inheritParams pladdrr_shared_params sounds
#' @param overlap Numeric. Overlap duration in seconds (default: 0)
#' @param return_r6 Logical. Return R6 Sound object (TRUE) or raw xptr (FALSE)
#'
#' @return Sound object (R6 or xptr depending on return_r6)
#'
#' @examples
#' sound_list <- list(
#'   Sound$create_tone(frequency = 440, duration = 0.2),
#'   Sound$create_tone(frequency = 880, duration = 0.2)
#' )
#' result <- sound_concatenate_all(sound_list)
#'
#' @export
sound_concatenate_all <- function(sounds, overlap = 0, return_r6 = TRUE) {
  if (length(sounds) == 0) {
    stop("Cannot concatenate empty list")
  }

  # Extract xptrs from R6 objects if needed
  xptrs <- lapply(sounds, function(s) {
    if (inherits(s, "Sound")) {
      # Try multiple extraction methods (Sound objects store xptr in different ways)
      ptr <- s$.xptr  # Primary method for function-based Sound objects
      if (is.null(ptr)) ptr <- s$get_xptr()  # Fallback 1: method call
      if (is.null(ptr) && !is.null(s$.pointer)) ptr <- s$.pointer  # Fallback 2: alternative name
      if (is.null(ptr)) {
        # Last resort: try private environment (old R6 style)
        tryCatch({
          ptr <- s$.__enclos_env__$private$ptr
        }, error = function(e) NULL)
      }
      if (is.null(ptr)) {
        stop("Could not extract external pointer from Sound object")
      }
      ptr
    } else if (inherits(s, "externalptr")) {
      s
    } else {
      stop("sounds must be a list of Sound objects or external pointers")
    }
  })

  result_ptr <- .sound_concatenate_all(xptrs, overlap)

  if (return_r6) {
    Sound(.xptr = result_ptr)
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
#' @inheritParams pladdrr_shared_params sounds
#' @inheritParams pladdrr_shared_params time_step
#' @inheritParams pladdrr_shared_params pitch_floor
#' @inheritParams pladdrr_shared_params pitch_ceiling
#' @inheritParams pladdrr_shared_params return_r6
#'
#' @return List of Pitch objects (R6 or xptr depending on return_r6)
#'
#' @examples
#' sounds <- list(
#'   Sound$create_tone(frequency = 150, duration = 0.5),
#'   Sound$create_tone(frequency = 200, duration = 0.5)
#' )
#' pitches <- sound_to_pitch_batch(sounds)
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
      ptr <- s$.xptr
      if (is.null(ptr)) ptr <- s$get_xptr()
      if (is.null(ptr)) stop("Could not extract pointer from Sound object")
      ptr
    } else if (inherits(s, "externalptr")) {
      s
    } else {
      stop("Invalid input type: expected Sound or externalptr")
    }
  })

  result_ptrs <- .sound_to_pitch_batch(xptrs, time_step, pitch_floor, pitch_ceiling)

  if (return_r6) {
    lapply(result_ptrs, function(ptr) Pitch(.xptr = ptr))
  } else {
    result_ptrs
  }
}


#' Extract Pitch (AC) from Multiple Sounds in Single C++ Call
#'
#' Batch version of to_pitch_ac with full voicing parameters.
#' Avoids O(n) R→C boundary crossings for VUV analysis workflows.
#'
#' @inheritParams pladdrr_shared_params sounds
#' @inheritParams pladdrr_shared_params time_step
#' @inheritParams pladdrr_shared_params pitch_floor
#' @inheritParams pladdrr_shared_params pitch_ceiling
#' @inheritParams pladdrr_shared_params max_candidates
#' @param very_accurate Logical. Use very accurate algorithm (default: FALSE)
#' @param silence_threshold Numeric. Silence threshold (default: 0.03)
#' @param voicing_threshold Numeric. Voicing threshold (default: 0.45)
#' @param octave_cost Numeric. Octave cost (default: 0.01)
#' @param octave_jump_cost Numeric. Octave jump cost (default: 0.35)
#' @param voiced_unvoiced_cost Numeric. Voiced/unvoiced cost (default: 0.14)
#' @inheritParams pladdrr_shared_params return_r6
#'
#' @return List of Pitch objects (R6 or xptr depending on return_r6)
#'
#' @examples
#' sounds <- list(
#'   Sound$create_tone(frequency = 150, duration = 0.5),
#'   Sound$create_tone(frequency = 200, duration = 0.5)
#' )
#' pitches <- sound_to_pitch_ac_batch(sounds)
#'
#' @export
sound_to_pitch_ac_batch <- function(sounds,
                                    time_step = 0,
                                    pitch_floor = 75,
                                    pitch_ceiling = 600,
                                    max_candidates = 15L,
                                    very_accurate = FALSE,
                                    silence_threshold = 0.03,
                                    voicing_threshold = 0.45,
                                    octave_cost = 0.01,
                                    octave_jump_cost = 0.35,
                                    voiced_unvoiced_cost = 0.14,
                                    return_r6 = TRUE) {
  xptrs <- lapply(sounds, function(s) {
    if (inherits(s, "Sound")) {
      ptr <- s$.xptr
      if (is.null(ptr)) ptr <- s$get_xptr()
      if (is.null(ptr)) stop("Could not extract pointer from Sound object")
      ptr
    } else if (inherits(s, "externalptr")) {
      s
    } else {
      stop("Invalid input type: expected Sound or externalptr")
    }
  })

  result_ptrs <- .sound_to_pitch_ac_batch(
    xptrs, time_step, pitch_floor, pitch_ceiling,
    as.integer(max_candidates), very_accurate,
    silence_threshold, voicing_threshold,
    octave_cost, octave_jump_cost, voiced_unvoiced_cost
  )

  if (return_r6) {
    lapply(result_ptrs, function(ptr) Pitch(.xptr = ptr))
  } else {
    result_ptrs
  }
}


#' Extract Pitch (CC) from Multiple Sounds in Single C++ Call
#'
#' Batch version of to_pitch_cc with full voicing parameters.
#' Avoids O(n) R→C boundary crossings for VUV analysis workflows.
#' Use this when processing many sound segments in a loop.
#'
#' @inheritParams pladdrr_shared_params sounds
#' @inheritParams pladdrr_shared_params time_step
#' @inheritParams pladdrr_shared_params pitch_floor
#' @inheritParams pladdrr_shared_params pitch_ceiling
#' @inheritParams pladdrr_shared_params max_candidates
#' @param very_accurate Logical. Use very accurate algorithm (default: FALSE)
#' @param silence_threshold Numeric. Silence threshold (default: 0.03)
#' @param voicing_threshold Numeric. Voicing threshold (default: 0.45)
#' @param octave_cost Numeric. Octave cost (default: 0.01)
#' @param octave_jump_cost Numeric. Octave jump cost (default: 0.35)
#' @param voiced_unvoiced_cost Numeric. Voiced/unvoiced cost (default: 0.14)
#' @inheritParams pladdrr_shared_params return_r6
#'
#' @return List of Pitch objects (R6 or xptr depending on return_r6)
#'
#' @examples
#' sounds <- list(
#'   Sound$create_tone(frequency = 150, duration = 0.5),
#'   Sound$create_tone(frequency = 200, duration = 0.5)
#' )
#' # Instead of a loop (pitches <- lapply(sounds, function(s) s$to_pitch_cc())):
#' pitches <- sound_to_pitch_cc_batch(sounds)
#'
#' @export
sound_to_pitch_cc_batch <- function(sounds,
                                    time_step = 0,
                                    pitch_floor = 75,
                                    pitch_ceiling = 600,
                                    max_candidates = 15L,
                                    very_accurate = FALSE,
                                    silence_threshold = 0.03,
                                    voicing_threshold = 0.45,
                                    octave_cost = 0.01,
                                    octave_jump_cost = 0.35,
                                    voiced_unvoiced_cost = 0.14,
                                    return_r6 = TRUE) {
  xptrs <- lapply(sounds, function(s) {
    if (inherits(s, "Sound")) {
      ptr <- s$.xptr
      if (is.null(ptr)) ptr <- s$get_xptr()
      if (is.null(ptr)) stop("Could not extract pointer from Sound object")
      ptr
    } else if (inherits(s, "externalptr")) {
      s
    } else {
      stop("Invalid input type: expected Sound or externalptr")
    }
  })

  result_ptrs <- .sound_to_pitch_cc_batch(
    xptrs, time_step, pitch_floor, pitch_ceiling,
    as.integer(max_candidates), very_accurate,
    silence_threshold, voicing_threshold,
    octave_cost, octave_jump_cost, voiced_unvoiced_cost
  )

  if (return_r6) {
    lapply(result_ptrs, function(ptr) Pitch(.xptr = ptr))
  } else {
    result_ptrs
  }
}


#' Extract Pitch (SHS) from Multiple Sounds
#'
#' Batch version of to_pitch_shs using Subharmonic Summation.
#'
#' @inheritParams pladdrr_shared_params sounds
#' @param time_step Numeric. Time step (default: 0.01)
#' @param pitch_floor Numeric. Pitch floor in Hz (default: 50)
#' @param max_frequency Numeric. Maximum frequency in Hz (default: 1250)
#' @param pitch_ceiling Numeric. Pitch ceiling in Hz (default: 500)
#' @param max_subharmonics Integer. Number of subharmonics (default: 15)
#' @inheritParams pladdrr_shared_params max_candidates
#' @param compression_factor Numeric. Compression factor (default: 0.84)
#' @param n_points_per_octave Integer. Points per octave (default: 48)
#' @inheritParams pladdrr_shared_params return_r6
#'
#' @return List of Pitch objects (R6 or xptr depending on return_r6)
#'
#' @examples
#' sounds <- list(
#'   Sound$create_tone(frequency = 150, duration = 0.5),
#'   Sound$create_tone(frequency = 200, duration = 0.5)
#' )
#' pitches <- sound_to_pitch_shs_batch(sounds)
#'
#' @export
sound_to_pitch_shs_batch <- function(sounds,
                                     time_step = 0.01,
                                     pitch_floor = 50,
                                     max_frequency = 1250,
                                     pitch_ceiling = 500,
                                     max_subharmonics = 15L,
                                     max_candidates = 15L,
                                     compression_factor = 0.84,
                                     n_points_per_octave = 48L,
                                     return_r6 = TRUE) {
  xptrs <- lapply(sounds, function(s) {
    if (inherits(s, "Sound")) {
      ptr <- s$.xptr
      if (is.null(ptr)) ptr <- s$get_xptr()
      if (is.null(ptr)) stop("Could not extract pointer from Sound object")
      ptr
    } else if (inherits(s, "externalptr")) {
      s
    } else {
      stop("Invalid input type: expected Sound or externalptr")
    }
  })

  result_ptrs <- lapply(xptrs, function(ptr) {
    .sound_to_pitch_shs(ptr, time_step, pitch_floor, max_frequency,
                         pitch_ceiling, as.integer(max_subharmonics),
                         as.integer(max_candidates), compression_factor,
                         as.integer(n_points_per_octave))
  })

  if (return_r6) {
    lapply(result_ptrs, function(ptr) Pitch(.xptr = ptr))
  } else {
    result_ptrs
  }
}


#' Extract Pitch (SPINET) from Multiple Sounds
#'
#' Batch version of to_pitch_spinet using spectral integration.
#'
#' @inheritParams pladdrr_shared_params sounds
#' @param time_step Numeric. Time step (default: 0.005)
#' @param window_duration Numeric. Analysis window (default: 0.04)
#' @param min_frequency Numeric. Minimum frequency in Hz (default: 70)
#' @param max_frequency Numeric. Maximum frequency in Hz (default: 5000)
#' @param n_filters Integer. Number of gamma-tone filters (default: 250)
#' @param pitch_ceiling Numeric. Pitch ceiling in Hz (default: 500)
#' @inheritParams pladdrr_shared_params max_candidates
#' @inheritParams pladdrr_shared_params return_r6
#'
#' @return List of Pitch objects (R6 or xptr depending on return_r6)
#'
#' @examples
#' # The vendored Praat SPINET path has a rare, non-deterministic native
#' # flake ("all amplitudes equal to zero") unrelated to the input signal;
#' # tryCatch keeps this example from failing R CMD check when it strikes.
#' sounds <- list(
#'   Sound$create_tone(frequency = 150, duration = 0.5),
#'   Sound$create_tone(frequency = 200, duration = 0.5)
#' )
#' pitches <- tryCatch(sound_to_pitch_spinet_batch(sounds), error = function(e) NULL)
#'
#' @export
sound_to_pitch_spinet_batch <- function(sounds,
                                        time_step = 0.005,
                                        window_duration = 0.04,
                                        min_frequency = 70,
                                        max_frequency = 5000,
                                        n_filters = 250L,
                                        pitch_ceiling = 500,
                                        max_candidates = 15L,
                                        return_r6 = TRUE) {
  xptrs <- lapply(sounds, function(s) {
    if (inherits(s, "Sound")) {
      ptr <- s$.xptr
      if (is.null(ptr)) ptr <- s$get_xptr()
      if (is.null(ptr)) stop("Could not extract pointer from Sound object")
      ptr
    } else if (inherits(s, "externalptr")) {
      s
    } else {
      stop("Invalid input type: expected Sound or externalptr")
    }
  })

  result_ptrs <- lapply(xptrs, function(ptr) {
    .sound_to_pitch_spinet(ptr, time_step, window_duration,
                            min_frequency, max_frequency,
                            as.integer(n_filters), pitch_ceiling,
                            as.integer(max_candidates))
  })

  if (return_r6) {
    lapply(result_ptrs, function(ptr) Pitch(.xptr = ptr))
  } else {
    result_ptrs
  }
}


#' Extract Formants from Multiple Sounds in Single C++ Call
#'
#' @inheritParams pladdrr_shared_params sounds
#' @param time_step Numeric. Time step in seconds (default: 0.005)
#' @param max_formants Numeric. Maximum number of formants (default: 5)
#' @param max_frequency Numeric. Maximum frequency in Hz (default: 5500)
#' @param window_length Numeric. Window length in seconds (default: 0.025)
#' @param pre_emphasis_from Numeric. Pre-emphasis from frequency (default: 50)
#' @param return_r6 Logical. Return R6 Formant objects (TRUE) or raw xptrs (FALSE)
#'
#' @return List of Formant objects (R6 or xptr depending on return_r6)
#'
#' @examples
#' sounds <- list(
#'   Sound$create_tone(frequency = 150, duration = 0.5),
#'   Sound$create_tone(frequency = 200, duration = 0.5)
#' )
#' formants <- sound_to_formant_batch(sounds)
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
      ptr <- s$.xptr
      if (is.null(ptr)) ptr <- s$get_xptr()
      if (is.null(ptr)) stop("Could not extract pointer from Sound object")
      ptr
    } else if (inherits(s, "externalptr")) {
      s
    } else {
      stop("Invalid input type: expected Sound or externalptr")
    }
  })

  result_ptrs <- .sound_to_formant_batch(
    xptrs, time_step, max_formants,
    max_frequency, window_length, pre_emphasis_from
  )

  if (return_r6) {
    lapply(result_ptrs, function(ptr) Formant(.xptr = ptr))
  } else {
    result_ptrs
  }
}


#' Extract Intensity from Multiple Sounds in Single C++ Call
#'
#' @inheritParams pladdrr_shared_params sounds
#' @param minimum_pitch Numeric. Minimum pitch for analysis (default: 100)
#' @inheritParams pladdrr_shared_params time_step
#' @param subtract_mean Logical. Subtract mean pressure (default: TRUE)
#' @param return_r6 Logical. Return R6 Intensity objects (TRUE) or raw xptrs (FALSE)
#'
#' @return List of Intensity objects (R6 or xptr depending on return_r6)
#'
#' @examples
#' sounds <- list(
#'   Sound$create_tone(frequency = 150, duration = 0.5),
#'   Sound$create_tone(frequency = 200, duration = 0.5)
#' )
#' intensities <- sound_to_intensity_batch(sounds)
#'
#' @export
sound_to_intensity_batch <- function(sounds,
                                     minimum_pitch = 100,
                                     time_step = 0,
                                     subtract_mean = TRUE,
                                     return_r6 = TRUE) {
  xptrs <- lapply(sounds, function(s) {
    if (inherits(s, "Sound")) {
      ptr <- s$.xptr
      if (is.null(ptr)) ptr <- s$get_xptr()
      if (is.null(ptr)) stop("Could not extract pointer from Sound object")
      ptr
    } else if (inherits(s, "externalptr")) {
      s
    } else {
      stop("Invalid input type: expected Sound or externalptr")
    }
  })

  result_ptrs <- .sound_to_intensity_batch(xptrs, minimum_pitch, time_step, subtract_mean)

  if (return_r6) {
    lapply(result_ptrs, function(ptr) Intensity(.xptr = ptr))
  } else {
    result_ptrs
  }
}


#' Extract Parts and Analyze Pitch in Single C++ Call
#'
#' Combines interval extraction and pitch analysis in a single C++ call,
#' avoiding intermediate R6 object creation, as an alternative to
#' extracting each part and calling `$to_pitch()` on it in a loop.
#'
#' @param sound Sound object (R6) or external pointer
#' @param from_times Numeric vector of start times
#' @param to_times Numeric vector of end times
#' @param time_step Numeric. Pitch time step (0 = automatic)
#' @inheritParams pladdrr_shared_params pitch_floor
#' @inheritParams pladdrr_shared_params pitch_ceiling
#' @inheritParams pladdrr_shared_params return_r6
#'
#' @return List of Pitch objects (R6 or xptr depending on return_r6)
#'
#' @examples
#' sound <- Sound$create_tone(frequency = 150, duration = 2.0)
#' from_times <- c(0.2, 1.0)
#' to_times <- c(0.6, 1.4)
#' pitches <- sound_extract_and_pitch(sound, from_times, to_times)
#'
#' @export
sound_extract_and_pitch <- function(sound, from_times, to_times,
                                    time_step = 0,
                                    pitch_floor = 75,
                                    pitch_ceiling = 600,
                                    return_r6 = TRUE) {
  xptr <- if (inherits(sound, "Sound")) {
    ptr <- sound$.xptr
    if (is.null(ptr)) ptr <- sound$get_xptr()
    if (is.null(ptr)) stop("Could not extract pointer from Sound object")
    ptr
  } else if (inherits(sound, "externalptr")) {
    sound
  } else {
    stop("Invalid input type: expected Sound or externalptr")
  }

  result_ptrs <- .sound_extract_and_pitch_batch(
    xptr, from_times, to_times,
    time_step, pitch_floor, pitch_ceiling
  )

  if (return_r6) {
    lapply(result_ptrs, function(ptr) Pitch(.xptr = ptr))
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
#' @examples
#' sound <- Sound$create_tone(frequency = 150, duration = 2.0)
#' from_times <- c(0.2, 1.0)
#' to_times <- c(0.6, 1.4)
#' formants <- sound_extract_and_formant(sound, from_times, to_times)
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
    ptr <- sound$.xptr
    if (is.null(ptr)) ptr <- sound$get_xptr()
    if (is.null(ptr)) stop("Could not extract pointer from Sound object")
    ptr
  } else if (inherits(sound, "externalptr")) {
    sound
  } else {
    stop("Invalid input type: expected Sound or externalptr")
  }

  result_ptrs <- .sound_extract_and_formant_batch(
    xptr, from_times, to_times,
    time_step, max_formants, max_frequency,
    window_length, pre_emphasis_from
  )

  if (return_r6) {
    lapply(result_ptrs, function(ptr) Formant(.xptr = ptr))
  } else {
    result_ptrs
  }
}


#' Merge Multiple TextGrid Objects
#'
#' Batch merging using Praat's O(n) algorithm instead of O(n²) manual tier copying.
#' Manual merge requires save/reload + insert_boundary for each interval (each insert shifts
#' all later intervals). Batch merge is single-pass.
#'
#' @param textgrids List of TextGrid objects (external pointers or R6 objects with .xptr)
#' @param equalize_domains If TRUE, all tiers extended to same domain with empty intervals
#'   at edges if needed (default: FALSE)
#'
#' @return TextGrid object (external pointer)
#'
#' @details
#' Manual merge requires save/reload plus an O(n²) sequence of
#' `insert_boundary` calls (each insert shifts all later intervals); batch
#' merge does a single O(n) pass with proper interval handling.
#'
#' **Domain handling:**
#' - If `equalize_domains = FALSE` (default):
#'   * New domain runs from min(xmin) to max(xmax) of all input TextGrids
#'   * Tiers retain their original domains
#'
#' - If `equalize_domains = TRUE`:
#'   * All tiers extended to the new domain
#'   * Empty intervals added at edges if needed
#'
#' **Use cases:**
#' - VUV analysis: Merging original TextGrid with VUV tier
#' - Multi-annotator: Combining annotations from different annotators
#' - Workflow: Adding automatic tiers to manual annotations
#'
#' @examples
#' # Create test TextGrids
#' tg1 <- textgrid_create(0, 1, "words")
#' tg1$insert_boundary(1, 0.5)
#' tg1$set_interval_text(1, 1, "hello")
#' tg1$set_interval_text(1, 2, "world")
#'
#' tg2 <- textgrid_create(0, 1, "events", "events")
#' tg2$insert_point(1, 0.25, "click")
#'
#' # Batch merge
#' merged <- textgrid_merge(list(tg1, tg2))
#' # Result has 2 tiers: "words" (interval) + "events" (point)
#'
#' # With domain equalization
#' merged_eq <- textgrid_merge(list(tg1, tg2), equalize_domains = TRUE)
#'
#' @family batch-ops
#' @seealso \code{\link{TextGrid}} for TextGrid object creation
#' @export
textgrid_merge <- function(textgrids, equalize_domains = FALSE) {
  if (!is.list(textgrids) || length(textgrids) == 0) {
    stop("textgrids must be a non-empty list")
  }
  if (!is.logical(equalize_domains) || length(equalize_domains) != 1) {
    stop("equalize_domains must be TRUE or FALSE")
  }
  
  # Call C++ wrapper (returns external pointer)
  result_xptr <- .textgrid_merge(textgrids, equalize_domains)
  
  # Wrap in R6 TextGrid object
  TextGrid(.xptr = result_xptr)
}



# Validate sound_load_window arguments.
.validate_sound_load_window <- function(path, start, end, resample_to, preserve_times) {
  if (!.is_string_scalar(path)) stop("path must be a single character string")
  if (!file.exists(path)) stop("File not found: ", path)
  if (!.is_numeric_scalar(start) || start < 0) stop("start must be a non-negative number")
  if (!.is_numeric_scalar(end)) stop("end must be a number")
  if (end <= start) stop("end must be greater than start")
  if (!is.null(resample_to)) {
    if (!.is_numeric_scalar(resample_to) || resample_to <= 0) stop("resample_to must be a positive number or NULL")
  }
  if (!.is_logical_scalar(preserve_times)) stop("preserve_times must be TRUE or FALSE")
  invisible(NULL)
}

#' Load Sound Window from File with Optional Resampling
#'
#' Extracts a time window from a sound file without loading the entire file.
#' Optionally resamples the window to a target sampling rate.
#' Uses LongSound for lazy loading - only the requested window is loaded from disk.
#'
#' @param path Path to sound file (WAV, AIFF, FLAC, MP3, etc.)
#' @param start Start time of window in seconds
#' @param end End time of window in seconds
#' @param resample_to Target sampling rate in Hz (optional). If NULL, no resampling.
#' @param preserve_times If TRUE, keep original time domain. If FALSE, shift to start at 0 (default: FALSE)
#'
#' @return Sound object containing the windowed (and optionally resampled) audio
#'
#' @details
#' A traditional workflow loads the entire file, resamples the entire file,
#' and then extracts the window of interest — reading and processing far more
#' samples than needed. This function instead opens the file as a `LongSound`
#' (lazily, reading only the header), extracts just the requested window from
#' disk, and resamples only that window.
#'
#' **Use cases:**
#' - Pharyngeal analysis: extracting short vowel windows from long recordings
#' - Formant tracking: analyzing specific time points
#' - Batch extraction: processing windows from multiple files
#' - Large file processing: working with hours-long recordings
#'
#' @examples
#' # Write a short synthetic recording, then load only part of it
#' sound <- Sound$create_tone(frequency = 220, duration = 2.0)
#' path <- tempfile(fileext = ".wav")
#' sound$save(path)
#'
#' window <- sound_load_window(path, start = 0.5, end = 0.6)
#'
#' # Extract and resample (for spectral analysis)
#' window_10k <- sound_load_window(path, start = 0.5, end = 0.6, resample_to = 10000)
#'
#' # Preserve original time domain (window starts at 0.5, not 0.0)
#' window_timed <- sound_load_window(path, start = 0.5, end = 0.6, preserve_times = TRUE)
#'
#' unlink(path)
#'
#' @family batch-ops
#' @seealso \code{\link{Sound}}, \code{\link{LongSound}}
#' @export
sound_load_window <- function(path, start, end, resample_to = NULL, preserve_times = FALSE) {
  .validate_sound_load_window(path, start, end, resample_to, preserve_times)
  
  # Call C++ wrapper (returns external pointer)
  result_xptr <- .sound_load_window(path, start, end, resample_to, preserve_times)
  
  # Wrap in R6 Sound object
  Sound(.xptr = result_xptr)
}
