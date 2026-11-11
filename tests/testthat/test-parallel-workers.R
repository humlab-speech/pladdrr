# process_sounds_parallel(): the multi-worker branch and its agreement with
# the sequential path. Skipped where fork-based parallelism is unavailable.

test_that("process_sounds_parallel agrees with the sequential path", {
  skip_if(.Platform$OS.type == "windows", "fork-based parallelism")
  skip_if_not(parallel::detectCores() >= 2, "needs at least two cores")

  in_covr <- requireNamespace("covr", quietly = TRUE) && covr::in_covr()
  skip_if(!identical(Sys.getenv("NOT_CRAN"), "true") && !in_covr)

  sounds <- list(
    Sound$create_tone(frequency = 200, duration = 0.1),
    Sound$create_tone(frequency = 300, duration = 0.1)
  )
  analysis <- function(sound) sound$get_rms()

  sequential <- vapply(sounds, analysis, numeric(1))
  parallel <- suppressMessages(
    process_sounds_parallel(
      sounds, analysis, n_cores = 2, threads_per_worker = 1
    )
  )

  expect_length(parallel, length(sounds))
  expect_equal(unlist(parallel), sequential, tolerance = 1e-12)
})

test_that("process_sounds_parallel with one core is the sequential path", {
  sounds <- list(
    Sound$create_tone(frequency = 200, duration = 0.1),
    Sound$create_tone(frequency = 300, duration = 0.1)
  )
  analysis <- function(sound) sound$get_rms()

  result <- process_sounds_parallel(sounds, analysis, n_cores = 1)

  expect_length(result, length(sounds))
  expect_equal(
    unlist(result),
    vapply(sounds, analysis, numeric(1)),
    tolerance = 1e-12
  )
})
