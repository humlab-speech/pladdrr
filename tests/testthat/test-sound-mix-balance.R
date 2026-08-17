# Regression test: balance = -1.0 zeroed the (1 + balance) normalizer in
# sound_mix()/sound_mix_simd(), producing silent Inf/NaN output instead of
# an error (src/sound_wrappers.cpp, src/sound_mixing_simd.cpp).

test_that("Sound$mix() rejects balance = -1.0 instead of producing Inf/NaN", {
  s1 <- Sound$create_tone(frequency = 440, duration = 0.1, sampling_rate = 8000)
  s2 <- Sound$create_tone(frequency = 880, duration = 0.1, sampling_rate = 8000)

  expect_error(s1$mix(s2, balance = -1.0))
})

test_that("Sound$mix() still works for ordinary balance values", {
  s1 <- Sound$create_tone(frequency = 440, duration = 0.1, sampling_rate = 8000)
  s2 <- Sound$create_tone(frequency = 880, duration = 0.1, sampling_rate = 8000)

  mixed <- s1$mix(s2, balance = 0.5)
  values <- mixed$get_values(1)

  expect_false(any(is.na(values)))
  expect_true(all(is.finite(values)))
})
