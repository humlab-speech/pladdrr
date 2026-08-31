# test-phase4-modules.R - Tests for Phase 4 Rcpp Modules (pladdrr 2.0)
library(data.table)
# Covers: Matrix, Cepstrum, PowerCepstrum, Cochleagram, Excitation,
#         Electroglottogram, FormantGrid

# ============================================================================
# Skip helpers
# ============================================================================

skip_if_no_module <- function(module_name) {
  tryCatch({
    mod <- Rcpp::Module(paste0(module_name, "_module"), PACKAGE = "pladdrr")
    TRUE
  }, error = function(e) {
    skip(paste0(module_name, " module not available"))
  })
}

# Shared state for the PowerCepstrum/PowerCepstrogram direct-module tests
# below. Those tests historically re-created this state across sibling
# test_that() frames (testthat shares one env per file); the three that abort
# R under MSVC on Windows run their bodies in an isolated child R process via
# probe_test() (helper-windows-crash-probe.R), so the child must rebuild the
# same state itself. Keep in sync with the inline setups in the tests.
PHASE4_PC_PREAMBLE <- c(
  "skip_if_no_module <- function(module_name) {",
  "  tryCatch({",
  "    mod <- Rcpp::Module(paste0(module_name, '_module'), PACKAGE = 'pladdrr')",
  "    TRUE",
  "  }, error = function(e) {",
  "    skip(paste0(module_name, ' module not available'))",
  "  })",
  "}",
  "snd <- Sound$new(system.file('extdata', 'test.wav', package = 'pladdrr'))",
  "sound_ptr <- snd$.xptr",
  "spectrum <- snd$to_spectrum()",
  "spec_ptr <- spectrum$.xptr",
  "pc_mod <- Rcpp::Module('powercepstrum_module', PACKAGE = 'pladdrr')",
  "pc_ptr <- pc_mod$Spectrum_to_PowerCepstrum(spec_ptr)",
  "rpc <- new(pc_mod$RPowerCepstrum, pc_ptr)",
  "pcg_ptr <- pc_mod$Sound_to_PowerCepstrogram(sound_ptr, 60, 0.01, 5000, 50)",
  "rpcg <- new(pc_mod$RPowerCepstrogram, pcg_ptr)"
)

# ============================================================================
# Matrix Module Tests
# ============================================================================

test_that("RMatrix module loads correctly", {
  skip_if_no_module("matrix")

  mod <- Rcpp::Module("matrix_module", PACKAGE = "pladdrr")
  expect_s4_class(mod, "Module")
  expect_false(is.null(mod$RMatrix))
})

test_that("RMatrix can be created from R matrix", {
  skip_if_no_module("matrix")

  mod <- Rcpp::Module("matrix_module", PACKAGE = "pladdrr")

  # Create simple R matrix
  r_mat <- matrix(1:12, nrow = 3, ncol = 4)
  ptr <- mod$Matrix_from_r_matrix(r_mat)

  rmatrix <- new(mod$RMatrix, ptr)
  expect_true(rmatrix$is_valid())
  expect_identical(rmatrix$get_nrow(), 3L)
  expect_identical(rmatrix$get_ncol(), 4L)
})

test_that("RMatrix statistics work", {
  skip_if_no_module("matrix")

  mod <- Rcpp::Module("matrix_module", PACKAGE = "pladdrr")
  r_mat <- matrix(1:12, nrow = 3, ncol = 4)
  ptr <- mod$Matrix_from_r_matrix(r_mat)
  rmatrix <- new(mod$RMatrix, ptr)

  expect_equal(rmatrix$get_sum(), sum(1:12), tolerance = sqrt(.Machine$double.eps))
  expect_equal(rmatrix$get_mean(), mean(1:12), tolerance = sqrt(.Machine$double.eps))
  expect_equal(rmatrix$get_minimum(), 1, tolerance = sqrt(.Machine$double.eps))
  expect_equal(rmatrix$get_maximum(), 12, tolerance = sqrt(.Machine$double.eps))
})

test_that("RMatrix value access works", {
  skip_if_no_module("matrix")

  mod <- Rcpp::Module("matrix_module", PACKAGE = "pladdrr")
  r_mat <- matrix(1:12, nrow = 3, ncol = 4)
  ptr <- mod$Matrix_from_r_matrix(r_mat)
  rmatrix <- new(mod$RMatrix, ptr)

  # Note: Praat matrices are 1-indexed (row, col)
  expect_equal(rmatrix$get_value(1, 1), 1, tolerance = sqrt(.Machine$double.eps))
  expect_equal(rmatrix$get_value(3, 4), 12, tolerance = sqrt(.Machine$double.eps))

  # Set and verify
  rmatrix$set_value(2, 2, 99)
  expect_equal(rmatrix$get_value(2, 2), 99, tolerance = sqrt(.Machine$double.eps))
})

test_that("RMatrix export works", {
  skip_if_no_module("matrix")

  mod <- Rcpp::Module("matrix_module", PACKAGE = "pladdrr")
  r_mat <- matrix(1:12, nrow = 3, ncol = 4)
  ptr <- mod$Matrix_from_r_matrix(r_mat)
  rmatrix <- new(mod$RMatrix, ptr)

  exported <- rmatrix$as_matrix()
  expect_equal(dim(exported), c(3, 4), tolerance = sqrt(.Machine$double.eps))
  expect_equal(exported[1, 1], 1, tolerance = sqrt(.Machine$double.eps))
})

# ============================================================================
# Cepstrum Module Tests
# ============================================================================

test_that("RCepstrum module loads correctly", {
  skip_if_no_module("cepstrum")

  mod <- Rcpp::Module("cepstrum_module", PACKAGE = "pladdrr")
  expect_s4_class(mod, "Module")
  expect_false(is.null(mod$RCepstrum))
})

test_that("RCepstrum can be created from Sound", {
  skip_if_no_module("cepstrum")
  skip_if_no_module("sound")

  snd <- Sound$new(system.file("extdata", "test.wav", package = "pladdrr"))
  sound_ptr <- snd$.xptr

  cep_mod <- Rcpp::Module("cepstrum_module", PACKAGE = "pladdrr")
  cep_ptr <- cep_mod$Sound_to_Cepstrum(sound_ptr)

  rcepstrum <- new(cep_mod$RCepstrum, cep_ptr)
  expect_true(rcepstrum$is_valid())
  expect_gt(rcepstrum$get_n_coefficients(), 0)
})

test_that("RCepstrum export works", {
  skip_if_no_module("cepstrum")
  skip_if_no_module("sound")

  snd <- Sound$new(system.file("extdata", "test.wav", package = "pladdrr"))
  sound_ptr <- snd$.xptr

  cep_mod <- Rcpp::Module("cepstrum_module", PACKAGE = "pladdrr")
  cep_ptr <- cep_mod$Sound_to_Cepstrum(sound_ptr)
  rcepstrum <- new(cep_mod$RCepstrum, cep_ptr)

  df <- rcepstrum$as_data_frame()
  expect_s3_class(df, "data.frame")
  expect_true("quefrency" %in% names(df))
  expect_true("value" %in% names(df))
})

# ============================================================================
# PowerCepstrum Module Tests
# ============================================================================

test_that("RPowerCepstrum module loads correctly", {
  skip_if_no_module("powercepstrum")

  mod <- Rcpp::Module("powercepstrum_module", PACKAGE = "pladdrr")
  expect_s4_class(mod, "Module")
  expect_false(is.null(mod$RPowerCepstrum))
  expect_false(is.null(mod$RPowerCepstrogram))
})

test_that("RPowerCepstrum can be created from Spectrum", {
  skip_if_no_module("powercepstrum")
  skip_if_no_module("sound")
  skip_if_no_module("spectrum")

  snd <- Sound$new(system.file("extdata", "test.wav", package = "pladdrr"))
  spectrum <- snd$to_spectrum()
  spec_ptr <- spectrum$.xptr

  pc_mod <- Rcpp::Module("powercepstrum_module", PACKAGE = "pladdrr")
  pc_ptr <- pc_mod$Spectrum_to_PowerCepstrum(spec_ptr)

  rpc <- new(pc_mod$RPowerCepstrum, pc_ptr)
  expect_true(rpc$is_valid())
  expect_gt(rpc$get_n_bins(), 0)
})

test_that("RPowerCepstrogram can be created from Sound", {
  skip_if_no_module("powercepstrum")
  skip_if_no_module("sound")

  snd <- Sound$new(system.file("extdata", "test.wav", package = "pladdrr"))
  sound_ptr <- snd$.xptr

  pc_mod <- Rcpp::Module("powercepstrum_module", PACKAGE = "pladdrr")
  pcg_ptr <- pc_mod$Sound_to_PowerCepstrogram(sound_ptr, 60, 0.01, 5000, 50)

  rpcg <- new(pc_mod$RPowerCepstrogram, pcg_ptr)
  expect_true(rpcg$is_valid())
  expect_gt(rpcg$get_nx(), 0)
  expect_gt(rpcg$get_ny(), 0)
})

test_that("RPowerCepstrogram CPPS works", {
  skip_if_no_module("powercepstrum")
  skip_if_no_module("sound")

  snd <- Sound$new(system.file("extdata", "test.wav", package = "pladdrr"))
  sound_ptr <- snd$.xptr

  pc_mod <- Rcpp::Module("powercepstrum_module", PACKAGE = "pladdrr")
  pcg_ptr <- pc_mod$Sound_to_PowerCepstrogram(sound_ptr, 60, 0.01, 5000, 50)
  rpcg <- new(pc_mod$RPowerCepstrogram, pcg_ptr)

  cpps <- rpcg$get_cpps(TRUE, 0.02, 0.0005, 60, 330, 0.05, 2L, 0.001, 0, 2L, 2L)
  expect_type(cpps, "double")
})

probe_test("RPowerCepstrum get_peak_prominence, hillenbrand, trend, smoothing, and export methods work", {
  # Coverage gap-fill note (task 20): PowerCepstrum$get_peak_prominence() (the
  # R6 method) dispatches to the bare .powercepstrum_get_peak_prominence()
  # wrapper.cpp export, NOT to this module's own get_peak_prominence() method
  # -- so this module method is otherwise dead code from the R6 API's
  # perspective (confirmed dual-implementation trap). Exercised directly here
  # via new(pc_mod$RPowerCepstrum, ptr), matching this file's existing
  # convention of testing module-only surface that the R6 wrapper doesn't use.
  skip_if_no_module("powercepstrum")
  skip_if_no_module("sound")
  skip_if_no_module("spectrum")

  snd <- Sound$new(system.file("extdata", "test.wav", package = "pladdrr"))
  spectrum <- snd$to_spectrum()
  spec_ptr <- spectrum$.xptr

  pc_mod <- Rcpp::Module("powercepstrum_module", PACKAGE = "pladdrr")
  pc_ptr <- pc_mod$Spectrum_to_PowerCepstrum(spec_ptr)
  rpc <- new(pc_mod$RPowerCepstrum, pc_ptr)

  # interpolation = parabolic(1), trend_type = exponential decay(2),
  # fit_method = robust slow(3) -- same integer codes R/constants.R's
  # .interp_map / .trend_line_map / .trend_fit_map use for these module calls.
  prom <- rpc$get_peak_prominence(60, 333.3, 1L, 0.001, 0.05, 2L, 3L)
  expect_true(is.numeric(prom))

  hb <- rpc$get_peak_prominence_hillenbrand(60, 333.3)
  expect_type(hb, "list")

  trend <- rpc$fit_trend_line(0.001, 0.05, 2L, 3L)
  expect_type(trend, "list")

  trend_val <- rpc$get_trend_line_value(0.005, 0.001, 0.05, 2L, 3L)
  expect_true(is.numeric(trend_val))

  smoothed_ptr <- rpc$smooth_ptr(0.0005, 100L)
  rpc_smoothed <- new(pc_mod$RPowerCepstrum, smoothed_ptr)
  expect_true(rpc_smoothed$is_valid())

  detrended_ptr <- rpc$subtract_trend_ptr(0.001, 0.05, 2L, 3L)
  rpc_detrended <- new(pc_mod$RPowerCepstrum, detrended_ptr)
  expect_true(rpc_detrended$is_valid())

  expect_no_error(rpc$subtract_trend_inplace(0.001, 0.05, 2L, 3L))

  spec_ptr2 <- rpc$to_spectrum_ptr(FALSE)
  expect_false(is.null(spec_ptr2))

  mat_ptr <- rpc$to_matrix_ptr()
  expect_false(is.null(mat_ptr))

  am <- rpc$as_matrix()
  expect_true(is.matrix(am))

  tmp <- tempfile()
  on.exit(unlink(tmp))
  expect_no_error(rpc$save(tmp))
}, preamble = PHASE4_PC_PREAMBLE)

probe_test("RPowerCepstrogram exposes time/quefrency domain properties, slicing, smoothing, matrix export, and save", {
  # Coverage gap-fill note (task 20): the PowerCepstrogram R6 class has NO
  # module at all ("# No module -- pure Rcpp function wrapper" in
  # R/powercepstrum.R) -- every one of RPowerCepstrogram's methods below is
  # unreachable from the normal PowerCepstrogram R6 API and can only be
  # exercised via direct module instantiation, as done throughout this file.
  skip_if_no_module("powercepstrum")
  skip_if_no_module("sound")

  snd <- Sound$new(system.file("extdata", "test.wav", package = "pladdrr"))
  sound_ptr <- snd$.xptr

  pc_mod <- Rcpp::Module("powercepstrum_module", PACKAGE = "pladdrr")
  pcg_ptr <- pc_mod$Sound_to_PowerCepstrogram(sound_ptr, 60, 0.01, 5000, 50)
  rpcg <- new(pc_mod$RPowerCepstrogram, pcg_ptr)

  expect_true(is.numeric(rpcg$get_xmin()))
  expect_true(is.numeric(rpcg$get_xmax()))
  expect_gt(rpcg$get_duration(), 0)
  expect_gt(rpcg$get_dx(), 0)
  expect_true(is.numeric(rpcg$get_ymin()))
  expect_true(is.numeric(rpcg$get_ymax()))
  expect_gt(rpcg$get_dy(), 0)

  mid_time <- (rpcg$get_xmin() + rpcg$get_xmax()) / 2
  cpp <- rpcg$get_cpp_at_time(mid_time, "cubic", 0.003, 0.04, "exponential decay", 0.05)
  expect_true(is.numeric(cpp))

  slice_ptr <- rpcg$get_slice_ptr(mid_time)
  rpc_slice <- new(pc_mod$RPowerCepstrum, slice_ptr)
  expect_true(rpc_slice$is_valid())

  smoothed_ptr <- rpcg$smooth_ptr(0.02, 0.001)
  rpcg_smoothed <- new(pc_mod$RPowerCepstrogram, smoothed_ptr)
  expect_true(rpcg_smoothed$is_valid())

  mat_ptr <- rpcg$to_matrix_ptr()
  expect_false(is.null(mat_ptr))

  am <- rpcg$as_matrix()
  expect_true(is.matrix(am))

  tmp <- tempfile()
  on.exit(unlink(tmp))
  expect_no_error(rpcg$save(tmp))
}, preamble = PHASE4_PC_PREAMBLE)

probe_test("powercepstrum_module's Sound_to_PowerCepstrogram free function validates pitch_floor, time_step, and maximum_frequency", {
  skip_if_no_module("powercepstrum")
  skip_if_no_module("sound")

  snd <- Sound$new(system.file("extdata", "test.wav", package = "pladdrr"))
  sound_ptr <- snd$.xptr
  pc_mod <- Rcpp::Module("powercepstrum_module", PACKAGE = "pladdrr")

  expect_error(pc_mod$Sound_to_PowerCepstrogram(sound_ptr, 0, 0.01, 5000, 50),
               "pitch_floor must be positive")
  expect_error(pc_mod$Sound_to_PowerCepstrogram(sound_ptr, 60, 0, 5000, 50),
               "time_step must be positive")
  expect_error(pc_mod$Sound_to_PowerCepstrogram(sound_ptr, 60, 0.01, 0, 50),
               "maximum_frequency must be between")
}, preamble = PHASE4_PC_PREAMBLE)

# ============================================================================
# Cochleagram Module Tests
# ============================================================================

test_that("RCochleagram module loads correctly", {
  skip_if_no_module("cochleagram")

  mod <- Rcpp::Module("cochleagram_module", PACKAGE = "pladdrr")
  expect_s4_class(mod, "Module")
  expect_false(is.null(mod$RCochleagram))
})

test_that("RCochleagram can be created from Sound", {
  skip_if_no_module("cochleagram")
  skip_if_no_module("sound")

  snd <- Sound$new(system.file("extdata", "test.wav", package = "pladdrr"))
  sound_ptr <- snd$.xptr

  coch_mod <- Rcpp::Module("cochleagram_module", PACKAGE = "pladdrr")
  coch_ptr <- coch_mod$Sound_to_Cochleagram(sound_ptr, 0.01, 0.1, 0.03, 0.05)

  rcoch <- new(coch_mod$RCochleagram, coch_ptr)
  expect_true(rcoch$is_valid())
  expect_gt(rcoch$get_nx(), 0)
  expect_gt(rcoch$get_ny(), 0)
})

test_that("RCochleagram export works", {
  skip_if_no_module("cochleagram")
  skip_if_no_module("sound")

  snd <- Sound$new(system.file("extdata", "test.wav", package = "pladdrr"))
  sound_ptr <- snd$.xptr

  coch_mod <- Rcpp::Module("cochleagram_module", PACKAGE = "pladdrr")
  coch_ptr <- coch_mod$Sound_to_Cochleagram(sound_ptr, 0.01, 0.1, 0.03, 0.05)
  rcoch <- new(coch_mod$RCochleagram, coch_ptr)

  mat <- rcoch$as_matrix()
  expect_true(is.matrix(mat))
  expect_equal(nrow(mat), rcoch$get_ny(), tolerance = sqrt(.Machine$double.eps))
  expect_equal(ncol(mat), rcoch$get_nx(), tolerance = sqrt(.Machine$double.eps))
})

# ============================================================================
# Excitation Module Tests
# ============================================================================

test_that("RExcitation module loads correctly", {
  skip_if_no_module("excitation")

  mod <- Rcpp::Module("excitation_module", PACKAGE = "pladdrr")
  expect_s4_class(mod, "Module")
  expect_false(is.null(mod$RExcitation))
})

test_that("RExcitation can be created from Spectrum", {
  skip_if_no_module("excitation")
  skip_if_no_module("sound")
  skip_if_no_module("spectrum")

  snd <- Sound$new(system.file("extdata", "test.wav", package = "pladdrr"))
  spectrum <- snd$to_spectrum()
  spec_ptr <- spectrum$.xptr

  exc_mod <- Rcpp::Module("excitation_module", PACKAGE = "pladdrr")
  exc_ptr <- exc_mod$Spectrum_to_Excitation(spec_ptr, 0.1)

  rexc <- new(exc_mod$RExcitation, exc_ptr)
  expect_true(rexc$is_valid())
  expect_gt(rexc$get_n_bins(), 0)
})

test_that("RExcitation loudness works", {
  skip_if_no_module("excitation")
  skip_if_no_module("sound")
  skip_if_no_module("spectrum")

  snd <- Sound$new(system.file("extdata", "test.wav", package = "pladdrr"))
  spectrum <- snd$to_spectrum()
  spec_ptr <- spectrum$.xptr

  exc_mod <- Rcpp::Module("excitation_module", PACKAGE = "pladdrr")
  exc_ptr <- exc_mod$Spectrum_to_Excitation(spec_ptr, 0.1)
  rexc <- new(exc_mod$RExcitation, exc_ptr)

  loudness <- rexc$get_loudness()
  expect_type(loudness, "double")
  expect_gte(loudness, 0)
})

# ============================================================================
# Electroglottogram Module Tests
# ============================================================================

test_that("RElectroglottogram module loads correctly", {
  skip_if_no_module("electroglottogram")

  mod <- Rcpp::Module("electroglottogram_module", PACKAGE = "pladdrr")
  expect_s4_class(mod, "Module")
  expect_false(is.null(mod$RElectroglottogram))
})

test_that("RElectroglottogram can be extracted from Sound", {
  skip_if_no_module("electroglottogram")
  skip_if_no_module("sound")

  snd <- Sound$new(system.file("extdata", "test.wav", package = "pladdrr"))
  sound_ptr <- snd$.xptr

  egg_mod <- Rcpp::Module("electroglottogram_module", PACKAGE = "pladdrr")
  egg_ptr <- egg_mod$Sound_extract_Electroglottogram(sound_ptr, 1L, FALSE)

  regg <- new(egg_mod$RElectroglottogram, egg_ptr)
  expect_true(regg$is_valid())
  expect_gt(regg$get_number_of_samples(), 0)
  expect_gt(regg$get_sample_rate(), 0)
})

test_that("RElectroglottogram export works", {
  skip_if_no_module("electroglottogram")
  skip_if_no_module("sound")

  snd <- Sound$new(system.file("extdata", "test.wav", package = "pladdrr"))
  sound_ptr <- snd$.xptr

  egg_mod <- Rcpp::Module("electroglottogram_module", PACKAGE = "pladdrr")
  egg_ptr <- egg_mod$Sound_extract_Electroglottogram(sound_ptr, 1L, FALSE)
  regg <- new(egg_mod$RElectroglottogram, egg_ptr)

  df <- regg$as_data_frame()
  expect_s3_class(df, "data.frame")
  expect_true("time" %in% names(df))
  expect_true("amplitude" %in% names(df))
})

# ============================================================================
# FormantGrid Module Tests
# ============================================================================

test_that("RFormantGrid module loads correctly", {
  skip_if_no_module("formantgrid")

  mod <- Rcpp::Module("formantgrid_module", PACKAGE = "pladdrr")
  expect_s4_class(mod, "Module")
  expect_false(is.null(mod$RFormantGrid))
})

test_that("RFormantGrid can be created", {
  skip_if_no_module("formantgrid")

  fg_mod <- Rcpp::Module("formantgrid_module", PACKAGE = "pladdrr")
  fg_ptr <- fg_mod$FormantGrid_create(0, 1, 5L, 500, 1000, 50, 50)

  rfg <- new(fg_mod$RFormantGrid, fg_ptr)
  expect_true(rfg$is_valid())
  expect_identical(rfg$get_number_of_formants(), 5L)
  expect_equal(rfg$get_duration(), 1, tolerance = sqrt(.Machine$double.eps))
})

test_that("RFormantGrid query works", {
  skip_if_no_module("formantgrid")

  fg_mod <- Rcpp::Module("formantgrid_module", PACKAGE = "pladdrr")
  fg_ptr <- fg_mod$FormantGrid_create(0, 1, 5L, 500, 1000, 50, 50)
  rfg <- new(fg_mod$RFormantGrid, fg_ptr)

  # Query first formant at t=0.5
  f1 <- rfg$get_formant_at_time(1L, 0.5)
  expect_equal(f1, 500, tolerance = 1)

  # Query second formant
  f2 <- rfg$get_formant_at_time(2L, 0.5)
  expect_equal(f2, 1500, tolerance = 1)  # 500 + 1000
})

test_that("RFormantGrid modification works", {
  skip_if_no_module("formantgrid")

  fg_mod <- Rcpp::Module("formantgrid_module", PACKAGE = "pladdrr")
  fg_ptr <- fg_mod$FormantGrid_create_empty(0, 1, 3L)
  rfg <- new(fg_mod$RFormantGrid, fg_ptr)

  # Add formant points
  rfg$add_formant_point(1L, 0.0, 500)
  rfg$add_formant_point(1L, 0.5, 600)
  rfg$add_formant_point(1L, 1.0, 500)

  # Verify
  expect_equal(rfg$get_formant_at_time(1L, 0.0), 500, tolerance = 1)
  expect_equal(rfg$get_formant_at_time(1L, 0.5), 600, tolerance = 1)
})

test_that("RFormantGrid from Formant works", {
  skip_if_no_module("formantgrid")
  skip_if_no_module("sound")
  skip_if_no_module("formant")

  snd <- Sound$new(system.file("extdata", "test.wav", package = "pladdrr"))
  formant <- snd$to_formant_burg()
  formant_ptr <- formant$.xptr

  fg_mod <- Rcpp::Module("formantgrid_module", PACKAGE = "pladdrr")
  fg_ptr <- fg_mod$Formant_to_FormantGrid(formant_ptr)

  rfg <- new(fg_mod$RFormantGrid, fg_ptr)
  expect_true(rfg$is_valid())
  expect_gt(rfg$get_number_of_formants(), 0)
})
