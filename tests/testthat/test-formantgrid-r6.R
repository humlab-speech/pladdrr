# Test FormantGrid R6 class
library(testthat)
library(pladdrr)

test_that("FormantGrid creation works", {
  # Create empty FormantGrid
  grid <- FormantGrid$new(tmin = 0, tmax = 1, number_of_formants = 5)
  
  expect_s3_class(grid, "FormantGrid")
  expect_s3_class(grid, "PraatObject")
  expect_equal(grid$get_start_time(), 0)
  expect_equal(grid$get_end_time(), 1)
  expect_equal(grid$get_number_of_formants(), 5)
})

test_that("FormantGrid with initial values works", {
  grid <- FormantGrid$new(
    tmin = 0, tmax = 1,
    number_of_formants = 3,
    initial_first_formant = 500,
    initial_formant_spacing = 1000,
    initial_first_bandwidth = 50,
    initial_bandwidth_spacing = 40
  )
  
  expect_s3_class(grid, "FormantGrid")
  expect_equal(grid$get_number_of_formants(), 3)
})

test_that("FormantGrid point addition works", {
  grid <- FormantGrid$new(tmin = 0, tmax = 1, number_of_formants = 3)
  
  # Add formant points
  result <- grid$add_formant_point(1, 0.5, 500)
  expect_identical(result, grid)  # Method chaining
  
  grid$add_formant_point(2, 0.5, 1500)
  grid$add_formant_point(3, 0.5, 2500)
  
  # Add bandwidth points
  grid$add_bandwidth_point(1, 0.5, 50)
  grid$add_bandwidth_point(2, 0.5, 70)
  grid$add_bandwidth_point(3, 0.5, 90)
  
  # Query values
  expect_equal(grid$get_formant_at_time(1, 0.5), 500)
  expect_equal(grid$get_formant_at_time(2, 0.5), 1500)
  expect_equal(grid$get_bandwidth_at_time(1, 0.5), 50)
})

test_that("FormantGrid point removal works", {
  grid <- FormantGrid$new(tmin = 0, tmax = 1, number_of_formants = 2)
  
  # Add multiple points
  grid$add_formant_point(1, 0.2, 500)
  grid$add_formant_point(1, 0.5, 550)
  grid$add_formant_point(1, 0.8, 600)
  
  # Remove points in middle
  grid$remove_formant_points_between(1, 0.3, 0.7)
  
  # First and last should still exist
  expect_equal(grid$get_formant_at_time(1, 0.2), 500)
  expect_equal(grid$get_formant_at_time(1, 0.8), 600)
})

test_that("FormantGrid to Formant conversion works", {
  grid <- FormantGrid$new(tmin = 0, tmax = 1, number_of_formants = 3)
  
  # Add some formant points
  grid$add_formant_point(1, 0.5, 500)
  grid$add_formant_point(2, 0.5, 1500)
  grid$add_bandwidth_point(1, 0.5, 50)
  
  # Convert to Formant
  formant <- grid$to_formant(time_step = 0.01)
  
  expect_s3_class(formant, "Formant")
  expect_true(formant$get_start_time() >= 0)
  expect_true(formant$get_end_time() <= 1)
})

test_that("FormantGrid synthesis works", {
  grid <- FormantGrid$new(tmin = 0, tmax = 1, number_of_formants = 5)
  
  # Add formant points for vowel /a/
  grid$add_formant_point(1, 0.5, 700)   # F1
  grid$add_formant_point(2, 0.5, 1220)  # F2
  grid$add_formant_point(3, 0.5, 2600)  # F3
  grid$add_bandwidth_point(1, 0.5, 60)
  grid$add_bandwidth_point(2, 0.5, 80)
  grid$add_bandwidth_point(3, 0.5, 120)
  
  # Synthesize sound
  sound <- grid$to_sound(
    sampling_frequency = 22050,
    f0_start = 100, f0_mid = 100, f0_end = 100
  )
  
  expect_s3_class(sound, "Sound")
  expect_equal(sound$get_sampling_frequency(), 22050)
  expect_true(sound$get_duration() > 0)
})

test_that("praat_formantgrid_create_empty works", {
  grid <- praat_formantgrid_create_empty(0, 1, 4)
  
  expect_s3_class(grid, "FormantGrid")
  expect_equal(grid$get_start_time(), 0)
  expect_equal(grid$get_end_time(), 1)
  expect_equal(grid$get_number_of_formants(), 4)
})

test_that("Sound FormantGrid filtering works", {
  skip_if_not(require("speaker", quietly = TRUE))
  
  # Create a simple sound
  sound <- Sound$new_tone_complex(0, 1, 44100, 100, 3, 0, 0)
  
  # Create FormantGrid
  grid <- FormantGrid$new(tmin = 0, tmax = 1, number_of_formants = 3)
  grid$add_formant_point(1, 0.5, 500)
  grid$add_formant_point(2, 0.5, 1500)
  grid$add_bandwidth_point(1, 0.5, 50)
  grid$add_bandwidth_point(2, 0.5, 70)
  
  # Filter sound
  filtered <- praat_sound_formantgrid_filter(sound, grid, scale = TRUE)
  
  expect_s3_class(filtered, "Sound")
  expect_equal(filtered$get_sampling_frequency(), 44100)
  expect_true(filtered$get_duration() > 0)
})

test_that("FormantGrid from Formant works", {
  skip_if_not(file.exists(test_path("testdata/test.wav")))
  
  # Create sound and extract formants
  sound <- Sound$new(test_path("testdata/test.wav"))
  formant <- sound$to_formant_burg()
  
  # Convert to FormantGrid
  formant_ptr <- formant$get_pointer()
  grid_ptr <- .formantgrid_from_formant(formant_ptr)
  grid <- FormantGrid$new(.xptr = grid_ptr)
  
  expect_s3_class(grid, "FormantGrid")
  expect_true(grid$get_number_of_formants() > 0)
})
