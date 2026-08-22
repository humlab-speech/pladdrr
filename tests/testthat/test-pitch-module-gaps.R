# test-pitch-module-gaps.R
# Coverage gap-fill for src/modules/pitch_module.cpp (task 18), targeting
# real Pitch$ methods that were entirely untested at the C++ level:
# get_statistics(), get_intensity_at_time()/get_mean_intensity(),
# get_strengths_vector(), get_intensities_vector(), kill_octave_jumps(),
# as_data_frame(include_strength=, include_intensity=) combos, save(),
# and to_textgrid_silences().

pitch_fixture <- function() {
  sound <- Sound$create_tone(frequency = 200, duration = 1.0)
  sound$to_pitch(pitch_floor = 75, pitch_ceiling = 600)
}

# ============================================================================
# get_statistics()
# ============================================================================

test_that("Pitch get_statistics returns all default metrics", {
  pitch <- pitch_fixture()
  stats <- pitch$get_statistics()

  expect_type(stats, "list")
  expect_true(all(c("mean", "stdev", "min", "max", "median", "q1", "q3") %in% names(stats)))
  expect_equal(stats$mean, 200, tolerance = 1)
  expect_true(stats$min <= stats$mean)
  expect_true(stats$max >= stats$mean)
})

test_that("Pitch get_statistics accepts every metric alias, including count_voiced", {
  pitch <- pitch_fixture()
  stats <- pitch$get_statistics(
    metrics = c(
      "minimum", "maximum", "standard_deviation", "sd",
      "quantile25", "q25", "quantile75", "q75",
      "count_voiced", "voiced_frames"
    )
  )

  expect_equal(stats$minimum, stats$maximum, tolerance = 1)  # pure tone: near-constant F0
  expect_equal(stats$standard_deviation, stats$sd)
  expect_equal(stats$quantile25, stats$q25)
  expect_equal(stats$quantile75, stats$q75)
  expect_equal(stats$count_voiced, stats$voiced_frames)
  expect_equal(stats$count_voiced, pitch$count_voiced_frames())
})

test_that("Pitch get_statistics warns (not errors) on an unknown metric name", {
  pitch <- pitch_fixture()
  expect_warning(
    result <- pitch$get_statistics(metrics = "bogus_metric"),
    "Unknown metric"
  )
  expect_equal(length(result), 0)
})

# ============================================================================
# get_time_of_minimum() / get_time_of_maximum()
# (unlike Formant/Harmonicity's like-named methods - different C++ classes
# entirely - Pitch's own get_time_of_minimum/get_time_of_maximum were never
# exercised anywhere in the suite)
# ============================================================================

test_that("Pitch get_time_of_minimum and get_time_of_maximum return times within the domain", {
  pitch <- pitch_fixture()
  t_min <- pitch$get_time_of_minimum()
  t_max <- pitch$get_time_of_maximum()

  expect_type(t_min, "double")
  expect_type(t_max, "double")
  expect_gte(t_min, pitch$get_start_time())
  expect_lte(t_min, pitch$get_end_time())
  expect_gte(t_max, pitch$get_start_time())
  expect_lte(t_max, pitch$get_end_time())
})

# ============================================================================
# get_intensity_at_time() / get_mean_intensity()
# (frame intensity carried on the Pitch object itself, distinct from the
# deprecated free functions of the same name that operate on an Intensity
# object - see test-deprecated-s3-delegates.R)
# ============================================================================

test_that("Pitch get_intensity_at_time returns the per-frame intensity", {
  pitch <- pitch_fixture()
  val <- pitch$get_intensity_at_time(pitch$get_total_duration() / 2)
  expect_type(val, "double")
  expect_false(is.na(val))
  expect_gt(val, 0)
})

test_that("Pitch get_mean_intensity averages frame intensity over an explicit range", {
  pitch <- pitch_fixture()
  mean_int <- pitch$get_mean_intensity(0, pitch$get_total_duration())
  expect_type(mean_int, "double")
  expect_false(is.na(mean_int))
  expect_gt(mean_int, 0)
})

test_that("Pitch get_mean_intensity(0, 0) is NA (unlike get_mean/get_minimum, it has no whole-range special case)", {
  # Confirmed by direct experimentation: get_mean_intensity() does not treat
  # (0, 0) as "whole domain" the way get_mean()/get_minimum() etc do; it
  # computes Sampled_xToHighIndex(0)/Sampled_xToLowIndex(0) literally, which
  # produces an empty [ifrom, ito] range and NA_REAL.
  pitch <- pitch_fixture()
  expect_true(is.na(pitch$get_mean_intensity(0, 0)))
})

# ============================================================================
# get_strengths_vector() / get_intensities_vector()
# ============================================================================

test_that("Pitch get_strengths_vector returns one strength per frame", {
  pitch <- pitch_fixture()
  strengths <- pitch$get_strengths_vector()
  expect_type(strengths, "double")
  expect_equal(length(strengths), pitch$get_number_of_frames())
  expect_true(all(strengths[!is.na(strengths)] >= 0))
})

test_that("Pitch get_intensities_vector returns one frame intensity per frame", {
  pitch <- pitch_fixture()
  intensities <- pitch$get_intensities_vector()
  expect_type(intensities, "double")
  expect_equal(length(intensities), pitch$get_number_of_frames())
  expect_true(all(intensities > 0))
})

# ============================================================================
# kill_octave_jumps()
# ============================================================================

test_that("Pitch kill_octave_jumps returns a new, valid Pitch object", {
  pitch <- pitch_fixture()
  cleaned <- pitch$kill_octave_jumps()

  expect_s3_class(cleaned, "Pitch")
  expect_true(cleaned$is_valid())
  expect_equal(cleaned$get_number_of_frames(), pitch$get_number_of_frames())
  # Not the same underlying object
  expect_false(identical(cleaned$.xptr, pitch$.xptr))
})

# ============================================================================
# as_data_frame(include_strength=, include_intensity=) combinations
# ============================================================================

test_that("Pitch as_data_frame with both include_strength and include_intensity returns all five columns", {
  pitch <- pitch_fixture()
  df <- pitch$as_data_frame(include_strength = TRUE, include_intensity = TRUE)

  expect_true(all(c("time", "frequency", "voiced", "strength", "intensity_db") %in% names(df)))
  expect_equal(nrow(df), pitch$get_number_of_frames())
})

test_that("Pitch as_data_frame with only include_intensity returns intensity but not strength", {
  pitch <- pitch_fixture()
  df <- pitch$as_data_frame(include_strength = FALSE, include_intensity = TRUE)

  expect_true(all(c("time", "frequency", "voiced", "intensity_db") %in% names(df)))
  expect_false("strength" %in% names(df))
})

# ============================================================================
# save()
# ============================================================================

test_that("Pitch save writes a readable Praat text file", {
  pitch <- pitch_fixture()
  tmp <- tempfile(fileext = ".Pitch")
  on.exit(unlink(tmp), add = TRUE)

  ret <- pitch$save(tmp)
  expect_true(file.exists(tmp))
  expect_gt(file.info(tmp)$size, 0)
  expect_s3_class(ret, "Pitch")  # save() returns invisible(.self)
})

test_that("Pitch save errors cleanly when the target directory does not exist", {
  pitch <- pitch_fixture()
  expect_error(
    pitch$save("/nonexistent_dir_xyz_pladdrr/out.Pitch"),
    "Failed to save"
  )
})

# ============================================================================
# to_textgrid_silences()
# ============================================================================

test_that("Pitch to_textgrid_silences on a fully-voiced tone returns one sounding interval", {
  pitch <- pitch_fixture()
  tg <- pitch$to_textgrid_silences()

  expect_s3_class(tg, "TextGrid")
  expect_true(tg$is_valid())
  df <- tg$as_data_frame()
  expect_equal(nrow(df), 1)
  expect_equal(df$label[1], "sounding")
})

test_that("Pitch to_textgrid_silences splits silence/tone/silence into three labeled intervals", {
  sr <- 44100
  dur_tone <- 0.6
  dur_sil <- 0.4
  t <- seq(0, dur_tone, length.out = round(sr * dur_tone))
  tone <- sin(2 * pi * 200 * t) * 0.5
  sil <- rep(0, round(sr * dur_sil))
  signal <- c(sil, tone, sil)
  sound <- Sound$from_values(signal, sr)
  pitch <- sound$to_pitch(pitch_floor = 75, pitch_ceiling = 600)

  tg <- pitch$to_textgrid_silences(min_silent_duration = 0.05, min_sounding_duration = 0.05)
  df <- tg$as_data_frame()

  expect_equal(nrow(df), 3)
  expect_equal(df$label, c("silent", "sounding", "silent"))
  # Intervals must be contiguous and span the whole pitch domain
  expect_equal(df$start_time[1], pitch$get_start_time())
  expect_equal(df$end_time[nrow(df)], pitch$get_end_time())
})

test_that("Pitch to_textgrid_silences with a very high min_sounding_duration collapses short voiced spans away", {
  sr <- 44100
  dur_tone <- 0.6
  dur_sil <- 0.4
  t <- seq(0, dur_tone, length.out = round(sr * dur_tone))
  tone <- sin(2 * pi * 200 * t) * 0.5
  sil <- rep(0, round(sr * dur_sil))
  signal <- c(sil, tone, sil)
  sound <- Sound$from_values(signal, sr)
  pitch <- sound$to_pitch(pitch_floor = 75, pitch_ceiling = 600)

  # min_sounding_duration far exceeds the tone's length, so the "sounding"
  # interval is dropped: the C++ loop still advances start/silent past the
  # skipped span (it does not merge backward), leaving two disjoint silent
  # intervals with a gap where the un-added sounding interval would have
  # been. Confirmed by direct experimentation before writing this assertion.
  tg <- pitch$to_textgrid_silences(min_silent_duration = 0.05, min_sounding_duration = 100)
  df <- tg$as_data_frame()

  expect_equal(nrow(df), 2)
  expect_true(all(df$label == "silent"))
  expect_lt(df$end_time[1], df$start_time[2])  # gap = the dropped sounding span
})
