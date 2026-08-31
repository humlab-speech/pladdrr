# Internal utility functions for pladdrr

#' Extract External Pointer from pladdrr Objects
#'
#' Unified function to extract external pointers from pladdrr objects.
#' Handles both function-wrapper and R6 class implementations.
#'
#' @param obj Object to extract pointer from (Sound, Pitch, Formant, etc.)
#' @param class_name Expected class name for error messages
#'
#' @return External pointer
#' @keywords internal
#' @examples
#' sound <- Sound$create_tone(frequency = 220, duration = 0.2, sampling_rate = 8000)
#' pladdrr:::extract_xptr(sound, "Sound")
#' @noRd
extract_xptr <- function(obj, class_name) {
  if (inherits(obj, class_name)) {
    # Try function-wrapper style first (.xptr field)
    ptr <- obj$.xptr
    
    # Fallback 1: method call
    if (is.null(ptr)) {
      tryCatch({
        ptr <- obj$get_xptr()
      }, error = function(e) NULL)
    }
    
    # Fallback 2: alternative field name
    if (is.null(ptr) && !is.null(obj$.pointer)) {
      ptr <- obj$.pointer
    }
    
    # Fallback 3: R6 private environment (legacy)
    if (is.null(ptr)) {
      tryCatch({
        ptr <- obj$.__enclos_env__$private$ptr
      }, error = function(e) NULL)
    }
    
    if (is.null(ptr)) {
      stop(sprintf("Could not extract external pointer from %s object", class_name))
    }
    
    ptr
  } else if (inherits(obj, "externalptr")) {
    obj
  } else {
    stop(sprintf("Expected %s or externalptr, got %s", class_name, class(obj)[1]))
  }
}


#' Convert Unit Name to Praat Unit Code
#'
#' Standardized mapping from unit names to Praat integer codes.
#' Ensures consistency across all APIs (Tier 1, 2, and 3).
#'
#' @param unit Character. Unit name
#' @param type Character. Type of unit: "pitch", "formant", or "intensity"
#'
#' @return Integer unit code for Praat C++ layer
#' @keywords internal
#' @examples
#' pladdrr:::unit_to_code("semitones", type = "pitch")
#' pladdrr:::unit_to_code("bark", type = "formant")
#' @noRd
unit_to_code <- function(unit, type = "pitch") {
  unit <- tolower(unit)
  
  code <- switch(type,
    pitch = switch(unit,
      hertz = 0L,
      hz = 0L,
      hertz_logarithmic = 1L,
      semitones = 1L, st = 1L,
      mel = 2L,
      loghertz = 3L,
      semitones_re_1hz = 4L,
      semitones_re_100hz = 5L,
      semitones_re_200hz = 6L,
      semitones_re_440hz = 7L,
      erb = 8L,
      0L  # default to hertz
    ),
    
    formant = switch(unit,
      hertz = 0L,
      hz = 0L,
      bark = 1L,
      0L  # default to hertz
    ),
    
    intensity = switch(unit,
      db = 0L,
      0L
    )
  )
  if (is.null(code)) {
    stop(sprintf("Unknown unit type: %s", type))
  }
  code
}
