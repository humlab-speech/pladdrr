# Coverage-gap tests: exercise defensive branches (input validation,
# empty-data warnings) that the main suites miss. These close covr gaps
# without changing package behavior.

test_that("batch extract functions reject invalid input types", {
  expect_error(sound_to_pitch_batch(list("garbage")), "Invalid input type")
  expect_error(sound_to_pitch_ac_batch(list("garbage")), "Invalid input type")
  expect_error(sound_to_pitch_cc_batch(list("garbage")), "Invalid input type")
  expect_error(sound_to_pitch_shs_batch(list("garbage")), "Invalid input type")
  expect_error(sound_to_pitch_spinet_batch(list("garbage")), "Invalid input type")
  expect_error(sound_to_formant_batch(list("garbage")), "Invalid input type")
  expect_error(sound_to_intensity_batch(list("garbage")), "Invalid input type")
  expect_error(sound_extract_and_pitch(list("garbage"), 0, 1),
               "Invalid input type")
  expect_error(sound_extract_and_formant(list("garbage"), 0, 1),
               "Invalid input type")
})

test_that("aggregate_measurements rejects unknown statistics", {
  df <- data.frame(
    label = c("a", "a", "b"),
    value = c(1, 2, 3),
    stringsAsFactors = FALSE
  )
  expect_error(aggregate_measurements(df, stats = "bogus"),
               "Unknown statistic: bogus")
})

test_that("autoplot of empty tiers warns and returns an empty plot", {
  expect_warning(autoplot(amplitude_tier_create(0, 1)),
                 "no data in the specified time range")
  expect_warning(autoplot(DurationTier(0, 1)),
                 "no data in the specified time range")
  expect_warning(autoplot(IntensityTier(0, 1)),
                 "no data in the specified time range")
  expect_warning(autoplot(PitchTier(0, 1)),
                 "no data in the specified time range")
})

test_that("extract_part warns when the window runs past the signal", {
  sound <- Sound$create_tone(frequency = 150, duration = 1.0,
    sampling_rate = 16000)

  expect_warning(sound$extract_part(0.5, 2), "zero-pads")

  old <- options(pladdrr.data_loss = "silent")
  on.exit(options(old), add = TRUE)
  expect_no_warning(sound$extract_part(0.5, 2))

  options(pladdrr.data_loss = "error")
  expect_error(sound$extract_part(0.5, 2), "zero-pads")
  options(old)
})

test_that("plot.Matrix supports all color scales", {
  mat <- Matrix(xmin = 0, xmax = 1, nx = 10, dx = 0.1, x1 = 0.05,
    ymin = 0, ymax = 2, ny = 20, dy = 0.1, y1 = 0.05)
  for (cs in c("magma", "plasma", "inferno", "cividis", "greyscale")) {
    expect_no_error(plot(mat, color_scale = cs))
  }
})

test_that("create_cepstrum_report saves the combined plot to disk", {
  cepstrogram <- Sound$create_tone(frequency = 220, duration = 0.5,
    sampling_rate = 16000)$to_powercepstrogram()
  tmp <- tempfile(fileext = ".png")
  expect_message(create_cepstrum_report(cepstrogram, save_path = tmp),
    "Cepstrum report saved")
  expect_true(file.exists(tmp))
})

test_that("autoplot.Pitch draws voicing strength when requested", {
  p <- Sound$create_tone(frequency = 220, duration = 0.5,
    sampling_rate = 16000)$to_pitch()
  expect_no_error(autoplot(p, show_voicing = TRUE))
})

test_that("plot.PowerCepstrum marks the peak", {
  pc <- Sound$create_tone(frequency = 220, duration = 0.5,
    sampling_rate = 16000)$to_spectrum()$to_power_cepstrum()
  expect_no_error(plot(pc, mark_peak = TRUE))
})

test_that("point-tier measurements honor interval_filter, catch failing measures, aggregate", {
  dir <- tempfile("pladdrr_batch_pts3_")
  dir.create(dir)
  tone <- Sound$create_tone(frequency = 220, duration = 0.3,
    sampling_rate = 16000)
  tone$save(file.path(dir, "pts.wav"))
  tg <- textgrid_create(0, 0.3, "points", point_tiers = "points")
  tg$insert_point("points", 0.1, "keep")
  tg$insert_point("points", 0.2, "drop")
  tg$save(file.path(dir, "pts.TextGrid"))

  expect_warning(
    df <- extract_measurements_custom(
      file.path(dir, "pts.wav"), file.path(dir, "pts.TextGrid"),
      tier = 1,
      measures = list(f0 = function(sound, tmin, tmax) stop("boom")),
      interval_filter = function(label) label == "keep",
      aggregate_by = "label"
    ),
    "Error in measure 'f0'"
  )
  # the failed measure stored a logical NA, so no numeric f0_mean is created
  expect_identical(df$label, "keep")
  expect_identical(df$n, 1L)
  expect_false("f0_mean" %in% names(df))
})

test_that("tier autoplot filters by time range", {
  at <- amplitude_tier_create(0, 1)
  at$add_point(0.25, 0.5)
  expect_warning(autoplot(at, from_time = 5, to_time = 6),
    "no data in the specified time range")

  dt <- DurationTier(0, 1)
  dt$add_point(0.5, 1.2)
  expect_warning(autoplot(dt, from_time = 5, to_time = 6),
    "no data in the specified time range")

  it <- IntensityTier(0, 1)
  it$add_point(0.5, 70)
  expect_warning(autoplot(it, from_time = 5, to_time = 6),
    "no data in the specified time range")

  pt <- PitchTier(0, 1)
  pt$add_point(0.5, 200)
  expect_warning(autoplot(pt, from_time = 5, to_time = 6),
    "no data in the specified time range")
})

test_that("praat direct functions validate their sound input", {
  expect_error(to_pitch_ac_direct("bad"),
    "sound must be a Sound object or external pointer")
  expect_error(to_formant_direct("bad"),
    "sound must be a Sound object or external pointer")
  expect_error(to_harmonicity_direct("bad"),
    "sound must be a Sound object or external pointer")
})

test_that("S3 print and as.data.frame methods delegate through the R6 API", {
  snd <- Sound$create_tone(frequency = 220, duration = 0.5,
    sampling_rate = 16000)
  expect_invisible(print(snd$to_bark_spectrogram()))
  expect_s3_class(as.data.frame(snd$to_spectrogram()), "data.frame")
  expect_s3_class(as.data.frame(snd$to_spectrum()), "data.frame")
  expect_s3_class(as.data.frame(snd$to_ltas()$to_spectrum_tier_peaks()),
    "data.frame")
})

test_that("autolayer returns NULL for tiers with no data in range", {
  at <- amplitude_tier_create(0, 1)
  at$add_point(0.25, 0.5)
  expect_null(ggplot2::autolayer(at, from_time = 5, to_time = 6))

  dt <- DurationTier(0, 1)
  dt$add_point(0.5, 1.2)
  expect_null(ggplot2::autolayer(dt, from_time = 5, to_time = 6))

  it <- IntensityTier(0, 1)
  it$add_point(0.5, 70)
  expect_null(ggplot2::autolayer(it, from_time = 5, to_time = 6))

  pt <- PitchTier(0, 1)
  pt$add_point(0.5, 200)
  expect_null(ggplot2::autolayer(pt, from_time = 5, to_time = 6))
})

test_that("FormantTier and FormantGrid autoplot warns for an empty time range", {
  snd <- Sound$create_tone(frequency = 220, duration = 0.5,
    sampling_rate = 16000)
  ft <- FormantTier$from_formant(snd$to_formant_burg())
  expect_warning(autoplot(ft, from_time = 5, to_time = 6), "no data")

  # filtering a plain data.frame to empty hits the documented
  # paste0-on-empty-vector quirk in .prep_formant_df (see
  # test-autoplot-missing-gaps.R) rather than the warning branch
  grid <- FormantGrid(tmin = 0, tmax = 1, number_of_formants = 3)
  expect_error(autoplot(grid, from_time = 5, to_time = 6),
    "replacement has 1 row")
})
