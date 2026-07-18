test_wav <- system.file("extdata", "test.wav", package = "pladdrr")

test_that("Spectrogram R6 creation from Sound works", {
  skip_if_not(file.exists(test_wav), "Test audio file not available")
  
  sound <- Sound$new(test_wav)
  spec <- sound$to_spectrogram(window_length = 0.005, max_frequency = 5000)
  
  expect_s3_class(spec, "Spectrogram")
})

test_that("Spectrogram R6 time queries work", {
  skip_if_not(file.exists(test_wav), "Test audio file not available")
  
  sound <- Sound$new(test_wav)
  spec <- sound$to_spectrogram(window_length = 0.005, max_frequency = 5000)
  
  tmin <- spec$get_start_time()
  tmax <- spec$get_end_time()
  
  expect_type(tmin, "double")
  expect_type(tmax, "double")
  expect_true(tmax > tmin)
})

test_that("Spectrogram R6 frequency queries work", {
  skip_if_not(file.exists(test_wav), "Test audio file not available")
  
  sound <- Sound$new(test_wav)
  spec <- sound$to_spectrogram(window_length = 0.005, max_frequency = 5000)
  
  fmin <- spec$get_lowest_frequency()
  fmax <- spec$get_highest_frequency()
  
  expect_type(fmin, "double")
  expect_type(fmax, "double")
  expect_true(fmax > fmin)
  expect_lte(fmax, 5000)
})

test_that("Spectrogram R6 power queries work", {
  skip_if_not(file.exists(test_wav), "Test audio file not available")
  
  sound <- Sound$new(test_wav)
  spec <- sound$to_spectrogram(window_length = 0.005, max_frequency = 5000)
  
  # Get power at a specific point
  tmin <- spec$get_start_time()
  tmax <- spec$get_end_time()
  mid_time <- (tmin + tmax) / 2
  
  power <- spec$get_power_at(time = mid_time, frequency = 1000)
  
  expect_type(power, "double")
  expect_gte(power, 0)  # Power should be non-negative
})

test_that("Spectrogram R6 dimension queries work", {
  skip_if_not(file.exists(test_wav), "Test audio file not available")
  
  sound <- Sound$new(test_wav)
  spec <- sound$to_spectrogram(window_length = 0.005, max_frequency = 5000)
  
  nt <- spec$get_number_of_time_bins()
  nf <- spec$get_number_of_frequency_bins()
  
  expect_type(nt, "integer")
  expect_type(nf, "integer")
  expect_gt(nt, 0)
  expect_gt(nf, 0)
})

test_that("Spectrogram R6 conversion to Spectrum works", {
  skip_if_not(file.exists(test_wav), "Test audio file not available")
  
  sound <- Sound$new(test_wav)
  spec <- sound$to_spectrogram(window_length = 0.005, max_frequency = 5000)
  
  # Convert to Spectrum at a specific time
  tmin <- spec$get_start_time()
  tmax <- spec$get_end_time()
  mid_time <- (tmin + tmax) / 2
  
  spectrum <- spec$to_spectrum(time = mid_time)
  
  expect_s3_class(spectrum, "Spectrum")
})

test_that("Spectrogram R6 to_ltas works", {
  skip_if_not(file.exists(test_wav), "Test audio file not available")
  
  sound <- Sound$new(test_wav)
  spec <- sound$to_spectrogram(window_length = 0.005, max_frequency = 5000)
  
  mid_time <- (spec$get_start_time() + spec$get_end_time()) / 2
  ltas <- spec$to_spectrum(time = mid_time)$to_ltas()
  
  expect_s3_class(ltas, "Ltas")
})
