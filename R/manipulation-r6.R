#' @title Praat Manipulation Object
#' @description
#' Praat Manipulation object with direct C++ module binding for PSOLA-based
#' pitch and duration modification.
#'
#' @details
#' The Manipulation object is Praat's main tool for modifying pitch and duration
#' of speech sounds using PSOLA (Pitch-Synchronous Overlap-Add) resynthesis.
#'
#' @export
Manipulation <- function(.xptr) {
  if (missing(.xptr) || is.null(.xptr)) {
    stop("Manipulation objects must be created from a Sound object using sound$to_manipulation()")
  }
  
  manip_mod <- get_module("manipulation_module")
  cpp_obj <- manip_mod$RManipulation$new(.xptr)
  
  obj <- structure(list(
    .cpp = cpp_obj,
    .xptr = .xptr,
    
    # Query
    get_start_time = function() cpp_obj$get_xmin(),
    get_end_time = function() cpp_obj$get_xmax(),
    get_duration = function() cpp_obj$get_duration(),
    has_pitch_tier = function() cpp_obj$has_pitch_tier(),
    has_duration_tier = function() cpp_obj$has_duration_tier(),
    has_pulses = function() cpp_obj$has_pulses(),
    has_original_sound = function() cpp_obj$has_original_sound(),
    
    # Extract tiers
    extract_pitch_tier = function() {
      tier_ptr <- .manipulation_extract_pitch_tier(.xptr)
      PitchTier(.xptr = tier_ptr)
    },
    extract_duration_tier = function() {
      tier_ptr <- .manipulation_extract_duration_tier(.xptr)
      DurationTier(.xptr = tier_ptr)
    },
    extract_pulses = function() {
      pp_ptr <- .manipulation_extract_pulses(.xptr)
      PointProcess(.xptr = pp_ptr)
    },
    extract_original_sound = function() {
      sound_ptr <- .manipulation_extract_sound(.xptr)
      Sound(.xptr = sound_ptr)
    },
    
    # Replace tiers
    replace_pitch_tier = function(pitch_tier) {
      if (!inherits(pitch_tier, "PitchTier")) {
        stop("pitch_tier must be a PitchTier object")
      }
      cpp_obj$replace_pitch_tier(pitch_tier$get_xptr())
      invisible(obj)
    },
    replace_duration_tier = function(duration_tier) {
      if (!inherits(duration_tier, "DurationTier")) {
        stop("duration_tier must be a DurationTier object")
      }
      cpp_obj$replace_duration_tier(duration_tier$get_xptr())
      invisible(obj)
    },
    replace_pulses = function(point_process) {
      if (!inherits(point_process, "PointProcess")) {
        stop("point_process must be a PointProcess object")
      }
      cpp_obj$replace_pulses(point_process$get_xptr())
      invisible(obj)
    },
    
    # Synthesis
    get_resynthesis_overlap_add = function() {
      sound_ptr <- .manipulation_get_resynthesis_overlap_add(.xptr)
      Sound(.xptr = sound_ptr)
    },
    get_resynthesis_pulses = function() {
      sound_ptr <- .manipulation_get_resynthesis_pulses(.xptr)
      Sound(.xptr = sound_ptr)
    },
    
    # Utility
    get_xptr = function() .xptr,
    
    # Print
    print = function() {
      cat("<Praat Manipulation>\n")
      cat(sprintf("  Time domain: %.3f to %.3f s\n", cpp_obj$get_xmin(), cpp_obj$get_xmax()))
      cat(sprintf("  Has pitch tier: %s\n", if(cpp_obj$has_pitch_tier()) "yes" else "no"))
      cat(sprintf("  Has duration tier: %s\n", if(cpp_obj$has_duration_tier()) "yes" else "no"))
      cat(sprintf("  Has pulses: %s\n", if(cpp_obj$has_pulses()) "yes" else "no"))
      invisible(obj)
    }
  ), class = c("Manipulation", "PraatObject"))
  
  obj
}

#' @export
print.Manipulation <- function(x, ...) x$print()
