# test-batch-partial-failure.R - the documented partial-failure contract of
# batch_process(): every input file produces exactly one output row, a failure
# carrying its message plus NA measures, row order preserved.
#
# Before the fix, the failure row built by .process_batch_file()
# (list(file, path, error)) had different columns from a successful row
# (list(<measures>, file, path)), so do.call(rbind, ...) in batch_process()
# died with "names do not match previous names" and *all* results - including
# every good file - were lost, with a message naming neither file nor cause.
# One unreadable file (a 0-byte .wav, i.e. an aborted download) was enough.

# Files are named so that list.files() returns the unreadable one in the middle:
# a1..a4, c_bad/c_trap, d5, d6.
make_partial_dir <- function(unreadable = TRUE, truncated = FALSE) {
  dir <- tempfile("pladdrr_partial_")
  dir.create(dir)
  for (f in c("a1.wav", "a2.wav", "a3.wav", "a4.wav", "d5.wav", "d6.wav")) {
    Sound$create_tone(frequency = 150, duration = 0.3, sampling_rate = 16000)$save(
      file.path(dir, f)
    )
  }
  if (unreadable) {
    con <- file(file.path(dir, "c_bad.wav"), "wb")   # 0 bytes: header and all missing
    close(con)
  }
  if (truncated) {
    path <- file.path(dir, "c_trap.wav")
    Sound$create_tone(frequency = 220, duration = 0.3, sampling_rate = 16000)$save(
      path
    )
    bytes <- readBin(path, "raw", file.size(path))
    writeBin(bytes[seq_len(60L)], path)   # header still declares the full length
  }
  dir
}

measure_duration <- function(sound) list(duration = sound$get_duration())

# The six readable files, measured on their own: the values the good rows of a
# partial-failure run must keep.
all_good_reference <- function() {
  suppressWarnings(batch_process(directory = make_partial_dir(unreadable = FALSE,
    truncated = FALSE), pattern = "\\.wav$", progress = FALSE,
    func = measure_duration))
}

test_that(
  "one zero-byte file gives one error row instead of crashing the batch", {
  dir <- make_partial_dir()
  reference <- all_good_reference()
  expect_identical(nrow(reference), 6L)

  res <- NULL
  suppressMessages(expect_warning(
    res <- batch_process(directory = dir, pattern = "\\.wav$", progress = FALSE,
      func = measure_duration),
    "c_bad.wav"
  ))

  # The return type must not change: callers get a plain data.frame, as before.
  expect_s3_class(res, "data.frame")
  expect_false(data.table::is.data.table(res))

  expect_identical(nrow(res), 7L)
  # Row order is the file order, bad row in the middle.
  expect_identical(res$file, sort(list.files(dir)))
  bad <- match("c_bad.wav", res$file)
  expect_identical(bad, 5L)

  # The failure row carries the message and NA where a measure would be.
  expect_true(is.character(res$error))
  expect_true(nzchar(res$error[bad]))
  expect_true(is.na(res$duration[bad]))
  # Every other row is exactly what the same file produced in an all-valid run.
  expect_false(anyNA(res$duration[-bad]))
  expect_identical(res$error[-bad], rep(NA_character_, 6L))
  expect_identical(res$duration[-bad], reference$duration)
})

test_that("the same merge holds on the progress-bar and data.frame-row paths", {
  dir <- make_partial_dir()

  res <- NULL
  suppressMessages(expect_warning(
    res <- batch_process(directory = dir, pattern = "\\.wav$", progress = TRUE,
      func = function(sound) data.frame(duration = sound$get_duration())),
    "c_bad.wav"
  ))
  expect_identical(nrow(res), 7L)
  bad <- which(!is.na(res$error))
  expect_identical(length(bad), 1L)
  expect_true(is.na(res$duration[bad]))
  expect_identical(sum(!is.na(res$duration)), 6L)
})

test_that("a failing measure merges too, not just a failing load", {
  dir <- make_partial_dir(unreadable = FALSE)
  n <- 0L
  res <- suppressWarnings(batch_process(directory = dir, pattern = "\\.wav$",
    progress = FALSE,
    func = function(sound) {
      n <<- n + 1L
      if (n == 3L) stop("boom")
      list(duration = sound$get_duration())
    }))

  expect_identical(nrow(res), 6L)
  expect_identical(res$error[3], "boom")
  expect_identical(res$error[c(1:2, 4:6)], rep(NA_character_, 5L))
  expect_true(is.na(res$duration[3]))
  expect_false(anyNA(res$duration[-3]))
})

test_that("batch_process(parallel = TRUE) keeps one row per file", {
  skip_parallel_on_cran()
  dir <- make_partial_dir()
  reference <- all_good_reference()

  res <- NULL
  # Not expect_warning(): parallel's forked workers re-emit their conditions on
  # the parent's stderr rather than through the parent's R handlers, so the
  # per-file warning cannot be asserted here (the sequential test above does).
  # What must survive the fork is the row.
  suppressMessages(suppressWarnings(
    res <- batch_process(directory = dir, pattern = "\\.wav$", progress = FALSE,
      parallel = TRUE, ncores = 2, func = measure_duration)
  ))

  expect_s3_class(res, "data.frame")
  expect_identical(nrow(res), 7L)
  expect_identical(res$file, sort(list.files(dir)))
  bad <- match("c_bad.wav", res$file)
  expect_true(nzchar(res$error[bad]))
  expect_true(is.na(res$duration[bad]))
  expect_identical(res$error[-bad], rep(NA_character_, 6L))
  expect_identical(res$duration[-bad], reference$duration)
})

test_that(
  "a truncation error under pladdrr.data_loss = 'error' still gives a row", {
  # F-security-02 made a short file a catchable condition; batch_process must
  # report it as a row rather than killing the run.
  dir <- make_partial_dir(unreadable = FALSE, truncated = TRUE)
  old <- options(pladdrr.data_loss = "error")
  on.exit(options(old), add = TRUE)

  res <- NULL
  suppressMessages(expect_warning(
    res <- batch_process(directory = dir, pattern = "\\.wav$", progress = FALSE,
      func = measure_duration),
    "c_trap.wav"
  ))

  expect_identical(nrow(res), 7L)
  bad <- match("c_trap.wav", res$file)
  expect_identical(bad, 5L)
  expect_match(res$error[bad], "data chunk")
  expect_true(is.na(res$duration[bad]))
  expect_identical(res$error[-bad], rep(NA_character_, 6L))
})

test_that("an all-valid run keeps exactly the shape base rbind produced", {
  # The ragged-row path uses rbindlist(fill = TRUE), which has no row names and
  # does not union differing factor levels. Anything base rbind could already
  # combine must stay on the base path: these three shapes are what
  # batch_process() returned before the change and what a user's existing
  # script keeps seeing.
  dir <- make_partial_dir(unreadable = FALSE, truncated = FALSE)
  run <- function(func) batch_process(directory = dir, pattern = "\\.wav$",
    progress = FALSE, func = func)

  plain <- run(function(sound) data.frame(n = 1, stringsAsFactors = FALSE))
  expect_identical(rownames(plain), c("1", "2", "3", "4", "5", "6"))

  named <- run(function(sound) {
    row <- data.frame(n = 1, stringsAsFactors = FALSE)
    rownames(row) <- "mine"
    row
  })
  expect_true(all(grepl("mine", rownames(named))))

  # a counter, not a property of the sound: every fixture file is the same
  # 0.3 s tone, so the only way to get two different factor levels per row is
  # the row index itself (rows come back in file order).
  seen <- 0L
  fac <- run(function(sound) {
    seen <<- seen + 1L
    data.frame(k = factor(if (seen %% 2L == 0L) "x" else "y"),
      stringsAsFactors = FALSE)
  })
  expect_s3_class(fac$k, "factor")
  expect_setequal(levels(fac$k), c("x", "y"))
})
