test_that("Spectrum R6 creation from Sound works", {
  skip_if_not(file.exists("test.wav"), "Test audio file not available")
  
  sound <- Sound$new("test.wav")
  spectrum <- sound$to_spectrum(fast = TRUE)
  
  expect_s3_class(spectrum, "Spectrum")
  expect_s3_class(spectrum, "R6")
})

test_that("Spectrum R6 frequency queries work", {
  skip_if_not(file.exists("test.wav"), "Test audio file not available")
  
  sound <- Sound$new("test.wav")
  spectrum <- sound$to_spectrum(fast = TRUE)
  
  fmin <- spectrum$get_lowest_frequency()
  fmax <- spectrum$get_highest_frequency()
  
  expect_type(fmin, "double")
  expect_type(fmax, "double")
  expect_true(fmax > fmin)
  expect_equal(fmin, 0.0)  # Should start at 0 Hz
})

test_that("Spectrum R6 centre of gravity works", {
  skip_if_not(file.exists("test.wav"), "Test audio file not available")
  
  sound <- Sound$new("test.wav")
  spectrum <- sound$to_spectrum(fast = TRUE)
  
  cog <- spectrum$get_centre_of_gravity(power = 2.0)
  
  expect_type(cog, "double")
  expect_gt(cog, 0)
  
  fmax <- spectrum$get_highest_frequency()
  expect_lt(cog, fmax)
})

test_that("Spectrum R6 moments work", {
  skip_if_not(file.exists("test.wav"), "Test audio file not available")
  
  sound <- Sound$new("test.wav")
  spectrum <- sound$to_spectrum(fast = TRUE)
  
  std_dev <- spectrum$get_standard_deviation(power = 2.0)
  skewness <- spectrum$get_skewness(power = 2.0)
  kurtosis <- spectrum$get_kurtosis(power = 2.0)
  
  expect_type(std_dev, "double")
  expect_type(skewness, "double")
  expect_type(kurtosis, "double")
  
  expect_gte(std_dev, 0)  # Standard deviation is non-negative
})

test_that("Spectrum R6 band properties work", {
  skip_if_not(file.exists("test.wav"), "Test audio file not available")
  
  sound <- Sound$new("test.wav")
  spectrum <- sound$to_spectrum(fast = TRUE)
  
  # Get band energy
  band_energy <- spectrum$get_band_energy(
    fmin = 100, fmax = 1000
  )
  
  expect_type(band_energy, "double")
  expect_gte(band_energy, 0)
})

test_that("Spectrum R6 conversion to Ltas works", {
  skip_if_not(file.exists("test.wav"), "Test audio file not available")
  
  sound <- Sound$new("test.wav")
  spectrum <- sound$to_spectrum(fast = TRUE)
  
  ltas <- spectrum$to_ltas()
  
  expect_s3_class(ltas, "Ltas")
})

test_that("Spectrum R6 get bin number from frequency works", {
  skip_if_not(file.exists("test.wav"), "Test audio file not available")
  
  sound <- Sound$new("test.wav")
  spectrum <- sound$to_spectrum(fast = TRUE)
  
  # Get bin for 1000 Hz
  bin <- spectrum$get_bin_number_from_frequency(frequency = 1000)
  
  expect_type(bin, "double")
  expect_gt(bin, 0)
})

test_that("Spectrum R6 get frequency from bin works", {
  skip_if_not(file.exists("test.wav"), "Test audio file not available")
  
  sound <- Sound$new("test.wav")
  spectrum <- sound$to_spectrum(fast = TRUE)
  
  # Get frequency for bin 10
  freq <- spectrum$get_frequency_from_bin(bin = 10)
  
  expect_type(freq, "double")
  expect_gte(freq, 0)
})

test_that("Spectrum R6 filtering works", {
  skip_if_not(file.exists("test.wav"), "Test audio file not available")
  
  sound <- Sound$new("test.wav")
  spectrum <- sound$to_spectrum(fast = TRUE)
  
  # Filter spectrum
  filtered <- spectrum$filter(from_frequency = 100, to_frequency = 3000, smooth_width = 100)
  
  expect_s3_class(filtered, "Spectrum")
})
