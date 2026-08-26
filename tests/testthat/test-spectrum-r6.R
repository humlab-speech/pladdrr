test_wav <- system.file("extdata", "test.wav", package = "pladdrr")

test_that("Spectrum R6 creation from Sound works", {
  skip_if_not(file.exists(test_wav), "Test audio file not available")
  
  sound <- Sound$new(test_wav)
  spectrum <- sound$to_spectrum(fast = TRUE)
  
  expect_s3_class(spectrum, "Spectrum")
})

test_that("Spectrum R6 frequency queries work", {
  skip_if_not(file.exists(test_wav), "Test audio file not available")
  
  sound <- Sound$new(test_wav)
  spectrum <- sound$to_spectrum(fast = TRUE)
  
  fmin <- spectrum$get_lowest_frequency()
  fmax <- spectrum$get_highest_frequency()
  
  expect_type(fmin, "double")
  expect_type(fmax, "double")
  expect_gt(fmax, fmin)
  expect_equal(fmin, 0.0)  # Should start at 0 Hz
})

test_that("Spectrum R6 centre of gravity works", {
  skip_if_not(file.exists(test_wav), "Test audio file not available")
  
  sound <- Sound$new(test_wav)
  spectrum <- sound$to_spectrum(fast = TRUE)
  
  cog <- spectrum$get_centre_of_gravity(power = 2.0)
  
  expect_type(cog, "double")
  expect_gt(cog, 0)
  
  fmax <- spectrum$get_highest_frequency()
  expect_lt(cog, fmax)
})

test_that("Spectrum R6 moments work", {
  skip_if_not(file.exists(test_wav), "Test audio file not available")
  
  sound <- Sound$new(test_wav)
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
  skip_if_not(file.exists(test_wav), "Test audio file not available")
  
  sound <- Sound$new(test_wav)
  spectrum <- sound$to_spectrum(fast = TRUE)
  
  # Get band energy
  band_energy <- spectrum$get_band_energy(
    fmin = 100, fmax = 1000
  )
  
  expect_type(band_energy, "double")
  expect_gte(band_energy, 0)
})

test_that("Spectrum R6 conversion to Ltas works", {
  skip_if_not(file.exists(test_wav), "Test audio file not available")
  
  sound <- Sound$new(test_wav)
  spectrum <- sound$to_spectrum(fast = TRUE)
  
  ltas <- spectrum$to_ltas()
  
  expect_s3_class(ltas, "Ltas")
})

test_that("Spectrum R6 get bin number from frequency works", {
  skip_if_not(file.exists(test_wav), "Test audio file not available")
  
  sound <- Sound$new(test_wav)
  spectrum <- sound$to_spectrum(fast = TRUE)
  
  # Get bin for 1000 Hz
  bin <- spectrum$get_bin_from_frequency(frequency = 1000)

  # Praat's "Get bin number from frequency" is Sampled_xToIndex, which returns a
  # REAL (fractional) bin index, not an integer - 1 + (f - x1)/dx. Expecting an
  # integer here was a test bug, not an implementation bug.
  expect_type(bin, "double")
  expect_gt(bin, 0)
})

test_that("Spectrum R6 get frequency from bin works", {
  skip_if_not(file.exists(test_wav), "Test audio file not available")
  
  sound <- Sound$new(test_wav)
  spectrum <- sound$to_spectrum(fast = TRUE)
  
  # Get frequency for bin 10
  freq <- spectrum$get_frequency_from_bin(bin = 10)
  
  expect_type(freq, "double")
  expect_gte(freq, 0)
})

test_that("Spectrum R6 filtering works", {
  skip_if_not(file.exists(test_wav), "Test audio file not available")
  
  sound <- Sound$new(test_wav)
  spectrum <- sound$to_spectrum(fast = TRUE)
  
  # Filter spectrum
  filtered <- spectrum$pass_hann_band(fmin = 100, fmax = 3000, smooth = 100)

  expect_s3_class(filtered, "Spectrum")
})

test_that("Spectrum R6 get_frequency_step works", {
  skip_if_not(file.exists(test_wav), "Test audio file not available")

  sound <- Sound$new(test_wav)
  spectrum <- sound$to_spectrum(fast = TRUE)

  df <- spectrum$get_frequency_step()

  expect_type(df, "double")
  expect_gt(df, 0)
})

test_that("Spectrum R6 get_real_value_in_bin and get_imaginary_value_in_bin work", {
  skip_if_not(file.exists(test_wav), "Test audio file not available")

  sound <- Sound$new(test_wav)
  spectrum <- sound$to_spectrum(fast = TRUE)

  re <- spectrum$get_real_value_in_bin(bin = 1)
  im <- spectrum$get_imaginary_value_in_bin(bin = 1)

  expect_type(re, "double")
  expect_type(im, "double")

  n_bins <- spectrum$get_number_of_bins()
  expect_error(spectrum$get_real_value_in_bin(bin = n_bins + 100), "out of range")
  expect_error(spectrum$get_imaginary_value_in_bin(bin = 0), "out of range")
})

test_that("Spectrum R6 get_band_density works", {
  skip_if_not(file.exists(test_wav), "Test audio file not available")

  sound <- Sound$new(test_wav)
  spectrum <- sound$to_spectrum(fast = TRUE)

  density <- spectrum$get_band_density(fmin = 100, fmax = 1000)

  expect_type(density, "double")
})

test_that("Spectrum R6 get_central_moment works", {
  skip_if_not(file.exists(test_wav), "Test audio file not available")

  sound <- Sound$new(test_wav)
  spectrum <- sound$to_spectrum(fast = TRUE)

  cm <- spectrum$get_central_moment(moment = 2, power = 2.0)

  expect_type(cm, "double")
})

test_that("Spectrum R6 to_sound converts back to a Sound", {
  skip_if_not(file.exists(test_wav), "Test audio file not available")

  sound <- Sound$new(test_wav)
  spectrum <- sound$to_spectrum(fast = TRUE)

  resynth <- spectrum$to_sound()

  expect_s3_class(resynth, "Sound")
})

test_that("Spectrum R6 to_cepstrum works", {
  skip_if_not(file.exists(test_wav), "Test audio file not available")

  sound <- Sound$new(test_wav)
  spectrum <- sound$to_spectrum(fast = TRUE)

  cepstrum <- spectrum$to_cepstrum()

  expect_s3_class(cepstrum, "Cepstrum")
})

test_that("Spectrum R6 formula applies a valid formula and errors on an invalid one", {
  skip_if_not(file.exists(test_wav), "Test audio file not available")

  sound <- Sound$new(test_wav)
  spectrum <- sound$to_spectrum(fast = TRUE)

  before <- spectrum$get_real_value_in_bin(bin = 1)
  result <- spectrum$formula("self * 2")
  after <- spectrum$get_real_value_in_bin(bin = 1)

  expect_s3_class(result, "Spectrum")
  expect_equal(after, before * 2, tolerance = 1e-6)

  # Syntax error in the formula is a real, guarded-against user mistake: caught
  # by Melder and converted to an R error (spectrum_wrappers.cpp try/catch),
  # not a crash.
  spectrum2 <- sound$to_spectrum(fast = TRUE)
  expect_error(spectrum2$formula("this is not a valid formula ((("))
})

test_that("Spectrum R6 apply_pre_emphasis scales bins above the cutoff", {
  skip_if_not(file.exists(test_wav), "Test audio file not available")

  sound <- Sound$new(test_wav)
  spectrum <- sound$to_spectrum(fast = TRUE)

  result <- spectrum$apply_pre_emphasis(from_frequency = 50)

  expect_s3_class(result, "Spectrum")
})

test_that("Spectrum R6 multiply_by_frequency scales bins by frequency", {
  skip_if_not(file.exists(test_wav), "Test audio file not available")

  sound <- Sound$new(test_wav)
  spectrum <- sound$to_spectrum(fast = TRUE)

  result <- spectrum$multiply_by_frequency(power = 1.0)

  expect_s3_class(result, "Spectrum")
})

test_that("Spectrum R6 shift_frequencies returns a new shifted Spectrum", {
  skip_if_not(file.exists(test_wav), "Test audio file not available")

  sound <- Sound$new(test_wav)
  spectrum <- sound$to_spectrum(fast = TRUE)

  shifted <- spectrum$shift_frequencies(shift_by = 100)

  expect_s3_class(shifted, "Spectrum")
  expect_false(identical(shifted$.xptr, spectrum$.xptr))
})

test_that("Spectrum R6 print and is_valid work", {
  skip_if_not(file.exists(test_wav), "Test audio file not available")

  sound <- Sound$new(test_wav)
  spectrum <- sound$to_spectrum(fast = TRUE)

  expect_true(spectrum$is_valid())

  output <- capture.output(spectrum$print())
  expect_true(any(grepl("Praat Spectrum", output, fixed = TRUE)))
  expect_true(any(grepl("Frequency range", output, fixed = TRUE)))
  expect_true(any(grepl("Number of bins", output, fixed = TRUE)))
  expect_true(any(grepl("Frequency step", output, fixed = TRUE)))

  # print.Spectrum S3 dispatch
  output2 <- capture.output(print(spectrum))
  expect_true(any(grepl("Praat Spectrum", output2, fixed = TRUE)))
})

test_that("Spectrum R6 get_band_densities and get_power_at_frequencies batch ops work", {
  skip_if_not(file.exists(test_wav), "Test audio file not available")

  sound <- Sound$new(test_wav)
  spectrum <- sound$to_spectrum(fast = TRUE)

  densities <- spectrum$get_band_densities(fmins = c(100, 500), fmaxs = c(500, 1000))
  expect_type(densities, "double")
  expect_length(densities, 2)

  fmax <- spectrum$get_highest_frequency()
  powers <- spectrum$get_power_at_frequencies(frequencies = c(500, fmax + 10000))
  expect_type(powers, "double")
  expect_length(powers, 2)
  expect_false(is.na(powers[1]))
  expect_true(is.na(powers[2]))  # frequency beyond fmax hits the NA branch

  # Mismatched-length fmins/fmaxs is a real, guarded-against user mistake
  # (Rcpp::stop in spectrum_module.cpp), not a crash.
  expect_error(spectrum$get_band_densities(fmins = c(100, 500), fmaxs = c(500)))
  expect_error(spectrum$get_band_energies(fmins = c(100, 500), fmaxs = c(500)))
})
