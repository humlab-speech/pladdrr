# test-vad.R - Tests for R/vad.R silence detection, interval filtering,
# segment extraction (sound_get_zcr is covered separately in test-zcr.R)

test_that(
  "sound_to_textgrid_silences returns a TextGrid with silence/sounding intervals", {
  sound <- sounds_append(
    sounds_append(
      Sound$create_tone(frequency = 200, duration = 0.5, amplitude = 0.8),
      Sound$create_tone(frequency = 200, duration = 0.3, amplitude = 0.001)
    ),
    Sound$create_tone(frequency = 200, duration = 0.5, amplitude = 0.8)
  )

  tg <- sound_to_textgrid_silences(sound)

  expect_s3_class(tg, "TextGrid")
  expect_identical(tg$get_number_of_tiers(), 1L)
  expect_identical(tg$get_number_of_intervals(1), 3L)
  expect_identical(tg$get_interval_text(1, 1), "sounding")
  expect_identical(tg$get_interval_text(1, 2), "silence")
  expect_identical(tg$get_interval_text(1, 3), "sounding")
  expect_equal(tg$get_interval_start_time(1, 1), 0,
    tolerance = sqrt(.Machine$double.eps))
  expect_equal(tg$get_interval_end_time(1, 3), sound$get_total_duration(),
    tolerance = sqrt(.Machine$double.eps))
})

test_that("sound_to_textgrid_silences honors custom labels and thresholds", {
  sound <- sounds_append(
    Sound$create_tone(frequency = 200, duration = 0.5, amplitude = 0.8),
    Sound$create_tone(frequency = 200, duration = 0.3, amplitude = 0.001)
  )

  tg <- sound_to_textgrid_silences(
    sound,
    silent_label = "sil",
    sounding_label = "voi"
  )

  expect_true(all(vapply(seq_len(tg$get_number_of_intervals(1)), function(i) {
    tg$get_interval_text(1, i) %in% c("sil", "voi")
  }, logical(1))))
})

test_that("sound_to_textgrid_silences rejects a non-Sound argument", {
  expect_error(sound_to_textgrid_silences(1:5), "sound must be a Sound object")
})

test_that(
  "sound_to_textgrid_silences with a very high min_sounding_interval collapses to one silent interval", {
  sound <- sounds_append(
    sounds_append(
      Sound$create_tone(frequency = 200, duration = 0.5, amplitude = 0.8),
      Sound$create_tone(frequency = 200, duration = 0.3, amplitude = 0.001)
    ),
    Sound$create_tone(frequency = 200, duration = 0.5, amplitude = 0.8)
  )

  tg <- sound_to_textgrid_silences(sound, min_sounding_interval = 10)

  expect_identical(tg$get_number_of_intervals(1), 1L)
  expect_identical(tg$get_interval_text(1, 1), "silence")
})

test_that(
  "textgrid_get_intervals_where 'equals' returns matching intervals with count", {
  sound <- sounds_append(
    sounds_append(
      Sound$create_tone(frequency = 200, duration = 0.5, amplitude = 0.8),
      Sound$create_tone(frequency = 200, duration = 0.3, amplitude = 0.001)
    ),
    Sound$create_tone(frequency = 200, duration = 0.5, amplitude = 0.8)
  )
  tg <- sound_to_textgrid_silences(sound)

  voiced <- textgrid_get_intervals_where(tg, tier = 1, condition = "equals",
    text = "sounding")

  expect_type(voiced, "list")
  expect_setequal(names(voiced), c("xmin", "xmax", "text", "count"))
  expect_equal(voiced$count, 2L, tolerance = sqrt(.Machine$double.eps))
  expect_length(voiced$xmin, 2)
  expect_length(voiced$xmax, 2)
  expect_true(all(voiced$text == "sounding"))
  expect_equal(voiced$xmin, c(0, 0.786))
})

test_that(
  "textgrid_get_intervals_where 'contains' / 'does not contain' / 'starts with' / 'ends with' all filter correctly", {
  sound <- sounds_append(
    sounds_append(
      Sound$create_tone(frequency = 200, duration = 0.5, amplitude = 0.8),
      Sound$create_tone(frequency = 200, duration = 0.3, amplitude = 0.001)
    ),
    Sound$create_tone(frequency = 200, duration = 0.5, amplitude = 0.8)
  )
  tg <- sound_to_textgrid_silences(sound, silent_label = "sil",
    sounding_label = "voi")

  contains <- textgrid_get_intervals_where(tg, tier = 1,
    condition = "contains", text = "il")
  expect_equal(contains$count, 1L, tolerance = sqrt(.Machine$double.eps))
  expect_identical(contains$text, "sil")

  does_not_contain <- textgrid_get_intervals_where(tg, tier = 1,
    condition = "does not contain", text = "sil")
  expect_equal(does_not_contain$count, 2L,
    tolerance = sqrt(.Machine$double.eps))
  expect_true(all(does_not_contain$text == "voi"))

  starts_with <- textgrid_get_intervals_where(tg, tier = 1,
    condition = "starts with", text = "v")
  expect_equal(starts_with$count, 2L, tolerance = sqrt(.Machine$double.eps))

  ends_with <- textgrid_get_intervals_where(tg, tier = 1,
    condition = "ends with", text = "l")
  expect_equal(ends_with$count, 1L, tolerance = sqrt(.Machine$double.eps))
  expect_identical(ends_with$text, "sil")
})

test_that(
  "textgrid_get_intervals_where returns empty result when nothing matches", {
  sound <- Sound$create_tone(frequency = 200, duration = 0.5, amplitude = 0.8)
  tg <- sound_to_textgrid_silences(sound)

  none <- textgrid_get_intervals_where(tg, tier = 1, condition = "equals",
    text = "nope")

  expect_equal(none$count, 0L, tolerance = sqrt(.Machine$double.eps))
  expect_length(none$xmin, 0)
  expect_length(none$xmax, 0)
  expect_length(none$text, 0)
})

test_that("textgrid_get_intervals_where rejects a non-TextGrid argument", {
  expect_error(
    textgrid_get_intervals_where(1:5, tier = 1, condition = "equals",
      text = "x"),
    "textgrid must be a TextGrid object"
  )
})

test_that("textgrid_get_intervals_where validates condition via match.arg", {
  sound <- Sound$create_tone(frequency = 200, duration = 0.5, amplitude = 0.8)
  tg <- sound_to_textgrid_silences(sound)

  expect_error(
    textgrid_get_intervals_where(tg, tier = 1, condition = "bogus", text = "x")
  )
})

test_that(
  "sound_extract_parts extracts non-overlapping segments as R6 Sound objects", {
  sound <- sounds_append(
    sounds_append(
      Sound$create_tone(frequency = 200, duration = 0.5, amplitude = 0.8),
      Sound$create_tone(frequency = 200, duration = 0.3, amplitude = 0.001)
    ),
    Sound$create_tone(frequency = 200, duration = 0.5, amplitude = 0.8)
  )

  parts <- sound_extract_parts(sound, start_times = c(0, 0.786),
    end_times = c(0.522, 1.3))

  expect_type(parts, "list")
  expect_length(parts, 2)
  expect_s3_class(parts[[1]], "Sound")
  expect_s3_class(parts[[2]], "Sound")
  expect_equal(parts[[1]]$get_total_duration(), 0.522, tolerance = 1e-6)
  expect_equal(parts[[2]]$get_total_duration(), 0.514, tolerance = 1e-6)
})

test_that(
  "sound_extract_parts return_r6 = FALSE returns raw external pointers", {
  sound <- Sound$create_tone(frequency = 200, duration = 1.0,
    sampling_rate = 16000)

  parts <- sound_extract_parts(sound, 0.1, 0.5, return_r6 = FALSE)

  expect_type(parts, "list")
  expect_type(parts[[1]], "externalptr")
})

test_that("sound_extract_parts accepts a non-default window_shape", {
  sound <- Sound$create_tone(frequency = 200, duration = 1.0,
    sampling_rate = 16000)

  parts <- sound_extract_parts(sound, 0.1, 0.5, window_shape = "hanning")

  expect_s3_class(parts[[1]], "Sound")
  expect_equal(parts[[1]]$get_total_duration(), 0.4, tolerance = 1e-6)
})

test_that("sound_extract_parts rejects mismatched start/end lengths", {
  sound <- Sound$create_tone(frequency = 200, duration = 1.0,
    sampling_rate = 16000)

  expect_error(
    sound_extract_parts(sound, c(0, 0.5), 0.3),
    "start_times and end_times must have the same length"
  )
})

test_that("sound_extract_parts rejects an invalid sound argument", {
  expect_error(
    sound_extract_parts(1:5, 0, 0.5),
    "sound must be a Sound object or external pointer"
  )
})

test_that("extract_voiced_segments returns a concatenated voiced Sound", {
  sound <- Sound$create_tone(frequency = 150, duration = 1,
    sampling_rate = 16000)

  segments <- extract_voiced_segments(sound)

  expect_s3_class(segments, "Sound")
  expect_equal(segments$get_total_duration(), 1, tolerance = 1e-6)
})

test_that("extract_voiced_segments with use_zcr = FALSE skips ZCR filtering", {
  sound <- Sound$create_tone(frequency = 150, duration = 1,
    sampling_rate = 16000)

  segments <- extract_voiced_segments(sound, use_zcr = FALSE)

  expect_s3_class(segments, "Sound")
  expect_equal(segments$get_total_duration(), 1, tolerance = 1e-6)
})

test_that(
  "extract_voiced_segments with return_textgrid = TRUE returns sound + textgrid list", {
  sound <- Sound$create_tone(frequency = 150, duration = 1,
    sampling_rate = 16000)

  result <- extract_voiced_segments(sound, return_textgrid = TRUE)

  expect_type(result, "list")
  expect_setequal(names(result), c("sound", "textgrid"))
  expect_s3_class(result$sound, "Sound")
  expect_s3_class(result$textgrid, "TextGrid")
})

test_that("extract_voiced_segments rejects a non-Sound argument", {
  expect_error(extract_voiced_segments(1:5), "sound must be a Sound object")
})

test_that(
  "extract_voiced_segments warns and returns NULL when no voiced segments are detected", {
  sound <- sounds_append(
    sounds_append(
      Sound$create_tone(frequency = 200, duration = 0.5, amplitude = 0.8),
      Sound$create_tone(frequency = 200, duration = 0.3, amplitude = 0.001)
    ),
    Sound$create_tone(frequency = 200, duration = 0.5, amplitude = 0.8)
  )

  expect_warning(
    result <- extract_voiced_segments(sound, min_sounding_interval = 10),
    "No voiced segments detected by intensity"
  )
  expect_null(result)
})

test_that(
  "extract_voiced_segments warns and returns textgrid-only list when no voiced segments and return_textgrid = TRUE", {
  sound <- sounds_append(
    sounds_append(
      Sound$create_tone(frequency = 200, duration = 0.5, amplitude = 0.8),
      Sound$create_tone(frequency = 200, duration = 0.3, amplitude = 0.001)
    ),
    Sound$create_tone(frequency = 200, duration = 0.5, amplitude = 0.8)
  )

  expect_warning(
    result <- extract_voiced_segments(sound, min_sounding_interval = 10,
      return_textgrid = TRUE),
    "No voiced segments detected by intensity"
  )
  expect_type(result, "list")
  expect_null(result$sound)
  expect_s3_class(result$textgrid, "TextGrid")
})

test_that(
  "extract_voiced_segments warns and returns NULL when ZCR filtering rejects all segments", {
  sound <- sounds_append(
    sounds_append(
      Sound$create_tone(frequency = 200, duration = 0.5, amplitude = 0.8),
      Sound$create_tone(frequency = 200, duration = 0.3, amplitude = 0.001)
    ),
    Sound$create_tone(frequency = 200, duration = 0.5, amplitude = 0.8)
  )

  expect_warning(
    result <- extract_voiced_segments(sound, zcr_threshold = 0.001),
    "All segments rejected by ZCR filter"
  )
  expect_null(result)
})
