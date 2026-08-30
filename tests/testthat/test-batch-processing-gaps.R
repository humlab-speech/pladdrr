# tests/testthat/test-batch-processing-gaps.R
# Coverage gap-fill for R/batch-processing.R remaining edge branches:
# the progress message, data.frame-returning funcs, empty-dir warnings,
# the custom-measure warning path, point-tier extraction, and the
# formant multiple-values aggregation branch.

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

test_that("batch_process reports progress and passes data frames through", {
  dir <- make_wav_dir(2)
  expect_message(
    res <- batch_process(dir, pattern = "\\.wav$", func = function(snd) snd$get_duration(),
                         progress = TRUE),
    "Processing 2 files"
  )
  expect_equal(nrow(res), 2)
  # func returning a data.frame directly (line 124 branch)
  res2 <- batch_process(dir, pattern = "\\.wav$",
                        func = function(snd) data.frame(dur = snd$get_duration()))
  expect_s3_class(res2, "data.frame")
  expect_equal(nrow(res2), 2)
})

test_that("pair_sound_textgrid warns on an empty directory", {
  dir <- tempfile("pladdrr_batch_empty_")
  dir.create(dir)
  expect_warning(pair_sound_textgrid(dir), "No sound files found")
})

test_that("extract_measurements_custom warns and returns NA for a failing measure", {
  dir <- make_wav_dir(1, with_textgrid = TRUE)
  wav <- list.files(dir, pattern = "\\.wav$", full.names = TRUE)[1]
  tg <- list.files(dir, pattern = "\\.TextGrid$", full.names = TRUE)[1]
  expect_warning(
    df <- extract_measurements_custom(
      wav, tg, tier = 1,
      measures = list(bad = function(sound, tmin, tmax) stop("boom"))
    ),
    "Error in measure 'bad'"
  )
  expect_true(all(is.na(df$bad)))
})

test_that("extract_measurements_custom extracts from point tiers", {
  dir <- tempfile("pladdrr_batch_pts_")
  dir.create(dir)
  tone <- Sound$create_tone(frequency = 220, duration = 0.3, sampling_rate = 16000)
  tone$save(file.path(dir, "pts.wav"))
  tg <- textgrid_create(0, 0.3, "points", point_tiers = "points")
  tg$insert_point("points", 0.15, "p")
  tg$save(file.path(dir, "pts.TextGrid"))
  df <- extract_measurements_custom(
    file.path(dir, "pts.wav"), file.path(dir, "pts.TextGrid"),
    tier = 1,
    measures = list(f0 = function(sound, tmin, tmax) 200)
  )
  expect_s3_class(df, "data.frame")
  expect_identical(df$label[1], "p")
})

test_that("extract_measurements returns formant columns at interval midpoints", {
  dir <- make_wav_dir(1, with_textgrid = TRUE)
  wav <- list.files(dir, pattern = "\\.wav$", full.names = TRUE)[1]
  tg <- list.files(dir, pattern = "\\.TextGrid$", full.names = TRUE)[1]
  # tone fixture yields undefined formant values in some intervals ->
  # the C++ layer emits a data_loss warning; expected, so suppress it
  df <- suppressWarnings(extract_measurements(wav, tg, tier = 1,
                             measurements = "formants",
                             formant_params = list(max_formants = 2,
                                                    max_frequency = 5500)))
  expect_s3_class(df, "data.frame")
  expect_true(any(grepl("^F[0-9]+", names(df))))
})
