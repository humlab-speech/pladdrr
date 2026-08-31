# tests/testthat/test-parallel-batch-gaps.R
# Coverage gap-fill for R/parallel-batch.R (was ~29%): the parallel batch
# processing family. macOS exercises the PSOCK cluster path of
# analyze_files_parallel (the loadNamespace+attachNamespace worker init)
# and the mclapply path of process_sounds_parallel.

test_wav <- function() system.file("extdata", "test.wav", package = "pladdrr")
snd_fixture <- function() Sound$create_tone(frequency = 220, duration = 0.2,
  sampling_rate = 16000)

test_that(".pladdrr_worker_thread_budget caps worker threads", {
  expect_identical(pladdrr:::.pladdrr_worker_thread_budget(2, 3), 3L)
  expect_gte(pladdrr:::.pladdrr_worker_thread_budget(2), 1L)
})

test_that("process_sounds_parallel single-core fallback applies func", {
  snds <- list(snd_fixture(), snd_fixture())
  res <- process_sounds_parallel(snds, function(s) s$get_duration(),
    n_cores = 1)
  expect_length(res, 2)
  expect_equal(res[[1]], 0.2, tolerance = 1e-6)
  expect_equal(res[[2]], 0.2, tolerance = 1e-6)
})

test_that("process_sounds_parallel mclapply path applies func", {
  skip_parallel_on_cran()
  snds <- list(snd_fixture(), snd_fixture())
  res <- process_sounds_parallel(snds, function(s) s$get_duration(),
    n_cores = 2)
  expect_length(res, 2)
  expect_equal(res[[1]], 0.2, tolerance = 1e-6)
})

test_that("analyze_files_parallel single-core fallback", {
  res <- analyze_files_parallel(test_wav(), function(s) s$get_duration(),
    n_cores = 1)
  expect_length(res, 1)
  expect_gt(res[[1]], 0)
})

test_that("analyze_files_parallel PSOCK path attaches pladdrr in workers", {
  skip_parallel_on_cran()
  res <- analyze_files_parallel(test_wav(), function(s) s$get_duration(),
    n_cores = 2)
  expect_length(res, 1)
  expect_gt(res[[1]], 0)
})

test_that("extract_pitch/formant/intensity_parallel return analysis objects", {
  skip_parallel_on_cran()
  p <- extract_pitch_parallel(test_wav(), n_cores = 1)
  expect_s3_class(p[[1]], "Pitch")
  f <- extract_formant_parallel(test_wav(), n_cores = 1)
  expect_s3_class(f[[1]], "Formant")
  i <- extract_intensity_parallel(test_wav(), n_cores = 1)
  expect_s3_class(i[[1]], "Intensity")
})
