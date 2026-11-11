# Window-level Sound queries that only have R6 exposure (no dedicated tests):
# zero-crossing rate per window, the window pass/fail filter, and filtered
# window extraction.

test_that("get_zcr_windows reports a plausible rate per window", {
  sound <- Sound$create_tone(frequency = 200, duration = 0.3)

  zcr <- sound$get_zcr_windows(c(0, 0.1), c(0.1, 0.2))

  expect_type(zcr, "double")
  expect_length(zcr, 2)
  expect_true(all(is.finite(zcr)))
  # A 200 Hz sine crosses zero ~400 times per second.
  expect_true(all(abs(zcr - 400) / 400 < 0.1))
})

test_that("get_windows_passing_filter disables the ZCR gate with -1", {
  sound <- Sound$create_tone(frequency = 200, duration = 0.3)

  passing <- sound$get_windows_passing_filter(
    c(0, 0.1), c(0.1, 0.2), min_power = 0, max_zcr = -1
  )

  expect_type(passing, "logical")
  expect_length(passing, 2)
  expect_true(all(passing))
})

test_that("extract_windows_filtered returns the accepted windows", {
  sound <- Sound$create_tone(frequency = 200, duration = 0.3)

  extracted <- sound$extract_windows_filtered(c(0, 0.1), c(0.1, 0.2))

  expect_s3_class(extracted, "Sound")
  expect_equal(extracted$get_duration(), 0.2, tolerance = 1e-9)
  expect_equal(
    extracted$get_number_of_samples(),
    2 * 0.1 * extracted$get_sampling_frequency(),
    tolerance = 1
  )
})
