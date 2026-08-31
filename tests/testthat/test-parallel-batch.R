# test-parallel-batch.R - Tests for R/parallel-batch.R
# Exercises the real PSOCK cluster path (n_cores > 1) on macOS/Windows, not
# just the n_cores = 1 sequential fallback: this is where a bug like an
# unforced analysis_func promise silently breaks workers (see
# windows-parallel-promise-bug in project history).

make_audio_dir <- function(n = 2) {
  dir <- tempfile("pladdrr_parallel_")
  dir.create(dir)
  for (i in seq_len(n)) {
    tone <- Sound$create_tone(frequency = 150 + i * 20, duration = 0.1,
                               sampling_rate = 8000)
    tone$save(file.path(dir, sprintf("tone%d.wav", i)))
  }
  list.files(dir, pattern = "\\.wav$", full.names = TRUE)
}

test_that(
  ".pladdrr_worker_thread_budget divides cores and honors explicit override", {
  budget <- pladdrr:::.pladdrr_worker_thread_budget
  expect_equal(budget(2, threads_per_worker = 3), 3,
    tolerance = sqrt(.Machine$double.eps))
  expect_equal(budget(2, threads_per_worker = 0), 1, tolerance = sqrt(.Machine$double.eps)) # clamps to >= 1
  auto <- budget(2, threads_per_worker = NULL)
  expect_gte(auto, 1)
})

test_that("analyze_files_parallel n_cores = 1 processes files sequentially", {
  files <- make_audio_dir(2)
  results <- analyze_files_parallel(files, function(sound) {
    sound$get_duration()
  }, n_cores = 1)

  expect_length(results, 2)
  expect_true(all(vapply(results, function(x) abs(x - 0.1) < 1e-6, logical(1))))
})

test_that(
  "analyze_files_parallel n_cores = 2 runs on a real cluster and gets correct results", {
  skip_parallel_on_cran()
  files <- make_audio_dir(2)
  results <- analyze_files_parallel(files, function(sound) {
    sound$to_pitch()$get_mean(0, 0, "hertz")
  }, n_cores = 2)

  expect_length(results, 2)
  expect_true(all(vapply(results, is.numeric, logical(1))))
})

test_that(
  "analyze_files_parallel passes ... through to analysis_func on a cluster", {
  skip_parallel_on_cran()
  files <- make_audio_dir(2)
  results <- analyze_files_parallel(files, function(sound, multiplier) {
    sound$get_duration() * multiplier
  }, n_cores = 2, multiplier = 10)

  expect_true(all(vapply(results, function(x) abs(x - 1) < 1e-6, logical(1))))
})

test_that(
  "process_sounds_parallel n_cores = 1 applies analysis_func directly", {
  sounds <- list(
    Sound$create_tone(frequency = 220, duration = 0.1, sampling_rate = 8000),
    Sound$create_tone(frequency = 440, duration = 0.1, sampling_rate = 8000)
  )
  results <- process_sounds_parallel(sounds, function(s) s$get_duration(),
    n_cores = 1)

  expect_length(results, 2)
  expect_true(all(vapply(results, function(x) abs(x - 0.1) < 1e-6, logical(1))))
})

test_that(
  "process_sounds_parallel n_cores = 2 round-trips Sounds through a cluster", {
  skip_parallel_on_cran()
  sounds <- list(
    Sound$create_tone(frequency = 220, duration = 0.1, sampling_rate = 8000),
    Sound$create_tone(frequency = 440, duration = 0.1, sampling_rate = 8000)
  )
  results <- process_sounds_parallel(sounds, function(s) {
    s$to_pitch()$get_mean(0, 0, "hertz")
  }, n_cores = 2)

  expect_length(results, 2)
  expect_true(all(vapply(results, is.numeric, logical(1))))
})

test_that("extract_pitch_parallel returns one Pitch object per file", {
  files <- make_audio_dir(2)
  pitches <- extract_pitch_parallel(files, n_cores = 1, pitch_floor = 75,
                                     pitch_ceiling = 600)

  expect_length(pitches, 2)
  expect_true(all(vapply(pitches, inherits, logical(1), what = "Pitch")))
})

test_that("extract_formant_parallel returns one Formant object per file", {
  files <- make_audio_dir(1)
  formants <- extract_formant_parallel(files, n_cores = 1)

  expect_length(formants, 1)
  expect_s3_class(formants[[1]], "Formant")
})

test_that("extract_intensity_parallel returns one Intensity object per file", {
  files <- make_audio_dir(1)
  intensities <- extract_intensity_parallel(files, n_cores = 1)

  expect_length(intensities, 1)
  expect_s3_class(intensities[[1]], "Intensity")
})

test_that(
  "benchmark_parallel returns timing rows for each requested core count", {
  skip_parallel_on_cran()
  files <- make_audio_dir(1)
  results <- benchmark_parallel(files, function(s) s$get_duration(),
                                 core_counts = c(1, 2))

  expect_s3_class(results, "data.frame")
  expect_identical(nrow(results), 2L)
  expect_equal(results$cores, c(1, 2), tolerance = sqrt(.Machine$double.eps))
  expect_true(all(results$time_sec >= 0))
  expect_equal(results$speedup[1], 1, tolerance = sqrt(.Machine$double.eps))
})

test_that("process_sounds_parallel uses default n_cores", {
  snds <- list(Sound$create_tone(200, 0.1), Sound$create_tone(300, 0.1))
  res <- process_sounds_parallel(snds, function(s) s$get_duration())
  expect_length(res, 2)
})

test_that("analyze_files_parallel uses default n_cores on a real wav", {
  s <- Sound$create_tone(frequency = 200, duration = 0.1)
  tmp <- tempfile(fileext = ".wav")
  s$save(tmp)
  on.exit(unlink(tmp), add = TRUE)
  res <- analyze_files_parallel(tmp, function(sound) sound$get_duration())
  expect_length(res, 1)
  expect_true(abs(res[[1]] - 0.1) < 1e-6)
})
