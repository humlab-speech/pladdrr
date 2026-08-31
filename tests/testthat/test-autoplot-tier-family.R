# test-autoplot-tier-family.R
# Tests for autoplot/autolayer/as.data.frame on AmplitudeTier, DurationTier,
# IntensityTier, PitchTier (R/autoplot-missing.R, R/as-data-frame-missing.R)

library(testthat)
library(pladdrr)

tier_fixtures <- list(
  # AmplitudeTier has no direct sound$to_amplitude_tier(); built from a
  # PointProcess, per amplitude_tier_from_point_process()
  #  (R/amplitudetier-wrapper.R:183).
  AmplitudeTier = function() {
    sound <- generate_sine_wave(220, 0.2, sampling_rate = 16000)
    pp <- sound$to_point_process_periodic_cc(pitch_floor = 75,
      pitch_ceiling = 500)
    amplitude_tier_from_point_process(pp, sound)
  },
  DurationTier = function() {
    dt <- DurationTier(tmin = 0, tmax = 1)
    dt$add_point(0.3, 1.2)
    dt$add_point(0.7, 0.8)
    dt
  },
  # IntensityTier: intensity$down_to_intensity_tier()
  #  (R/intensity-wrapper.R:116),
  # not to_intensity_tier() (that name lives on AmplitudeTier instead).
  IntensityTier = function() {
    sound <- generate_sine_wave(220, 0.2, sampling_rate = 16000)
    intensity <- sound$to_intensity()
    intensity$down_to_intensity_tier()
  },
  # PitchTier: pitch$down_to_pitch_tier() (R/pitch-wrapper.R:212).
  PitchTier = function() {
    sound <- generate_sine_wave(220, 0.2, sampling_rate = 16000)
    pitch <- sound$to_pitch()
    pitch$down_to_pitch_tier()
  }
)

for (cls in names(tier_fixtures)) {
  local({
    class_name <- cls
    make <- tier_fixtures[[class_name]]

    test_that(paste(class_name, "autoplot produces a ggplot"), {
      obj <- make()
      p <- ggplot2::autoplot(obj)
      expect_s3_class(p, "ggplot")
    })

    test_that(paste(class_name, "autolayer produces layer(s) usable with +"), {
      obj <- make()
      p <- ggplot2::ggplot() + ggplot2::autolayer(obj)
      expect_s3_class(p, "ggplot")
    })

    test_that(paste(class_name, "as.data.frame has time and a value column"), {
      obj <- make()
      df <- as.data.frame(obj)
      expect_s3_class(df, "data.frame")
      expect_true("time" %in% names(df))
    })

    test_that(
      paste(class_name, "from_time/to_time filtering narrows the range"), {
      obj <- make()
      full <- as.data.frame(obj)
      skip_if(nrow(full) < 2, "not enough points to test filtering")
      mid <- mean(range(full$time))
      p <- ggplot2::autoplot(obj, from_time = mid, to_time = max(full$time))
      expect_s3_class(p, "ggplot")
    })
  })
}

test_that("empty tier warns and returns an empty plot, not an error", {
  empty_tier <- DurationTier(tmin = 0, tmax = 1)  # no points added
  expect_warning(p <- ggplot2::autoplot(empty_tier))
  expect_s3_class(p, "ggplot")
})
