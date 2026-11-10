## Sizes that become allocations are validated before they reach Praat
## (F-cochleagram-input-validation, "negative-size doors"). Before:
##   sound_create_tone(duration = -2, sampling_rate = 8000)  -> a Sound, nx = -16000
##   Matrix(numberOfRows = -3, numberOfColumns = -4)         -> a corrupt Matrix
##   Excitation$to_formant(max_formants = -1)                -> a corrupt Formant
## and a huge request asked the allocator for terabytes (macOS: session killed).

expect_input_error <- function(expr, param) {
  cond <- tryCatch(expr, error = function(e) e)
  expect_s3_class(cond, "pladdrr_input_error")
  expect_identical(cond$param, param)
}

test_that("Sound factories refuse non-positive, non-finite and absurd sizes", {
  for (f in list(sound_create_tone, sound_create_pure_tone, sound_create_tone_complex)) {
    for (bad in list(-2, 0, NA_real_, Inf, NaN, "a", c(1, 2))) {
      expect_input_error(f(duration = bad), "duration")
      expect_input_error(f(sampling_rate = bad), "sampling_rate")
    }
    # 1e9 s at 44.1 kHz is 4.4e13 samples: refused, not attempted.
    expect_input_error(f(duration = 1e9), "duration")
  }
})

test_that("the cell budget counts channels", {
  # 1e7 samples is fine for one channel; 64 channels of it is 6.4e8 cells
  # (over the 2^29 limit, ~5 GB) and used to pass a guard that ignored channels.
  expect_input_error(
    sound_create_pure_tone(duration = 100, sampling_rate = 1e5, channels = 64),
    "channels")
  for (bad in list(0, -1, NA_real_, Inf, "a")) {
    expect_input_error(sound_create_pure_tone(channels = bad), "channels")
  }
  s <- sound_create_pure_tone(duration = 0.1, sampling_rate = 8000, channels = 2)
  expect_identical(s$get_number_of_channels(), 2L)
})

test_that("Sound factories still build ordinary sounds", {
  s <- sound_create_tone(duration = 0.5, sampling_rate = 8000)
  expect_identical(s$get_number_of_samples(), 4000L)
})

test_that("Matrix refuses non-positive and absurd dimensions", {
  expect_input_error(Matrix(numberOfRows = -3, numberOfColumns = -4), "numberOfRows")
  expect_input_error(Matrix(numberOfRows = 3, numberOfColumns = 0), "numberOfColumns")
  expect_input_error(Matrix(numberOfRows = NA_real_, numberOfColumns = 3), "numberOfRows")
  expect_input_error(Matrix(numberOfRows = 1e6, numberOfColumns = 1e6), "numberOfRows")
  expect_input_error(
    Matrix(xmin = 0, xmax = 1, nx = -5, dx = 0.1, x1 = 0, ymin = 0, ymax = 1,
      ny = 3, dy = 0.1, y1 = 0), "nx")
  expect_input_error(matrix_create_simple(-1, 2), "numberOfRows")
  m <- matrix_create_simple(3, 4)
  expect_identical(dim(as.matrix(m)), c(3L, 4L))
})

test_that("Sound$to_formant* refuse a non-positive or non-finite formant count", {
  ## max_formants = -1 used to segfault (address 0xfffffffffffffff0) in Burg/robust.
  s <- Sound$create_tone(frequency = 440, duration = 0.2, sampling_rate = 22050)
  doors <- list(
    function(x) s$to_formant(max_formants = x),
    function(x) s$to_formant_burg(max_formants = x),
    function(x) s$to_formant_robust(max_formants = x))
  for (door in doors) {
    for (bad in list(-1, 0, NA_real_, Inf, 1e9, "a")) {
      expect_input_error(door(bad), "max_formants")
    }
  }
  expect_s3_class(s$to_formant(max_formants = 5), "Formant")
  expect_s3_class(s$to_formant_robust(max_formants = 5), "Formant")
})

test_that(".check_positive_count refuses Inf", {
  expect_input_error(pladdrr:::.check_positive_count(Inf, "n"), "n")
  expect_true(pladdrr:::.check_positive_count(2e6, "n"))
})

test_that("Excitation$to_formant needs a positive formant count", {
  ex <- Sound$create_tone(frequency = 440, duration = 0.2, sampling_rate = 22050)$
    to_spectrum()$to_excitation()
  for (bad in list(-1, 0, NA_real_, "a")) {
    expect_input_error(ex$to_formant(max_formants = bad), "max_formants")
  }
  expect_s3_class(ex$to_formant(max_formants = 5), "Formant")
})
