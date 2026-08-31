# test-audio-quality.R - Tests for check_audio_quality() /
#  format_quality_report()

test_that("check_audio_quality returns expected metrics for a clean tone", {
  snd <- Sound$create_tone(frequency = 220, duration = 0.5,
    sampling_rate = 16000)
  q <- check_audio_quality(snd)

  expect_type(q, "list")
  expect_named(q, c(
    "max_amplitude", "is_clipped", "n_clipping_samples", "clipping_percentage",
    "mean_intensity_db", "min_intensity_db", "max_intensity_db",
    "intensity_range_db", "rms_amplitude", "duration", "sampling_frequency"
  ))

  expect_false(q$is_clipped)
  expect_equal(q$n_clipping_samples, 0, tolerance = sqrt(.Machine$double.eps))
  expect_equal(q$clipping_percentage, 0, tolerance = sqrt(.Machine$double.eps))
  expect_equal(q$duration, 0.5, tolerance = 1e-6)
  expect_equal(q$sampling_frequency, 16000,
    tolerance = sqrt(.Machine$double.eps))
  expect_gt(q$rms_amplitude, 0)
  expect_gt(q$max_amplitude, 0); expect_lte(q$max_amplitude, 1)
  expect_gte(q$intensity_range_db, 0)
})

test_that("check_audio_quality detects clipping", {
  snd <- Sound$create_tone(frequency = 220, duration = 0.5,
    sampling_rate = 16000,
                            amplitude = 0.999)
  q <- check_audio_quality(snd, clipping_threshold = 0.5)

  expect_true(q$is_clipped)
  expect_gt(q$n_clipping_samples, 0)
  expect_gt(q$clipping_percentage, 0)
})

test_that(
  "check_audio_quality respects clipping_threshold and intensity_floor args", {
  snd <- Sound$create_tone(frequency = 220, duration = 0.5,
    sampling_rate = 16000)

  q_strict <- check_audio_quality(snd, clipping_threshold = 1e-9)
  expect_true(q_strict$is_clipped)

  q_floor <- check_audio_quality(snd, intensity_floor = 75)
  expect_type(q_floor$mean_intensity_db, "double")
})

test_that(
  "format_quality_report produces a character report with expected sections", {
  snd <- Sound$create_tone(frequency = 220, duration = 0.5,
    sampling_rate = 16000)
  q <- check_audio_quality(snd)
  report <- format_quality_report(q)

  expect_type(report, "character")
  expect_length(report, 1)
  expect_true(grepl("Audio Quality Report", report, fixed = TRUE))
  expect_true(grepl("Overall Status", report, fixed = TRUE))
  expect_true(grepl("Basic Properties", report, fixed = TRUE))
  expect_true(grepl("Amplitude Metrics", report, fixed = TRUE))
  expect_true(grepl("Clipping: NO", report, fixed = TRUE))
})

test_that("format_quality_report flags clipping and quiet recordings", {
  loud <- Sound$create_tone(frequency = 220, duration = 0.5,
    sampling_rate = 16000,
                             amplitude = 0.999)
  q_clip <- check_audio_quality(loud, clipping_threshold = 0.5)
  report_clip <- format_quality_report(q_clip)

  expect_true(grepl("Clipping: YES", report_clip, fixed = TRUE))
  expect_true(grepl("BAD|Re-record", report_clip))

  quiet <- Sound$create_tone(frequency = 220, duration = 0.5,
    sampling_rate = 16000,
                              amplitude = 0.001)
  q_quiet <- check_audio_quality(quiet)
  report_quiet <- format_quality_report(q_quiet)
  expect_type(report_quiet, "character")
})

test_that("format_quality_report(detailed = FALSE) omits detail sections", {
  snd <- Sound$create_tone(frequency = 220, duration = 0.5,
    sampling_rate = 16000)
  q <- check_audio_quality(snd)
  report <- format_quality_report(q, detailed = FALSE)

  expect_type(report, "character")
  expect_true(grepl("Overall Status", report, fixed = TRUE))
  expect_true(grepl("Amplitude Metrics", report, fixed = TRUE))
  expect_false(grepl("Intensity Metrics", report, fixed = TRUE))
  expect_false(grepl("Recommendations", report, fixed = TRUE))
})
