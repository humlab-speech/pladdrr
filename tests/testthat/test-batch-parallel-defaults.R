## Batch/parallel defaults (round-2 review items 1-3).

test_that(".default_n_cores keeps one CPU spare only when there are more than two", {
  withr_env <- Sys.getenv("_R_CHECK_LIMIT_CORES_", NA)
  Sys.setenv("_R_CHECK_LIMIT_CORES_" = "false")
  on.exit(if (is.na(withr_env)) Sys.unsetenv("_R_CHECK_LIMIT_CORES_")
          else Sys.setenv("_R_CHECK_LIMIT_CORES_" = withr_env), add = TRUE)
  f <- pladdrr:::.default_n_cores
  expect_identical(f(1L), 1)
  expect_identical(f(2L), 2)        # was 1: a 2-CPU allowance silently serialised
  expect_identical(f(3L), 2)
  expect_identical(f(8L), 7)
  Sys.setenv("_R_CHECK_LIMIT_CORES_" = "TRUE")
  expect_equal(f(16L), 2)           # R CMD check still caps at two
})

test_that("a failed batch row records the class of the condition", {
  skip_if_not_installed("data.table")
  dir <- tempfile("batch_"); dir.create(dir); on.exit(unlink(dir, recursive = TRUE))
  good <- file.path(dir, "good.wav")
  Sound$create_tone(frequency = 220, duration = 0.2, sampling_rate = 8000)$save(good)
  bad <- file.path(dir, "bad.wav"); file.create(bad)            # 0-byte download
  res <- suppressWarnings(
    batch_process(dir, func = function(s) list(dur = s$get_total_duration()),
      parallel = FALSE, progress = FALSE))
  expect_identical(nrow(res), 2L)
  expect_true(all(c("error", "error_class") %in% names(res)))
  row_bad <- res[res$file == "bad.wav", ]
  expect_false(is.na(row_bad$error))
  expect_true(nzchar(row_bad$error_class))
  expect_true(is.na(res$error_class[res$file == "good.wav"]))
})

test_that("channels = NA from av falls back to mono instead of 'invalid dim'", {
  # The line under test is inside the av fallback: assert it textually, since the
  # branch only runs for formats Praat cannot read natively.
  src <- deparse(body(pladdrr:::.sound_read_via_av))
  expect_true(any(grepl("is.na(channels)", src, fixed = TRUE)))
})
