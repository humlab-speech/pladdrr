# test-pointprocess-r6.R - Tests for R/pointprocess-wrapper.R (PointProcess object)
#
# There is no dedicated test file for the PointProcess R6 class elsewhere in
# this repo -- it's only exercised incidentally in test-batch-queries.R,
# test-autoplot-methods-gaps.R and test-plotting-methods-gaps.R (as a
# PointProcess(0, 1) fixture for other purposes), plus test-voice-report.R
# (voice_report()) and test-extract-intervals-where.R/test-textgrid-batch.R
# (to_textgrid_vuv()). This file covers the rest of the PointProcess API:
# construction, property/query getters, period statistics, modification,
# set operations, conversions, jitter accessors (without a cached Sound),
# I/O, and error paths.

# --- Construction ---

test_that("PointProcess() creates an empty object spanning [tmin, tmax]", {
  pp <- PointProcess(0, 1)

  expect_s3_class(pp, "PointProcess")
  expect_s3_class(pp, "PraatObject")
  expect_true(pp$is_valid())
  expect_equal(pp$get_xmin(), 0)
  expect_equal(pp$get_xmax(), 1)
  expect_equal(pp$get_duration(), 1)
  expect_equal(pp$get_number_of_points(), 0)
})

test_that("PointProcess() with no arguments and no .xptr errors clearly", {
  expect_error(PointProcess(), "must be created from a Sound or Pitch")
  expect_error(PointProcess(tmin = 0), "must be created from a Sound or Pitch")
  expect_error(PointProcess(tmax = 1), "must be created from a Sound or Pitch")
})

test_that("Pitch$to_point_process() and Sound$to_point_process_periodic_cc() both build a valid PointProcess", {
  s <- generate_sine_wave(150, 0.3, sampling_rate = 16000)
  pitch <- s$to_pitch_cc(pitch_floor = 75, pitch_ceiling = 600)

  pp_from_pitch <- suppressWarnings(pitch$to_point_process())
  expect_s3_class(pp_from_pitch, "PointProcess")
  expect_true(pp_from_pitch$get_number_of_points() > 0)

  pp_from_sound <- s$to_point_process_periodic_cc(pitch_floor = 75, pitch_ceiling = 600)
  expect_s3_class(pp_from_sound, "PointProcess")
  expect_true(pp_from_sound$get_number_of_points() > 0)
})

# --- Basic query getters ---

test_that("basic query getters work on a manually-populated empty PointProcess", {
  pp <- PointProcess(0, 1)
  pp$add_point(0.1)
  pp$add_point(0.2)
  pp$add_point(0.3)

  expect_equal(pp$get_number_of_points(), 3)
  expect_equal(pp$get_time(1), 0.1, tolerance = 1e-10)
  expect_equal(pp$get_time_from_index(2), 0.2, tolerance = 1e-10)
  expect_equal(pp$get_low_index(0.15), 1L)
  expect_equal(pp$get_high_index(0.15), 2L)
  expect_equal(pp$get_nearest_index(0.19), 2L)
  expect_equal(pp$get_interval(0.15), 0.1, tolerance = 1e-10)
})

test_that("get_time() errors on an out-of-range point number", {
  pp <- PointProcess(0, 1)
  pp$add_point(0.1)

  expect_error(pp$get_time(99))
  expect_error(pp$get_time(0))
})

# --- Period statistics ---

test_that("period statistics work with both qualifying and non-qualifying period ranges", {
  s <- generate_sine_wave(150, 0.3, sampling_rate = 16000)
  pitch <- s$to_pitch_cc(pitch_floor = 75, pitch_ceiling = 600)
  pp <- suppressWarnings(pitch$to_point_process())

  # Defaults (period_floor = 0.0001, period_ceiling = 0.02) should qualify
  # most ~6.7ms periods of a 150 Hz tone.
  n_periods <- pp$get_number_of_periods(0, 0)
  expect_gt(n_periods, 0)
  expect_true(is.finite(pp$get_mean_period(0, 0)))
  expect_true(is.finite(pp$get_stdev_period(0, 0)))
  expect_equal(pp$get_voice_breaks(0, 0), 0)

  # A period_ceiling far below any real period disqualifies everything;
  # this exercises the "0 qualifying periods" (NaN) branch too.
  pp2 <- PointProcess(0, 1)
  pp2$add_point(0.1); pp2$add_point(0.2); pp2$add_point(0.3)
  expect_equal(pp2$get_number_of_periods(0, 0, period_floor = 0.0001, period_ceiling = 0.02), 0)
  expect_true(is.nan(pp2$get_mean_period(0, 0, period_floor = 0.0001, period_ceiling = 0.02)))
})

# --- Periods as vectors ---

test_that("get_periods_vector() and get_periods_filtered() work, including the n<2 empty branch", {
  # n < 2 points: both should return an empty (length-0) numeric vector.
  pp_empty <- PointProcess(0, 1)
  expect_equal(pp_empty$get_periods_vector(), numeric(0))
  expect_equal(pp_empty$get_periods_filtered(), numeric(0))

  pp_one <- PointProcess(0, 1)
  pp_one$add_point(0.1)
  expect_equal(pp_one$get_periods_vector(), numeric(0))

  pp <- PointProcess(0, 1)
  pp$add_point(0.1); pp$add_point(0.2); pp$add_point(0.3); pp$add_point(0.45)
  periods <- pp$get_periods_vector()
  expect_equal(periods, c(0.1, 0.1, 0.15), tolerance = 1e-10)

  filtered <- pp$get_periods_filtered(min_period = 0.05, max_period = 0.12)
  expect_equal(filtered, c(0.1, 0.1), tolerance = 1e-10)

  # A range matching nothing should return an empty vector too.
  none <- pp$get_periods_filtered(min_period = 0.9, max_period = 1.0)
  expect_equal(none, numeric(0))
})

# --- Modification methods ---

test_that("add_point/remove_point/remove_point_near/remove_points_between/fill/voice all mutate and return invisible self", {
  pp <- PointProcess(0, 1)

  ret <- pp$add_point(0.1)
  expect_s3_class(ret, "PointProcess")
  pp$add_point(0.2)
  pp$add_point(0.3)
  expect_equal(pp$get_number_of_points(), 3)

  pp$remove_point(2)
  expect_equal(pp$get_number_of_points(), 2)
  expect_equal(sort(pp$as_vector()), c(0.1, 0.3), tolerance = 1e-10)

  pp$add_point(0.31)
  pp$remove_point_near(0.305)
  expect_equal(pp$get_number_of_points(), 2)

  pp$fill(0.5, 0.6, 0.02)
  n_after_fill <- pp$get_number_of_points()
  expect_gt(n_after_fill, 2)

  pp$remove_points_between(0.5, 0.6)
  expect_equal(pp$get_number_of_points(), 2)

  pp$voice(0.01, 1.3)
  expect_true(pp$get_number_of_points() >= 2)
})

# --- Set operations ---

test_that("union_with/intersection_with/difference_with combine two PointProcess objects", {
  # These return a *new* PointProcess wrapping the result (see the NOTE
  # above .pp_methods$union_with in R/pointprocess-wrapper.R) - callers
  # must reassign, e.g. `pp1 <- pp1$union_with(pp2)`.
  pp1 <- PointProcess(0, 1); pp1$add_point(0.1); pp1$add_point(0.2)
  pp2 <- PointProcess(0, 1); pp2$add_point(0.15); pp2$add_point(0.25)
  merged <- pp1$union_with(pp2)
  expect_s3_class(merged, "PointProcess")
  expect_equal(merged$get_number_of_points(), 4)
  # The receiver is NOT mutated in place (the C++ side only returns the new
  # xptr; mutating the receiver's ptr in place would free the original
  # PointProcess while the caller's .xptr still referenced it).
  expect_equal(pp1$get_number_of_points(), 2)

  ipp1 <- PointProcess(0, 1); ipp1$add_point(0.1); ipp1$add_point(0.2)
  ipp2 <- PointProcess(0, 1); ipp2$add_point(0.2); ipp2$add_point(0.3)
  intersected <- ipp1$intersection_with(ipp2)
  expect_equal(intersected$get_number_of_points(), 1)
  expect_equal(intersected$as_vector(), 0.2, tolerance = 1e-10)

  dpp1 <- PointProcess(0, 1); dpp1$add_point(0.1); dpp1$add_point(0.2)
  dpp2 <- PointProcess(0, 1); dpp2$add_point(0.2)
  diffed <- dpp1$difference_with(dpp2)
  expect_equal(diffed$get_number_of_points(), 1)
  expect_equal(diffed$as_vector(), 0.1, tolerance = 1e-10)
})

test_that("union_with/intersection_with/difference_with reject non-PointProcess arguments", {
  pp <- PointProcess(0, 1)
  expect_error(pp$union_with("not a pointprocess"), "Argument must be PointProcess")
  expect_error(pp$intersection_with(42), "Argument must be PointProcess")
  expect_error(pp$difference_with(list()), "Argument must be PointProcess")
})

# --- Conversions ---

test_that("upto_pitch_tier() and upto_intensity_tier() convert to the expected tier classes", {
  pp <- PointProcess(0, 1)
  pp$add_point(0.1); pp$add_point(0.2); pp$add_point(0.3)

  pt <- pp$upto_pitch_tier(600)
  expect_s3_class(pt, "PitchTier")

  it <- pp$upto_intensity_tier(100)
  expect_s3_class(it, "IntensityTier")
})

test_that("to_sound_pulse_train() and to_sound_hum() synthesize Sound objects", {
  s <- generate_sine_wave(150, 0.3, sampling_rate = 16000)
  pitch <- s$to_pitch_cc(pitch_floor = 75, pitch_ceiling = 600)
  pp <- suppressWarnings(pitch$to_point_process())

  pulse_train <- pp$to_sound_pulse_train()
  expect_s3_class(pulse_train, "Sound")
  expect_true(pulse_train$get_total_duration() > 0)

  hum <- pp$to_sound_hum()
  expect_s3_class(hum, "Sound")
  expect_true(hum$get_total_duration() > 0)
})

# --- Batch operations ---

test_that("get_values_from_sound() returns one value per point, and rejects non-Sound input", {
  s <- generate_sine_wave(150, 0.3, sampling_rate = 16000)
  pitch <- s$to_pitch_cc(pitch_floor = 75, pitch_ceiling = 600)
  pp <- suppressWarnings(pitch$to_point_process())

  vals <- pp$get_values_from_sound(s, channel = 1, interpolation = "cubic")
  expect_type(vals, "double")
  expect_length(vals, pp$get_number_of_points())

  expect_error(pp$get_values_from_sound("not a sound"), "sound must be a Sound object")
})

test_that("get_jitter_batch() returns all five jitter measures in one call", {
  s <- generate_sine_wave(150, 0.3, sampling_rate = 16000)
  pitch <- s$to_pitch_cc(pitch_floor = 75, pitch_ceiling = 600)
  pp <- suppressWarnings(pitch$to_point_process())

  res <- pp$get_jitter_batch(0, 0, 0.0001, 0.02, 1.3)
  expect_type(res, "list")
  expect_named(res, c("local", "local_absolute", "rap", "ppq5", "ddp"), ignore.order = TRUE)
  for (nm in names(res)) {
    expect_type(res[[nm]], "double")
  }
})

# --- Voice quality (jitter) without a cached Sound (bare .pointprocess_get_jitter_* path) ---

test_that("jitter accessors work directly (no prior shimmer call caching a Sound)", {
  s <- generate_sine_wave(150, 0.3, sampling_rate = 16000)
  pitch <- s$to_pitch_cc(pitch_floor = 75, pitch_ceiling = 600)
  pp <- suppressWarnings(pitch$to_point_process())

  expect_type(pp$get_jitter_local(), "double")
  expect_type(pp$get_jitter_local_absolute(), "double")
  expect_type(pp$get_jitter_rap(), "double")
  expect_type(pp$get_jitter_ppq5(), "double")
  expect_type(pp$get_jitter_ddp(), "double")

  expect_true(pp$get_jitter_local() >= 0)
  expect_true(pp$get_jitter_local_absolute() >= 0)
})

# --- Export / I/O ---

test_that("as_vector()/as_data_frame() export point times", {
  pp <- PointProcess(0, 1)
  pp$add_point(0.1); pp$add_point(0.2); pp$add_point(0.3)

  v <- pp$as_vector()
  expect_equal(v, c(0.1, 0.2, 0.3), tolerance = 1e-10)

  df <- pp$as_data_frame()
  expect_true(is.data.frame(df) || inherits(df, "data.table"))
  expect_equal(nrow(df), 3)
  expect_true("time" %in% names(df))
})

test_that("save() writes a PointProcess to a Praat text file", {
  pp <- PointProcess(0, 1)
  pp$add_point(0.1); pp$add_point(0.2)

  f <- tempfile(fileext = ".PointProcess")
  on.exit(unlink(f), add = TRUE)
  ret <- pp$save(f)
  expect_true(file.exists(f))
  content <- readLines(f)
  expect_true(any(grepl("PointProcess", content, fixed = TRUE)))
})

test_that("get_xptr() returns the underlying external pointer", {
  pp <- PointProcess(0, 1)
  expect_type(pp$get_xptr(), "externalptr")
})

# --- Print ---

test_that("print.PointProcess() and $print() report time domain and point count", {
  pp <- PointProcess(0, 1)
  pp$add_point(0.1); pp$add_point(0.2)

  expect_output(print(pp), "PointProcess")
  expect_output(print(pp), "Points: 2")
  ret <- pp$print()
  expect_s3_class(ret, "PointProcess")
})

# --- voice_report edge case (no jitter/shimmer-qualifying periods, still succeeds) ---

# voice_report on an empty PointProcess aborts silently under MSVC on
# Windows; the body runs in an isolated child R process there (see
# helper-windows-crash-probe.R) so the abort is a visible failure, not a skip.
probe_test("voice_report() on a nearly-empty PointProcess still returns a list (no crash)", {
  s <- generate_sine_wave(150, 0.3, sampling_rate = 16000)
  pitch <- s$to_pitch_cc(pitch_floor = 75, pitch_ceiling = 600)
  pp_empty <- PointProcess(0, s$get_total_duration())

  report <- pp_empty$voice_report(s, pitch)
  expect_type(report, "list")
})
