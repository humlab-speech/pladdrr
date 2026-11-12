# Shared argument validators, called at wrapper entry so users get a clear
# R-level error instead of a generic "Failed to ..." from the C++ boundary.
#
# These raise `pladdrr_input_error` conditions (see R/error-classes.R), so the
# typed-error contract documented in inst/agents/AGENT_GUIDE.md holds for
# argument validation whether or not the call goes through
# `with_pladdrr_errors()`. C++-side failures still surface untagged unless the
# wrapper uses the PLADDRR_* macros in src/pladdrr_errors.h.

# One-line, length-capped deparse for error messages: deparse() of a long
# vector returns several strings, which would make the condition message a
# vector.
.short_deparse <- function(x, width = 60L) {
  txt <- base::deparse1(x)
  if (nchar(txt) > width) paste0(substr(txt, 1L, width - 3L), "...") else txt
}

# Raise a classed input error. `routine` and `param` are carried on the
# condition so programmatic callers can branch on them.
#' Raise a classed `pladdrr_input_error`.
#' `routine` and `param` are carried on the condition so callers can branch on them.
#' @noRd
.stop_input <- function(routine, param, msg, call = sys.call(-2L)) {
  stop(
    pladdrr_error_cond("pladdrr_input_error", routine, param, msg, call = call))
}

# Warn that output is incomplete relative to what was requested. Praat itself
# often returns a silently padded or clipped result; design principle 6 says the
# user must be told. Honours options(pladdrr.data_loss =
#  "warn"|"error"|"silent").
# Is x a single (length-1) non-NA numeric scalar?
#' Is `x` a single, non-NA number?
#' @noRd
.is_numeric_scalar <- function(x) is.numeric(x) && length(x) == 1L && !is.na(x)


# Is x a single (length-1) character string?
#' Is `x` a single character string?
#' @noRd
.is_string_scalar <- function(x) is.character(x) && length(x) == 1L

# Is x a single (length-1) logical?
#' Is `x` a single logical value?
#' @noRd
.is_logical_scalar <- function(x) is.logical(x) && length(x) == 1L

#' Signal that output is incomplete relative to what was requested.
#' Behaviour follows `options(pladdrr.data_loss = "warn" | "error" | "silent")`;
#' the condition is classed `pladdrr_data_loss`.
#' @noRd
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

# G4.0: file-writing methods append the format's conventional suffix when the
# caller gave a path without one ("out/pitch" -> "out/pitch.Pitch"). A path that
# already has an extension is used as given, so an explicit choice such as
# "pitch.txt" is respected. Tilde paths are expanded.
#' Append a file suffix when a path has no extension (G4.0).
#' A path whose basename already has an extension is used as given.
#' @noRd
.ensure_suffix <- function(path, suffix) {
  if (!is.character(path) || length(path) != 1L || is.na(path) || !nzchar(path)) {
    .stop_input("ensure_suffix", "path",
                "ensure_suffix(): path must be a single non-empty string")
  }
  path <- path.expand(path)
  if (nzchar(tools::file_ext(path))) path else paste0(path, ".", suffix)
}

# Require a single non-NA string (G2.0-G2.2). `null_ok` admits NULL, e.g. an
# optional file pattern. The message names the routine so each is unique.
.check_string <- function(value, name, routine, null_ok = FALSE) {
  if (null_ok && is.null(value)) return(invisible(TRUE))
  if (!is.character(value) || length(value) != 1L || is.na(value)) {
    .stop_input(routine, name,
                paste0(routine, "(): ", name, " must be a single string, got: ",
                       .short_deparse(value)))
  }
  invisible(TRUE)
}

# Require a single TRUE/FALSE (not NA, not 0/1).
.check_flag <- function(value, name, routine) {
  if (!is.logical(value) || length(value) != 1L || is.na(value)) {
    .stop_input(routine, name,
                paste0(routine, "(): ", name, " must be TRUE or FALSE, got: ",
                       .short_deparse(value)))
  }
  invisible(TRUE)
}

# TS2.4a: every short-time analysis assumes the signal is long enough for at
# least one analysis window. Praat's own failure ("Failed to create ...") does
# not say why, so report the duration the window needs. The `periods` factors
# were measured against the Praat sources: AC pitch 3 / floor, CC pitch 2 /
# floor, cross-correlation harmonicity (periods_per_window + 1) / floor,
# intensity 6.4 / minimum_pitch.
.check_window_fits <- function(sound, periods, floor, floor_name, routine) {
  if (!.is_numeric_scalar(floor) || floor <= 0) return(invisible(TRUE))
  need <- periods / floor
  dur <- tryCatch(sound$get_total_duration(), error = function(e) NA_real_)
  if (is.finite(dur) && is.finite(need) && dur < need * (1 - 1e-9)) {
    .stop_input(routine, floor_name,
                paste0(routine, "(): the sound lasts ", format(dur, digits = 3),
                       " s but an analysis with ", floor_name, " = ", floor,
                       " Hz needs at least ", format(need, digits = 3), " s (",
                       periods, " periods of the floor); use a longer signal ",
                       "or a higher ", floor_name))
  }
  invisible(TRUE)
}

# Praat has no missing-value representation for sample data: a NaN or Inf sample
# silently propagates through every analysis (and Inf can overflow filters).
# Reject non-finite input at the boundary and say how many samples are bad.
#' Require sample values to be numeric and finite: NA, NaN and Inf are a
#' `pladdrr_input_error` that reports how many samples are bad (Praat has no missing-sample type).
#' @noRd
.check_finite_samples <- function(values, routine) {
  if (!is.numeric(values)) {
    .stop_input(routine, "values",
                paste0(routine, "(): values must be numeric, got ",
                       class(values)[1L]))
  }
  bad <- sum(!is.finite(values))
  if (bad > 0L) {
    .stop_input(routine, "values",
                paste0(routine, "(): values must be finite; found ", bad,
                       " NA, NaN or Inf sample(s) out of ", length(values)))
  }
  invisible(TRUE)
}

# Praat refuses pitch_floor >= pitch_ceiling in its forms; without this check
# the C++ analysis either fails opaquely or silently computes on an inverted
# range.
#' Require `0 < pitch_floor < pitch_ceiling`, both single numbers in Hz.
#' @noRd
.check_pitch_range <- function(pitch_floor, pitch_ceiling) {
  if (!.is_numeric_scalar(pitch_floor) || pitch_floor <= 0) {
    .stop_input("check_pitch_range", "pitch_floor",
                paste0(
                  "pitch_floor must be a single positive number (Hz), got: ",
                       .short_deparse(pitch_floor)))
  }
  if (!.is_numeric_scalar(pitch_ceiling) || pitch_ceiling <= pitch_floor) {
    .stop_input("check_pitch_range", "pitch_ceiling",
                paste0("pitch_ceiling (", .short_deparse(pitch_ceiling),
                       ") must be a single number greater than pitch_floor (",
                       pitch_floor, ")"))
  }
  invisible(TRUE)
}

# Formant/pole counts must be positive; a zero or negative count makes the
# split-Levinson/Burg solver produce garbage frames (and, for Willems, spew
# "no zero" diagnostics) instead of failing cleanly.
#' Require `value` to be a single finite number in [1, `max`].
#' @noRd
.check_positive_count <- function(value, name, max = Inf) {
  if (!is.numeric(value) || length(value) != 1L || !is.finite(value) ||
    value < 1 || value > max) {
    .stop_input("check_positive_count", name,
                paste0(name, " must be a single finite number >= 1",
                  if (is.finite(max)) paste0(" and <= ", max), ", got: ",
                  .short_deparse(value)))
  }
  invisible(TRUE)
}

#' Require `value` to be a single number > 0.
#' @noRd
.check_positive_number <- function(value, name) {
  if (!is.numeric(value) || length(value) != 1L || is.na(value) || value <= 0) {
    .stop_input("check_positive_number", name,
                paste0(name, " must be a single positive number, got: ",
                       .short_deparse(value)))
  }
  invisible(TRUE)
}

# Sizes that become allocations. A negative duration gave a Sound with nx =
# -16000, a negative row count a corrupt Matrix, and an enormous one a request
# the OS answers by killing the session (macOS, exit 137; see
# src/pladdrr_limits.h). Positive, finite, and no more cells than the C++ bound
# allows (2^29, 4 GiB of doubles).
.max_cells <- 2^29

#' Require `x` to be a single positive, finite number (named `name` in errors).
#' @noRd
.check_positive_finite <- function(value, name, routine = name) {
  if (!is.numeric(value) || length(value) != 1L || !is.finite(value) ||
    value <= 0) {
    .stop_input(routine, name,
      paste0(name, " must be a single positive, finite number, got: ",
        .short_deparse(value)))
  }
  invisible(TRUE)
}

#' Refuse an allocation of more than `.max_cells` cells with a `pladdrr_input_error`.
#' @noRd
.check_cell_count <- function(cells, routine, ...) {
  if (cells > .max_cells) {
    .stop_input(routine, names(list(...))[1L],
      paste0("would allocate ", format(cells, big.mark = ",", scientific = FALSE),
        " cells; the limit is ", format(.max_cells, big.mark = ",",
          scientific = FALSE)))
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

#' Warn once per session when `fit_method = "robust slow"`, whose Theil-Sen fit
#' is not reproducible in Praat itself.
#' @noRd
.check_trend_fit_method <- function(fit_method) {
  if (identical(fit_method, "robust slow") &&
      is.null(.warned_robust_slow$done)) {
    .warned_robust_slow$done <- TRUE
    warning(
      "fit_method = \"robust slow\" (Praat's Theil-Sen trend fit) is not ",
      "reproducible: it draws random samples internally, so repeated ",
      "runs on the ",
      "same input differ (~0.8 dB observed) and can return wildly ",
      "wrong values. ",
      "This is an upstream Praat defect, reproduced faithfully here. Use ",
      "fit_method = \"robust\" (Siegel) or \"least_squares\" for a ",
      "deterministic result.",
      call. = FALSE
    )
  }
  invisible(TRUE)
}

# Praat autowindows a reversed or zero quefrency range, but a caller who passes
# qstart > qend almost always means the opposite of what they get. Fail loudly
# rather than return a silently different measurement.
#' Require `qstart` and `qend` to be single non-negative numbers (s) with
#' `qend > qstart`; `qend = 0` is allowed and means the full quefrency range.
#' @noRd
.check_quefrency_range <- function(qstart, qend, qstart_name = "qstart_fit",
                                   qend_name = "qend_fit") {
  if (!.is_numeric_scalar(qstart) || qstart < 0) {
    .stop_input("check_quefrency_range", qstart_name,
                paste0(qstart_name,
                  " must be a single non-negative number (s), got: ",
                       .short_deparse(qstart)))
  }
  if (!.is_numeric_scalar(qend) || qend < 0) {
    .stop_input("check_quefrency_range", qend_name,
                paste0(qend_name,
                  " must be a single non-negative number (s), got: ",
                       .short_deparse(qend)))
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
#' Require `time_step` to be a single non-negative number (0 means automatic).
#' @noRd
.check_time_step <- function(time_step) {
  if (!is.numeric(time_step) || length(time_step) != 1L || is.na(time_step) ||
      time_step < 0) {
    .stop_input("check_time_step", "time_step",
                paste0("time_step must be a single non-negative number ",
                       "(0 = auto), got: ", .short_deparse(time_step)))
  }
  invisible(TRUE)
}

# Praat's "Extract part" zero-pads any portion of the requested window that lies
# outside the signal and returns it silently, so `sound$extract_part(5, 10)` on
#  a
# 1 s Sound yields 5 s of fabricated silence. pladdrr reproduces the value (goal
#  1)
# but reports the fabrication (goal 6).
#' Warn (class `pladdrr_data_loss`) when a requested extraction range extends
#' outside the Sound, since Praat zero-pads the excess.
#' @noRd
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
                     "Praat zero-pads the excess, so part of the returned ",
                     "Sound is ",
                     "silence, not data"),
              lo, hi, xmin, xmax))
  }
  invisible(TRUE)
}

#' @srrstats {G2.3} Character parameters that select an option are matched with `match.arg()` or an explicit `switch()` (see `R/validators.R`, `.pitch_unit_code`, `.window_shape_code`, `.ltas_unit_code`).
#' @srrstats {G2.3a} `match.arg()` is used 87 times in `R/`; option lookups that map to Praat integer codes use `switch()` with an explicit error or documented default.
#' @srrstats {G2.3b} Unit, window-shape, averaging-method and format names are lower-cased before lookup (`.pitch_unit_code`, `.window_shape_code`, `.ltas_unit_code`, `.intensity_avg_code`, `Sound$save(format=)`); parameters that list their choices as a vector use `match.arg()` and are case-sensitive. `vignettes/terminology.Rmd`, section 'Option strings', states both.
#' @srrstats {G4.0} All 27 `save()`/`write` methods route the path through `.ensure_suffix()` (`R/validators.R`): the format's suffix is appended when none is given. Tested in `tests/testthat/test-output-suffix.R`, including a static check that no `.cpp$save` call bypasses the helper.
#' @srrstats {G2.13} Input samples are checked in `Sound$from_values()` (`.check_finite_samples()` in `R/validators.R`): NA, NaN and Inf are a `pladdrr_input_error`. Tested in `tests/testthat/test-edge-conditions.R`.
#' @srrstats {G2.14} The package's policy is documented in `vignettes/terminology.Rmd` ('Missing and undefined values'): input NA is an error, undefined output is NaN, imputation is left to the caller.
#' @srrstats {G2.14a} Error on missing input: `.check_finite_samples()`; `tests/testthat/test-edge-conditions.R`.
#' @srrstats {G2.16} Inf and -Inf input are rejected (`.check_finite_samples()`); undefined output values are NaN, documented in `vignettes/terminology.Rmd`; aggregates skip undefined frames.
#' @srrstats {TS2.1} See G2.14: input missing values are an error.
#' @srrstats {TS2.1a} Error on missing data (`.check_finite_samples()`).
#'
#' @noRd
NULL
