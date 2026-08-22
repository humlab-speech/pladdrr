# test-sound-shs-spinet-pitch.R - Tests for Sound$to_pitch_shs / to_pitch_spinet
# (exercises Sound_correlateParts/Sound_localPeak/Sound_createHamming and
#  Sound_createGammaTone/Sound_power in src/sound_create_gaussian.cpp)

test_that("Sound$to_pitch_shs constructs a valid Pitch object", {
  sound <- generate_sine_wave(150, 0.5, sampling_rate = 16000)
  pitch <- sound$to_pitch_shs(time_step = 0.01, pitch_floor = 50,
                               max_frequency = 1250, pitch_ceiling = 500)
  expect_s3_class(pitch, "Pitch")
  expect_true(pitch$is_valid())
  expect_gte(pitch$get_number_of_frames(), 1)
})

test_that("Sound$to_pitch_shs respects custom candidate/octave parameters", {
  sound <- generate_sine_wave(150, 0.5, sampling_rate = 16000)
  pitch <- sound$to_pitch_shs(time_step = 0.01, pitch_floor = 50,
                               max_frequency = 1250, pitch_ceiling = 500,
                               max_subharmonics = 5L, max_candidates = 5L,
                               compression_factor = 0.7,
                               n_points_per_octave = 24L)
  expect_s3_class(pitch, "Pitch")
  expect_true(pitch$is_valid())
  expect_gte(pitch$get_number_of_frames(), 1)
})

test_that("Sound$to_pitch_spinet constructs a valid Pitch object", {
  # The vendored Praat SPINET path intermittently fails with "The sound
  # should not have all amplitudes equal to zero" even though the input
  # signal is unchanged. See tests/testthat/helper-retry.R::retry_once() for
  # the full rationale and the data behind the single-retry mitigation.
  sound <- generate_sine_wave(150, 0.5, sampling_rate = 16000)
  pitch <- retry_once(sound$to_pitch_spinet())
  expect_s3_class(pitch, "Pitch")
  expect_true(pitch$is_valid())
  expect_gte(pitch$get_number_of_frames(), 1)
})

test_that("Sound$to_pitch_spinet respects custom filter/frequency parameters", {
  sound <- generate_sine_wave(150, 0.5, sampling_rate = 16000)
  pitch <- retry_once(sound$to_pitch_spinet(
    time_step = 0.01, window_duration = 0.04,
    min_frequency = 70, max_frequency = 3000,
    n_filters = 100L, pitch_ceiling = 500,
    max_candidates = 5L
  ))
  expect_s3_class(pitch, "Pitch")
  expect_true(pitch$is_valid())
  expect_gte(pitch$get_number_of_frames(), 1)
})
