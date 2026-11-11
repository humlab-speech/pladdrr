# Point-based tier statistics and the amplitude of a tier curve. The existing
# tier tests cover get_mean()/get_standard_deviation(); these cover the
# point-based variants and the DurationTier/IntensityTier mean.

test_that("PitchTier point statistics match the point values", {
  tier <- PitchTier(0, 1)
  tier$add_point(0.2, 100)
  tier$add_point(0.5, 150)
  tier$add_point(0.8, 200)

  heights <- c(100, 150, 200)
  expect_equal(tier$get_mean_points(0, 1), mean(heights), tolerance = 1e-12)
  expect_equal(
    tier$get_standard_deviation_points(0, 1),
    sd(heights),
    tolerance = 1e-12
  )
  expect_equal(tier$get_area(0, 1), 150, tolerance = 1e-9)

  point_process <- tier$down_to_point_process()
  expect_s3_class(point_process, "PointProcess")
  expect_equal(point_process$get_number_of_points(), 3)
})

test_that("DurationTier and IntensityTier get_mean integrate the curve", {
  duration <- DurationTier(0, 1)
  duration$add_point(0.25, 1.0)
  duration$add_point(0.75, 3.0)
  expect_equal(duration$get_mean(0, 1), 2, tolerance = 1e-9)

  intensity <- IntensityTier(0, 1)
  intensity$add_point(0.25, 60)
  intensity$add_point(0.75, 80)
  expect_equal(intensity$get_mean(0, 1), 70, tolerance = 1e-9)
})
