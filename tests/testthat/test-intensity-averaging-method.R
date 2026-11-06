# tests/testthat/test-intensity-averaging-method.R
# F-api-01 / F-faith-01: the averaging_method strings must land on Praat's
# Intensity_averaging enum (fon/Intensity.h:64-67: MEDIAN=0, ENERGY=1, SONES=2,
# DB=3), not one code lower, and an unknown string must error instead of
# silently falling back to the median.
#
# The fixture is level-stepped (0.2 -> 1.0 at t = 1.5 s) on purpose: on steady
# material all four averages coincide to ~1e-9 dB, which is why the stationary
# inst/extdata/test.wav row in faithfulness/routines.R never caught the shift.

intensity_stepped_fixture <- function() {
  samplingRate <- 16000L
  time <- seq(0, 3 - 1 / samplingRate, length.out = 3 * samplingRate)
  signal <- ifelse(time < 1.5, 0.2, 1.0) * sin(2 * pi * 200 * time)
  Sound$from_values(signal, samplingRate)$to_intensity(
    minimum_pitch = 100, time_step = 0)
}

test_that("get_mean averages in the unit the averaging_method string names", {
  it <- intensity_stepped_fixture()
  z <- it$get_values_vector()
  expect_gte(length(z), 100L)

  # Praat's own conversions, structIntensity :: v_convertStandardToSpecialUnit /
  # v_convertSpecialToStandardUnit (fon/Intensity.cpp:34-50): energy = 10^(z/10),
  # sones = 2^(z/10), dB passthrough; MEDIAN is the 0.5 quantile of the contour
  # (Intensity_getAverage, fon/Intensity.cpp:117-122).
  expect_equal(it$get_mean(averaging_method = "median"), median(z),
    tolerance = 1e-9)
  expect_equal(it$get_mean(averaging_method = "energy"),
    10 * log10(mean(10^(z / 10))), tolerance = 1e-9)
  expect_equal(it$get_mean(averaging_method = "sones"),
    10 * log2(mean(2^(z / 10))), tolerance = 1e-9)
  expect_equal(it$get_mean(averaging_method = "db"), mean(z),
    tolerance = 1e-9)

  # The four statistics are distinct here; if they were not, the rows above
  # would not pin down the enum.
  four <- vapply(c("median", "energy", "sones", "db"),
    function(m) it$get_mean(averaging_method = m), 0)
  expect_equal(length(unique(round(four, 6))), 4L)
})

test_that("averaging_method is case-insensitive and defaults to energy", {
  it <- intensity_stepped_fixture()
  energy <- it$get_mean(averaging_method = "energy")
  expect_equal(it$get_mean(), energy, tolerance = 0)
  expect_equal(it$get_mean(averaging_method = "ENERGY"), energy, tolerance = 0)
  expect_equal(it$get_mean(averaging_method = "dB"),
    it$get_mean(averaging_method = "db"), tolerance = 0)
})

test_that("the documented default is no longer Praat's code 0 (MEDIAN)", {
  it <- intensity_stepped_fixture()
  # Raw code 0 is MEDIAN in Praat's enum; $get_mean() promises "energy", so the
  # two must differ on stepped material. This is exactly the pre-fix behaviour.
  expect_false(isTRUE(all.equal(it$get_mean(), it$.cpp$get_mean(0, 0, 0L))))
  expect_equal(it$get_mean(averaging_method = "energy"),
    it$.cpp$get_mean(0, 0, 1L), tolerance = 0)
  expect_equal(it$get_mean(averaging_method = "sones"),
    it$.cpp$get_mean(0, 0, 2L), tolerance = 0)
  expect_equal(it$get_mean(averaging_method = "db"),
    it$.cpp$get_mean(0, 0, 3L), tolerance = 0)
})

test_that("an unknown averaging_method errors, naming the accepted strings", {
  it <- intensity_stepped_fixture()
  expect_error(it$get_mean(averaging_method = "bogus"), "energy")
  expect_error(it$get_mean(averaging_method = NA_character_), "energy")
  expect_error(it$get_mean(averaging_method = "median_is_not_a_choice"),
    "energy")
})

test_that("get_statistics()'s \"mean\" and print()'s line report the same number as get_mean()", {
  # Review round on F-api-01: the enum fix left these two hard-coded to Praat
  # code 0 (the median), so they disagreed with get_mean() by 0.39 dB on
  # stepped material -- a number labelled "mean" that no Praat average
  # produces (the oracle's legacy two-argument `Intensity: Get mean: from, to`
  # is the plain dB mean: measured 84.0088749372 dB on this fixture = mean(z),
  # fon/praat_uvafon_init.cpp:827-835 + Intensity.cpp:34-40).
  it <- intensity_stepped_fixture()
  z <- it$get_values_vector()
  energy <- 10 * log10(mean(10^(z / 10)))

  expect_equal(it$get_statistics(metrics = "mean")$mean, energy,
    tolerance = 1e-9)
  expect_equal(it$get_mean(), energy, tolerance = 1e-9)
  expect_output(print(it),
    sprintf("Mean intensity: %.2f dB", energy), fixed = TRUE)

  # "median" stays the 0.5 quantile, so nothing was lost by moving "mean"
  expect_equal(it$get_statistics(metrics = "median")$median, median(z),
    tolerance = 1e-9)
})
