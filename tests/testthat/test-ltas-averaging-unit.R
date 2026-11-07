# tests/testthat/test-ltas-averaging-unit.R
# F-faith-13: the Ltas averaging unit must mean what Praat's Ltas queries mean.
#
# Three defects sat on the same three lines of src/modules/ltas_module.cpp:
#  (a) get_mean / get_means_batch / get_standard_deviation called Praat's
#      Sampled_getMean / Sampled_getStandardDeviation instead of the
#      *_standardUnit entry points Praat's own Ltas queries use
#      (fon/praat_uvafon_init.cpp:1107-1108 and :1156-1159), so unit="energy"
#      and unit="sones" returned the LINEAR mean of the converted bins
#      (10^(z/10), 2^(z/10)) where Praat prints a dB number.
#  (b) R/ltas-wrapper.R mapped "dB" to code 0, while Ltas_getSlope and
#      Ltas_getLocalPeakHeight special-case averagingUnits == 3 (fon/Ltas.cpp:87,
#      :95), so get_slope(unit = "dB") -- the default -- returned a dimensionless
#      ratio instead of a dB difference.
#  (c) the same calls passed interpolate = true where Praat passes false, which
#      reweights the bins at an incomplete range edge. That moves the *default*
#      dB mean as well: 0.27 dB for get_mean(500, 2000) on inst/extdata/test.wav
#      and up to 8.08 dB scanning 50 Hz-wide bands over 0-5500 Hz (review round
#      measurement), while full-band means are unaffected.
#
# Expected values are computed in R from the object's own bins with Praat's own
# formulas (each step cited to the vendored source) AND frozen against the
# oracle: Praat 6.4.27 reading the identical inst/extdata/test.wav,
# `To Ltas: 100`, then `Ltas: Get mean / Get standard deviation / Get slope /
# Get local peak height`. Scripts and both outputs:
# audit/2026-11/evidence/ltas-faith13/{repro_R.R,repro_oracle.praat,
# repro_base.txt,repro_oracle.txt}. The Ltas bin arrays themselves are identical
# between the two systems (max |difference| 2.7e-12 dB, see dump_bins.*).

# Praat's averaging window with interpolate = false: the
# `else { // no interpolation }` branch of getSumAndDefinitionRange
# (src/praat.github.io/fon/Sampled.cpp:277-316), reached after
# Function_unidirectionalAutowindow (fon/Function.cpp:152-157: the whole domain
# when from >= to) and Function_intersectRangeWithDomain (fon/Function.cpp:165).
# Sample indices are 1-based as in Praat; Melder_iround rounds half away from 0.
ltas_avg_weights <- function(nx, dx, x1, domain, range) {
  fmin <- range[1]
  fmax <- range[2]
  if (fmin >= fmax) {
    fmin <- domain[1]
    fmax <- domain[2]
  }
  fmin <- max(fmin, domain[1])
  fmax <- min(fmax, domain[2])
  iround <- function(x) if (x >= 0) floor(x + 0.5) else ceiling(x - 0.5)
  rimin <- (fmin - x1) / dx + 1
  rimax <- (fmax - x1) / dx + 1
  w <- numeric(nx)
  if (rimax >= 0.5 && rimin < nx + 0.5) {
    imin <- if (rimin < 0.5) 0L else as.integer(iround(rimin))
    imax <- if (rimax >= nx + 0.5) nx + 1L else as.integer(iround(rimax))
    if (imax - imin > 1) {
      w[(imin + 1):(imax - 1)] <- w[(imin + 1):(imax - 1)] + 1
    }
    if (imin == imax) {
      w[imin] <- w[imin] + (rimax - rimin)
    } else {
      if (imin >= 1) w[imin] <- w[imin] + (imin - rimin + 0.5)
      if (imax <= nx) w[imax] <- w[imax] + (rimax - imax + 0.5)
    }
  }
  w
}

# structLtas::v_convertStandardToSpecialUnit / v_convertSpecialToStandardUnit
# (fon/Ltas.cpp:44-51 / :53-60).
ltas_from_db <- function(z, unit) {
  switch(unit, energy = 10^(0.1 * z), sones = 2^(0.1 * z), z)
}
ltas_to_db <- function(v, unit) {
  switch(unit, energy = 10 * log10(v), sones = 10 * log2(v), v)
}

# Sampled_getMean (fon/Sampled.cpp:493-497): sum(value * weight) / definitionRange
ltas_linear_mean <- function(z, w, unit) {
  sum(w * ltas_from_db(z, unit)) / sum(w)
}

# Sampled_getMean_standardUnit (fon/Sampled.cpp:505-509)
ltas_expected_mean <- function(z, w, unit) {
  ltas_to_db(ltas_linear_mean(z, w, unit), unit)
}

# Sampled_getStandardDeviation (fon/Sampled.cpp:541-548,
# sqrt(sumOfSquared / (definitionRange - 1))) + its *_standardUnit wrapper
# (fon/Sampled.cpp:550-554)
ltas_expected_sd <- function(z, w, unit) {
  definition_range <- sum(w)
  v <- ltas_from_db(z, unit)
  m <- sum(w * v) / definition_range
  ltas_to_db(sqrt(sum(w * (v - m)^2) / (definition_range - 1)), unit)
}

ltas_unit_fixture <- function() {
  ltas <- Sound(system.file("extdata", "test.wav", package = "pladdrr"))$
    to_ltas(bandwidth = 100)
  list(
    ltas = ltas,
    z = as.data.frame(ltas)[[2]],
    nx = ltas$get_number_of_bins(),
    dx = ltas$get_bin_width(),
    x1 = ltas$get_frequency_from_bin(1),
    domain = c(ltas$get_lowest_frequency(), ltas$get_highest_frequency())
  )
}

# `oracle` = c(mean, standard deviation) as printed by Praat 6.4.27.
expect_ltas_units <- function(fx, range, oracle) {
  w <- ltas_avg_weights(fx$nx, fx$dx, fx$x1, fx$domain, range)
  for (unit in c("dB", "energy", "sones")) {
    expect_equal(fx$ltas$get_mean(range[1], range[2], unit = unit),
      ltas_expected_mean(fx$z, w, unit), tolerance = 1e-9,
      label = sprintf("get_mean(%g, %g, \"%s\")", range[1], range[2], unit))
    expect_equal(fx$ltas$get_means_batch(range[1], range[2], unit = unit),
      ltas_expected_mean(fx$z, w, unit), tolerance = 1e-9,
      label = sprintf("get_means_batch(%g, %g, \"%s\")", range[1], range[2], unit))
    expect_equal(fx$ltas$get_standard_deviation(range[1], range[2], unit = unit),
      ltas_expected_sd(fx$z, w, unit), tolerance = 1e-9,
      label = sprintf("get_standard_deviation(%g, %g, \"%s\")", range[1], range[2], unit))
    expect_equal(fx$ltas$get_mean(range[1], range[2], unit = unit),
      oracle[[unit]][1], tolerance = 1e-9,
      label = sprintf("oracle get_mean %s", unit))
    expect_equal(fx$ltas$get_standard_deviation(range[1], range[2], unit = unit),
      oracle[[unit]][2], tolerance = 1e-9,
      label = sprintf("oracle get_standard_deviation %s", unit))
  }
}

test_that("get_mean, get_means_batch and get_standard_deviation answer in dB for all three units (full band)", {
  fx <- ltas_unit_fixture()
  expect_gte(fx$nx, 100L)
  expect_ltas_units(fx, c(0, 0), list(
    dB = c(-22.832718943, 15.741783085),
    energy = c(41.513718148, 53.221438646),
    sones = c(-1.519994509, 26.268732764)))
  # The three units must not coincide, or the rows above pin nothing.
  three <- vapply(c("dB", "energy", "sones"),
    function(u) fx$ltas$get_mean(0, 0, unit = u), 0)
  expect_equal(length(unique(round(three, 6))), 3L)
})

test_that("a non-bin-aligned band averages exactly the bins Praat's window keeps", {
  fx <- ltas_unit_fixture()
  # 123.5 Hz and 2777 Hz fall inside bins: this is where the interpolate flag
  # showed (10.717937 before vs 10.444981 dB from Praat for 500-2000).
  expect_ltas_units(fx, c(123.5, 2777), list(
    dB = c(10.416064239, 16.422577396),
    energy = c(50.709000074, 57.819088367),
    sones = c(25.759831911, 41.048196618)))
  expect_ltas_units(fx, c(500, 2000), list(
    dB = c(10.444981126, 9.189718496),
    energy = c(20.828887109, 25.403457474),
    sones = c(13.600857249, 10.663804073)))
})

test_that("the C++ entry points back-convert like Praat's *_standardUnit variants", {
  fx <- ltas_unit_fixture()
  # Raw averaging codes as Praat's dialog passes them (1 = energy, 2 = sones,
  # 3 = dB; fon/praat_uvafon_init.cpp:1101-1105). Before the fix, code 1 returned
  # the linear mean 14170.064098 where Praat prints 41.513718148 dB -- i.e.
  # 10*log10() of the old answer is the new one:
  expect_equal(ltas_to_db(14170.064097557, "energy"), 41.513718148,
    tolerance = 1e-9)
  expect_equal(fx$ltas$.cpp$get_mean(0, 0, 1L), 41.513718148, tolerance = 1e-9)
  expect_equal(fx$ltas$.cpp$get_mean(0, 0, 2L), -1.519994509, tolerance = 1e-9)
  expect_equal(fx$ltas$.cpp$get_mean(0, 0, 3L), -22.832718943, tolerance = 1e-9)
  expect_equal(fx$ltas$.cpp$get_standard_deviation(0, 0, 1L), 53.221438646,
    tolerance = 1e-9)
  expect_equal(fx$ltas$.cpp$get_means_batch(0, 0, 1L), 41.513718148,
    tolerance = 1e-9)
})

test_that("get_slope returns a dB difference for unit=\"dB\" and the ratio conversions otherwise", {
  fx <- ltas_unit_fixture()
  low <- ltas_avg_weights(fx$nx, fx$dx, fx$x1, fx$domain, c(0, 1000))
  high <- ltas_avg_weights(fx$nx, fx$dx, fx$x1, fx$domain, c(1000, 4000))
  # Ltas_getSlope (fon/Ltas.cpp:83-88): averagingUnits == 3 gives high - low,
  # otherwise the *ratio* of the two raw means is converted back (fon/Ltas.cpp:53-60).
  slope <- function(unit) {
    if (unit == "dB") {
      ltas_linear_mean(fx$z, high, unit) - ltas_linear_mean(fx$z, low, unit)
    } else {
      ltas_to_db(ltas_linear_mean(fx$z, high, unit) /
        ltas_linear_mean(fx$z, low, unit), unit)
    }
  }
  for (unit in c("dB", "energy", "sones")) {
    expect_equal(fx$ltas$get_slope(0, 1000, 1000, 4000, unit = unit),
      slope(unit), tolerance = 1e-9,
      label = sprintf("get_slope(unit = \"%s\")", unit))
  }
  # oracle: Praat 6.4.27 Get slope: 0, 1000, 1000, 4000
  expect_equal(fx$ltas$get_slope(0, 1000, 1000, 4000, unit = "dB"),
    -31.906945759, tolerance = 1e-9)
  expect_equal(fx$ltas$get_slope(0, 1000, 1000, 4000, unit = "energy"),
    -52.513077760, tolerance = 1e-9)
  expect_equal(fx$ltas$get_slope(0, 1000, 1000, 4000, unit = "sones"),
    -40.065371447, tolerance = 1e-9)
})

test_that("get_slope and get_mean accept both unit spellings and default to dB", {
  fx <- ltas_unit_fixture()
  # pladdrr lower-cases the unit; Praat 6.4.27 itself rejects lowercase "db" for
  # this CHOICE (option matching is case-sensitive there).
  expect_equal(fx$ltas$get_slope(0, 1000, 1000, 4000, unit = "db"),
    fx$ltas$get_slope(0, 1000, 1000, 4000, unit = "dB"), tolerance = 0)
  expect_equal(fx$ltas$get_slope(0, 1000, 1000, 4000, unit = "DB"),
    fx$ltas$get_slope(0, 1000, 1000, 4000, unit = "dB"), tolerance = 0)
  expect_equal(fx$ltas$get_mean(0, 0, unit = "ENERGY"),
    fx$ltas$get_mean(0, 0, unit = "energy"), tolerance = 0)
  expect_equal(fx$ltas$get_mean(0, 0), fx$ltas$get_mean(0, 0, unit = "dB"),
    tolerance = 0)
})

test_that("get_local_peak_height compares in the unit it names", {
  fx <- ltas_unit_fixture()
  # Ltas_getLocalPeakHeight (fon/Ltas.cpp:90-97): dB gives
  # peak - 0.5 * (environmentLow + environmentHigh), otherwise the *ratio* of
  # peak to that average is converted back.
  env_low <- ltas_avg_weights(fx$nx, fx$dx, fx$x1, fx$domain, c(1700, 2400))
  env_high <- ltas_avg_weights(fx$nx, fx$dx, fx$x1, fx$domain, c(3200, 4200))
  peak <- ltas_avg_weights(fx$nx, fx$dx, fx$x1, fx$domain, c(2400, 3200))
  height <- function(unit) {
    environment <- 0.5 * (ltas_linear_mean(fx$z, env_low, unit) +
      ltas_linear_mean(fx$z, env_high, unit))
    if (unit == "dB") {
      ltas_linear_mean(fx$z, peak, unit) - environment
    } else {
      ltas_to_db(ltas_linear_mean(fx$z, peak, unit) / environment, unit)
    }
  }
  for (unit in c("dB", "energy", "sones")) {
    expect_equal(
      fx$ltas$get_local_peak_height(1700, 4200, 2400, 3200, unit = unit),
      height(unit), tolerance = 1e-9,
      label = sprintf("get_local_peak_height(unit = \"%s\")", unit))
  }
  # oracle: Praat 6.4.27 Get local peak height: 1700, 4200, 2400, 3200
  expect_equal(fx$ltas$get_local_peak_height(1700, 4200, 2400, 3200, unit = "dB"),
    -0.370929253, tolerance = 1e-9)
  expect_equal(fx$ltas$get_local_peak_height(1700, 4200, 2400, 3200, unit = "energy"),
    -3.074175936, tolerance = 1e-9)
  expect_equal(fx$ltas$get_local_peak_height(1700, 4200, 2400, 3200, unit = "sones"),
    -1.319694412, tolerance = 1e-9)
})

test_that("an unknown unit errors instead of silently averaging like energy", {
  fx <- ltas_unit_fixture()
  for (bad in c("nonsense", "median", "db/Hz", "DB ", NA_character_)) {
    expect_error(fx$ltas$get_mean(0, 0, unit = bad), "energy",
      label = sprintf("get_mean(unit = \"%s\")", bad))
    expect_error(fx$ltas$get_slope(0, 1000, 1000, 4000, unit = bad), "energy")
    expect_error(fx$ltas$get_means_batch(0, 0, unit = bad), "energy")
    expect_error(fx$ltas$get_standard_deviation(0, 0, unit = bad), "energy")
    expect_error(
      fx$ltas$get_local_peak_height(1700, 4200, 2400, 3200, unit = bad), "energy")
  }
})
