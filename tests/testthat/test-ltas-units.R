# test-ltas-units.R - the Ltas averaging-unit contract, pinned.
#
# The old version of this file asserted only that a slope was negative, which
# the buggy build also satisfied -- it pinned nothing (11/11 on the pre-fix
# build). What is actually checkable without an oracle is the unit *enum* and
# the typed error:
#   "energy" = 1, "sones" = 2, "dB" = 3   (NOT 0: Praat's Ltas averaging CHOICE
#   has no MEDIAN, so its dB is the third option -- fon/praat_uvafon_init.cpp:1101-1105,
#   and fon/Ltas.cpp:87/:95 test averagingUnits == 3 for the dB branch)
# and that an unrecognised unit raises the classed pladdrr_input_error naming the
# routine that rejected it (F-faith-13 review round: four of the five queries
# used to report routine = "get_mean").
# The numeric equality against Praat lives in test-ltas-averaging-unit.R.

test_that("LTAS get_slope returns dB values, not ratios", {
  # Generate test tone
  sound <- Sound$create_tone(frequency = 440, duration = 0.5,
    sampling_rate = 16000)
  ltas <- sound$to_ltas(bandwidth = 100)

  # Test energy unit returns dB (negative value), not ratio (small positive)
  slope_energy <- ltas$get_slope(0, 1000, 1000, 10000, unit = "energy")

  # If returning ratio, would be ~0.1-1.0
  # If returning dB, should be negative ~-10 to -40
  expect_lt(slope_energy, 0,
              label = "energy unit should return dB (negative), not ratio")
  expect_gt(slope_energy, -100,
    label = "energy unit value should be reasonable dB")
})

test_that("LTAS get_slope dB unit matches energy unit", {
  sound <- Sound$create_tone(frequency = 440, duration = 0.5,
    sampling_rate = 16000)
  ltas <- sound$to_ltas(bandwidth = 100)

  slope_energy <- ltas$get_slope(0, 1000, 1000, 10000, unit = "energy")
  slope_db <- ltas$get_slope(0, 1000, 1000, 10000, unit = "dB")

  # Both should be in dB - energy uses 10*log10, dB is passthrough
  # For slope calculation they should be similar
  expect_type(slope_energy, "double")
  expect_type(slope_db, "double")
  expect_lt(slope_energy, 0)
  expect_lt(slope_db, 0)
})

test_that("LTAS get_slope sones unit returns dB values", {
  sound <- Sound$create_tone(frequency = 440, duration = 0.5,
    sampling_rate = 16000)
  ltas <- sound$to_ltas(bandwidth = 100)

  slope_sones <- ltas$get_slope(0, 1000, 1000, 10000, unit = "sones")

  # Sones uses log2 instead of log10, but should still return dB-scale values
  expect_type(slope_sones, "double")
  # Should be in dB range, not a ratio
  expect_true(is.finite(slope_sones))
  expect_lt(slope_sones, 50,
              label = "sones unit returns reasonable dB value")
})

test_that("LTAS get_mean respects unit parameter", {
  sound <- Sound$create_tone(frequency = 440, duration = 0.5,
    sampling_rate = 16000)
  ltas <- sound$to_ltas(bandwidth = 100)

  mean_energy <- ltas$get_mean(0, 0, unit = "energy")
  mean_db <- ltas$get_mean(0, 0, unit = "dB")

  expect_type(mean_energy, "double")
  expect_type(mean_db, "double")
})

test_that("the unit enum is Praat's, not one code low", {
  expect_identical(pladdrr:::.ltas_unit_code("dB"), 3L)
  expect_identical(pladdrr:::.ltas_unit_code("db"), 3L)
  expect_identical(pladdrr:::.ltas_unit_code("energy"), 1L)
  expect_identical(pladdrr:::.ltas_unit_code("sones"), 2L)
})

test_that("an unrecognised unit is a classed input error naming the query", {
  sound <- Sound$create_tone(frequency = 440, duration = 0.5,
    sampling_rate = 16000)
  ltas <- sound$to_ltas(bandwidth = 100)

  expect_error(ltas$get_mean(0, 0, unit = "furlong"), "energy",
    class = "pladdrr_input_error")
  expect_error(ltas$get_means_batch(c(0), c(1000), unit = "furlong"),
    class = "pladdrr_input_error")
  expect_error(ltas$get_standard_deviation(0, 0, unit = "furlong"),
    class = "pladdrr_input_error")

  e <- tryCatch(ltas$get_mean(0, 0, unit = "furlong"),
    pladdrr_input_error = function(e) e)
  expect_identical(e$routine, "get_mean")
  expect_identical(e$param, "unit")

  # the routine field must say which query refused, not always "get_mean"
  for (m in c("get_slope", "get_local_peak_height", "get_standard_deviation",
              "get_means_batch")) {
    err <- switch(m,
      get_slope = tryCatch(ltas$get_slope(0, 1000, 1000, 4000, unit = "furlong"),
        pladdrr_input_error = function(e) e),
      get_local_peak_height = tryCatch(
        ltas$get_local_peak_height(0, 1000, 1000, 4000, unit = "furlong"),
        pladdrr_input_error = function(e) e),
      get_standard_deviation = tryCatch(
        ltas$get_standard_deviation(0, 0, unit = "furlong"),
        pladdrr_input_error = function(e) e),
      get_means_batch = tryCatch(
        ltas$get_means_batch(c(0), c(1000), unit = "furlong"),
        pladdrr_input_error = function(e) e))
    expect_identical(err$routine, m, info = m)
  }
})
