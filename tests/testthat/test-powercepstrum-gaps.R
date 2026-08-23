# tests/testthat/test-powercepstrum-gaps.R
# Coverage gap-fill (task 20) for src/powercepstrum_wrappers.cpp and
# src/modules/powercepstrum_module.cpp.
#
# Dual-implementation note (see CLAUDE.md and this task's brief): PowerCepstrum's
# R6 methods mostly dispatch through the Rcpp Module object
# (`.self$.cpp$<method>()`, RPowerCepstrum in powercepstrum_module.cpp),
# EXCEPT get_peak_prominence(), get_rnr(), and tabulate_rhamonics(), which call
# bare `.powercepstrum_*` wrapper.cpp exports directly (see R/powercepstrum.R).
# PowerCepstrogram has NO module at all -- every one of its methods calls a
# bare `.powercepstrogram_*` wrapper.cpp export. This file exercises both
# families of gaps at the R6 level. Direct-module-only gaps (RPowerCepstrogram
# methods, which are unreachable from the PowerCepstrogram R6 API since it has
# no module; and RPowerCepstrum's own get_peak_prominence(), which the R6
# get_peak_prominence() does NOT call) are covered separately in
# test-phase4-modules.R, matching that file's existing convention of testing
# module-only surface via direct `new(mod$RClass, ptr)` construction.

sound_fixture <- function() {
  Sound$create_tone(frequency = 150, duration = 0.5, sampling_rate = 16000)
}

# ---------------------------------------------------------------------------
# PowerCepstrum -- wrapper.cpp gaps: get_peak_prominence() branches, the
# permanently-unsupported get_rnr(), and tabulate_rhamonics()
# ---------------------------------------------------------------------------

# PowerCepstrum/PowerCepstrogram numerical code (trend fitting, peak
# prominence, cepstral smoothing) aborts silently under MSVC during Windows
# R CMD check. Coverage-only tests; public API is verified on macOS/Linux.
skip_on_os("windows")

test_that("PowerCepstrum$get_peak_prominence covers cubic/sinc70/sinc700 interpolation", {
  pc <- sound_fixture()$to_spectrum()$to_power_cepstrum()
  for (interp in c("cubic", "sinc70", "sinc700")) {
    cpp <- pc$get_peak_prominence(interpolation = interp)
    expect_true(is.numeric(cpp))
  }
})

test_that("PowerCepstrum$get_peak_prominence covers the least-squares fit_method branch (both spellings)", {
  pc <- sound_fixture()$to_spectrum()$to_power_cepstrum()
  cpp1 <- pc$get_peak_prominence(fit_method = "least squares")
  expect_true(is.numeric(cpp1))
  cpp2 <- pc$get_peak_prominence(fit_method = "least_squares")
  expect_true(is.numeric(cpp2))
})

test_that("PowerCepstrum$get_rnr is a documented, permanently-unsupported stub", {
  # powercepstrum_get_rnr() in powercepstrum_wrappers.cpp always stop()s --
  # PowerCepstrum_getRNR() is noted (in a comment right above the stop()) to
  # segfault when the PowerCepstrum was created from a Spectrum, so the
  # wrapper disables the call entirely rather than risk it. Reachable and
  # deterministic; safe to assert on directly.
  pc <- sound_fixture()$to_spectrum()$to_power_cepstrum()
  expect_error(pc$get_rnr(), "unsupported")
})

# NOTE: PowerCepstrum$tabulate_rhamonics() (-> .powercepstrum_tabulate_rhamonics()
# -> PowerCepstrum_tabulateRhamonics()) SEGFAULTS when the PowerCepstrum was
# created via Spectrum$to_power_cepstrum() (confirmed live, in an isolated
# subprocess -- see task-20-report.md). This is the same "requires workspace
# initialization" hazard get_rnr()'s code comment documents for
# PowerCepstrum_getRNR(); tabulate_rhamonics evidently shares it but was
# undocumented. Deliberately left uncovered here -- do not call this method
# without first confirming the exact PowerCepstrum provenance is safe.

# ---------------------------------------------------------------------------
# PowerCepstrum -- module.cpp gaps reachable via the R6 API (hillenbrand,
# trend fit/value, smooth, subtract_trend[_inplace], to_spectrum, to_matrix,
# as_matrix, save)
# ---------------------------------------------------------------------------

test_that("PowerCepstrum$get_peak_prominence_hillenbrand returns a list", {
  pc <- sound_fixture()$to_spectrum()$to_power_cepstrum()
  h <- pc$get_peak_prominence_hillenbrand()
  expect_true(is.list(h))
})

test_that("PowerCepstrum$fit_trend_line covers multiple trend_type/fit_method combinations", {
  pc <- sound_fixture()$to_spectrum()$to_power_cepstrum()
  fit1 <- pc$fit_trend_line(trend_type = "parabolic", fit_method = "least squares")
  expect_true(is.list(fit1))
  fit2 <- pc$fit_trend_line(trend_type = "straight", fit_method = "robust")
  expect_true(is.list(fit2))
})

test_that("PowerCepstrum$get_trend_line_value returns a numeric value", {
  pc <- sound_fixture()$to_spectrum()$to_power_cepstrum()
  val <- pc$get_trend_line_value(quefrency = 0.005)
  expect_true(is.numeric(val))
})

test_that("PowerCepstrum$smooth returns a new, valid, smoothed PowerCepstrum", {
  pc <- sound_fixture()$to_spectrum()$to_power_cepstrum()
  smoothed <- pc$smooth(averaging_window = 0.0005)
  expect_s3_class(smoothed, "PowerCepstrum")
  expect_true(smoothed$is_valid())
})

test_that("PowerCepstrum$subtract_trend returns a new object; subtract_trend_inplace mutates and returns self", {
  pc <- sound_fixture()$to_spectrum()$to_power_cepstrum()
  detrended <- pc$subtract_trend()
  expect_s3_class(detrended, "PowerCepstrum")
  expect_true(detrended$is_valid())

  pc2 <- sound_fixture()$to_spectrum()$to_power_cepstrum()
  ret <- pc2$subtract_trend_inplace()
  expect_identical(ret, pc2)
})

test_that("PowerCepstrum$to_spectrum round-trips with and without random phases", {
  pc <- sound_fixture()$to_spectrum()$to_power_cepstrum()
  spec1 <- pc$to_spectrum(random_phases = FALSE)
  expect_s3_class(spec1, "Spectrum")
  spec2 <- pc$to_spectrum(random_phases = TRUE)
  expect_s3_class(spec2, "Spectrum")
})

test_that("PowerCepstrum$to_matrix and $as_matrix export data", {
  pc <- sound_fixture()$to_spectrum()$to_power_cepstrum()
  m <- pc$to_matrix()
  expect_s3_class(m, "Matrix")
  am <- pc$as_matrix()
  expect_true(is.matrix(am))
  expect_gt(ncol(am), 0)
})

test_that("PowerCepstrum$save writes a file", {
  pc <- sound_fixture()$to_spectrum()$to_power_cepstrum()
  tmp <- tempfile()
  on.exit(unlink(tmp))
  expect_no_error(pc$save(tmp))
  expect_true(file.exists(tmp))
})

# ---------------------------------------------------------------------------
# PowerCepstrogram -- wrapper.cpp gaps: get_cpp_at_time() branches,
# get_mean_cpp(), to_matrix(), smooth(), get_cpps()
# ---------------------------------------------------------------------------

test_that("PowerCepstrogram$get_cpp_at_time covers cubic interpolation and exponential-decay fit_method", {
  pcg <- sound_fixture()$to_powercepstrogram(pitch_floor = 60, time_step = 0.01)
  cpp <- pcg$get_cpp_at_time(0.25, interpolation = "cubic", fit_method = "exponential decay")
  expect_true(is.numeric(cpp))
})

test_that("PowerCepstrogram$get_mean_cpp works with defaults and an explicit time range/fit_method", {
  pcg <- sound_fixture()$to_powercepstrogram(pitch_floor = 60, time_step = 0.01)
  mean_cpp <- pcg$get_mean_cpp()
  expect_true(is.numeric(mean_cpp))
  mean_cpp2 <- pcg$get_mean_cpp(from_time = 0.1, to_time = 0.3, fit_method = "exponential decay")
  expect_true(is.numeric(mean_cpp2))
})

test_that("PowerCepstrogram$to_matrix returns a Matrix object", {
  pcg <- sound_fixture()$to_powercepstrogram(pitch_floor = 60, time_step = 0.01)
  m <- pcg$to_matrix()
  expect_s3_class(m, "Matrix")
})

test_that("PowerCepstrogram$smooth returns a new PowerCepstrogram", {
  pcg <- sound_fixture()$to_powercepstrogram(pitch_floor = 60, time_step = 0.01)
  smoothed <- pcg$smooth(time_averaging_window = 0.02, quefrency_averaging_window = 0.001)
  expect_s3_class(smoothed, "PowerCepstrogram")
})

test_that("PowerCepstrogram$get_cpps works with default and non-default arguments", {
  pcg <- sound_fixture()$to_powercepstrogram(pitch_floor = 60, time_step = 0.01)
  cpps1 <- pcg$get_cpps()
  expect_true(is.numeric(cpps1))
  cpps2 <- pcg$get_cpps(subtract_tilt = FALSE, fit_method = "least squares",
                         interpolation = "cubic", trend_line_type = "exponential decay")
  expect_true(is.numeric(cpps2))
})

# ---------------------------------------------------------------------------
# Sound$to_powercepstrogram -- input validation guards in
# .sound_to_powercepstrogram() (powercepstrum_wrappers.cpp). All are stop()
# calls that fire before any Praat engine call is made, so they are safe to
# exercise with invalid numeric input (unlike the NaN/NA crash cases found
# elsewhere in this codebase).
# ---------------------------------------------------------------------------

test_that("Sound$to_powercepstrogram validates pitch_floor", {
  s <- sound_fixture()
  expect_error(s$to_powercepstrogram(pitch_floor = 0), "pitch_floor must be positive")
  expect_error(s$to_powercepstrogram(pitch_floor = -10), "pitch_floor must be positive")
  # sampling_rate = 16000 Hz -> Nyquist = 8000 Hz
  expect_error(s$to_powercepstrogram(pitch_floor = 9000), "Nyquist")
})

test_that("Sound$to_powercepstrogram validates duration vs pitch_floor", {
  short <- Sound$create_tone(frequency = 150, duration = 0.01, sampling_rate = 16000)
  expect_error(short$to_powercepstrogram(pitch_floor = 60), "too short")
})

test_that("Sound$to_powercepstrogram validates time_step", {
  s <- sound_fixture()
  expect_error(s$to_powercepstrogram(time_step = 0), "time_step must be positive")
  expect_error(s$to_powercepstrogram(time_step = -1), "time_step must be positive")
  expect_error(s$to_powercepstrogram(time_step = 10), "cannot be longer than sound duration")
})

test_that("Sound$to_powercepstrogram validates maximum_frequency", {
  s <- sound_fixture()
  expect_error(s$to_powercepstrogram(maximum_frequency = 0), "maximum_frequency must be positive")
  expect_error(s$to_powercepstrogram(maximum_frequency = 9000), "Nyquist")
})

test_that("Sound$to_powercepstrogram validates pre_emphasis_frequency", {
  s <- sound_fixture()
  expect_error(s$to_powercepstrogram(pre_emphasis_frequency = -1), "cannot be negative")
  expect_error(s$to_powercepstrogram(pre_emphasis_frequency = 9000), "Nyquist")
})

# ---------------------------------------------------------------------------
# Cepstrum / Spectrum -- remaining wrapper.cpp exports in
# powercepstrum_wrappers.cpp (Cepstrum<->Sound/Spectrum/PowerCepstrum
# conversions live in this file even though the class is Cepstrum, not
# PowerCepstrum/PowerCepstrogram)
# ---------------------------------------------------------------------------

test_that("Cepstrum$to_sound is a documented, permanently-unsupported stub", {
  # cepstrum_to_sound() always stop()s -- a code comment records that
  # Cepstrum_to_Sound() fails with an "invalid file argument" error coming
  # from R's error handling, not Praat, so the wrapper disables the call.
  cep <- sound_fixture()$to_cepstrum()
  expect_error(cep$to_sound(), "unsupported")
})

test_that("Cepstrum$to_spectrum converts back to a Spectrum", {
  cep <- sound_fixture()$to_cepstrum()
  spec <- cep$to_spectrum()
  expect_s3_class(spec, "Spectrum")
})

test_that("Spectrum$to_cepstrum_hillenbrand creates a Cepstrum", {
  spec <- sound_fixture()$to_spectrum()
  cep <- spec$to_cepstrum_hillenbrand()
  expect_s3_class(cep, "Cepstrum")
})
