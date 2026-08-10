# Regression tests for amplitudetier-wrapper.R conversion helpers.
#
# amplitude_tier_from_point_process() and intensity_tier_to_amplitude_tier()
# used to read `$.pointer` on Sound/PointProcess/IntensityTier objects, but
# those classes store the external pointer under `$.xptr`. The mismatch
# resolved silently to NULL and only surfaced as a NILSXP error deep in the
# C++ layer (caught by `R CMD check`'s example run, not by unit tests).

test_that("intensity_tier_to_amplitude_tier converts a populated IntensityTier", {
  it <- IntensityTier(0, 1)
  it$add_point(0.25, 70)
  it$add_point(0.75, 60)

  at <- intensity_tier_to_amplitude_tier(it)

  expect_s3_class(at, "AmplitudeTier")
  expect_equal(at$get_number_of_points(), 2)
})

test_that("amplitude_tier_from_point_process converts a Sound/PointProcess pair", {
  sound <- Sound$create_tone(frequency = 150, duration = 0.5, sampling_rate = 16000)
  pp <- sound$to_point_process_periodic_cc(75, 600)

  tier <- amplitude_tier_from_point_process(pp, sound)

  expect_s3_class(tier, "AmplitudeTier")
  expect_gt(tier$get_number_of_points(), 0)
})
