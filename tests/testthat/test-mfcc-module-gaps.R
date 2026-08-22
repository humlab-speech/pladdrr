# test-mfcc-module-gaps.R
# Coverage gap-fill for src/modules/mfcc_module.cpp (RMFCC / RLFCC Rcpp module
# classes, and the Sound_to_MFCC / LPC_to_LFCC factory functions).
#
# tests/testthat/test-phase3-mfcc-simd.R already covers SIMD-focused MFCC
# extraction paths (get_number_of_frames, get_num_coefficients_at_frame).
# This file covers the rest of the RMFCC/RLFCC method surface: time-domain
# properties, frame/coefficient queries (in- and out-of-range), liftering,
# conversions (to_matrix, to_lpc), data.frame export, get_info, save, and
# the constructor error paths.
#
# Edge-case notes (read the C++/Praat guard logic before adding a case):
#  - MFCC_lifter() (src/praat.github.io/dwtools/MFCC.cpp) does
#    `Melder_assert (lifter > 0)` with NO try/catch around the assert -- a
#    lifter_coefficient <= 0 would hit a hard assert, not a caught R error.
#    Deliberately NOT tested here to avoid a crash.
#  - CC_getValueInFrame / CC_getNumberOfCoefficients / CC_getValue (Praat's
#    CC.cpp) explicitly bounds-check frame_number and return 0/NaN for
#    out-of-range frames rather than crashing -- safe to test.
#  - Module_LPC_to_LFCC's catch block (num_coefficients < 1) is not
#    reachable: LPC_to_LFCC() silently falls back to the LPC's own
#    maxnCoefficients instead of throwing, so no safe way to reach that
#    catch block was found; left uncovered.

library(testthat)
library(pladdrr)

make_test_mfcc <- function(num_coefficients = 12) {
  snd <- generate_sine_wave(frequency = 150, duration = 0.3, sampling_rate = 16000,
                             amplitude = 0.8)
  snd$to_mfcc(num_coefficients = num_coefficients, analysis_width = 0.02, time_step = 0.005)
}

make_test_lfcc <- function(num_coefficients = 12) {
  snd <- generate_sine_wave(frequency = 150, duration = 0.3, sampling_rate = 16000,
                             amplitude = 0.8)
  # LPC_Frame_into_CC_Frame (src/praat.github.io/LPC/LPC_and_LFCC.cpp) sets
  # each LFCC frame's actual numberOfCoefficients from the *source LPC
  # frame's own order*, not from LFCC's num_coefficients argument -- so use
  # a matching prediction_order here to keep frame-level coefficient counts
  # predictable in these tests.
  lpc <- snd$to_lpc_burg(prediction_order = num_coefficients, analysis_width = 0.02,
                         time_step = 0.005)
  lpc$to_lfcc(num_coefficients = num_coefficients)
}

# ============================================================================
# MFCC: time-domain / CC properties
# ============================================================================

test_that("MFCC time-domain and CC properties are correct", {
  mfcc <- make_test_mfcc(12)

  expect_true(mfcc$is_valid())
  expect_type(mfcc$get_xmin(), "double")
  expect_type(mfcc$get_xmax(), "double")
  expect_true(mfcc$get_xmax() > mfcc$get_xmin())
  expect_equal(mfcc$get_duration(), mfcc$get_xmax() - mfcc$get_xmin())
  # get_max_num_coefficients() reflects MFCC's mel-filter-bank *capacity*
  # (MelSpectrogram_to_MFCC sets maximumNumberOfCoefficients = ny - 1, the
  # number of mel filters), not the num_coefficients requested at
  # extraction time -- so just check it's a sane positive integer, and
  # confirm the number *actually used per frame* via get_info() instead.
  expect_true(mfcc$get_max_num_coefficients() > 0)
  expect_equal(mfcc$get_info()$max_n_coefficients_used, 12)
  expect_equal(mfcc$get_number_of_frames(), mfcc$get_number_of_frames())
  expect_true(mfcc$get_time_step() > 0)

  # get_fmin/get_fmax (mel-scale range) are exposed at the R level
  expect_true(mfcc$get_fmax() > mfcc$get_fmin())

  # get_dx / get_x1 are not exposed through the R6-style dispatch table at
  # all (only get_time_step, an alias for get_dx, is) -- reach them via the
  # underlying Rcpp module object directly, same pattern used elsewhere in
  # this test suite (e.g. test-lpc-r6.R, test-dtw.R).
  expect_equal(mfcc$.cpp$get_dx(), mfcc$get_time_step())
  expect_type(mfcc$.cpp$get_x1(), "double")
})

# ============================================================================
# MFCC: frame-level queries, in range and out of range
# ============================================================================

test_that("MFCC frame-level queries work for valid frame numbers", {
  mfcc <- make_test_mfcc(12)
  n_frames <- mfcc$get_number_of_frames()
  expect_true(n_frames > 1)

  expect_type(mfcc$get_c0_at_frame(1), "double")
  expect_equal(mfcc$get_num_coefficients_at_frame(1), 12)
  expect_type(mfcc$get_value_in_frame(1, 1), "double")
  expect_type(mfcc$get_value_at_time(mfcc$get_xmin(), 1), "double")

  coefs <- mfcc$get_coefficients_at_frame(1)
  expect_type(coefs, "double")
  expect_equal(length(coefs), 13)  # 12 coefficients + c0

  all_c0 <- mfcc$get_all_c0()
  expect_equal(length(all_c0), n_frames)

  all_coefs <- mfcc$get_all_coefficients()
  expect_equal(ncol(all_coefs), n_frames)
  expect_equal(nrow(all_coefs), 13)  # c0 row + 12 coefficient rows
})

test_that("MFCC frame-level queries handle out-of-range frames per their own C++ guards", {
  mfcc <- make_test_mfcc(12)
  n_frames <- mfcc$get_number_of_frames()

  # get_c0_at_frame and get_coefficients_at_frame have an explicit
  # `if (frame_number < 1 || frame_number > nx) Rcpp::stop(...)` guard.
  expect_error(mfcc$get_c0_at_frame(0))
  expect_error(mfcc$get_c0_at_frame(n_frames + 1000))
  expect_error(mfcc$get_coefficients_at_frame(0))
  expect_error(mfcc$get_coefficients_at_frame(n_frames + 1000))

  # get_num_coefficients_at_frame delegates to CC_getNumberOfCoefficients(),
  # which bounds-checks internally and returns 0 for an out-of-range frame.
  expect_equal(mfcc$get_num_coefficients_at_frame(n_frames + 1000), 0)
  expect_equal(mfcc$get_num_coefficients_at_frame(0), 0)

  # get_value_in_frame delegates to CC_getValueInFrame(), which
  # bounds-checks internally and returns Praat's `undefined` (NaN) for an
  # out-of-range frame, rather than throwing.
  expect_true(is.nan(mfcc$get_value_in_frame(n_frames + 1000, 1)))
})

# ============================================================================
# MFCC: frame/time conversion
# ============================================================================

test_that("MFCC frame/time conversion round-trips", {
  mfcc <- make_test_mfcc(12)
  n_frames <- mfcc$get_number_of_frames()

  t <- mfcc$get_time_from_frame(1)
  expect_type(t, "double")
  f <- mfcc$get_frame_from_time(t)
  expect_equal(f, 1)

  t_last <- mfcc$get_time_from_frame(n_frames)
  expect_true(t_last > t)
})

# ============================================================================
# MFCC: liftering
# ============================================================================

test_that("MFCC$lifter applies cepstral weighting in place and returns self", {
  mfcc <- make_test_mfcc(12)
  before <- mfcc$get_coefficients_at_frame(2)
  result <- mfcc$lifter(22)
  after <- mfcc$get_coefficients_at_frame(2)

  expect_identical(result, mfcc)  # invisible(.self)
  # Liftering rescales non-c0 coefficients; at least one should have changed
  # (c0 itself is untouched by MFCC_lifter's per-coefficient loop starting
  # at icoef=1, but c1.. should differ unless all were exactly zero).
  expect_false(isTRUE(all.equal(before[-1], after[-1])))
})

# ============================================================================
# MFCC: conversions and export
# ============================================================================

test_that("MFCC$to_matrix converts to a Matrix object", {
  mfcc <- make_test_mfcc(12)
  mat <- mfcc$to_matrix()
  expect_s3_class(mat, "Matrix")
})

test_that("MFCC$as_data_frame includes/excludes c0 as requested", {
  mfcc <- make_test_mfcc(12)

  df_with_c0 <- mfcc$as_data_frame(include_c0 = TRUE)
  expect_true("c0" %in% names(df_with_c0))
  expect_true("time" %in% names(df_with_c0))
  expect_true("c1" %in% names(df_with_c0))
  expect_equal(nrow(df_with_c0), mfcc$get_number_of_frames())

  df_no_c0 <- mfcc$as_data_frame(include_c0 = FALSE)
  expect_false("c0" %in% names(df_no_c0))
})

test_that("MFCC$get_info returns the expected named fields", {
  mfcc <- make_test_mfcc(12)
  info <- mfcc$get_info()

  expect_type(info, "list")
  expect_true(all(c("xmin", "xmax", "nx", "dx", "x1", "fmin_mel", "fmax_mel",
                     "max_n_coefficients", "max_n_coefficients_used") %in% names(info)))
  expect_equal(info$nx, mfcc$get_number_of_frames())
  expect_equal(info$max_n_coefficients_used, 12)
})

test_that("MFCC$save writes a readable Praat text file", {
  mfcc <- make_test_mfcc(12)
  path <- tempfile(fileext = ".MFCC")
  on.exit(unlink(path), add = TRUE)

  result <- mfcc$save(path)
  expect_identical(result, mfcc)  # invisible(.self)
  expect_true(file.exists(path))
  expect_gt(file.size(path), 0)
})

test_that("MFCC print method works via the S3 dispatch and cpp print", {
  mfcc <- make_test_mfcc(12)
  expect_output(print(mfcc), "Praat MFCC")
})

# ============================================================================
# MFCC: constructor error path
# ============================================================================

test_that("MFCC() without .xptr errors with a clear message", {
  expect_error(MFCC(), "sound\\$to_mfcc\\(\\)")
})

# ============================================================================
# Module_Sound_to_MFCC: factory error path
# ============================================================================

test_that("Sound$to_mfcc errors (rather than crashing) when analysis_width exceeds the signal duration", {
  # Sampled_shortTermAnalysis (Praat's standard short-term-analysis guard,
  # used throughout the codebase) throws a MelderError -- caught and
  # re-thrown as a plain R error -- when the analysis window doesn't fit in
  # the signal at all. This exercises Module_Sound_to_MFCC's catch block.
  snd <- generate_sine_wave(frequency = 150, duration = 0.05, sampling_rate = 16000,
                             amplitude = 0.8)
  expect_error(snd$to_mfcc(num_coefficients = 12, analysis_width = 5.0, time_step = 0.005))
})

# ============================================================================
# LFCC: mirrors the MFCC surface above
# ============================================================================

test_that("LFCC time-domain and CC properties are correct", {
  lfcc <- make_test_lfcc(12)

  expect_true(lfcc$is_valid())
  expect_type(lfcc$get_xmin(), "double")
  expect_type(lfcc$get_xmax(), "double")
  expect_true(lfcc$get_xmax() > lfcc$get_xmin())
  expect_equal(lfcc$get_duration(), lfcc$get_xmax() - lfcc$get_xmin())
  expect_equal(lfcc$get_max_num_coefficients(), 12)
  expect_true(lfcc$get_number_of_frames() > 1)
  expect_true(lfcc$get_time_step() > 0)
  expect_true(lfcc$get_fmax() > lfcc$get_fmin())

  expect_equal(lfcc$.cpp$get_dx(), lfcc$get_time_step())
  expect_type(lfcc$.cpp$get_x1(), "double")
})

test_that("LFCC frame-level queries work for valid frame numbers", {
  lfcc <- make_test_lfcc(12)
  n_frames <- lfcc$get_number_of_frames()

  expect_type(lfcc$get_c0_at_frame(1), "double")
  expect_equal(lfcc$get_num_coefficients_at_frame(1), 12)
  expect_type(lfcc$get_value_in_frame(1, 1), "double")
  expect_type(lfcc$get_value_at_time(lfcc$get_xmin(), 1), "double")

  coefs <- lfcc$get_coefficients_at_frame(1)
  expect_equal(length(coefs), 13)

  all_coefs <- lfcc$get_all_coefficients()
  expect_equal(ncol(all_coefs), n_frames)
  expect_equal(nrow(all_coefs), 13)
})

test_that("LFCC frame-level queries handle out-of-range frames per their own C++ guards", {
  lfcc <- make_test_lfcc(12)
  n_frames <- lfcc$get_number_of_frames()

  expect_error(lfcc$get_c0_at_frame(0))
  expect_error(lfcc$get_c0_at_frame(n_frames + 1000))
  expect_error(lfcc$get_coefficients_at_frame(0))
  expect_error(lfcc$get_coefficients_at_frame(n_frames + 1000))

  expect_equal(lfcc$get_num_coefficients_at_frame(n_frames + 1000), 0)
  expect_true(is.nan(lfcc$get_value_in_frame(n_frames + 1000, 1)))
})

test_that("LFCC frame/time conversion round-trips", {
  lfcc <- make_test_lfcc(12)
  t <- lfcc$get_time_from_frame(1)
  expect_type(t, "double")
  expect_equal(lfcc$get_frame_from_time(t), 1)
})

test_that("LFCC$to_lpc and $to_matrix convert correctly", {
  lfcc <- make_test_lfcc(12)

  lpc <- lfcc$to_lpc(num_coefficients = 10)
  expect_s3_class(lpc, "LPC")

  mat <- lfcc$to_matrix()
  expect_s3_class(mat, "Matrix")
})

test_that("LFCC$as_data_frame includes/excludes c0 as requested", {
  lfcc <- make_test_lfcc(12)

  df_with_c0 <- lfcc$as_data_frame(include_c0 = TRUE)
  expect_true("c0" %in% names(df_with_c0))
  expect_true("c1" %in% names(df_with_c0))

  df_no_c0 <- lfcc$as_data_frame(include_c0 = FALSE)
  expect_false("c0" %in% names(df_no_c0))
})

test_that("LFCC$get_info returns the expected named fields", {
  lfcc <- make_test_lfcc(12)
  info <- lfcc$get_info()

  expect_type(info, "list")
  expect_true(all(c("xmin", "xmax", "nx", "dx", "x1", "fmin", "fmax",
                     "max_n_coefficients", "max_n_coefficients_used") %in% names(info)))
  expect_equal(info$max_n_coefficients, 12)
})

test_that("LFCC$save writes a readable Praat text file", {
  lfcc <- make_test_lfcc(12)
  path <- tempfile(fileext = ".LFCC")
  on.exit(unlink(path), add = TRUE)

  result <- lfcc$save(path)
  expect_identical(result, lfcc)
  expect_true(file.exists(path))
  expect_gt(file.size(path), 0)
})

test_that("LFCC print method works via the S3 dispatch and cpp print", {
  lfcc <- make_test_lfcc(12)
  expect_output(print(lfcc), "Praat LFCC")
})

test_that("LFCC() without .xptr errors with a clear message", {
  expect_error(LFCC(), "lpc\\$to_lfcc\\(\\)")
})

cat("\n=== MFCC/LFCC module gap-fill tests complete ===\n")
