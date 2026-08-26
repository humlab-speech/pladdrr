# Test Batch/Vectorized Operations
sound_generate_tone <- function(frequency, duration, sample_rate) Sound$create_tone(frequency = frequency, duration = duration, sampling_rate = sample_rate)
module_available <- function(name) !is.null(tryCatch(pladdrr:::get_module(name), error = function(e) NULL))
# These tests verify that batch operations produce the same results as
# individual calls, while being significantly faster.

test_that("Sound window operations are vectorized", {
  skip_if_not(module_available("sound_module"))

  # Create a test sound (1 second, 16kHz)
  sound <- sound_generate_tone(440, duration = 1.0, sample_rate = 16000)

  # Define windows
  starts <- seq(0, 0.9, by = 0.1)
  ends <- starts + 0.1

  # Batch call for power
  powers_batch <- sound$get_power_windows(starts, ends)

  # Individual calls
  powers_individual <- vapply(seq_along(starts), function(i) {
    sound$get_power(starts[i], ends[i])
  }, FUN.VALUE = numeric(1))

  expect_equal(powers_batch, powers_individual, tolerance = 1e-10)
  expect_length(powers_batch, 10)

  # Batch call for RMS
  rms_batch <- sound$get_rms_windows(starts, ends)
  rms_individual <- vapply(seq_along(starts), function(i) {
    sound$get_rms(starts[i], ends[i])
  }, FUN.VALUE = numeric(1))

  expect_equal(rms_batch, rms_individual, tolerance = 1e-10)

  # Batch call for energy
  energy_batch <- sound$get_energy_windows(starts, ends)
  energy_individual <- vapply(seq_along(starts), function(i) {
    sound$get_energy(starts[i], ends[i])
  }, FUN.VALUE = numeric(1))

  expect_equal(energy_batch, energy_individual, tolerance = 1e-10)
})

test_that("Sound value extraction is vectorized", {
  skip_if_not(module_available("sound_module"))

  sound <- sound_generate_tone(440, duration = 0.5, sample_rate = 16000)

  # Get values at specific times
  times <- seq(0.1, 0.4, by = 0.05)
  values_batch <- sound$get_values_at_times(times, channel = 1, interpolation = "linear")

  expect_length(values_batch, length(times))
  expect_true(all(is.finite(values_batch)))

  # Get values in range
  values_range <- sound$get_values_in_range(0.1, 0.2, channel = 1)
  times_range <- sound$get_times_in_range(0.1, 0.2)

  expect_length(values_range, length(times_range))
  expect_true(all(times_range >= 0.1 & times_range <= 0.2))
})

test_that("Pitch batch operations work", {
  skip_if_not(module_available("pitch_module"))

  sound <- sound_generate_tone(200, duration = 0.5, sample_rate = 16000)
  pitch <- sound$to_pitch(0.01, 75, 500)

  # Get voiced mask
  mask <- pitch$get_voiced_mask()
  expect_type(mask, "logical")
  expect_length(mask, pitch$get_number_of_frames())

  # Get values at times
  times <- pitch$get_times_vector()
  values_batch <- pitch$get_values_at_times(times[seq_len(min(10, length(times)))])

  expect_type(values_batch, "double")
})

test_that("Harmonicity batch stats work", {
  skip_if_not(module_available("harmonicity_module"))

  sound <- sound_generate_tone(200, duration = 0.5, sample_rate = 16000)
  hnr <- sound$to_harmonicity_ac(0.01, 75)

  # Batch statistics for multiple windows
  starts <- c(0.1, 0.2, 0.3)
  ends <- c(0.2, 0.3, 0.4)

  stats <- hnr$get_statistics_batch(starts, ends, c("mean", "min", "max"))

  expect_true(is.matrix(stats))
  expect_equal(nrow(stats), 3)
  expect_equal(ncol(stats), 3)

  # Direct vector access
  values <- hnr$get_values_vector()
  times <- hnr$get_times_vector()

  expect_length(values, hnr$get_number_of_frames())
  expect_length(times, hnr$get_number_of_frames())
})

test_that("TextGrid batch labels work", {
  skip_if_not(module_available("textgrid_module"))

  # Create a TextGrid with an interval tier
  tg <- textgrid_create(0, 2, "words", "")
  tg$insert_boundary("words", 0.5)
  tg$insert_boundary("words", 1.0)
  tg$insert_boundary("words", 1.5)
  tg$set_interval_text("words", 1, "hello")
  tg$set_interval_text("words", 2, "world")
  tg$set_interval_text("words", 3, "test")

  # Get labels at multiple times
  times <- c(0.2, 0.7, 1.2, 1.8)
  labels <- tg$get_labels_at_times("words", times)

  expect_equal(labels[1], "hello")
  expect_equal(labels[2], "world")
  expect_equal(labels[3], "test")
  expect_equal(labels[4], "")  # empty last interval

  # Batch set interval texts
  tg$set_interval_texts_batch("words", c(1, 2), c("foo", "bar"))
  expect_equal(tg$get_interval_text("words", 1), "foo")
  expect_equal(tg$get_interval_text("words", 2), "bar")
})

test_that("Spectrum vector operations work", {
  skip_if_not(module_available("spectrum_module"))

  sound <- sound_generate_tone(440, duration = 0.1, sample_rate = 16000)
  spectrum <- sound$to_spectrum()

  # Get all vectors
  freqs <- spectrum$get_frequencies_vector()
  powers <- spectrum$get_power_vector()
  reals <- spectrum$get_real_vector()
  imags <- spectrum$get_imaginary_vector()

  n_bins <- spectrum$get_number_of_bins()
  expect_length(freqs, n_bins)
  expect_length(powers, n_bins)
  expect_length(reals, n_bins)
  expect_length(imags, n_bins)

  # Verify power = real^2 + imag^2
  expect_equal(powers, reals^2 + imags^2, tolerance = 1e-10)

  # Band energies
  fmins <- c(0, 500, 1000)
  fmaxs <- c(500, 1000, 2000)
  energies <- spectrum$get_band_energies(fmins, fmaxs)

  expect_length(energies, 3)
})

test_that("Formant track extraction works", {
  skip_if_not(module_available("formant_module"))

  sound <- sound_generate_tone(200, duration = 0.3, sample_rate = 16000)
  formant <- sound$to_formant_burg(0.01, 5, 5500)

  # Get tracks
  times <- formant$get_times_vector()
  f1_track <- formant$get_formant_track(1)
  f2_track <- formant$get_formant_track(2)

  expect_length(times, formant$get_number_of_frames())
  expect_length(f1_track, formant$get_number_of_frames())
  expect_length(f2_track, formant$get_number_of_frames())

  # Get all formant tracks at once
  all_tracks <- formant$get_all_formant_tracks(3)
  expect_true(is.matrix(all_tracks))
  expect_equal(ncol(all_tracks), 3)
})

test_that("Spectrogram batch queries work", {
  skip_if_not(module_available("spectrogram_module"))

  sound <- sound_generate_tone(440, duration = 0.2, sample_rate = 16000)
  spectrogram <- sound$to_spectrogram(window_length = 0.005, max_frequency = 5000)

  # Get vectors
  times <- spectrogram$get_times_vector()
  freqs <- spectrogram$get_frequencies_vector()

  expect_true(length(times) > 0)
  expect_true(length(freqs) > 0)

  # Get a frame
  frame <- spectrogram$get_frame(times[1])
  expect_length(frame, length(freqs))

  # Get frequency slice
  slice <- spectrogram$get_frequency_slice(freqs[5])
  expect_length(slice, length(times))

  # Get band power over time
  band_power <- spectrogram$get_band_power(400, 500)
  expect_length(band_power, length(times))
})
