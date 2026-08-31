# tests/testthat/test-spectrogram-wrapper-gaps.R
# Coverage gap-fill for R/spectrogram-wrapper.R (was ~65%): geometry,
# frame/frequency conversion, power queries, and conversions.

sg_fixture <- function() {
  Sound$create_tone(frequency = 220, duration = 0.3,
    sampling_rate = 16000)$to_spectrogram()
}

test_that("Spectrogram geometry getters", {
  sg <- sg_fixture()
  expect_lte(sg$get_start_time(), sg$get_end_time())
  expect_gt(sg$get_time_step(), 0)
  expect_gte(sg$get_number_of_time_bins(), 1L)
  expect_lte(sg$get_lowest_frequency(), sg$get_highest_frequency())
  expect_gt(sg$get_frequency_step(), 0)
  expect_gte(sg$get_number_of_frequency_bins(), 1L)
})

test_that("Spectrogram frame/frequency conversion", {
  sg <- sg_fixture()
  t <- sg$get_start_time() + 0.05
  f <- sg$get_frame_from_time(t)
  expect_gte(f, 1L)
  expect_lte(f, sg$get_number_of_time_bins())
  t2 <- sg$get_time_from_frame(f)
  expect_type(t2, "double")
  b <- sg$get_bin_from_frequency(sg$get_lowest_frequency() + 10)
  expect_gte(b, 1L)
  f2 <- sg$get_frequency_from_bin(b)
  expect_type(f2, "double")
})

test_that("Spectrogram power queries", {
  sg <- sg_fixture()
  p <- sg$get_power_at(sg$get_start_time() + 0.05,
    sg$get_lowest_frequency() + 10)
  expect_type(p, "double")
  fr <- sg$get_frame(sg$get_start_time() + 0.05)
  expect_type(fr, "double")
  fs <- sg$get_frequency_slice(sg$get_lowest_frequency() + 10)
  expect_type(fs, "double")
  frs <- sg$get_frames(c(0.05, 0.1))
  expect_true(is.list(frs) || is.matrix(frs))
  bp <- sg$get_band_power(sg$get_lowest_frequency() + 10,
    sg$get_lowest_frequency() + 100)
  expect_type(bp, "double")
})

test_that("Spectrogram vectors and conversions", {
  sg <- sg_fixture()
  tv <- sg$get_times_vector()
  expect_type(tv, "double")
  fv <- sg$get_frequencies_vector()
  expect_type(fv, "double")
  pp <- sg$get_power_at_points(tv[seq_len(min(3, length(tv)))],
    rep(fv[1], min(3, length(tv))))
  expect_type(pp, "double")
  sm <- sg$get_spectral_moments_batch()
  expect_type(sm, "list")
  sp <- sg$to_spectrum(sg$get_start_time() + 0.05)
  expect_s3_class(sp, "Spectrum")
  m <- sg$as_matrix()
  expect_type(m, "double")
  expect_true(is.matrix(m))
})
