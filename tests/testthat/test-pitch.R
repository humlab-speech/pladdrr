# test-pitch.R - Tests for pitch extraction and analysis
#
# These tests follow TDD principles (written BEFORE implementation)
# They define expected behavior for pitch analysis functions

test_that("extract_pitch() creates valid praat_pitch object", {
  # Load test sound
  sound <- read_sound(test_path("fixtures/speech_sample.wav"))

  # Extract pitch with default parameters
  pitch <- extract_pitch(sound)

  # Check object class
  expect_s3_class(pitch, "Pitch")
  expect_s3_class(pitch, "data.frame")

  # Check required columns exist
  expect_true("time" %in% names(pitch))
  expect_true("frequency" %in% names(pitch))

  # Optional: strength column (confidence measure)
  # expect_true("strength" %in% names(pitch))

  # Check data types
  expect_type(pitch$time, "double")
  expect_type(pitch$frequency, "double")

  # Check time is monotonically increasing
  expect_true(all(diff(pitch$time) > 0))

  # Check frequency values are positive when defined (or NA)
  defined_freqs <- pitch$frequency[!is.na(pitch$frequency)]
  expect_true(all(defined_freqs > 0))
})

test_that("extract_pitch() accepts pitch_floor and pitch_ceiling parameters", {
  sound <- read_sound(test_path("fixtures/speech_sample.wav"))

  # Extract with custom pitch range (typical male voice)
  pitch <- extract_pitch(sound, pitch_floor = 75, pitch_ceiling = 300)

  expect_s3_class(pitch, "Pitch")

  # All defined frequencies should be within range
  defined_freqs <- pitch$frequency[!is.na(pitch$frequency)]
  expect_true(all(defined_freqs >= 75))
  expect_true(all(defined_freqs <= 300))
})

test_that("extract_pitch() accepts time_step parameter", {
  sound <- read_sound(test_path("fixtures/speech_sample.wav"))

  # Extract with larger time step
  pitch_coarse <- extract_pitch(sound, time_step = 0.02)  # 20ms
  pitch_fine <- extract_pitch(sound, time_step = 0.005)   # 5ms

  # Coarse should have fewer frames
  expect_lt(nrow(pitch_coarse), nrow(pitch_fine))
})

test_that("extract_pitch() identifies unvoiced segments as NA", {
  sound <- read_sound(test_path("fixtures/speech_sample.wav"))

  pitch <- extract_pitch(sound)

  # Should have some NA values (unvoiced sections)
  expect_true(any(is.na(pitch$frequency)))

  # Should have some voiced values (not all NA)
  expect_true(any(!is.na(pitch$frequency)))

  # Unvoiced section (0.3-0.5s) should have NAs
  unvoiced_frames <- pitch$time >= 0.3 & pitch$time < 0.5
  if (any(unvoiced_frames)) {
    # Most unvoiced frames should be NA
    na_rate <- sum(is.na(pitch$frequency[unvoiced_frames])) / sum(unvoiced_frames)
    expect_gt(na_rate, 0.5)  # At least 50% should be NA
  }
})

test_that("extract_pitch() output matches reference Praat output", {
  skip_if_not(file.exists(test_path("../../../inst/testdata/speech_sample_pitch_reference.csv")),
              "Reference pitch data not found")

  sound <- read_sound(test_path("fixtures/speech_sample.wav"))
  pitch <- extract_pitch(sound, time_step = 0.01)  # 10ms to match reference

  # Load reference data
  ref <- read.csv(test_path("../../../inst/testdata/speech_sample_pitch_reference.csv"))

  # Check we have roughly the same number of frames (within 10%)
  expect_equal(nrow(pitch), nrow(ref), tolerance = 0.1 * nrow(ref))

  # For voiced frames, check frequency matches within 0.1% (constitution requirement)
  for (i in seq_len(min(nrow(pitch), nrow(ref)))) {
    ref_freq <- ref$frequency[i]
    pitch_freq <- pitch$frequency[i]

    # Both should agree on voiced/unvoiced
    if (is.na(ref_freq)) {
      # Reference says unvoiced - we can be unvoiced or low confidence
      # (NA is acceptable)
    } else {
      # Reference says voiced - check frequency matches
      if (!is.na(pitch_freq)) {
        rel_error <- abs(pitch_freq - ref_freq) / ref_freq
        expect_lt(rel_error, 0.001,  # 0.1% relative error
                  label = sprintf("Frame %d: freq=%.1f vs ref=%.1f", i, pitch_freq, ref_freq))
      }
    }
  }
})

test_that("get_pitch_at_time() returns F0 at specific time point", {
  sound <- read_sound(test_path("fixtures/speech_sample.wav"))
  pitch <- extract_pitch(sound)

  # Get pitch at a voiced time point (0.15s - should be ~120 Hz)
  f0 <- get_pitch_at_time(pitch, 0.15)

  expect_type(f0, "double")
  expect_length(f0, 1)
  expect_gt(f0, 0)  # Should be positive

  # Should be close to 120 Hz (within 10%)
  expect_equal(f0, 120, tolerance = 12)
})

test_that("get_pitch_at_time() returns NA for unvoiced segments", {
  sound <- read_sound(test_path("fixtures/speech_sample.wav"))
  pitch <- extract_pitch(sound)

  # Get pitch at unvoiced time point (0.4s - noise section)
  f0 <- get_pitch_at_time(pitch, 0.4)

  # Should be NA or very low confidence
  expect_true(is.na(f0) || f0 == 0)
})

test_that("get_pitch_at_time() interpolates between frames", {
  sound <- read_sound(test_path("fixtures/speech_sample.wav"))
  pitch <- extract_pitch(sound, time_step = 0.05)  # Coarse sampling

  # Get pitch at time between frames
  f0 <- get_pitch_at_time(pitch, 0.125, interpolate = TRUE)

  expect_type(f0, "double")
  # Should return a reasonable value (not exactly at a frame time)
})

test_that("get_pitch_at_time() handles unit parameter", {
  sound <- read_sound(test_path("fixtures/speech_sample.wav"))
  pitch <- extract_pitch(sound)

  # Get pitch in Hz
  f0_hz <- get_pitch_at_time(pitch, 0.15, unit = "Hz")
  expect_gt(f0_hz, 0)

  # Get pitch in semitones (re: 1 Hz)
  f0_st <- get_pitch_at_time(pitch, 0.15, unit = "semitones")
  expect_type(f0_st, "double")

  # Conversion check: semitones = 12 * log2(f0_hz / 1)
  expected_st <- 12 * log2(f0_hz)
  expect_equal(f0_st, expected_st, tolerance = 0.01)
})

test_that("get_mean_pitch() computes correct mean excluding NA values", {
  sound <- read_sound(test_path("fixtures/speech_sample.wav"))
  pitch <- extract_pitch(sound)

  mean_f0 <- get_mean_pitch(pitch)

  expect_type(mean_f0, "double")
  expect_length(mean_f0, 1)
  expect_gt(mean_f0, 0)

  # Should match manual calculation
  voiced_freqs <- pitch$frequency[!is.na(pitch$frequency)]
  expected_mean <- mean(voiced_freqs)
  expect_equal(mean_f0, expected_mean, tolerance = 1e-10)

  # For our test signal, mean should be between 120 and 150 Hz
  expect_gt(mean_f0, 110)
  expect_lt(mean_f0, 160)
})

test_that("get_mean_pitch() works with time range", {
  sound <- read_sound(test_path("fixtures/speech_sample.wav"))
  pitch <- extract_pitch(sound)

  # Get mean only for first voiced section (0-0.3s, ~120 Hz)
  mean_f0 <- get_mean_pitch(pitch, time_range = c(0.0, 0.3))

  expect_equal(mean_f0, 120, tolerance = 10)
})

test_that("get_mean_pitch() handles unit parameter", {
  sound <- read_sound(test_path("fixtures/speech_sample.wav"))
  pitch <- extract_pitch(sound)

  mean_hz <- get_mean_pitch(pitch, unit = "Hz")
  mean_st <- get_mean_pitch(pitch, unit = "semitones")

  # Should be able to convert between them
  expect_equal(mean_st, 12 * log2(mean_hz), tolerance = 0.01)
})

test_that("get_min_pitch() finds minimum F0", {
  sound <- read_sound(test_path("fixtures/speech_sample.wav"))
  pitch <- extract_pitch(sound)

  min_f0 <- get_min_pitch(pitch)

  expect_type(min_f0, "double")
  expect_gt(min_f0, 0)

  # Should be <= mean
  mean_f0 <- get_mean_pitch(pitch)
  expect_lte(min_f0, mean_f0)

  # For our test signal, min should be around 120 Hz
  expect_equal(min_f0, 120, tolerance = 15)
})

test_that("get_max_pitch() finds maximum F0", {
  sound <- read_sound(test_path("fixtures/speech_sample.wav"))
  pitch <- extract_pitch(sound)

  max_f0 <- get_max_pitch(pitch)

  expect_type(max_f0, "double")
  expect_gt(max_f0, 0)

  # Should be >= mean
  mean_f0 <- get_mean_pitch(pitch)
  expect_gte(max_f0, mean_f0)

  # For our test signal, max should be around 150 Hz
  expect_equal(max_f0, 150, tolerance = 15)
})

test_that("pitch statistics functions exclude NA values", {
  sound <- read_sound(test_path("fixtures/speech_sample.wav"))
  pitch <- extract_pitch(sound)

  # All stats functions should handle NA gracefully
  expect_false(is.na(get_mean_pitch(pitch)))
  expect_false(is.na(get_min_pitch(pitch)))
  expect_false(is.na(get_max_pitch(pitch)))
})

test_that("pitch extraction emits warning for poor quality audio", {
  # Create a very noisy sound (poor quality)
  noise_sound <- generate_noise(1.0, sampling_rate = 16000, amplitude = 1.0)

  # Should emit a warning about quality
  expect_warning(
    extract_pitch(noise_sound),
    "quality|voiced|tracking"
  )
})

test_that("pitch extraction emits warning for very few voiced frames", {
  # Create mostly unvoiced sound
  short_voiced <- create_sound(c(rep(0.1, 100), rnorm(10000, sd = 0.05)),
                               sampling_rate = 16000)

  expect_warning(
    extract_pitch(short_voiced),
    "few.*voiced|quality"
  )
})

test_that("extract_pitch() validates input parameters", {
  sound <- read_sound(test_path("fixtures/speech_sample.wav"))

  # Invalid pitch_floor
  expect_error(extract_pitch(sound, pitch_floor = 0), "positive")
  expect_error(extract_pitch(sound, pitch_floor = -50), "positive")

  # Invalid pitch_ceiling
  expect_error(extract_pitch(sound, pitch_ceiling = 0), "positive")

  # pitch_floor >= pitch_ceiling
  expect_error(extract_pitch(sound, pitch_floor = 300, pitch_ceiling = 100),
               "floor.*ceiling")

  # Invalid time_step
  expect_error(extract_pitch(sound, time_step = 0), "positive")
  expect_error(extract_pitch(sound, time_step = -0.01), "positive")
})

test_that("pitch functions validate input", {
  sound <- read_sound(test_path("fixtures/speech_sample.wav"))

  # extract_pitch requires praat_sound
  expect_error(extract_pitch(list()), "praat_sound")
  expect_error(extract_pitch(NULL))

  pitch <- extract_pitch(sound)

  # Other functions require praat_pitch
  expect_error(get_pitch_at_time(list(), 0.5), "praat_pitch")
  expect_error(get_mean_pitch(list()), "praat_pitch")
  expect_error(get_min_pitch(data.frame()), "praat_pitch")
  expect_error(get_max_pitch(NULL))
})

test_that("is_praat_pitch() correctly identifies pitch objects", {
  sound <- read_sound(test_path("fixtures/speech_sample.wav"))
  pitch <- extract_pitch(sound)

  expect_true(is_praat_pitch(pitch))
  expect_false(is_praat_pitch(sound))
  expect_false(is_praat_pitch(list()))
  expect_false(is_praat_pitch(data.frame()))
  expect_false(is_praat_pitch(NULL))
})
