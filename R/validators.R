# Shared argument validators, called at wrapper entry so users get a clear
# R-level error instead of a generic "Failed to ..." from the C++ boundary.

# Praat refuses pitch_floor >= pitch_ceiling in its forms; without this check
# the C++ analysis either fails opaquely or silently computes on an inverted
# range.
.check_pitch_range <- function(pitch_floor, pitch_ceiling) {
  if (!is.numeric(pitch_floor) || length(pitch_floor) != 1L || is.na(pitch_floor) ||
      pitch_floor <= 0) {
    stop("pitch_floor must be a single positive number (Hz), got: ",
         deparse(pitch_floor), call. = FALSE)
  }
  if (!is.numeric(pitch_ceiling) || length(pitch_ceiling) != 1L || is.na(pitch_ceiling) ||
      pitch_ceiling <= pitch_floor) {
    stop("pitch_ceiling (", deparse(pitch_ceiling),
         ") must be a single number greater than pitch_floor (",
         pitch_floor, ")", call. = FALSE)
  }
  invisible(TRUE)
}

# Formant/pole counts must be positive; a zero or negative count makes the
# split-Levinson/Burg solver produce garbage frames (and, for Willems, spew
# "no zero" diagnostics) instead of failing cleanly.
.check_positive_count <- function(value, name) {
  if (!is.numeric(value) || length(value) != 1L || is.na(value) || value < 1) {
    stop(name, " must be a single number >= 1, got: ", deparse(value),
         call. = FALSE)
  }
  invisible(TRUE)
}

.check_positive_number <- function(value, name) {
  if (!is.numeric(value) || length(value) != 1L || is.na(value) || value <= 0) {
    stop(name, " must be a single positive number, got: ", deparse(value),
         call. = FALSE)
  }
  invisible(TRUE)
}
