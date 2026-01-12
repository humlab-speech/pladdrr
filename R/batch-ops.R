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
    lapply(result_ptrs, function(ptr) Pitch$new(.xptr = ptr))
  } else {
    result_ptrs
  }
}


#' Extract Pitch (AC) from Multiple Sounds in Single C++ Call
#'
#' Batch version of to_pitch_ac with full voicing parameters.
#' Avoids O(n) R→C boundary crossings for VUV analysis workflows.
#'
#' @param sounds List of Sound objects (R6) or external pointers
#' @param time_step Numeric. Time step (0 = automatic)
#' @param pitch_floor Numeric. Pitch floor in Hz (default: 75)
#' @param pitch_ceiling Numeric. Pitch ceiling in Hz (default: 600)
#' @param max_candidates Integer. Max candidates per frame (default: 15)
#' @param very_accurate Logical. Use very accurate algorithm (default: FALSE)
#' @param silence_threshold Numeric. Silence threshold (default: 0.03)
#' @param voicing_threshold Numeric. Voicing threshold (default: 0.45)
#' @param octave_cost Numeric. Octave cost (default: 0.01)
#' @param octave_jump_cost Numeric. Octave jump cost (default: 0.35)
#' @param voiced_unvoiced_cost Numeric. Voiced/unvoiced cost (default: 0.14)
#' @param return_r6 Logical. Return R6 Pitch objects (TRUE) or raw xptrs (FALSE)
#'
#' @return List of Pitch objects (R6 or xptr depending on return_r6)
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
    lapply(result_ptrs, function(ptr) Pitch$new(.xptr = ptr))
  } else {
    result_ptrs
  }
}


#' Extract Pitch (CC) from Multiple Sounds in Single C++ Call
#'
#' Batch version of to_pitch_cc with full voicing parameters.
#' Avoids O(n) R→C boundary crossings for VUV analysis workflows.
#' Use this for maximum performance when processing many sound segments.
#'
#' @param sounds List of Sound objects (R6) or external pointers
#' @param time_step Numeric. Time step (0 = automatic)
#' @param pitch_floor Numeric. Pitch floor in Hz (default: 75)
#' @param pitch_ceiling Numeric. Pitch ceiling in Hz (default: 600)
#' @param max_candidates Integer. Max candidates per frame (default: 15)
#' @param very_accurate Logical. Use very accurate algorithm (default: FALSE)
#' @param silence_threshold Numeric. Silence threshold (default: 0.03)
#' @param voicing_threshold Numeric. Voicing threshold (default: 0.45)
#' @param octave_cost Numeric. Octave cost (default: 0.01)
#' @param octave_jump_cost Numeric. Octave jump cost (default: 0.35)
#' @param voiced_unvoiced_cost Numeric. Voiced/unvoiced cost (default: 0.14)
#' @param return_r6 Logical. Return R6 Pitch objects (TRUE) or raw xptrs (FALSE)
#'
#' @return List of Pitch objects (R6 or xptr depending on return_r6)
#'
#' @examples
#' \dontrun{
#' # Instead of slow loop:
#' # pitches <- lapply(sounds, function(s) s$to_pitch_cc())
#'
#' # Use batch operation (much faster for many sounds):
#' pitches <- sound_to_pitch_cc_batch(sounds)
#' }
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


#' Merge Multiple TextGrid Objects Efficiently
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
#' **Performance:**
#' - Manual merge: Save/reload + O(n²) insert_boundary calls + O(n) label setting
#' - Batch merge: Single-pass O(n) with proper interval handling
#' - Speedup: ~17x for 100 intervals (VUV use case)
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
#' \dontrun{
#' # Create test TextGrids
#' tg1 <- TextGrid(0, 1)
#' tg1$add_interval_tier("words")
#' tg1$insert_boundary(1, 0.5)
#' tg1$set_interval_text(1, 1, "hello")
#' tg1$set_interval_text(1, 2, "world")
#'
#' tg2 <- TextGrid(0, 1)
#' tg2$add_point_tier("events")
#' tg2$add_point(1, 0.25, "click")
#'
#' # Batch merge (fast)
#' merged <- textgrid_merge(list(tg1, tg2))
#' # Result has 2 tiers: "words" (interval) + "events" (point)
#'
#' # With domain equalization
#' merged_eq <- textgrid_merge(list(tg1, tg2), equalize_domains = TRUE)
#' }
#'
#' @family performance
#' @seealso [TextGrid] for TextGrid object creation
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


#' Load Sound Window from File with Optional Resampling
#'
#' Extracts a time window from a sound file without loading the entire file.
#' Optionally resamples the window to a target sampling rate.
#' Uses LongSound for lazy loading - only the requested window is loaded from disk.
#'
#' @param path Path to sound file (WAV, AIFF, etc.)
#' @param start Start time of window in seconds
#' @param end End time of window in seconds
#' @param resample_to Target sampling rate in Hz (optional). If NULL, no resampling.
#' @param preserve_times If TRUE, keep original time domain. If FALSE, shift to start at 0 (default: FALSE)
#'
#' @return Sound object containing the windowed (and optionally resampled) audio
#'
#' @details
#' **Performance:**
#'
#' Traditional workflow (slow):
#' 1. Load entire file: 10s @ 44.1kHz = 441,000 samples
#' 2. Resample entire file: 10s @ 10kHz = 100,000 samples
#' 3. Extract window: 40ms = 400 samples
#' Waste: 100,000 / 400 = 250x overhead
#'
#' Window-first workflow (fast):
#' 1. Open as LongSound (lazy - just reads header)
#' 2. Extract window from disk: 40ms = only loads 1,764 samples
#' 3. Resample small window: 400 samples
#' Memory: 400 vs 100,000 samples (250x reduction)
#' CPU: Resample 400 vs 100,000 samples (250x reduction)
#'
#' **Speedup scales with file_duration / window_duration:**
#' - 10s file, 40ms window: 250x
#' - 60s file, 100ms window: 600x
#' - 300s file, 50ms window: 6000x
#'
#' **Use cases:**
#' - Pharyngeal analysis: Extracting 40ms vowel windows from long recordings (27x speedup)
#' - Formant tracking: Analyzing specific time points
#' - Batch extraction: Processing windows from multiple files
#' - Large file processing: Working with hours-long recordings
#'
#' @examples
#' \dontrun{
#' # Extract 100ms window starting at 2.5 seconds
#' window <- sound_load_window("long_recording.wav", start = 2.5, end = 2.6)
#'
#' # Extract and resample to 10 kHz (for spectral analysis)
#' window_10k <- sound_load_window(
#'   "recording.wav",
#'   start = 1.0,
#'   end = 1.05,
#'   resample_to = 10000
#' )
#'
#' # Preserve original time domain (window starts at 1.0, not 0.0)
#' window_timed <- sound_load_window(
#'   "recording.wav",
#'   start = 1.0,
#'   end = 1.05,
#'   preserve_times = TRUE
#' )
#' }
#'
#' @family performance
#' @seealso [Sound], [LongSound]
#' @export
sound_load_window <- function(path, start, end, resample_to = NULL, preserve_times = FALSE) {
  if (!is.character(path) || length(path) != 1) {
    stop("path must be a single character string")
  }
  if (!file.exists(path)) {
    stop("File not found: ", path)
  }
  if (!is.numeric(start) || length(start) != 1 || start < 0) {
    stop("start must be a non-negative number")
  }
  if (!is.numeric(end) || length(end) != 1) {
    stop("end must be a number")
  }
  if (end <= start) {
    stop("end must be greater than start")
  }
  if (!is.null(resample_to)) {
    if (!is.numeric(resample_to) || length(resample_to) != 1 || resample_to <= 0) {
      stop("resample_to must be a positive number or NULL")
    }
  }
  if (!is.logical(preserve_times) || length(preserve_times) != 1) {
    stop("preserve_times must be TRUE or FALSE")
  }
  
  # Call C++ wrapper (returns external pointer)
  result_xptr <- .sound_load_window(path, start, end, resample_to, preserve_times)
  
  # Wrap in R6 Sound object
  Sound(.xptr = result_xptr)
}
