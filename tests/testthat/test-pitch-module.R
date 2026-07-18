# test-pitch-module.R - Tests for RPitch Rcpp Module (pladdrr 2.0)
library(data.table)

# Skip all tests if module boot function not registered
# (requires manual RcppExports.cpp patch after compileAttributes)
skip_if_no_pitch_module <- function() {
  tryCatch({
    mod <- Rcpp::Module("pitch_module", PACKAGE = "pladdrr")
    mod$RPitch  # This triggers full initialization
    TRUE
  }, error = function(e) {
    skip("RPitch module not available (RcppExports.cpp needs patching)")
  })
}

# Helper to get RPitch from R6 Pitch
get_rpitch <- function(pitch_r6) {
  mod <- Rcpp::Module("pitch_module", PACKAGE = "pladdrr")
  pitch_xptr <- pitch_r6$.xptr
  new(mod$RPitch, pitch_xptr)
}

test_that("RPitch module loads correctly", {
  skip_if_no_pitch_module()

  mod <- Rcpp::Module("pitch_module", PACKAGE = "pladdrr")
  expect_s4_class(mod, "Module")
  expect_false(is.null(mod$RPitch))
  expect_s4_class(mod$RPitch, "C++Class")
})

test_that("RPitch can be constructed from XPtr", {
  skip_if_no_pitch_module()
  snd <- Sound$new(system.file("extdata", "test.wav", package = "pladdrr"))
  pitch_r6 <- snd$to_pitch()

  rpitch <- get_rpitch(pitch_r6)
  expect_true(rpitch$is_valid())
})

test_that("RPitch property methods work", {
  skip_if_no_pitch_module()
  snd <- Sound$new(system.file("extdata", "test.wav", package = "pladdrr"))
  pitch_r6 <- snd$to_pitch()
  rpitch <- get_rpitch(pitch_r6)

  # Time domain properties
  expect_equal(rpitch$get_xmin(), 0)
  expect_equal(rpitch$get_xmax(), 1)
  expect_equal(rpitch$get_duration(), 1)

  # Frame properties
  expect_gt(rpitch$get_nx(), 0)
  expect_gt(rpitch$get_dx(), 0)
  expect_gt(rpitch$get_x1(), 0)

  # Pitch-specific
  expect_equal(rpitch$get_ceiling(), 600)  # default ceiling

  # Aliases
  expect_equal(rpitch$get_number_of_frames(), rpitch$get_nx())
  expect_equal(rpitch$get_time_step(), rpitch$get_dx())
})

test_that("RPitch frame/time conversion works", {
  skip_if_no_pitch_module()
  snd <- Sound$new(system.file("extdata", "test.wav", package = "pladdrr"))
  pitch_r6 <- snd$to_pitch()
  rpitch <- get_rpitch(pitch_r6)

  # Frame to time
  t50 <- rpitch$get_time_from_frame(50)
  expect_type(t50, "double")
  expect_gt(t50, 0)
  expect_lt(t50, 1)

  # Time to frame (round-trip)
  f <- rpitch$get_frame_from_time(t50)
  expect_equal(f, 50, tolerance = 1)
})

test_that("RPitch query methods return correct values for sine wave", {
  skip_if_no_pitch_module()
  # test.wav is a 440 Hz sine wave
  snd <- Sound$new(system.file("extdata", "test.wav", package = "pladdrr"))
  pitch_r6 <- snd$to_pitch()
  rpitch <- get_rpitch(pitch_r6)

  # Mean should be ~440 Hz
  mean_f0 <- rpitch$get_mean(0, 0, 0)  # (from, to, unit) - 0=Hz
  expect_equal(mean_f0, 440, tolerance = 1)

  # Std dev should be very small for pure tone
  sd_f0 <- rpitch$get_standard_deviation(0, 0, 0)
  expect_lt(sd_f0, 0.1)

  # Min/max should be ~440 Hz
  expect_equal(rpitch$get_minimum(0, 0, 0, FALSE), 440, tolerance = 1)
  expect_equal(rpitch$get_maximum(0, 0, 0, FALSE), 440, tolerance = 1)

  # Median (quantile 0.5) should be ~440 Hz
  expect_equal(rpitch$get_quantile(0, 0, 0.5, 0), 440, tolerance = 1)

  # All frames should be voiced
  expect_equal(rpitch$count_voiced_frames(), rpitch$get_nx())
})

test_that("RPitch get_value_at_time works", {
  skip_if_no_pitch_module()
  snd <- Sound$new(system.file("extdata", "test.wav", package = "pladdrr"))
  pitch_r6 <- snd$to_pitch()
  rpitch <- get_rpitch(pitch_r6)

  # Get value at middle of file
  f0 <- rpitch$get_value_at_time(0.5, 0, FALSE)  # (time, unit, interpolate)
  expect_equal(f0, 440, tolerance = 1)

  # Test different units
  f0_hz <- rpitch$get_value_at_time(0.5, 0, FALSE)
  f0_st <- rpitch$get_value_at_time(0.5, 4, FALSE)  # semitones re 100 Hz

  # Semitones = 12 * log2(f0 / 100)
  expected_st <- 12 * log2(440 / 100)
  expect_equal(f0_st, expected_st, tolerance = 0.1)
})

test_that("RPitch strength methods work", {
  skip_if_no_pitch_module()
  snd <- Sound$new(system.file("extdata", "test.wav", package = "pladdrr"))
  pitch_r6 <- snd$to_pitch()
  rpitch <- get_rpitch(pitch_r6)

  # Pure tone should have high strength (autocorrelation near 1)
  strength <- rpitch$get_strength_at_time(0.5, 0, FALSE)
  expect_gt(strength, 0.9)

  mean_strength <- rpitch$get_mean_strength(0, 0, 0)
  expect_gt(mean_strength, 0.9)
})

test_that("RPitch as_data_frame exports correctly", {
  skip_if_no_pitch_module()
  snd <- Sound$new(system.file("extdata", "test.wav", package = "pladdrr"))
  pitch_r6 <- snd$to_pitch()
  rpitch <- get_rpitch(pitch_r6)

  # Basic export
  df <- rpitch$as_data_frame(TRUE, FALSE)
  expect_s3_class(df, "data.frame")
  expect_s3_class(df, "data.table")
  expect_true("time" %in% names(df))
  expect_true("frequency" %in% names(df))
  expect_true("voiced" %in% names(df))
  expect_equal(nrow(df), rpitch$get_nx())

  # Check values
  expect_true(all(df$frequency > 400 & df$frequency < 480))  # ~440 Hz
  expect_true(all(df$voiced))  # All frames voiced for pure tone
})

test_that("RPitch as_matrix exports correctly", {
  skip_if_no_pitch_module()
  snd <- Sound$new(system.file("extdata", "test.wav", package = "pladdrr"))
  pitch_r6 <- snd$to_pitch()
  rpitch <- get_rpitch(pitch_r6)

  mat <- rpitch$as_matrix()
  expect_true(is.matrix(mat))
  expect_equal(nrow(mat), rpitch$get_nx())
  expect_equal(ncol(mat), 2)  # time, frequency
})

test_that("RPitch get_all_candidates returns list", {
  skip_if_no_pitch_module()
  snd <- Sound$new(system.file("extdata", "test.wav", package = "pladdrr"))
  pitch_r6 <- snd$to_pitch()
  rpitch <- get_rpitch(pitch_r6)

  cands <- rpitch$get_all_candidates()
  expect_type(cands, "list")
  # First candidate should have frequency ~440 Hz
  if (length(cands) > 0 && length(cands[[1]]) > 0) {
    expect_equal(cands[[1]][[1]]$frequency, 440, tolerance = 1)
  }
})

test_that("RPitch conversion methods return valid XPtrs", {
  skip_if_no_pitch_module()
  snd <- Sound$new(system.file("extdata", "test.wav", package = "pladdrr"))
  pitch_r6 <- snd$to_pitch()
  rpitch <- get_rpitch(pitch_r6)

  # to_point_process_ptr
  pp_ptr <- rpitch$to_point_process_ptr()
  expect_s4_class(pp_ptr, "externalptr")

  # down_to_pitch_tier_ptr
  pt_ptr <- rpitch$down_to_pitch_tier_ptr()
  expect_s4_class(pt_ptr, "externalptr")

  # to_textgrid_vuv_ptr
  tg_ptr <- rpitch$to_textgrid_vuv_ptr()
  expect_s4_class(tg_ptr, "externalptr")
})

test_that("RPitch matches R6 Pitch values", {
  skip_if_no_pitch_module()
  snd <- Sound$new(system.file("extdata", "test.wav", package = "pladdrr"))
  pitch_r6 <- snd$to_pitch()
  rpitch <- get_rpitch(pitch_r6)

  # Compare key properties
  expect_equal(rpitch$get_nx(), pitch_r6$get_number_of_frames())
  expect_equal(rpitch$count_voiced_frames(), pitch_r6$count_voiced_frames())

  # Compare query results
  r6_mean <- pitch_r6$get_mean(0, 0, 0)
  mod_mean <- rpitch$get_mean(0, 0, 0)
  expect_equal(mod_mean, r6_mean, tolerance = 1e-10)
})
