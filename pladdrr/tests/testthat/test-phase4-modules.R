# test-phase4-modules.R - Tests for Phase 4 Rcpp Modules (pladdrr 2.0)
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

# ============================================================================
# Matrix Module Tests
# ============================================================================

test_that("RMatrix module loads correctly", {
  skip_if_no_module("matrix")

  mod <- Rcpp::Module("matrix_module", PACKAGE = "pladdrr")
  expect_s4_class(mod, "Module")
  expect_true("RMatrix" %in% names(mod))
})

test_that("RMatrix can be created from R matrix", {
  skip_if_no_module("matrix")

  mod <- Rcpp::Module("matrix_module", PACKAGE = "pladdrr")

  # Create simple R matrix
  r_mat <- matrix(1:12, nrow = 3, ncol = 4)
  ptr <- mod$Matrix_from_r_matrix(r_mat)

  rmatrix <- new(mod$RMatrix, ptr)
  expect_true(rmatrix$is_valid())
  expect_equal(rmatrix$get_nrow(), 3)
  expect_equal(rmatrix$get_ncol(), 4)
})

test_that("RMatrix statistics work", {
  skip_if_no_module("matrix")

  mod <- Rcpp::Module("matrix_module", PACKAGE = "pladdrr")
  r_mat <- matrix(1:12, nrow = 3, ncol = 4)
  ptr <- mod$Matrix_from_r_matrix(r_mat)
  rmatrix <- new(mod$RMatrix, ptr)

  expect_equal(rmatrix$get_sum(), sum(1:12))
  expect_equal(rmatrix$get_mean(), mean(1:12))
  expect_equal(rmatrix$get_minimum(), 1)
  expect_equal(rmatrix$get_maximum(), 12)
})

test_that("RMatrix value access works", {
  skip_if_no_module("matrix")

  mod <- Rcpp::Module("matrix_module", PACKAGE = "pladdrr")
  r_mat <- matrix(1:12, nrow = 3, ncol = 4)
  ptr <- mod$Matrix_from_r_matrix(r_mat)
  rmatrix <- new(mod$RMatrix, ptr)

  # Note: Praat matrices are 1-indexed (row, col)
  expect_equal(rmatrix$get_value(1, 1), 1)
  expect_equal(rmatrix$get_value(3, 4), 12)

  # Set and verify
  rmatrix$set_value(2, 2, 99)
  expect_equal(rmatrix$get_value(2, 2), 99)
})

test_that("RMatrix export works", {
  skip_if_no_module("matrix")

  mod <- Rcpp::Module("matrix_module", PACKAGE = "pladdrr")
  r_mat <- matrix(1:12, nrow = 3, ncol = 4)
  ptr <- mod$Matrix_from_r_matrix(r_mat)
  rmatrix <- new(mod$RMatrix, ptr)

  exported <- rmatrix$as_matrix()
  expect_equal(dim(exported), c(3, 4))
  expect_equal(exported[1, 1], 1)
})

# ============================================================================
# Cepstrum Module Tests
# ============================================================================

test_that("RCepstrum module loads correctly", {
  skip_if_no_module("cepstrum")

  mod <- Rcpp::Module("cepstrum_module", PACKAGE = "pladdrr")
  expect_s4_class(mod, "Module")
  expect_true("RCepstrum" %in% names(mod))
})

test_that("RCepstrum can be created from Sound", {
  skip_if_no_module("cepstrum")
  skip_if_no_module("sound")

  snd <- Sound$new(system.file("extdata", "test.wav", package = "pladdrr"))
  sound_ptr <- snd$.__enclos_env__$private$ptr

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
  sound_ptr <- snd$.__enclos_env__$private$ptr

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
  expect_true("RPowerCepstrum" %in% names(mod))
  expect_true("RPowerCepstrogram" %in% names(mod))
})

test_that("RPowerCepstrum can be created from Spectrum", {
  skip_if_no_module("powercepstrum")
  skip_if_no_module("sound")
  skip_if_no_module("spectrum")

  snd <- Sound$new(system.file("extdata", "test.wav", package = "pladdrr"))
  spectrum <- snd$to_spectrum()
  spec_ptr <- spectrum$.__enclos_env__$private$ptr

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
  sound_ptr <- snd$.__enclos_env__$private$ptr

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
  sound_ptr <- snd$.__enclos_env__$private$ptr

  pc_mod <- Rcpp::Module("powercepstrum_module", PACKAGE = "pladdrr")
  pcg_ptr <- pc_mod$Sound_to_PowerCepstrogram(sound_ptr, 60, 0.01, 5000, 50)
  rpcg <- new(pc_mod$RPowerCepstrogram, pcg_ptr)

  cpps <- rpcg$get_cpps(TRUE, 0.02, 0.0005, 60, 330, 0.05, 2L, 0.001, 0, 2L, 2L)
  expect_type(cpps, "double")
})

# ============================================================================
# Cochleagram Module Tests
# ============================================================================

test_that("RCochleagram module loads correctly", {
  skip_if_no_module("cochleagram")

  mod <- Rcpp::Module("cochleagram_module", PACKAGE = "pladdrr")
  expect_s4_class(mod, "Module")
  expect_true("RCochleagram" %in% names(mod))
})

test_that("RCochleagram can be created from Sound", {
  skip_if_no_module("cochleagram")
  skip_if_no_module("sound")

  snd <- Sound$new(system.file("extdata", "test.wav", package = "pladdrr"))
  sound_ptr <- snd$.__enclos_env__$private$ptr

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
  sound_ptr <- snd$.__enclos_env__$private$ptr

  coch_mod <- Rcpp::Module("cochleagram_module", PACKAGE = "pladdrr")
  coch_ptr <- coch_mod$Sound_to_Cochleagram(sound_ptr, 0.01, 0.1, 0.03, 0.05)
  rcoch <- new(coch_mod$RCochleagram, coch_ptr)

  mat <- rcoch$as_matrix()
  expect_true(is.matrix(mat))
  expect_equal(nrow(mat), rcoch$get_ny())
  expect_equal(ncol(mat), rcoch$get_nx())
})

# ============================================================================
# Excitation Module Tests
# ============================================================================

test_that("RExcitation module loads correctly", {
  skip_if_no_module("excitation")

  mod <- Rcpp::Module("excitation_module", PACKAGE = "pladdrr")
  expect_s4_class(mod, "Module")
  expect_true("RExcitation" %in% names(mod))
})

test_that("RExcitation can be created from Spectrum", {
  skip_if_no_module("excitation")
  skip_if_no_module("sound")
  skip_if_no_module("spectrum")

  snd <- Sound$new(system.file("extdata", "test.wav", package = "pladdrr"))
  spectrum <- snd$to_spectrum()
  spec_ptr <- spectrum$.__enclos_env__$private$ptr

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
  spec_ptr <- spectrum$.__enclos_env__$private$ptr

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
  expect_true("RElectroglottogram" %in% names(mod))
})

test_that("RElectroglottogram can be extracted from Sound", {
  skip_if_no_module("electroglottogram")
  skip_if_no_module("sound")

  snd <- Sound$new(system.file("extdata", "test.wav", package = "pladdrr"))
  sound_ptr <- snd$.__enclos_env__$private$ptr

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
  sound_ptr <- snd$.__enclos_env__$private$ptr

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
  expect_true("RFormantGrid" %in% names(mod))
})

test_that("RFormantGrid can be created", {
  skip_if_no_module("formantgrid")

  fg_mod <- Rcpp::Module("formantgrid_module", PACKAGE = "pladdrr")
  fg_ptr <- fg_mod$FormantGrid_create(0, 1, 5L, 500, 1000, 50, 50)

  rfg <- new(fg_mod$RFormantGrid, fg_ptr)
  expect_true(rfg$is_valid())
  expect_equal(rfg$get_number_of_formants(), 5)
  expect_equal(rfg$get_duration(), 1)
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
  formant <- snd$to_formant()
  formant_ptr <- formant$.__enclos_env__$private$ptr

  fg_mod <- Rcpp::Module("formantgrid_module", PACKAGE = "pladdrr")
  fg_ptr <- fg_mod$Formant_to_FormantGrid(formant_ptr)

  rfg <- new(fg_mod$RFormantGrid, fg_ptr)
  expect_true(rfg$is_valid())
  expect_gt(rfg$get_number_of_formants(), 0)
})
