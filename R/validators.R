# Shared argument validators, called at wrapper entry so users get a clear
# R-level error instead of a generic "Failed to ..." from the C++ boundary.
#
# These raise `pladdrr_input_error` conditions (see R/error-classes.R), so the
# typed-error contract documented in inst/agents/AGENT_GUIDE.md holds for
# argument validation whether or not the call goes through
# `with_pladdrr_errors()`. C++-side failures still surface untagged unless the
# wrapper uses the PLADDRR_* macros in src/pladdrr_errors.h.

# Raise a classed input error. `routine` and `param` are carried on the
# condition so programmatic callers can branch on them.
.stop_input <- function(routine, param, msg, call = sys.call(-2L)) {
  stop(
    pladdrr_error_cond("pladdrr_input_error", routine, param, msg, call = call))
}

# Warn that output is incomplete relative to what was requested. Praat itself
# often returns a silently padded or clipped result; design principle 6 says the
# user must be told. Honours options(pladdrr.data_loss =
#  "warn"|"error"|"silent").
# Is x a single (length-1) non-NA numeric scalar?
.is_numeric_scalar <- function(x) is.numeric(x) && length(x) == 1L && !is.na(x)


# Is x a single (length-1) character string?
.is_string_scalar <- function(x) is.character(x) && length(x) == 1L

# Is x a single (length-1) logical?
.is_logical_scalar <- function(x) is.logical(x) && length(x) == 1L

.warn_data_loss <- function(routine, msg, call = sys.call(-2L)) {
  mode <- getOption("pladdrr.data_loss", "warn")
  if (identical(mode, "silent")) return(invisible(FALSE))
  cond <- pladdrr_warning_cond("pladdrr_data_loss", routine, NA_character_, msg,
                               call = call)
  if (identical(mode, "error")) {
    stop(pladdrr_error_cond("pladdrr_data_loss", routine, NA_character_, msg,
                            call = call))
  }
  warning(cond)
  invisible(TRUE)
}

# Praat refuses pitch_floor >= pitch_ceiling in its forms; without this check
# the C++ analysis either fails opaquely or silently computes on an inverted
# range.
.check_pitch_range <- function(pitch_floor, pitch_ceiling) {
  if (!.is_numeric_scalar(pitch_floor) || pitch_floor <= 0) {
    .stop_input("check_pitch_range", "pitch_floor",
                paste0(
                  "pitch_floor must be a single positive number (Hz), got: ",
                       deparse(pitch_floor)))
  }
  if (!.is_numeric_scalar(pitch_ceiling) || pitch_ceiling <= pitch_floor) {
    .stop_input("check_pitch_range", "pitch_ceiling",
                paste0("pitch_ceiling (", deparse(pitch_ceiling),
                       ") must be a single number greater than pitch_floor (",
                       pitch_floor, ")"))
  }
  invisible(TRUE)
}

# Formant/pole counts must be positive; a zero or negative count makes the
# split-Levinson/Burg solver produce garbage frames (and, for Willems, spew
# "no zero" diagnostics) instead of failing cleanly.
.check_positive_count <- function(value, name) {
  if (!is.numeric(value) || length(value) != 1L || is.na(value) || value < 1) {
    .stop_input("check_positive_count", name,
                paste0(name, " must be a single number >= 1, got: ",
                  deparse(value)))
  }
  invisible(TRUE)
}

.check_positive_number <- function(value, name) {
  if (!is.numeric(value) || length(value) != 1L || is.na(value) || value <= 0) {
    .stop_input("check_positive_number", name,
                paste0(name, " must be a single positive number, got: ",
                       deparse(value)))
  }
  invisible(TRUE)
}

# Praat's "Robust slow" trend fit (kCepstrum_trendFit::ROBUST_SLOW ->
#  SlopeSelector
# THEILSEN) draws random samples via NUMrandomInteger inside Matousek's slope
# selection, and the upstream implementation is not reproducible: repeated runs
#  on
# identical input differ by ~0.8 dB, and Praat itself occasionally returns
#  values on
# the order of 1e290. pladdrr inherits the instability faithfully. Warn once per
# session so a user does not silently build an analysis on an irreproducible
#  number.
# See dev/ASSESSMENT_2026-08-05.md section 2.6.
.warned_robust_slow <- new.env(parent = emptyenv())

.check_trend_fit_method <- function(fit_method) {
  if (identical(fit_method, "robust slow") &&
      is.null(.warned_robust_slow$done)) {
    .warned_robust_slow$done <- TRUE
    warning(
      "fit_method = \"robust slow\" (Praat's Theil-Sen trend fit) is not ",
      "reproducible: it draws random samples internally, so repeated runs on the ",
      "same input differ (~0.8 dB observed) and can return wildly wrong values. ",
      "This is an upstream Praat defect, reproduced faithfully here. Use ",
      "fit_method = \"robust\" (Siegel) or \"least_squares\" for a deterministic result.",
      call. = FALSE
    )
  }
  invisible(TRUE)
}

# Praat autowindows a reversed or zero quefrency range, but a caller who passes
# qstart > qend almost always means the opposite of what they get. Fail loudly
# rather than return a silently different measurement.
.check_quefrency_range <- function(qstart, qend, qstart_name = "qstart_fit",
                                   qend_name = "qend_fit") {
  if (!.is_numeric_scalar(qstart) || qstart < 0) {
    .stop_input("check_quefrency_range", qstart_name,
                paste0(qstart_name,
                  " must be a single non-negative number (s), got: ",
                       deparse(qstart)))
  }
  if (!.is_numeric_scalar(qend) || qend < 0) {
    .stop_input("check_quefrency_range", qend_name,
                paste0(qend_name,
                  " must be a single non-negative number (s), got: ",
                       deparse(qend)))
  }
  # qend == 0 means "autowindow to the full quefrency range" (Praat convention).
  if (qend != 0 && qend <= qstart) {
    .stop_input("check_quefrency_range", qend_name,
                paste0(qend_name, " (", qend, ") must be greater than ",
                  qstart_name,
                       " (", qstart, "); pass ", qend_name,
                       " = 0 to autowindow the full quefrency range"))
  }
  invisible(TRUE)
}

# Praat treats time step 0 as "auto" (= window_length / 4) in every To Formant /
# To Pitch / To Intensity form, so 0 must be accepted here too — rejecting it
#  made
# a documented Praat idiom unusable in to_formant_keepall/willems/sl. Negative
#  or
# non-finite values are still errors.
.check_time_step <- function(time_step) {
  if (!is.numeric(time_step) || length(time_step) != 1L || is.na(time_step) ||
      time_step < 0) {
    .stop_input("check_time_step", "time_step",
                paste0("time_step must be a single non-negative number ",
                       "(0 = auto), got: ", deparse(time_step)))
  }
  invisible(TRUE)
}

# Praat's "Extract part" zero-pads any portion of the requested window that lies
# outside the signal and returns it silently, so `sound$extract_part(5, 10)` on
#  a
# 1 s Sound yields 5 s of fabricated silence. pladdrr reproduces the value (goal
#  1)
# but reports the fabrication (goal 6).
.check_extract_range <- function(.self, from_time, to_time) {
  dur <- tryCatch(.self$get_total_duration(), error = function(e) NA_real_)
  if (is.na(dur)) return(invisible(FALSE))
  xmin <- tryCatch(.self$get_start_time(), error = function(e) 0)
  xmax <- xmin + dur
  lo <- suppressWarnings(min(as.numeric(from_time)))
  hi <- suppressWarnings(max(as.numeric(to_time)))
  if (!is.finite(lo) || !is.finite(hi)) return(invisible(FALSE))
  if (lo < xmin || hi > xmax) {
    .warn_data_loss(
      "sound_extract_part",
      sprintf(
        paste0("requested [%g, %g] s extends outside the signal [%g, %g] s; ",
                     "Praat zero-pads the excess, so part of the returned Sound is ",
                     "silence, not data"),
              lo, hi, xmin, xmax))
  }
  invisible(TRUE)
}
