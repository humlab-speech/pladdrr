#' @title Praat Manipulation Object
#' @description
#' R6 class representing a Praat Manipulation object. Manipulations enable PSOLA-based
#' pitch and duration modification for speech synthesis and prosody manipulation.
#'
#' @details
#' The Manipulation object is Praat's main tool for modifying pitch and duration of
#' speech sounds using PSOLA (Pitch-Synchronous Overlap-Add) resynthesis. It contains:
#' - Original Sound
#' - PointProcess (glottal pulse markers)
#' - PitchTier (editable pitch contour)
#' - DurationTier (editable duration factors)
#'
#' ## Creating Manipulation Objects
#'
#' - `sound$to_manipulation()` - Create from Sound with pitch analysis
#'
#' ## Extracting Tiers
#'
#' - `$extract_pitch_tier()` - Get editable PitchTier
#' - `$extract_duration_tier()` - Get editable DurationTier
#' - `$extract_pulses()` - Get PointProcess
#'
#' ## Replacing Tiers (for synthesis)
#'
#' - `$replace_pitch_tier(pitch_tier)` - Replace pitch contour
#' - `$replace_duration_tier(duration_tier)` - Replace duration
#'
#' ## Synthesis
#'
#' - `$get_resynthesis_overlap_add()` - Resynthesize with PSOLA
#' - `$play_overlap_add()` - Play resynthesized sound
#'
#' @examples
#' \dontrun{
#' # Create manipulation from sound
#' sound <- Sound$new("voice.wav")
#' manip <- sound$to_manipulation(pitch_floor = 75, pitch_ceiling = 600)
#'
#' # Modify pitch
#' pitch_tier <- manip$extract_pitch_tier()
#' pitch_tier$multiply_frequencies(1.5)  # Raise pitch 50%
#' manip$replace_pitch_tier(pitch_tier)
#'
#' # Modify duration
#' dur_tier <- manip$extract_duration_tier()
#' dur_tier$add_point(0.5, 1.5)  # Slow down middle section
#' manip$replace_duration_tier(dur_tier)
#'
#' # Synthesize modified sound
#' modified <- manip$get_resynthesis_overlap_add()
#' modified$save("modified_voice.wav")
#'
#' # Quick pitch shift
#' sound <- Sound$new("voice.wav")
#' manip <- sound$to_manipulation()
#' pitch_tier <- manip$extract_pitch_tier()
#' pitch_tier$multiply_frequencies(0.8)  # Lower pitch 20%
#' manip$replace_pitch_tier(pitch_tier)
#' result <- manip$get_resynthesis_overlap_add()
#' }
#'
#' @export
Manipulation <- R6::R6Class(
  "Manipulation",
  inherit = PraatObject,
  
  public = list(
    
    #' @description
    #' Create a Manipulation object (internal - use Sound$to_manipulation())
    #' @param .xptr External pointer from C++
    #' @return A new Manipulation object
    initialize = function(.xptr = NULL) {
      if (is.null(.xptr)) {
        stop("Manipulation objects must be created from Sound$to_manipulation()")
      }
      super$initialize(.xptr)
    },
    
    # ========================================================================
    # Query Methods
    # ========================================================================
    
    #' @description Get start time
    #' @return Start time in seconds
    get_start_time = function() {
      .manipulation_get_start_time(private$ptr)
    },
    
    #' @description Get end time
    #' @return End time in seconds
    get_end_time = function() {
      .manipulation_get_end_time(private$ptr)
    },
    
    # ========================================================================
    # Extract Tiers
    # ========================================================================
    
    #' @description Extract PitchTier for editing
    #' @return PitchTier object
    extract_pitch_tier = function() {
      tier_ptr <- .manipulation_extract_pitch_tier(private$ptr)
      PitchTier(.xptr = tier_ptr)
    },
    
    #' @description Extract DurationTier for editing
    #' @return DurationTier object
    extract_duration_tier = function() {
      tier_ptr <- .manipulation_extract_duration_tier(private$ptr)
      DurationTier$new(.xptr = tier_ptr)
    },
    
    #' @description Extract PointProcess (pulse markers)
    #' @return PointProcess object
    extract_pulses = function() {
      pp_ptr <- .manipulation_extract_pulses(private$ptr)
      PointProcess$new(.xptr = pp_ptr)
    },
    
    #' @description Extract original Sound
    #' @return Sound object
    extract_original_sound = function() {
      sound_ptr <- .manipulation_extract_original_sound(private$ptr)
      Sound$new(.xptr = sound_ptr)
    },
    
    # ========================================================================
    # Replace Tiers
    # ========================================================================
    
    #' @description Replace pitch tier
    #' @param pitch_tier PitchTier object with modified pitch
    #' @return Self (invisibly) for method chaining
    replace_pitch_tier = function(pitch_tier) {
      if (!inherits(pitch_tier, "PitchTier")) {
        stop("Argument must be a PitchTier object")
      }
      .manipulation_replace_pitch_tier(private$ptr, pitch_tier$.__enclos_env__$private$ptr)
      invisible(self)
    },
    
    #' @description Replace duration tier
    #' @param duration_tier DurationTier object with modified durations
    #' @return Self (invisibly) for method chaining
    replace_duration_tier = function(duration_tier) {
      if (!inherits(duration_tier, "DurationTier")) {
        stop("Argument must be a DurationTier object")
      }
      .manipulation_replace_duration_tier(private$ptr, duration_tier$.__enclos_env__$private$ptr)
      invisible(self)
    },
    
    # ========================================================================
    # Synthesis Methods
    # ========================================================================
    
    #' @description Resynthesize sound using overlap-add (PSOLA)
    #' @return Sound object with modified pitch and/or duration
    get_resynthesis_overlap_add = function() {
      sound_ptr <- .manipulation_get_resynthesis_overlap_add(private$ptr)
      Sound$new(.xptr = sound_ptr)
    },
    
    # LPC resynthesis disabled - requires LPC module not available in current Praat version
    # #' @description Resynthesize using LPC
    # #' @return Sound object (LPC resynthesis)
    # get_resynthesis_lpc = function() {
    #   sound_ptr <- .manipulation_get_resynthesis_lpc(private$ptr)
    #   Sound$new(.xptr = sound_ptr)
    # },
    
    # ========================================================================
    # Print Method
    # ========================================================================
    
    #' @description Print manipulation information
    print = function() {
      cat("<Praat Manipulation>\n")
      cat(sprintf("  Time domain: %.3f to %.3f s\n", 
                  self$get_start_time(), self$get_end_time()))
      
      # Try to get tier info
      tryCatch({
        pitch_tier <- self$extract_pitch_tier()
        cat(sprintf("  Pitch points: %d\n", pitch_tier$get_number_of_points()))
        
        dur_tier <- self$extract_duration_tier()
        cat(sprintf("  Duration points: %d\n", dur_tier$get_number_of_points()))
      }, error = function(e) {
        # Silent fail if tiers unavailable
      })
      
      invisible(self)
    }
  ),
  
  # ========================================================================
  # Active Bindings
  # ========================================================================
  active = list(
    #' @field tmin Start time (read-only)
    tmin = function() self$get_start_time(),
    
    #' @field tmax End time (read-only)
    tmax = function() self$get_end_time()
  )
)
