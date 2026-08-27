# test-batch-processing.R - Tests for R/batch-processing.R

make_wav_dir <- function(n = 2, with_textgrid = FALSE) {
  dir <- tempfile("pladdrr_batch_")
  dir.create(dir)
  for (i in seq_len(n)) {
    tone <- Sound$create_tone(frequency = 150 + i * 30, duration = 0.3,
                               sampling_rate = 16000)
    base <- sprintf("utt%d", i)
    tone$save(file.path(dir, paste0(base, ".wav")))
    if (with_textgrid) {
      tg <- textgrid_create(0, 0.3, "phones")
      tg$insert_boundary("phones", 0.15)
      tg$set_interval_text("phones", 1, "a")
      tg$set_interval_text("phones", 2, "e")
      tg$save(file.path(dir, paste0(base, ".TextGrid")))
    }
  }
  dir
}

# --- create_file_list -------------------------------------------------------

test_that("create_file_list lists matching files", {
  dir <- make_wav_dir(3)
  files <- create_file_list(dir, pattern = "\\.wav$")

  expect_length(files, 3)
  expect_true(all(grepl("\\.wav$", files)))
})

test_that("create_file_list respects full_names = FALSE", {
  dir <- make_wav_dir(2)
  files <- create_file_list(dir, pattern = "\\.wav$", full_names = FALSE)

  expect_length(files, 2)
  expect_false(any(grepl(dir, files, fixed = TRUE)))
})

# --- pair_sound_textgrid -----------------------------------------------------

test_that("pair_sound_textgrid matches by basename and requires both by default", {
  dir <- make_wav_dir(2, with_textgrid = TRUE)
  pairs <- pair_sound_textgrid(sound_dir = dir)

  expect_s3_class(pairs, "data.frame")
  expect_equal(nrow(pairs), 2)
  expect_true(!anyNA(pairs$sound_file))
  expect_true(!anyNA(pairs$textgrid_file))
})

test_that("pair_sound_textgrid with require_both = FALSE keeps unmatched sound files", {
  dir <- make_wav_dir(2, with_textgrid = FALSE)
  pairs <- pair_sound_textgrid(sound_dir = dir, require_both = FALSE)

  expect_equal(nrow(pairs), 2)
  expect_true(all(is.na(pairs$textgrid_file)))
})

test_that("pair_sound_textgrid rejects an unknown matching strategy", {
  dir <- make_wav_dir(1, with_textgrid = TRUE)
  expect_error(pair_sound_textgrid(sound_dir = dir, by = "nonsense"), "Unknown matching strategy")
})

# --- pair_files (data.table-backed) -----------------------------------------

test_that("pair_files matches sound and TextGrid files by basename", {
  dir <- make_wav_dir(2, with_textgrid = TRUE)
  pairs <- pair_files(sound_dir = dir)

  expect_s3_class(pairs, "data.frame")
  expect_equal(nrow(pairs), 2)
})

test_that("pair_files rejects non-basename matching strategies", {
  dir <- make_wav_dir(1, with_textgrid = TRUE)
  expect_error(pair_files(sound_dir = dir, by = "full"), "basename")
})

# --- batch_process -----------------------------------------------------------

test_that("batch_process applies func to every matching file and tags file/path", {
  dir <- make_wav_dir(2)
  results <- batch_process(
    directory = dir, pattern = "\\.wav$", progress = FALSE,
    func = function(sound) list(duration = sound$get_duration())
  )

  expect_s3_class(results, "data.frame")
  expect_equal(nrow(results), 2)
  expect_true(all(abs(results$duration - 0.3) < 1e-6))
  expect_true(all(c("file", "path") %in% names(results)))
})

test_that("batch_process warns and returns an empty data frame when nothing matches", {
  dir <- tempfile("pladdrr_empty_")
  dir.create(dir)
  expect_warning(result <- batch_process(dir, pattern = "\\.wav$", progress = FALSE,
                                          func = function(sound) list()),
                  "No files found")
  expect_equal(nrow(result), 0)
})

test_that("batch_process captures per-file errors instead of aborting the batch", {
  dir <- make_wav_dir(2)
  expect_warning(
    results <- batch_process(
      directory = dir, pattern = "\\.wav$", progress = FALSE,
      func = function(sound) stop("boom")
    ),
    "boom"
  )

  expect_equal(nrow(results), 2)
  expect_true(all(results$error == "boom"))
})

# --- extract_measurements_custom --------------------------------------------

test_that("extract_measurements_custom returns one row per interval with measures applied", {
  sound <- Sound$create_tone(frequency = 150, duration = 0.6, sampling_rate = 16000)
  tg <- textgrid_create(0, 0.6, "phones")
  tg$insert_boundary("phones", 0.3)
  tg$set_interval_text("phones", 1, "a")
  tg$set_interval_text("phones", 2, "e")

  measurements <- extract_measurements_custom(
    sound = sound, textgrid = tg, tier = "phones",
    measures = list(
      dur_check = function(snd, t1, t2) snd$get_duration()
    )
  )

  expect_s3_class(measurements, "data.frame")
  expect_equal(nrow(measurements), 2)
  expect_equal(measurements$label, c("a", "e"))
  expect_true(all(abs(measurements$dur_check - 0.3) < 1e-6))
})

test_that("extract_measurements_custom applies interval_filter", {
  sound <- Sound$create_tone(frequency = 150, duration = 0.6, sampling_rate = 16000)
  tg <- textgrid_create(0, 0.6, "phones")
  tg$insert_boundary("phones", 0.3)
  tg$set_interval_text("phones", 1, "a")
  tg$set_interval_text("phones", 2, "")

  measurements <- extract_measurements_custom(
    sound = sound, textgrid = tg, tier = "phones",
    measures = list(dur = function(snd, t1, t2) t2 - t1),
    interval_filter = function(label) nzchar(label)
  )

  expect_equal(nrow(measurements), 1)
  expect_equal(measurements$label, "a")
})

test_that("extract_measurements_custom loads sound/textgrid from file paths", {
  dir <- make_wav_dir(1, with_textgrid = TRUE)
  sound_path <- list.files(dir, pattern = "\\.wav$", full.names = TRUE)[1]
  tg_path <- list.files(dir, pattern = "\\.TextGrid$", full.names = TRUE)[1]

  measurements <- extract_measurements_custom(
    sound = sound_path, textgrid = tg_path, tier = "phones",
    measures = list(dur = function(snd, t1, t2) t2 - t1)
  )

  expect_equal(nrow(measurements), 2)
})

# --- extract_measurements (batch C++ path) ----------------------------------

test_that("extract_measurements returns pitch/formant/intensity columns at interval midpoints", {
  sound <- Sound$create_tone(frequency = 150, duration = 0.6, sampling_rate = 16000)
  tg <- textgrid_create(0, 0.6, "phones")
  tg$insert_boundary("phones", 0.3)
  tg$set_interval_text("phones", 1, "a")
  tg$set_interval_text("phones", 2, "e")

  measurements <- extract_measurements(
    sound = sound, textgrid = tg, tier = 1,
    measurements = c("pitch", "intensity"),
    time_point = "midpoint"
  )

  expect_s3_class(measurements, "data.frame")
  expect_equal(nrow(measurements), 2)
  expect_true("f0" %in% names(measurements))
  expect_true("intensity" %in% names(measurements))
})

test_that("extract_measurements returns NULL when no intervals have text", {
  sound <- Sound$create_tone(frequency = 150, duration = 0.3, sampling_rate = 16000)
  tg <- textgrid_create(0, 0.3, "phones")

  measurements <- extract_measurements(sound = sound, textgrid = tg, tier = 1,
                                        measurements = "pitch")
  expect_null(measurements)
})

# --- aggregate_measurements ---------------------------------------------------

test_that("aggregate_measurements computes mean/sd/n grouped by label", {
  measurements <- data.frame(
    label = c("a", "a", "e", "e"),
    f0 = c(150, 155, 210, 205)
  )

  agg <- aggregate_measurements(measurements, by = "label", stats = c("mean", "sd", "n"))

  expect_s3_class(agg, "data.frame")
  expect_equal(nrow(agg), 2)
  expect_true(all(c("f0_mean", "f0_sd", "n") %in% names(agg)))

  a_row <- agg[agg$label == "a", ]
  expect_equal(a_row$f0_mean, mean(c(150, 155)))
  expect_equal(a_row$n, 2)
})

test_that("aggregate_measurements errors on an unknown grouping column", {
  measurements <- data.frame(label = c("a", "b"), f0 = c(150, 160))
  expect_error(aggregate_measurements(measurements, by = "bogus"), "not found")
})
