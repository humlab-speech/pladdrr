# test-lpc-module-gaps.R
#
# Coverage for src/modules/lpc_module.cpp (RLPC Rcpp Module class) and the
# non-R6-reachable Rcpp::export wrappers in src/lpc_wrappers.cpp.
#
# R6's LPC$... dispatch table (R/lpc-wrapper.R, .lpc_methods) only calls a
# subset of RLPC's methods (get_number_of_frames/get_time_step/
# get_sampling_period/get_max_num_coefficients/get_gain_at_frame/
# get_coefficients_at_frame/get_all_gains/get_all_coefficients/is_valid),
# and routes conversions/inverse-filtering through separate Rcpp::export
# wrappers in lpc_wrappers.cpp (.lpc_to_spectrum, .lpc_to_matrix,
# .lpc_to_spectrogram, .lpc_sound_filter_inverse_r6,
# .lpc_sound_filter_inverse_at_time) rather than RLPC's own
# to_spectrum_ptr/to_matrix_ptr/filter_inverse_ptr/filter_inverse_at_time_ptr.
#
# The `.cpp` field on an LPC S3 object is the real, live RLPC module
# instance -- calling its methods directly (bypassing the R6-style
# dispatch table) exercises real compiled code, it's just a different
# entry point than the one `$` normally routes through. See the
# "PowerCepstrum dual-implementation trap" pattern documented elsewhere
# in this codebase: check both entry points before assuming a missed
# line is dead.

test_that("RLPC getters not exposed via LPC$ dispatch table work via $.cpp directly", {
  sound <- generate_sine_wave(150, 0.3, sampling_rate = 16000)
  lpc <- sound$to_lpc_burg()

  # get_xmin/get_xmax/get_duration/get_x1/get_sampling_frequency have no
  # R6-dispatch counterpart (only get_nx/get_dx aliases -- exposed as
  # get_number_of_frames()/get_time_step() -- are used by R/lpc-wrapper.R).
  expect_type(lpc$.cpp$get_xmin(), "double")
  expect_type(lpc$.cpp$get_xmax(), "double")
  expect_gt(lpc$.cpp$get_xmax(), lpc$.cpp$get_xmin())
  expect_equal(lpc$.cpp$get_duration(), lpc$.cpp$get_xmax() - lpc$.cpp$get_xmin())
  expect_type(lpc$.cpp$get_x1(), "double")
  expect_type(lpc$.cpp$get_sampling_frequency(), "double")
  expect_equal(lpc$.cpp$get_sampling_frequency(), 1 / lpc$.cpp$get_sampling_period())

  # get_nx/get_dx are the underlying implementations behind the R6-exposed
  # aliases get_number_of_frames()/get_time_step() -- cross check.
  expect_equal(lpc$.cpp$get_nx(), lpc$get_number_of_frames())
  expect_equal(lpc$.cpp$get_dx(), lpc$get_time_step())
})

test_that("RLPC$get_num_coefficients_at_frame works (no R6-dispatch counterpart)", {
  sound <- generate_sine_wave(150, 0.3, sampling_rate = 16000)
  lpc <- sound$to_lpc_burg(prediction_order = 10)

  n_coef <- lpc$.cpp$get_num_coefficients_at_frame(1)
  expect_type(n_coef, "integer")
  expect_gte(n_coef, 1)
  # Should agree with the length of the coefficient vector for that frame.
  expect_equal(n_coef, length(lpc$get_coefficients_at_frame(1)))
})

test_that("RLPC frame/time conversion methods work (no R6-dispatch counterpart)", {
  sound <- generate_sine_wave(150, 0.3, sampling_rate = 16000)
  lpc <- sound$to_lpc_burg()

  n_frames <- lpc$get_number_of_frames()
  t1 <- lpc$.cpp$get_time_from_frame(1)
  expect_type(t1, "double")

  # Round trip: time -> nearest frame should land back on (or very near) 1
  # for the first frame's own time.
  frame_back <- lpc$.cpp$get_frame_from_time(t1)
  expect_type(frame_back, "integer")
  expect_equal(frame_back, 1L)

  t_last <- lpc$.cpp$get_time_from_frame(n_frames)
  expect_gt(t_last, t1)
})

test_that("RLPC$get_gain_at_frame / get_coefficients_at_frame reject out-of-range frames", {
  sound <- generate_sine_wave(150, 0.3, sampling_rate = 16000)
  lpc <- sound$to_lpc_burg()
  n_frames <- lpc$get_number_of_frames()

  # The C++ guard (`frame_number < 1 || frame_number > ptr->nx`) runs before
  # any array indexing, so these are caught R errors, not crashes.
  expect_error(lpc$.cpp$get_gain_at_frame(0L), "out of range")
  expect_error(lpc$.cpp$get_gain_at_frame(n_frames + 1L), "out of range")
  expect_error(lpc$.cpp$get_coefficients_at_frame(0L), "out of range")
  expect_error(lpc$.cpp$get_coefficients_at_frame(n_frames + 1L), "out of range")
  expect_error(lpc$.cpp$get_num_coefficients_at_frame(0L), "out of range")
})

test_that("RLPC$to_spectrum_ptr / to_matrix_ptr work directly (R6 routes through lpc_wrappers.cpp instead)", {
  sound <- generate_sine_wave(150, 0.3, sampling_rate = 16000)
  lpc <- sound$to_lpc_burg()

  spec_ptr <- lpc$.cpp$to_spectrum_ptr(0.1, 20.0, 0.0, 50.0)
  expect_true(inherits(spec_ptr, "externalptr"))
  spec <- Spectrum(.xptr = spec_ptr)
  expect_s3_class(spec, "Spectrum")

  mat_ptr <- lpc$.cpp$to_matrix_ptr()
  expect_true(inherits(mat_ptr, "externalptr"))
  mat <- Matrix(.xptr = mat_ptr)
  expect_s3_class(mat, "Matrix")
})

test_that("RLPC$filter_inverse_ptr / filter_inverse_at_time_ptr work directly on a raw Sound xptr", {
  # R6's LPC$filter_inverse(sound) is broken (documented in test-lpc-r6.R):
  # .lpc_sound_filter_inverse_r6() expects an R6-shaped S4 object and
  # pladdrr's Sound() is a plain S3 list. RLPC$filter_inverse_ptr(), by
  # contrast, takes a raw XPtr<structSound> (same shape sound$get_xptr()
  # returns) and has no such S4-conversion step -- it's reachable and works.
  sound <- generate_sine_wave(150, 0.3, sampling_rate = 16000)
  lpc <- sound$to_lpc_burg()

  source_ptr <- lpc$.cpp$filter_inverse_ptr(sound$get_xptr())
  expect_true(inherits(source_ptr, "externalptr"))
  source_sound <- Sound(.xptr = source_ptr)
  expect_s3_class(source_sound, "Sound")

  source_ptr2 <- lpc$.cpp$filter_inverse_at_time_ptr(sound$get_xptr(), 1L, 0.1)
  expect_true(inherits(source_ptr2, "externalptr"))
  source_sound2 <- Sound(.xptr = source_ptr2)
  expect_s3_class(source_sound2, "Sound")
})

test_that("RLPC$as_data_frame / get_info / save work directly (no R6-dispatch counterpart)", {
  sound <- generate_sine_wave(150, 0.3, sampling_rate = 16000)
  lpc <- sound$to_lpc_burg(prediction_order = 8)
  n_frames <- lpc$get_number_of_frames()

  df <- lpc$.cpp$as_data_frame()
  expect_s3_class(df, "data.frame")
  expect_equal(nrow(df), n_frames)
  expect_setequal(names(df), c("time", "gain", "n_coefficients"))
  expect_equal(df$gain, lpc$get_all_gains())

  info <- lpc$.cpp$get_info()
  expect_type(info, "list")
  expect_setequal(
    names(info),
    c("xmin", "xmax", "nx", "dx", "x1", "sampling_period", "max_n_coefficients")
  )
  expect_equal(info$nx, n_frames)
  expect_equal(info$max_n_coefficients, lpc$get_max_num_coefficients())

  tmp <- tempfile(fileext = ".LPC")
  on.exit(unlink(tmp), add = TRUE)
  expect_no_error(lpc$.cpp$save(tmp))
  expect_true(file.exists(tmp))
  expect_gt(file.info(tmp)$size, 0)
})

test_that("Module_Sound_to_LPC_burg/auto/covar/marple factory functions work directly (dead from R6's perspective)", {
  # R/sound-wrapper.R's Sound$to_lpc_burg()/to_lpc_auto()/to_lpc_covariance()/
  # to_lpc_marple() all call the standalone Rcpp::export wrappers in
  # lpc_wrappers.cpp (.sound_to_lpc_burg etc, RcppExports.R), never the
  # near-duplicate Module_Sound_to_LPC_* factory functions registered on
  # the lpc_module Rcpp Module itself. Those are only reachable by pulling
  # the module directly.
  sound <- generate_sine_wave(150, 0.3, sampling_rate = 16000)
  lpc_mod <- pladdrr:::get_module("lpc_module")

  burg_ptr <- lpc_mod$Sound_to_LPC_burg(sound$get_xptr(), 12L, 0.025, 0.005, 50.0)
  expect_true(inherits(burg_ptr, "externalptr"))
  expect_s3_class(LPC(.xptr = burg_ptr), "LPC")

  auto_ptr <- lpc_mod$Sound_to_LPC_auto(sound$get_xptr(), 12L, 0.025, 0.005, 50.0)
  expect_true(inherits(auto_ptr, "externalptr"))
  expect_s3_class(LPC(.xptr = auto_ptr), "LPC")

  covar_ptr <- lpc_mod$Sound_to_LPC_covar(sound$get_xptr(), 12L, 0.025, 0.005, 50.0)
  expect_true(inherits(covar_ptr, "externalptr"))
  expect_s3_class(LPC(.xptr = covar_ptr), "LPC")

  marple_ptr <- lpc_mod$Sound_to_LPC_marple(sound$get_xptr(), 12L, 0.025, 0.005, 50.0, 1e-6, 1e-6)
  expect_true(inherits(marple_ptr, "externalptr"))
  expect_s3_class(LPC(.xptr = marple_ptr), "LPC")
})

test_that("Module_Sound_to_LPC_* factory functions reject an invalid Sound pointer", {
  lpc_mod <- pladdrr:::get_module("lpc_module")
  null_ptr <- methods::new("externalptr")

  expect_error(lpc_mod$Sound_to_LPC_burg(null_ptr, 12L, 0.025, 0.005, 50.0), "Invalid Sound pointer")
})

test_that(".lpc_sound_filter_inverse (raw-xptr variant) works directly, unlike the broken R6 _r6 variant", {
  # lpc_wrappers.cpp exports BOTH .lpc_sound_filter_inverse(lpc_xptr, sound_xptr)
  # (raw XPtr<structSound>, no S4 conversion) and
  # .lpc_sound_filter_inverse_r6(lpc_xptr, sound_r6) (expects R6-shaped S4,
  # broken for pladdrr's S3 Sound -- see test-lpc-r6.R). R6's LPC$filter_inverse()
  # only calls the _r6 variant; the raw-xptr variant is otherwise dead from R6
  # but directly reachable and correct, matching the working
  # filter_inverse_at_time() pattern.
  sound <- generate_sine_wave(150, 0.3, sampling_rate = 16000)
  lpc <- sound$to_lpc_burg()

  source_ptr <- pladdrr:::.lpc_sound_filter_inverse(lpc$.xptr, sound$get_xptr())
  expect_true(inherits(source_ptr, "externalptr"))
  source_sound <- Sound(.xptr = source_ptr)
  expect_s3_class(source_sound, "Sound")
})
