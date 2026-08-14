test_that("batch functions work with function-wrapper Sound", {
  
  # Create test sounds using function wrapper
  sounds <- lapply(1:3, function(i) {
    Sound$from_values(sin(seq(0, 2*pi, length.out = 44100)), 44100)
  })
  
  # Test sound_to_pitch_batch
  expect_no_error({
    pitches <- sound_to_pitch_batch(sounds)
  })
  expect_length(pitches, 3)
  
  # Test sound_to_pitch_ac_batch
  expect_no_error({
    pitches_ac <- sound_to_pitch_ac_batch(sounds)
  })
  expect_length(pitches_ac, 3)
  
  # Test sound_to_pitch_cc_batch
  expect_no_error({
    pitches_cc <- sound_to_pitch_cc_batch(sounds)
  })
  expect_length(pitches_cc, 3)
  
  # Test sound_to_formant_batch
  expect_no_error({
    formants <- sound_to_formant_batch(sounds)
  })
  expect_length(formants, 3)
  
  # Test sound_to_intensity_batch
  expect_no_error({
    intensities <- sound_to_intensity_batch(sounds)
  })
  expect_length(intensities, 3)
})


test_that("batch results match individual calls", {
  
  # Use test audio file if available
  test_file <- system.file("signalfiles", "KA.wav", package = "pladdrr")
  if (!file.exists(test_file)) {
    skip("Test file not available")
  }
  
  sound <- Sound(test_file)
  sounds <- list(sound, sound, sound)
  
  # Test pitch batch
  batch_pitches <- sound_to_pitch_batch(sounds, pitch_floor = 75, pitch_ceiling = 300)
  individual_pitch <- sound$to_pitch(pitch_floor = 75, pitch_ceiling = 300)
  
  # Compare first result
  batch_mean <- batch_pitches[[1]]$get_mean(0, 0, "hertz")
  individual_mean <- individual_pitch$get_mean(0, 0, "hertz")
  
  expect_equal(batch_mean, individual_mean, tolerance = 1e-10)
  
  # Test formant batch
  batch_formants <- sound_to_formant_batch(sounds, time_step = 0.005, max_formants = 5)
  individual_formant <- sound$to_formant(time_step = 0.005, max_formants = 5)
  
  # Get a formant value at a specific time
  time_point <- individual_formant$get_time_from_frame_number(1)
  batch_f1 <- batch_formants[[1]]$get_value_at_time(1, time_point, "hertz")
  individual_f1 <- individual_formant$get_value_at_time(1, time_point, "hertz")
  
  expect_equal(batch_f1, individual_f1, tolerance = 1e-10)
})


test_that("batch extract-and-analyze functions work", {
  
  test_file <- system.file("signalfiles", "KA.wav", package = "pladdrr")
  if (!file.exists(test_file)) {
    skip("Test file not available")
  }
  
  sound <- Sound(test_file)
  duration <- sound$get_total_duration()
  
  # Create some time intervals
  from_times <- c(0, duration * 0.3)
  to_times <- c(duration * 0.3, duration * 0.6)
  
  # Test sound_extract_and_pitch
  expect_no_error({
    pitches <- sound_extract_and_pitch(sound, from_times, to_times)
  })
  expect_length(pitches, 2)
  
  # Test sound_extract_and_formant
  expect_no_error({
    formants <- sound_extract_and_formant(sound, from_times, to_times)
  })
  expect_length(formants, 2)
})


test_that("vectorized query functions work", {
  
  test_file <- system.file("signalfiles", "KA.wav", package = "pladdrr")
  if (!file.exists(test_file)) {
    skip("Test file not available")
  }
  
  sound <- Sound(test_file)
  pitch <- sound$to_pitch()
  formant <- sound$to_formant()
  intensity <- sound$to_intensity()
  
  # Create time points
  times <- seq(pitch$get_start_time(), pitch$get_end_time(), length.out = 10)
  
  # Test get_pitch_at_times
  expect_no_error({
    pitch_values <- get_pitch_at_times(pitch, times)
  })
  expect_length(pitch_values, 10)
  
  # Test get_formants_at_times
  expect_no_error({
    formant_values <- get_formants_at_times(formant, times)
  })
  expect_length(formant_values, 10)
  
  # Test get_intensity_at_times
  expect_no_error({
    intensity_values <- get_intensity_at_times(intensity, times)
  })
  expect_length(intensity_values, 10)
  
  # Compare with individual calls
  pitch_val_0 <- pitch$get_value_at_time(times[1], "hertz")
  expect_equal(pitch_values[1], pitch_val_0, tolerance = 1e-10)
})


test_that("batch functions accept external pointers", {
  
  # Create sounds and extract pointers
  sounds <- lapply(1:2, function(i) {
    Sound$from_values(sin(seq(0, 2*pi, length.out = 44100)), 44100)
  })
  
  xptrs <- lapply(sounds, function(s) s$.xptr)
  
  # Batch functions should accept xptrs directly
  expect_no_error({
    pitches <- sound_to_pitch_batch(xptrs, return_r6 = FALSE)
  })
  expect_length(pitches, 2)
  expect_true(inherits(pitches[[1]], "externalptr"))
})


test_that("extract_xptr utility works correctly", {
  
  sound <- Sound$from_values(sin(seq(0, 2*pi, length.out = 44100)), 44100)
  
  # Extract pointer
  ptr <- pladdrr:::extract_xptr(sound, "Sound")
  expect_true(inherits(ptr, "externalptr"))
  
  # Should accept pointer directly
  ptr2 <- pladdrr:::extract_xptr(ptr, "Sound")
  expect_identical(ptr, ptr2)
  
  # Should fail on wrong class
  expect_error({
    pladdrr:::extract_xptr(list(a = 1), "Sound")
  })
})


test_that("unit_to_code utility provides consistent mapping", {
  
  # Pitch units
  expect_equal(pladdrr:::unit_to_code("hertz", "pitch"), 0L)
  expect_equal(pladdrr:::unit_to_code("Hz", "pitch"), 0L)
  expect_equal(pladdrr:::unit_to_code("mel", "pitch"), 2L)
  expect_equal(pladdrr:::unit_to_code("erb", "pitch"), 8L)
  
  # Formant units
  expect_equal(pladdrr:::unit_to_code("hertz", "formant"), 0L)
  expect_equal(pladdrr:::unit_to_code("bark", "formant"), 1L)
  
  # Default fallback
  expect_equal(pladdrr:::unit_to_code("unknown", "pitch"), 0L)
})

test_that("sound_load_window validates its arguments", {
  wav <- tempfile(fileext = ".wav")
  Sound$create_tone(frequency = 150, duration = 1, sampling_rate = 16000)$save(wav)
  on.exit(unlink(wav))

  expect_error(sound_load_window(123, 0, 0.5), "single character string")
  expect_error(sound_load_window("nonexistent.wav", 0, 0.5), "File not found")
  expect_error(sound_load_window(wav, -1, 0.5), "non-negative number")
  expect_error(sound_load_window(wav, 0, "x"), "end must be a number")
  expect_error(sound_load_window(wav, 0.5, 0.5), "end must be greater than start")
  expect_error(sound_load_window(wav, 0, 0.5, resample_to = -1), "resample_to must be")
  expect_error(sound_load_window(wav, 0, 0.5, preserve_times = "yes"), "TRUE or FALSE")
})

test_that("sound_load_window loads a time window from disk", {
  wav <- tempfile(fileext = ".wav")
  Sound$create_tone(frequency = 150, duration = 1, sampling_rate = 16000)$save(wav)
  on.exit(unlink(wav))

  window <- sound_load_window(wav, 0.2, 0.7)
  expect_s3_class(window, "Sound")
  expect_equal(window$get_duration(), 0.5, tolerance = 1e-2)
})

test_that("sound_load_window resamples when resample_to is given", {
  wav <- tempfile(fileext = ".wav")
  Sound$create_tone(frequency = 150, duration = 1, sampling_rate = 16000)$save(wav)
  on.exit(unlink(wav))

  window <- sound_load_window(wav, 0, 0.5, resample_to = 8000)
  expect_equal(window$get_sampling_frequency(), 8000)
})
