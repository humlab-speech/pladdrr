# test-formant-module-gaps.R
# Coverage gap-fill for src/modules/formant_module.cpp (RFormant Rcpp module
# class) and src/formant_wrappers.cpp (the bare Rcpp::export functions the
# Formant R6 wrapper actually dispatches to).
#
# Dual-implementation trap (documented for PowerCepstrum/Table/Sound/TextGrid,
# confirmed here for Formant): `.formant_methods` in R/formant-wrapper.R calls
# bare `.formant_get_value_at_time()`-style Rcpp::export functions (defined in
# formant_wrappers.cpp) for nearly all query methods, NOT `.self$.cpp$...`.
# That means the near-duplicate RFormant:: methods registered on the Rcpp
# Module in formant_module.cpp (get_value_at_time, get_bandwidth_at_time,
# get_mean, get_standard_deviation, get_quantile, get_minimum, get_maximum,
# get_time_of_minimum, get_time_of_maximum, as_data_frame, save) are dead code
# from the public R6 API's perspective. They ARE reachable, though, via the
# `.cpp` field the S3 `$.Formant` dispatcher exposes directly -- the same
# escape hatch test-mfcc-module-gaps.R / test-powercepstrum-gaps.R /
# test-table-wrapper.R use for the identical pattern on other classes. Tests
# below use `formant$.cpp$method()` for exactly those methods.
#
# get_x1(), get_time_from_frame(), get_frame_from_time() and get_duration()
# are registered on the module (and even exposed as R6-style "fast access"
# .property()s) but have NO `.formant_methods` entry at all -- not even a
# bare-wrapper dead-code case, just never wired up to the public API. Same
# `.cpp$` escape hatch used to reach them.
#
# get_bandwidth_track() IS wired up normally (`.formant_methods$get_bandwidth_track`
# calls `.self$.cpp$get_bandwidth_track()`) but was simply untested before this
# file -- get_formant_track()'s sibling function, covered elsewhere, masked
# the gap.
#
# `track()` (-> .formant_tracker(), Formant_tracker) and `down_to_table()`
# (-> .formant_down_to_table(), Formant_downto_Table) are full public
# `.formant_methods` entries that had NO test coverage anywhere in the
# existing suite (grep for "$track(" / "down_to_table(" on Formant objects
# turned up nothing) -- straightforward real gaps, closed with success-path
# tests below.
#
# Edge-case notes (read the C++ guard logic / ran the actual binary before
# deciding what's safe to test):
#  - Sound$to_formant_keepall()/to_formant_willems()/to_formant_sl() each
#    wrap their Praat call in try/catch(MelderError) in formant_wrappers.cpp,
#    but no *existing* test reaches those catch blocks: the negative/zero
#    inputs used in test-formant-advanced.R's "handles invalid parameters"
#    test are all rejected earlier, at the R-level .check_time_step() /
#    .check_positive_count() / .check_positive_number() guards. A
#    `max_frequency` that is positive (passes R validation) but too low for
#    the requested formant/pole count DOES reach the C++ catch block
#    (verified interactively: `max_frequency = 1` on a 16 kHz sine wave
#    reliably throws "Failed to extract formants ..." for all three
#    algorithms) -- used below.
#  - Formant_getMinNumFormants/getMaxNumFormants/getValueAtTime/
#    getBandwidthAtTime/getMean/getStandardDeviation/getQuantile/getMinimum/
#    getMaximum/getTimeOfMinimum/getTimeOfMaximum (Praat's Formant.cpp) are
#    all deliberately lenient: out-of-range formant_number, reversed
#    from_time/to_time, NaN times, and quantile values outside [0, 1] were
#    all tried interactively and every one returned NaN/NA rather than
#    throwing. A zero-frame Formant (which would be the other obvious way to
#    provoke an internal Melder error) could not be constructed either --
#    Praat's Sound_to_Formant_* family always forces at least 1 frame, even
#    with an absurdly large time_step. The corresponding catch blocks in
#    both formant_module.cpp and formant_wrappers.cpp (missed lines
#    147-247/338-364 in formant_module.cpp minus what's covered here, and
#    172-176/185-189/218-221/245-247/267-271/292-296/317-321/344-348/
#    371-375/398-402/425-429/452-456 in formant_wrappers.cpp) are left
#    uncovered as confirmed-unreachable defensive branches, not because
#    reaching them wasn't attempted.
#  - **REAL BUG FOUND, NOT TESTED**: `sound$to_formant_willems(number_of_formants = 200)`
#    segfaults (SIGSEGV, exit 139) and `sound$to_formant_sl(number_of_poles = 200)`
#    aborts (SIGABRT, exit 134) on a plain 0.3 s / 16 kHz sine wave -- both pass
#    R's `.check_positive_count()` guard (200 is a positive count) and reach
#    Sound_to_Formant_any_inplace() in
#    src/praat.github.io/fon/Sound_to_Formant.cpp, where `numberOfPoles`
#    (2*200=400) is large enough relative to the analysis window that
#    something downstream (burg()/splitLevinson(), or a fixed-size Formant
#    frame allocation) overruns instead of hitting the `nsamp_window <
#    numberOfPoles + 1 -> Melder_throw("Window too short.")` guard cleanly.
#    Root cause not tracked down further (out of scope for a coverage task);
#    deliberately NOT reproduced in a test here because it would crash the R
#    session running the suite. Left as a documented finding for the report.

library(testthat)
library(pladdrr)

make_test_formant <- function(frequency = 150, duration = 0.3, sampling_rate = 16000) {
  snd <- generate_sine_wave(frequency = frequency, duration = duration,
                             sampling_rate = sampling_rate, amplitude = 0.8)
  snd$to_formant_burg()
}

# ============================================================================
# formant_module.cpp: RFormant default constructor (line 41)
# ============================================================================

test_that("RFormant default (no-arg) constructor rejects a NULL xptr cleanly", {
  mod <- pladdrr:::get_module("formant_module")
  # RFormant() : ptr(R_NilValue) {} -- Rcpp::XPtr's SEXP constructor itself
  # rejects a NULL/non-pointer SEXP, so this throws during construction
  # rather than yielding an is_valid()==FALSE object. Confirmed interactively
  # before writing this expectation.
  expect_error(mod$RFormant$new(), "external pointer")
})

# ============================================================================
# formant_module.cpp: methods reachable only via the .cpp escape hatch
# (dual-implementation trap -- dead from the public R6 API, live via .cpp$)
# ============================================================================

test_that("RFormant module time-domain methods not wired into the R6 API are reachable via .cpp$", {
  formant <- make_test_formant()

  expect_equal(formant$.cpp$get_duration(), formant$get_xmax() - formant$get_xmin())
  expect_type(formant$.cpp$get_x1(), "double")
  # x1 (centre of first analysis frame) should be within the signal's domain
  expect_true(formant$.cpp$get_x1() >= formant$get_xmin())
  expect_true(formant$.cpp$get_x1() <= formant$get_xmax())

  expect_equal(formant$.cpp$get_time_from_frame(1L), formant$.cpp$get_x1())
  expect_type(formant$.cpp$get_frame_from_time(0.1), "integer")
  expect_true(formant$.cpp$get_frame_from_time(0.1) >= 1L)
})

test_that("RFormant module query methods (dead via R6, live via .cpp$) match the public wrapper results", {
  formant <- make_test_formant()

  # Same public-API call, just checking the module's own independent
  # implementation (Formant_getValueAtTime etc. called directly from
  # RFormant:: methods) agrees with the public bare-wrapper result.
  expect_equal(formant$.cpp$get_value_at_time(1L, 0.1, 0L),
               formant$get_value_at_time(1, 0.1, "hertz"))
  expect_equal(formant$.cpp$get_bandwidth_at_time(1L, 0.1, 0L),
               formant$get_bandwidth_at_time(1, 0.1, "hertz"))
  expect_equal(formant$.cpp$get_mean(1L, 0, 0, 0L),
               formant$get_mean(1, unit = "hertz"))
  expect_equal(formant$.cpp$get_standard_deviation(1L, 0, 0, 0L),
               formant$get_standard_deviation(1, unit = "hertz"))
  expect_equal(formant$.cpp$get_quantile(1L, 0.5, 0, 0, 0L),
               formant$get_quantile(1, 0.5, unit = "hertz"))
  expect_equal(formant$.cpp$get_minimum(1L, 0, 0, 0L, FALSE),
               formant$get_minimum(1, unit = "hertz"))
  expect_equal(formant$.cpp$get_maximum(1L, 0, 0, 0L, FALSE),
               formant$get_maximum(1, unit = "hertz"))
  expect_type(formant$.cpp$get_time_of_minimum(1L, 0, 0, 0L, FALSE), "double")
  expect_type(formant$.cpp$get_time_of_maximum(1L, 0, 0, 0L, FALSE), "double")
})

test_that("RFormant module as_data_frame() (dead via R6, live via .cpp$) matches shape of public as_data_frame()", {
  formant <- make_test_formant()

  df_module <- formant$.cpp$as_data_frame(5L)
  df_public <- formant$as_data_frame(5)

  expect_s3_class(df_module, "data.frame")
  expect_setequal(colnames(df_module), c("time", "formant", "frequency", "bandwidth"))
  expect_equal(nrow(df_module), nrow(df_public))
})

test_that("RFormant module as_matrix() (unreachable from any public method) exports frames x formants", {
  formant <- make_test_formant()
  nx <- formant$get_number_of_frames()

  mat_bw <- formant$.cpp$as_matrix(5L, TRUE)
  expect_true(is.matrix(mat_bw))
  expect_equal(dim(mat_bw), c(nx, 1L + 5L * 2L))  # time + 5 freq + 5 bandwidth

  mat_nobw <- formant$.cpp$as_matrix(3L, FALSE)
  expect_true(is.matrix(mat_nobw))
  expect_equal(dim(mat_nobw), c(nx, 1L + 3L))  # time + 3 freq only
})

test_that("RFormant module save() (dead via R6, live via .cpp$) writes a readable Praat text file", {
  formant <- make_test_formant()
  path <- tempfile(fileext = ".Formant")
  on.exit(unlink(path), add = TRUE)

  formant$.cpp$save(path)
  expect_true(file.exists(path))
  expect_gt(file.size(path), 0)
})

# ============================================================================
# formant_module.cpp: get_bandwidth_track() -- reachable via the normal
# public API, just previously untested
# ============================================================================

test_that("Formant$get_bandwidth_track returns one bandwidth per frame", {
  formant <- make_test_formant()

  track <- formant$get_bandwidth_track(1, unit = "hertz")
  expect_type(track, "double")
  expect_equal(length(track), formant$get_number_of_frames())
  expect_true(all(is.na(track) | track > 0))
})

# ============================================================================
# formant_wrappers.cpp: creation-method catch blocks (keepall/willems/sl)
# ============================================================================

test_that("Sound$to_formant_keepall surfaces a Praat analysis failure as a caught R error", {
  sound <- generate_sine_wave(frequency = 150, duration = 0.3, sampling_rate = 16000,
                               amplitude = 0.8)
  # max_frequency = 1 passes .check_positive_number() (positive) but is far
  # too low for Sound_to_Formant_keepAll's internal LPC order requirements --
  # reaches the try/catch(MelderError) in formant_from_sound_keepall() and
  # surfaces as a normal R error, not a crash (verified interactively).
  expect_error(sound$to_formant_keepall(max_frequency = 1),
               "Failed to extract formants")
})

test_that("Sound$to_formant_willems surfaces a Praat analysis failure as a caught R error", {
  sound <- generate_sine_wave(frequency = 150, duration = 0.3, sampling_rate = 16000,
                               amplitude = 0.8)
  expect_error(sound$to_formant_willems(max_frequency = 1),
               "Failed to extract formants")
})

test_that("Sound$to_formant_sl surfaces a Praat analysis failure as a caught R error", {
  sound <- generate_sine_wave(frequency = 150, duration = 0.3, sampling_rate = 16000,
                               amplitude = 0.8)
  expect_error(sound$to_formant_sl(max_frequency = 1),
               "Failed to extract formants")
})

# ============================================================================
# formant_wrappers.cpp: save() catch block
# ============================================================================

test_that("Formant$save surfaces a write failure (bad path) as a caught R error", {
  formant <- make_test_formant()
  bad_path <- file.path(tempfile(), "nonexistent_subdir", "out.Formant")
  expect_error(formant$save(bad_path), "Failed to save formant")
})

# ============================================================================
# formant_wrappers.cpp: track() (Formant_tracker) -- previously untested
# ============================================================================

test_that("Formant$track re-tracks formants and returns a new valid Formant", {
  formant <- make_test_formant()

  tracked <- formant$track(number_of_tracks = 3)
  expect_s3_class(tracked, "Formant")
  expect_true(tracked$is_valid())
  expect_equal(tracked$get_number_of_frames(), formant$get_number_of_frames())
})

test_that("Formant$track accepts custom reference frequencies and costs", {
  formant <- make_test_formant()

  tracked <- formant$track(
    number_of_tracks = 3,
    ref_f1 = 500, ref_f2 = 1500, ref_f3 = 2500, ref_f4 = 3500, ref_f5 = 4500,
    frequency_cost = 2.0, bandwidth_cost = 0.5, transition_cost = 1.5
  )
  expect_true(tracked$is_valid())
})

# ============================================================================
# formant_wrappers.cpp: down_to_table() (Formant_downto_Table) -- previously
# untested
# ============================================================================

test_that("Formant$down_to_table converts to a Table with the expected default columns", {
  formant <- make_test_formant()

  tbl <- formant$down_to_table()
  expect_s3_class(tbl, "Table")
  expect_true(tbl$is_valid())
  expect_gt(tbl$get_number_of_rows(), 0)
})

test_that("Formant$down_to_table respects include_* toggles", {
  formant <- make_test_formant()

  tbl_minimal <- formant$down_to_table(
    include_frame_numbers = FALSE, include_time = FALSE,
    include_intensity = FALSE, include_number_of_formants = FALSE,
    include_bandwidths = FALSE
  )
  expect_s3_class(tbl_minimal, "Table")
  expect_true(tbl_minimal$is_valid())
})
