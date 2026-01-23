# test-phase3-textgrid-simd.R
# Phase 3 Task 3.3: TextGrid Batch Operations SIMD Tests
# Part of pladdrr SIMD implementation (v4.5.3)

# Load pladdrr - R6 classes available in attached namespace
library(pladdrr)

# Helper to access internal functions
.set_simd <- function(x) pladdrr:::set_textgrid_simd_enabled_bridge(x)
.simd_enabled <- function() pladdrr:::textgrid_simd_enabled()
.calc_dur <- function(s, e) pladdrr:::calculate_durations_simd_bridge(s, e)
.calc_mid <- function(s, e) pladdrr:::calculate_midpoints_simd_bridge(s, e)
.dur_stats <- function(d) pladdrr:::duration_statistics_simd_bridge(d)
.filter_dur <- function(d, min, max) pladdrr:::filter_by_duration_simd_bridge(d, min, max)
.tg_stats <- function(tg, tier) pladdrr:::textgrid_interval_statistics_batch(tg, tier)
.tg_pitch <- function(tg, p, tier, unit) pladdrr:::textgrid_interval_pitch_batch(tg, p, tier, unit)
.tg_formant <- function(tg, f, tier, fn) pladdrr:::textgrid_interval_formant_batch(tg, f, tier, fn)
.tg_intensity <- function(tg, i, tier) pladdrr:::textgrid_interval_intensity_batch(tg, i, tier)
.tg_all <- function(tg, p, f, i, tier) pladdrr:::textgrid_interval_all_features_batch(tg, p, f, i, tier)

test_that("SIMD duration calculation matches scalar", {
  skip_if_not_installed("pladdrr")

  n <- 1000
  starts <- sort(runif(n, 0, 100))
  ends <- starts + runif(n, 0.1, 0.5)

  # Force scalar
  .set_simd(FALSE)
  dur_scalar <- .calc_dur(starts, ends)

  # Force SIMD
  .set_simd(TRUE)
  dur_simd <- .calc_dur(starts, ends)

  expect_equal(dur_scalar, dur_simd, tolerance = 1e-14)
})

test_that("SIMD midpoint calculation matches scalar", {
  skip_if_not_installed("pladdrr")

  n <- 500
  starts <- runif(n, 0, 10)
  ends <- starts + runif(n, 0.1, 1.0)

  .set_simd(FALSE)
  mid_scalar <- .calc_mid(starts, ends)

  .set_simd(TRUE)
  mid_simd <- .calc_mid(starts, ends)

  expect_equal(mid_scalar, mid_simd, tolerance = 1e-14)
})

test_that("duration statistics SIMD matches manual calculation", {
  skip_if_not_installed("pladdrr")

  durations <- c(0.1, 0.2, 0.15, 0.3, 0.25)

  stats <- .dur_stats(durations)

  expect_equal(stats$mean, mean(durations), tolerance = 1e-10)
  expect_equal(stats$stdev, sd(durations), tolerance = 1e-10)
  expect_equal(stats$min, min(durations), tolerance = 1e-10)
  expect_equal(stats$max, max(durations), tolerance = 1e-10)
})

test_that("duration filtering returns correct indices", {
  skip_if_not_installed("pladdrr")

  durations <- c(0.05, 0.1, 0.15, 0.2, 0.3, 0.08)
  min_dur <- 0.1
  max_dur <- 0.25

  indices <- .filter_dur(durations, min_dur, max_dur)

  # Expected: indices 2, 3, 4 (0.1, 0.15, 0.2) - 1-based
  expect_equal(indices, c(2, 3, 4))
})

test_that("SIMD toggle functions work", {
  skip_if_not_installed("pladdrr")

  # Enable SIMD
  .set_simd(TRUE)
  expect_true(.simd_enabled())

  # Disable SIMD
  .set_simd(FALSE)
  expect_false(.simd_enabled())

  # Re-enable for other tests
  .set_simd(TRUE)
})

test_that("textgrid_interval_statistics_batch uses SIMD for duration", {
  skip_if_not_installed("pladdrr")

  # Create a simple TextGrid with intervals using exported function
  tg <- textgrid_create(
    tmin = 0, tmax = 2.0,
    tier_names = "segment",
    point_tiers = FALSE
  )

  # Insert boundaries to create intervals: [0,0.3], [0.3,0.5], [0.5,0.8], [0.8,2.0]
  tg$insert_boundary(1, 0.3)
  tg$insert_boundary(1, 0.5)
  tg$insert_boundary(1, 0.8)
  tg$set_interval_text(1, 1, "a")
  tg$set_interval_text(1, 2, "b")
  tg$set_interval_text(1, 3, "c")
  tg$set_interval_text(1, 4, "d")

  # Get statistics
  stats <- .tg_stats(tg$.xptr, 1)

  # Check durations
  expect_equal(stats$duration[1], 0.3, tolerance = 1e-10)
  expect_equal(stats$duration[2], 0.2, tolerance = 1e-10)
  expect_equal(stats$duration[3], 0.3, tolerance = 1e-10)
  expect_equal(stats$duration[4], 1.2, tolerance = 1e-10)  # last interval extends to tmax=2.0
})

test_that("textgrid_interval_pitch_batch returns valid statistics", {
  skip_if_not_installed("pladdrr")

  # Create tone with known pitch using exported function
  sound <- sound_create_tone(frequency = 440, duration = 1.0, sampling_rate = 16000)
  pitch <- sound$to_pitch()

  tg <- textgrid_create(tmin = 0, tmax = 1.0, tier_names = "seg", point_tiers = FALSE)
  tg$insert_boundary(1, 0.3)
  tg$insert_boundary(1, 0.6)
  tg$set_interval_text(1, 1, "seg1")
  tg$set_interval_text(1, 2, "seg2")
  tg$set_interval_text(1, 3, "seg3")

  stats <- .tg_pitch(tg$.xptr, pitch$.xptr, 1, "HERTZ")

  # Check structure
  expect_true("pitch_mean" %in% names(stats))
  expect_true("pitch_stdev" %in% names(stats))
  expect_true("duration" %in% names(stats))

  # Pitch should be close to 440 Hz for pure tone
  valid_means <- !is.na(stats$pitch_mean)
  if (any(valid_means)) {
    expect_true(all(stats$pitch_mean[valid_means] > 430))
    expect_true(all(stats$pitch_mean[valid_means] < 450))
  }
})

test_that("textgrid_interval_formant_batch returns valid statistics", {
  skip_if_not_installed("pladdrr")

  # Create speech-like sound with formants
  sound <- sound_create_tone(frequency = 150, duration = 0.5, sampling_rate = 16000)
  formant <- sound$to_formant_burg()

  tg <- textgrid_create(tmin = 0, tmax = 0.5, tier_names = "word", point_tiers = FALSE)
  tg$insert_boundary(1, 0.2)
  tg$set_interval_text(1, 1, "w1")
  tg$set_interval_text(1, 2, "w2")

  stats <- .tg_formant(tg$.xptr, formant$.xptr, 1, 1)

  expect_true("formant_mean" %in% names(stats))
  expect_true("formant_stdev" %in% names(stats))
  expect_true("bandwidth_mean" %in% names(stats))
})

test_that("textgrid_interval_intensity_batch returns valid statistics", {
  skip_if_not_installed("pladdrr")

  sound <- sound_create_tone(frequency = 440, duration = 0.5, sampling_rate = 16000)
  intensity <- sound$to_intensity()

  tg <- textgrid_create(tmin = 0, tmax = 0.5, tier_names = "seg", point_tiers = FALSE)
  tg$insert_boundary(1, 0.25)
  tg$set_interval_text(1, 1, "s1")
  tg$set_interval_text(1, 2, "s2")

  stats <- .tg_intensity(tg$.xptr, intensity$.xptr, 1)

  expect_true("intensity_mean" %in% names(stats))
  expect_true("intensity_min" %in% names(stats))
  expect_true("intensity_max" %in% names(stats))

  # Intensity values should be reasonable (dB range)
  valid <- !is.na(stats$intensity_mean)
  if (any(valid)) {
    expect_true(all(stats$intensity_mean[valid] > 0))  # Positive dB
    expect_true(all(stats$intensity_mean[valid] < 120))  # Reasonable max
  }
})

test_that("textgrid_interval_all_features_batch returns combined statistics", {
  skip_if_not_installed("pladdrr")

  sound <- sound_create_tone(frequency = 220, duration = 0.5, sampling_rate = 16000)
  pitch <- sound$to_pitch()
  formant <- sound$to_formant_burg()
  intensity <- sound$to_intensity()

  tg <- textgrid_create(tmin = 0, tmax = 0.5, tier_names = "phone", point_tiers = FALSE)
  tg$insert_boundary(1, 0.25)
  tg$set_interval_text(1, 1, "p1")
  tg$set_interval_text(1, 2, "p2")

  stats <- .tg_all(tg$.xptr, pitch$.xptr, formant$.xptr, intensity$.xptr, 1)

  # Check all expected columns
  expect_true("duration" %in% names(stats))
  expect_true("pitch_mean" %in% names(stats))
  expect_true("f1_mean" %in% names(stats))
  expect_true("f2_mean" %in% names(stats))
  expect_true("intensity_mean" %in% names(stats))
})

test_that("SIMD vs scalar produce identical results for large arrays", {
  skip_if_not_installed("pladdrr")

  # Large array to test SIMD remainder handling
  n <- 10007  # Prime number to test non-aligned sizes
  starts <- sort(runif(n, 0, 1000))
  ends <- starts + runif(n, 0.01, 0.5)

  .set_simd(FALSE)
  dur_scalar <- .calc_dur(starts, ends)
  mid_scalar <- .calc_mid(starts, ends)

  .set_simd(TRUE)
  dur_simd <- .calc_dur(starts, ends)
  mid_simd <- .calc_mid(starts, ends)

  # Exact match within floating-point precision
  expect_equal(dur_scalar, dur_simd, tolerance = 1e-15)
  expect_equal(mid_scalar, mid_simd, tolerance = 1e-15)

  # Re-enable SIMD
  .set_simd(TRUE)
})
