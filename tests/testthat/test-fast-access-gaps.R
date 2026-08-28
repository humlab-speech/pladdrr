# tests/testthat/test-fast-access-gaps.R
# Coverage gap-fill for R/fast-access.R (was ~54%): the fast/zerocopy
# sound-value accessors and the fast_vector/zerocopy_vector S3 classes.

sound_fixture <- function() {
  Sound$create_tone(frequency = 220, duration = 0.3, sampling_rate = 16000)
}

test_that("get_sound_values_fast / times_fast return vectors", {
  snd <- sound_fixture()
  v <- get_sound_values_fast(snd)
  expect_type(v, "double")
  expect_length(v, snd$get_number_of_samples())
  t <- get_sound_times_fast(snd)
  expect_type(t, "double")
  expect_length(t, length(v))
})

test_that("sound_as_matrix_fast returns a numeric matrix", {
  snd <- sound_fixture()
  m <- sound_as_matrix_fast(snd)
  expect_type(m, "double")
  expect_true(is.matrix(m))
  expect_equal(ncol(m), snd$get_number_of_channels())
})

test_that("fast_vector class and print", {
  snd <- sound_fixture()
  fv <- get_sound_values_fast(snd)
  expect_true(is_fast_vector(fv))
  expect_output(print(fv), "more values")
})

test_that("zerocopy accessors", {
  snd <- sound_fixture()
  v <- suppressWarnings(get_sound_values_zerocopy(snd))
  expect_type(v, "double")
  expect_true(is_zerocopy_vector(v))
  m <- suppressWarnings(sound_as_matrix_zerocopy(snd))
  expect_type(m, "double")
  expect_true(is.matrix(m))
  expect_output(print(v), "more values")
})
