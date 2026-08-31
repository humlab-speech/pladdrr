# Regression test for the column-major/row-major memcpy bug in
# sound_create_from_values (src/sound_wrappers.cpp): a multi-channel
# NumericMatrix is stored column-major by R, so channel rows are not
# contiguous -- a raw memcpy silently interleaved channel data.

test_that(
  "Sound$from_values preserves per-channel data for multi-channel input", {
  n_samples <- 100
  ch1 <- sin(2 * pi * 5 * seq(0, 1, length.out = n_samples))
  ch2 <- cos(2 * pi * 5 * seq(0, 1, length.out = n_samples))
  values <- rbind(ch1, ch2)

  sound <- Sound$from_values(values, sampling_rate = n_samples)

  expect_identical(sound$get_number_of_channels(), 2L)
  expect_equal(sound$get_values(1), ch1, tolerance = 1e-10)
  expect_equal(sound$get_values(2), ch2, tolerance = 1e-10)
})

test_that("Sound$from_values preserves per-channel data for 4+ channels", {
  n_samples <- 50
  values <- rbind(
    rep(1, n_samples),
    rep(2, n_samples),
    seq_len(n_samples) / n_samples,
    -seq_len(n_samples) / n_samples
  )

  sound <- Sound$from_values(values, sampling_rate = n_samples)

  expect_identical(sound$get_number_of_channels(), 4L)
  for (ch in 1:4) {
    expect_equal(sound$get_values(ch), values[ch, ], tolerance = 1e-10)
  }
})
