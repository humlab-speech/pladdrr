# test-performance-helpers.R - Tests for R/performance-helpers.R
#
# R/performance-helpers.R has two distinct CPPS parameter profiles that are
# easy to confuse (see CLAUDE.md "CPPS parameter defaults" and the
# .cpps_profiles table in R/constants.R, which is the authoritative source):
#   - calculate_cpps_fast()/calculate_cpps_ultra(): the "r6" profile
#     (time_averaging_window = 0.001, quefrency_averaging_window = 0.0005,
#     pitch_ceiling = 333.3) - same numbers as PowerCepstrogram$get_cpps().
#   - get_cpps_fast(): the "avqi" profile (time_averaging_window = 0.01,
#     quefrency_averaging_window = 0.001, pitch_ceiling = 330,
#     subtract_tilt = FALSE) - and note it takes a PowerCepstrogram external
#     pointer (from to_powercepstrogram_fast()), NOT a Sound.
# Exact default *values* are already exhaustively checked against
# .cpps_profiles in test-cpps-defaults.R; this file exercises the actual
# code paths (execution, return types, cross-function invariants) instead of
# re-asserting formals().

test_that("to_powercepstrogram_fast returns a bare external pointer usable by get_cpps_fast", {
  sound <- Sound$create_tone(frequency = 150, duration = 0.5, sampling_rate = 16000)
  pcg <- to_powercepstrogram_fast(sound)

  # This is the raw Rcpp XPtr<PowerCepstrogram>, not a classed PowerCepstrogram
  # R6/wrapper object - it has no extra class beyond "externalptr".
  expect_type(pcg, "externalptr")
  expect_identical(class(pcg), "externalptr")

  cpps <- get_cpps_fast(pcg)
  expect_type(cpps, "double")
  expect_length(cpps, 1L)
  expect_true(is.finite(cpps))
})

test_that("to_powercepstrogram_fast rejects non-Sound, non-pointer input", {
  expect_error(to_powercepstrogram_fast("not a sound"),
               "sound must be a Sound object or external pointer")
})

test_that("get_cpps_fast rejects a non-pointer argument", {
  sound <- Sound$create_tone(frequency = 150, duration = 0.5, sampling_rate = 16000)
  expect_error(get_cpps_fast(sound),
               "powercepstrogram must be an external pointer from to_powercepstrogram_fast\\(\\)")
})

test_that("calculate_cpps_fast returns a finite scalar for a Sound object", {
  sound <- Sound$create_tone(frequency = 150, duration = 0.5, sampling_rate = 16000)
  result <- calculate_cpps_fast(sound)
  expect_type(result, "double")
  expect_length(result, 1L)
  expect_true(is.finite(result))
})

test_that("calculate_cpps_fast also accepts a raw Sound external pointer", {
  sound <- Sound$create_tone(frequency = 150, duration = 0.5, sampling_rate = 16000)
  result_r6 <- calculate_cpps_fast(sound)
  result_ptr <- calculate_cpps_fast(sound$.xptr)
  expect_equal(result_ptr, result_r6)
})

test_that("calculate_cpps_fast rejects a non-Sound, non-pointer argument", {
  expect_error(calculate_cpps_fast("not a sound"),
               "sound must be a Sound object or external pointer")
})

test_that("get_cpps_fast (avqi profile) and calculate_cpps_fast (r6 profile) diverge", {
  # The two profiles are deliberately different (see file banner); on the
  # same input they should NOT coincidentally agree.
  sound <- Sound(system.file("extdata", "test.wav", package = "pladdrr"))

  r6_value <- calculate_cpps_fast(sound)
  pcg <- to_powercepstrogram_fast(sound)
  avqi_value <- get_cpps_fast(pcg)

  expect_true(is.finite(r6_value))
  expect_true(is.finite(avqi_value))
  expect_false(isTRUE(all.equal(r6_value, avqi_value, tolerance = 0.01)))
})

test_that("create_window_xptr builds each supported window type", {
  skip_if_not_installed("RcppXPtrUtils")

  for (wtype in c("hamming", "hanning", "gaussian", "triangular",
                   "blackman", "rectangular")) {
    win <- create_window_xptr(wtype)
    expect_true(inherits(win, "externalptr") || inherits(win, "XPtr"),
                info = paste("window type:", wtype))
  }
})

test_that("create_window_xptr rejects an unsupported type", {
  skip_if_not_installed("RcppXPtrUtils")
  expect_error(create_window_xptr("not-a-window"))
})

test_that("apply_window_xptr applies a Hanning window that zeroes the edges", {
  skip_if_not_installed("RcppXPtrUtils")

  sound <- Sound$create_tone(frequency = 220, duration = 0.3, sampling_rate = 16000)
  hann <- create_window_xptr("hanning")
  windowed <- apply_window_xptr(sound, hann)

  expect_s3_class(windowed, "Sound")
  expect_equal(windowed$get_total_duration(), sound$get_total_duration())

  orig <- sound$get_values()
  ws <- windowed$get_values()
  expect_length(ws, length(orig))
  # Hanning window is 0 at t=0 and t=1 (sample edges), so the windowed
  # edge samples should collapse toward zero relative to the un-windowed tone.
  expect_true(abs(ws[1]) < abs(orig[1]))
  expect_true(abs(ws[length(ws)]) < abs(orig[length(orig)]))
})

test_that("apply_window_xptr rejects a non-Sound, non-pointer argument", {
  skip_if_not_installed("RcppXPtrUtils")
  hann <- create_window_xptr("hanning")
  expect_error(apply_window_xptr("not a sound", hann),
               "sound must be a Sound object or external pointer")
})

test_that("apply_transform_xptr applies a compiled sample transform", {
  skip_if_not_installed("RcppXPtrUtils")

  sound <- Sound$create_tone(frequency = 220, duration = 0.3, sampling_rate = 16000)
  orig <- sound$get_values()
  expect_true(any(orig < 0))  # a sine tone has negative samples

  square_xptr <- RcppXPtrUtils::cppXPtr(
    "double square_it(double x) { return x * x; }",
    depends = character()
  )
  transformed <- apply_transform_xptr(sound, square_xptr)

  expect_s3_class(transformed, "Sound")
  ts <- transformed$get_values()
  expect_length(ts, length(orig))
  # x*x cannot be negative
  expect_true(all(ts >= 0))
})

test_that("apply_transform_xptr rejects a non-Sound, non-pointer argument", {
  skip_if_not_installed("RcppXPtrUtils")
  square_xptr <- RcppXPtrUtils::cppXPtr(
    "double square_it(double x) { return x * x; }",
    depends = character()
  )
  expect_error(apply_transform_xptr("not a sound", square_xptr),
               "sound must be a Sound object or external pointer")
})

test_that("calculate_cpps_ultra matches calculate_cpps_fast within tolerance", {
  # Both share the "r6" parameter profile; calculate_cpps_ultra just fuses
  # the PowerCepstrogram-creation and CPPS-extraction C++ calls into one.
  sound <- Sound(system.file("extdata", "test.wav", package = "pladdrr"))

  cpps_ultra <- calculate_cpps_ultra(sound)
  cpps_fast <- calculate_cpps_fast(sound)

  expect_type(cpps_ultra, "double")
  expect_true(is.finite(cpps_ultra))
  expect_equal(cpps_ultra, cpps_fast, tolerance = 0.01)
})

test_that("calculate_cpps_ultra rejects a non-Sound, non-pointer argument", {
  expect_error(calculate_cpps_ultra("not a sound"),
               "sound must be a Sound object or external pointer")
})

test_that("calculate_cpps_ultra rejects a null external pointer at the C++ layer", {
  # calculate_cpps_ultra() accepts a bare externalptr (not just a Sound R6
  # object), so a null externalptr reaches calculate_cpps_ultra_cpp()'s own
  # "Invalid Sound pointer" guard directly through the public API, unlike
  # the R-level "not a sound" check above.
  null_ptr <- methods::new("externalptr")
  expect_error(calculate_cpps_ultra(null_ptr), "Invalid Sound pointer")
})

test_that("extract_voiced_segments_ultra returns a shorter voiced-only Sound (both AVQI versions)", {
  sound <- Sound(system.file("extdata", "test.wav", package = "pladdrr"))
  full_duration <- sound$get_total_duration()

  # inst/extdata/test.wav's low intensity range triggers Praat's own
  # "The loudest and softest part in your sound differ by only ... dB"
  # notice (Melder_warning, src/praat.github.io/dwtools/Intensity_extensions.cpp).
  # Note this is NOT an R condition -- Melder_warning's default handler writes
  # straight to the console/stderr (MelderConsole::write in
  # src/praat.github.io/melder/melder_warning.cpp), so suppressWarnings() has
  # no actual effect here (verified: no R warning condition is raised); kept
  # defensively in case that wiring changes and it starts routing through
  # R's warning() in the future.
  voiced_v2 <- suppressWarnings(
    extract_voiced_segments_ultra(sound, version = "v2.03")
  )
  voiced_v3 <- suppressWarnings(
    extract_voiced_segments_ultra(sound, version = "v3.01")
  )

  expect_s3_class(voiced_v2, "Sound")
  expect_s3_class(voiced_v3, "Sound")
  expect_true(voiced_v2$get_total_duration() > 0)
  expect_true(voiced_v3$get_total_duration() > 0)
  expect_true(voiced_v2$get_total_duration() <= full_duration)
  expect_true(voiced_v3$get_total_duration() <= full_duration)
})

test_that("extract_voiced_segments_ultra rejects an invalid version", {
  sound <- Sound$create_tone(frequency = 150, duration = 0.5, sampling_rate = 16000)
  expect_error(extract_voiced_segments_ultra(sound, version = "v9.99"))
})

test_that("extract_voiced_segments_ultra rejects a non-Sound, non-pointer argument", {
  expect_error(extract_voiced_segments_ultra("not a sound"),
               "sound must be a Sound object or external pointer")
})

test_that("build_multiband_harmonicity returns 5 named Harmonicity objects", {
  sound <- Sound(system.file("extdata", "test.wav", package = "pladdrr"))
  # See the low-dB-range Melder_warning note above extract_voiced_segments_ultra's
  # test -- same benign, non-R-condition notice, same test.wav.
  built <- suppressWarnings(build_multiband_harmonicity(sound))

  expect_type(built, "list")
  expect_length(built, 5L)
  expect_named(built, c("full", "band500", "band1500", "band2500", "band3500"))
  for (name in names(built)) {
    expect_true(inherits(built[[name]], "Harmonicity"), info = name)
  }
})

test_that("build_multiband_harmonicity rejects a bands vector of the wrong length", {
  sound <- Sound$create_tone(frequency = 150, duration = 0.5, sampling_rate = 16000)
  expect_error(build_multiband_harmonicity(sound, bands = c(0, 500, 1500)),
               "bands parameter must have exactly 5 elements")
})

test_that("multiband_hnr_stats returns mean/sd for each band and matches calculate_multiband_hnr_ultra", {
  sound <- Sound(system.file("extdata", "test.wav", package = "pladdrr"))
  # See the low-dB-range Melder_warning note above extract_voiced_segments_ultra's
  # test -- same benign, non-R-condition notice, same test.wav.
  built <- suppressWarnings(build_multiband_harmonicity(sound))

  stats_interval <- multiband_hnr_stats(built, 0, 0.5)
  expect_type(stats_interval, "list")
  expect_length(stats_interval, 10L)
  expect_named(stats_interval, c(
    "full_mean", "full_sd", "band500_mean", "band500_sd",
    "band1500_mean", "band1500_sd", "band2500_mean", "band2500_sd",
    "band3500_mean", "band3500_sd"
  ))
  for (v in stats_interval) {
    expect_true(is.numeric(v))
    expect_false(is.na(v))
  }

  # Whole-sound stats (to_time = 0 means "full sound") must agree exactly
  # with the single-call ultra path, since both run the identical C++
  # Harmonicity computation - one reuses cached objects, one doesn't.
  stats_whole <- multiband_hnr_stats(built, 0, 0)
  # See the low-dB-range Melder_warning note above extract_voiced_segments_ultra's
  # test -- same benign, non-R-condition notice, same test.wav.
  hnr_whole <- suppressWarnings(calculate_multiband_hnr_ultra(sound))
  expect_equal(stats_whole, hnr_whole, tolerance = 1e-6)
})

test_that("multiband_hnr_stats rejects a malformed multiband list", {
  expect_error(multiband_hnr_stats(list(a = 1, b = 2), 0, 1),
               "multiband must be a named list of 5 Harmonicity objects")
})

test_that("calculate_multiband_hnr_ultra returns mean/sd for each band directly from a Sound", {
  sound <- Sound(system.file("extdata", "test.wav", package = "pladdrr"))
  # See the low-dB-range Melder_warning note above extract_voiced_segments_ultra's
  # test -- same benign, non-R-condition notice, same test.wav.
  hnr <- suppressWarnings(calculate_multiband_hnr_ultra(sound))

  expect_type(hnr, "list")
  expect_length(hnr, 10L)
  expect_named(hnr, c(
    "full_mean", "full_sd", "band500_mean", "band500_sd",
    "band1500_mean", "band1500_sd", "band2500_mean", "band2500_sd",
    "band3500_mean", "band3500_sd"
  ))
  for (v in hnr) {
    expect_true(is.numeric(v))
    expect_false(is.na(v))
  }
})

test_that("calculate_multiband_hnr_ultra rejects a bands vector of the wrong length", {
  sound <- Sound$create_tone(frequency = 150, duration = 0.5, sampling_rate = 16000)
  expect_error(calculate_multiband_hnr_ultra(sound, bands = c(0, 500)),
               "bands parameter must have exactly 5 elements")
})

test_that("validate_multiband_hnr_bands() C++ guard is reachable directly (both R wrappers pre-validate)", {
  # Both build_multiband_harmonicity() and calculate_multiband_hnr_ultra()
  # validate length(bands) == 5 in R before ever calling into C++, so the
  # two tests above never exercise validate_multiband_hnr_bands() itself.
  # Call the internal exports directly to close that gap.
  sound <- Sound$create_tone(frequency = 150, duration = 0.5, sampling_rate = 16000)
  expect_error(
    pladdrr:::.build_multiband_harmonicity_cpp(sound$.xptr, c(0, 500, 1500), 0.005, 75),
    "bands parameter must have exactly 5 elements"
  )
  expect_error(
    pladdrr:::.calculate_multiband_hnr_ultra_cpp(sound$.xptr, c(0, 500), 0.005, 75, 0, 0),
    "bands parameter must have exactly 5 elements"
  )
})

test_that("build_multiband_harmonicity / calculate_multiband_hnr_ultra reject a null pointer at the C++ layer", {
  # Both accept a bare externalptr (via extract_xptr()), so a null pointer
  # with a valid bands length reaches each C++ export's own null-pointer
  # guard directly through the public API.
  null_ptr <- methods::new("externalptr")
  expect_error(build_multiband_harmonicity(null_ptr), "Invalid Sound pointer")
  expect_error(calculate_multiband_hnr_ultra(null_ptr), "Invalid Sound pointer")
})
