# Query/export methods that are exposed on the R6 classes but were not
# exercised by the class-specific test files.

test_that("Cochleagram axes agree with the exported matrix", {
  sound <- Sound$create_tone(frequency = 200, duration = 0.3)
  cochleagram <- sound$to_cochleagram()

  values <- cochleagram$as_matrix()
  expect_equal(nrow(values), cochleagram$get_number_of_frequency_bands())
  expect_equal(ncol(values), cochleagram$get_number_of_frames())

  expect_equal(
    cochleagram$get_time_from_column(2) -
      cochleagram$get_time_from_column(1),
    cochleagram$get_time_step(),
    tolerance = 1e-12
  )
  expect_equal(
    cochleagram$get_frequency_from_row(2) -
      cochleagram$get_frequency_from_row(1),
    cochleagram$get_frequency_step(),
    tolerance = 1e-12
  )

  expect_error(cochleagram$get_time_from_column(0), "out of range")
  expect_error(cochleagram$get_frequency_from_row(1e6), "out of range")
})

test_that("Spectrogram as_data_frame matches get_power_at", {
  sound <- Sound$create_tone(frequency = 200, duration = 0.3)
  spectrogram <- sound$to_spectrogram()

  df <- spectrogram$as_data_frame()
  expect_named(df, c("time", "frequency", "power"))
  expect_equal(
    nrow(df),
    spectrogram$get_number_of_time_bins() *
      spectrogram$get_number_of_frequency_bins()
  )

  row <- 10
  expect_equal(
    df$power[row],
    spectrogram$get_power_at(df$time[row], df$frequency[row]),
    tolerance = 1e-12
  )
})

test_that("Spectrum as_data_frame matches the exported vectors", {
  sound <- Sound$create_tone(frequency = 200, duration = 0.3)
  spectrum <- sound$to_spectrum()

  df <- spectrum$as_data_frame()
  expect_named(
    df,
    c("bin", "frequency", "real", "imaginary", "power", "phase")
  )
  expect_equal(nrow(df), spectrum$get_number_of_bins())
  expect_equal(df$frequency, spectrum$get_frequencies_vector(),
               tolerance = 1e-12)
  expect_equal(df$real, spectrum$get_real_vector(), tolerance = 1e-12)
  expect_equal(df$imaginary, spectrum$get_imaginary_vector(),
               tolerance = 1e-12)
  expect_equal(df$power, spectrum$get_power_vector(),
               tolerance = 1e-6)
})

test_that("FormantGrid as_data_frame reports every point", {
  grid <- FormantGrid(0, 1, number_of_formants = 3)

  expect_equal(grid$get_number_of_formants(), 3)
  expect_equal(grid$get_formant_at_time(1, 0.5), 550, tolerance = 1e-12)

  df <- grid$as_data_frame()
  expect_named(df, c("formant_number", "time", "frequency", "bandwidth"))
  expect_equal(sort(unique(df$formant_number)), 1:3)
  expect_equal(
    nrow(df),
    grid$get_number_of_formants() * length(unique(df$time))
  )
  expect_true(all(df$frequency[df$formant_number == 1] == 550))

  rendered <- grid$to_sound()
  expect_s3_class(rendered, "Sound")
  expect_equal(rendered$get_duration(), 1, tolerance = 1e-9)
})

test_that("Matrix setter/getter and export agree", {
  matrix <- PraatMatrix(numberOfRows = 2, numberOfColumns = 2)
  matrix$set_value(1, 1, 10)
  matrix$set_value(1, 2, 20)
  matrix$set_value(2, 1, 30)
  matrix$set_value(2, 2, 40)

  expect_equal(matrix$get_value(1, 1), 10)
  expect_equal(matrix$get_value(2, 1), 30)
  expect_equal(matrix$as_matrix(), matrix(c(10, 30, 20, 40), nrow = 2))
})
