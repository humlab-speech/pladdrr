#' @title Praat Manipulation Object
#' @description
#' Praat Manipulation object with direct C++ module binding for PSOLA-based
#' pitch and duration modification.
#'
#' @details
#' The Manipulation object is Praat's main tool for modifying pitch and duration
#' of speech sounds using PSOLA (Pitch-Synchronous Overlap-Add) resynthesis.
#'
#' @param .xptr Not for direct use. External pointer to the underlying C++
#'   Manipulation object; set internally when a method returns a new
#'   Manipulation, e.g. \code{sound$to_manipulation()}.
#' @return A \code{Manipulation} object.
#'
#' @examples
#' sound <- Sound$create_tone(frequency = 150, duration = 0.5)
#' manip <- sound$to_manipulation(pitch_floor = 75, pitch_ceiling = 300)
#' manip$has_pitch_tier()
#' pt <- manip$extract_pitch_tier()
#'
#' @name Manipulation
NULL

# ============================================================================
# Shared Method Dispatch Table
# ============================================================================

.manipulation_methods <- new.env(hash = TRUE, parent = emptyenv())

# Query
.manipulation_methods$get_start_time <- function(.self) .self$.cpp$get_xmin()
.manipulation_methods$get_end_time <- function(.self) .self$.cpp$get_xmax()
.manipulation_methods$get_duration <- function(.self) .self$.cpp$get_duration()
.manipulation_methods$has_pitch_tier <- function(.self) .self$.cpp$has_pitch_tier()
.manipulation_methods$has_duration_tier <- function(.self) .self$.cpp$has_duration_tier()
.manipulation_methods$has_pulses <- function(.self) .self$.cpp$has_pulses()
.manipulation_methods$has_original_sound <- function(.self) .self$.cpp$has_original_sound()

# Extract tiers
.manipulation_methods$extract_pitch_tier <- function(.self) {
  tier_ptr <- .manipulation_extract_pitch_tier(.self$.xptr)
  PitchTier(.xptr = tier_ptr)
}
.manipulation_methods$extract_duration_tier <- function(.self) {
  tier_ptr <- .manipulation_extract_duration_tier(.self$.xptr)
  DurationTier(.xptr = tier_ptr)
}
.manipulation_methods$extract_pulses <- function(.self) {
  pp_ptr <- .manipulation_extract_pulses(.self$.xptr)
  PointProcess(.xptr = pp_ptr)
}
.manipulation_methods$extract_original_sound <- function(.self) {
  sound_ptr <- .manipulation_extract_original_sound(.self$.xptr)
  Sound(.xptr = sound_ptr)
}

# Replace tiers
.manipulation_methods$replace_pitch_tier <- function(.self, pitch_tier) {
  if (!inherits(pitch_tier, "PitchTier")) stop("pitch_tier must be a PitchTier object")
  .self$.cpp$replace_pitch_tier(pitch_tier$get_xptr())
  invisible(.self)
}
.manipulation_methods$replace_duration_tier <- function(.self, duration_tier) {
  if (!inherits(duration_tier, "DurationTier")) stop("duration_tier must be a DurationTier object")
  .self$.cpp$replace_duration_tier(duration_tier$get_xptr())
  invisible(.self)
}
.manipulation_methods$replace_pulses <- function(.self, point_process) {
  if (!inherits(point_process, "PointProcess")) stop("point_process must be a PointProcess object")
  .self$.cpp$replace_pulses(point_process$get_xptr())
  invisible(.self)
}

# Synthesis
.manipulation_methods$get_resynthesis_overlap_add <- function(.self) {
  sound_ptr <- .manipulation_get_resynthesis_overlap_add(.self$.xptr)
  Sound(.xptr = sound_ptr)
}
.manipulation_methods$get_resynthesis_pulses <- function(.self) {
  sound_ptr <- .self$.cpp$get_resynthesis_pulses_ptr()
  Sound(.xptr = sound_ptr)
}

# Utility
.manipulation_methods$get_xptr <- function(.self) .self$.xptr

# Print
.manipulation_methods$print <- function(.self) {
  cat("<Praat Manipulation>\n")
  cat(sprintf("  Time domain: %.3f to %.3f s\n", .self$.cpp$get_xmin(), .self$.cpp$get_xmax()))
  cat(sprintf("  Has pitch tier: %s\n", if(.self$.cpp$has_pitch_tier()) "yes" else "no"))
  cat(sprintf("  Has duration tier: %s\n", if(.self$.cpp$has_duration_tier()) "yes" else "no"))
  cat(sprintf("  Has pulses: %s\n", if(.self$.cpp$has_pulses()) "yes" else "no"))
  invisible(.self)
}

.manipulation_methods$is_valid <- function(.self) .self$.cpp$is_valid()
lockEnvironment(.manipulation_methods, bindings = TRUE)

# ============================================================================
# S3 Dispatch
# ============================================================================

#' @method $ Manipulation
#' @export
`$.Manipulation` <- function(x, name) {
  val <- .subset2(x, name)
  if (!is.null(val)) return(val)
  method <- .manipulation_methods[[name]]
  if (is.null(method)) return(NULL)
  function(...) method(x, ...)
}

# ============================================================================
# Constructor
# ============================================================================

#' @export
Manipulation <- function(.xptr) {
  if (missing(.xptr) || is.null(.xptr)) {
    stop("Manipulation objects must be created from a Sound object using sound$to_manipulation()")
  }
  
  manip_mod <- get_module("manipulation_module")
  cpp_obj <- manip_mod$RManipulation$new(.xptr)
  
  structure(list(
    .cpp = cpp_obj,
    .xptr = .xptr
  ), class = c("Manipulation", "PraatObject"))
}

#' @export
print.Manipulation <- function(x, ...) {
  x$print()
  invisible(x)
}
