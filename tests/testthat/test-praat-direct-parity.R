# The direct API accepts either an R6 object or a raw external pointer.
# Existing tests only exercise the R6 branch; these cover the pointer branch
# and the lower-level getters that have no R6 wrapper.

direct_tone <- function() {
  Sound$create_tone(frequency = 200, duration = 0.3)
}

test_that("direct constructors agree with R6 conversions", {
  sound <- direct_tone()

  pitch_r6 <- sound$to_pitch()
  pitch_direct <- Pitch(.xptr = to_pitch_direct(sound))
  expect_equal(
    pitch_direct$get_mean(0, 0, "hertz"),
    pitch_r6$get_mean(0, 0, "hertz"),
    tolerance = 1e-6
  )

  intensity_r6 <- sound$to_intensity()
  intensity_direct <- Intensity(.xptr = to_intensity_direct(sound))
  expect_equal(
    intensity_direct$get_mean(0, 0),
    intensity_r6$get_mean(0, 0),
    tolerance = 1e-2
  )

  formant_r6 <- sound$to_formant()
  formant_direct <- Formant(.xptr = to_formant_direct(sound))
  expect_equal(
    formant_direct$get_value_at_time(1, 0.15, "hertz"),
    formant_r6$get_value_at_time(1, 0.15, "hertz"),
    tolerance = 1e-6
  )

  spectrogram_r6 <- sound$to_spectrogram(
    time_step = 0.005, max_frequency = 5000
  )
  spectrogram_direct <- Spectrogram(
    .xptr = to_spectrogram_direct(
      sound, time_step = 0.005, max_frequency = 5000
    )
  )
  expect_equal(
    spectrogram_direct$get_number_of_time_bins(),
    spectrogram_r6$get_number_of_time_bins()
  )
  expect_equal(
    spectrogram_direct$get_number_of_frequency_bins(),
    spectrogram_r6$get_number_of_frequency_bins()
  )

  ltas <- to_ltas_direct(sound)
  expect_s3_class(ltas, "Ltas")
  expect_gt(ltas$get_number_of_bins(), 0)
})

test_that("direct getters agree with the R6 methods", {
  sound <- direct_tone()

  pitch <- sound$to_pitch()
  expect_equal(
    pladdrr:::pitch_get_minimum_direct(pitch$.xptr),
    pitch$get_minimum(),
    tolerance = 1e-9
  )
  expect_equal(
    pladdrr:::pitch_get_maximum_direct(pitch$.xptr),
    pitch$get_maximum(),
    tolerance = 1e-9
  )
  expect_gt(pladdrr:::pitch_count_voiced_direct(pitch$.xptr), 0)

  intensity <- sound$to_intensity()
  expect_equal(
    pladdrr:::intensity_get_mean_direct(intensity$.xptr),
    intensity$get_mean(0, 0),
    tolerance = 1e-2
  )
  expect_lte(
    pladdrr:::intensity_get_minimum_direct(intensity$.xptr),
    pladdrr:::intensity_get_maximum_direct(intensity$.xptr)
  )

  harmonicity <- Harmonicity(.xptr = to_harmonicity_direct(sound))
  expect_equal(
    pladdrr:::harmonicity_get_mean_direct(harmonicity$.xptr),
    harmonicity$get_mean(0, 0),
    tolerance = 1e-9
  )
  expect_equal(
    pladdrr:::harmonicity_get_value_direct(harmonicity$.xptr, 0.15),
    harmonicity$get_value_at_time(0.15),
    tolerance = 1e-9
  )

  formant <- sound$to_formant()
  expect_equal(
    pladdrr:::formant_get_bandwidth_direct(formant$.xptr, 1, 0.15),
    formant$get_bandwidth_at_time(1, 0.15),
    tolerance = 1e-9
  )
  expect_equal(
    pladdrr:::formant_get_mean_direct(formant$.xptr, 1),
    formant$get_mean(1, 0, 0),
    tolerance = 1e-9
  )

  point_process <- to_point_process_direct(sound)
  expect_gt(pp_get_mean_period_direct(point_process), 0)
  expect_gte(pp_get_stdev_period_direct(point_process), 0)
})

test_that("to_spectrogram_direct maps every supported window shape", {
  sound <- direct_tone()

  for (shape in c("square", "hamming", "bartlett", "welch", "hanning",
                  "gaussian")) {
    ptr <- to_spectrogram_direct(
      sound, time_step = 0.005, max_frequency = 5000, window_shape = shape
    )
    expect_type(ptr, "externalptr")
    expect_gt(Spectrogram(.xptr = ptr)$get_number_of_time_bins(), 0)
  }
})

test_that("direct conversions reject non-Sound input", {
  expect_error(
    to_pitch_direct(list()), "sound must be a Sound object"
  )
  expect_error(
    to_intensity_direct("x"), "sound must be a Sound object"
  )
  expect_error(
    to_harmonicity_direct("x"), "sound must be a Sound object"
  )
  expect_error(
    to_formant_direct("x"), "sound must be a Sound object"
  )
})
