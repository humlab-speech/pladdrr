# tests/testthat/test-autoplot-missing-gaps.R
# Task 16 gap-fill: R/autoplot-missing.R branches left uncovered by
# test-autoplot-{tier,formant,spectral,statistical,streaming}-family.R --
# argument-variation branches (from_time/to_time filters, style/type/
# plot_type/formant_type selectors, coefficient_range, quefrency_range,
# show_phase), autolayer() counterparts that were never called, and empty/
# out-of-range "no data" warning branches.

library(testthat)
library(pladdrr)

sound_fixture <- function() generate_sine_wave(220, 0.2, sampling_rate = 16000)

# ---------------------------------------------------------------------------
# .formant_colors / .prep_formant_df helpers (custom colors argument)
# ---------------------------------------------------------------------------

test_that(
  ".formant_colors uses caller-supplied colors instead of the default palette", {
  grid <- FormantGrid(tmin = 0, tmax = 1, number_of_formants = 3)
  grid$add_formant_point(1, 0.5, 500)
  p <- ggplot2::autoplot(grid, colors = c("red", "blue", "green"))
  expect_s3_class(p, "ggplot")
})

test_that(".prep_formant_df's paste0-on-empty-vector bug makes FormantGrid's
'no data' warning branch unreachable via time filtering (data.frame input)", {
  # paste0("F", numeric(0)) returns "F" (length 1), not character(0) -- a
  # documented R paste()/paste0() quirk (zero-length args are recycled to ""
  # rather than making the whole call zero-length). .prep_formant_df's final
  # `df$formant_label <- paste0("F", df$formant_number)` therefore errors
  # with "replacement has 1 row, data has 0" whenever filtering empties a
  # *plain data.frame* input, rather than falling through to the
  # nrow(df)==0 warning check in the calling autoplot.FormantGrid.
  # FormantGrid$as_data_frame() returns a plain data.frame, so it hits this;
  # FormantPath$as_data_frame() returns a data.table, whose `$<-` tolerates
  # the length-1-into-0-rows assignment instead of erroring (verified
  # interactively; see the next test), so FormantPath's own "no data"
  # warning IS reachable and is asserted normally below. This documents the
  # actual (buggy, data.frame-only) behavior per Task 16 brief instructions.
  grid <- FormantGrid(tmin = 0, tmax = 1, number_of_formants = 3)
  grid$add_formant_point(1, 0.5, 500)
  expect_error(
    ggplot2::autoplot(grid, from_time = 100, to_time = 200),
    "replacement has 1 row"
  )
})

test_that(
  "FormantPath autoplot/autolayer warn and return NULL when time-filtered to empty", {
  # Unlike FormantGrid (data.frame-backed, see above), FormantPath's
  # as_data_frame() returns a data.table, so .prep_formant_df's
  # paste0()-into-0-rows assignment doesn't error here -- the intended
  # nrow(df)==0 warning branch is reached normally.
  sound <- sound_fixture()
  fp <- sound$to_formant_path()
  expect_warning(p <- ggplot2::autoplot(fp, from_time = 100, to_time = 200),
                  "FormantPath has no data")
  expect_s3_class(p, "ggplot")
  expect_null(ggplot2::autolayer(fp, from_time = 100, to_time = 200))
})

# ---------------------------------------------------------------------------
# FormantTier: from_time/to_time filtering (style="speckle" `next` branch)
# ---------------------------------------------------------------------------

test_that(
  "FormantTier autoplot/autolayer respect from_time/to_time and warn when empty", {
  sound <- sound_fixture()
  formant <- sound$to_formant_burg()
  ft <- FormantTier$from_formant(formant)

  p <- ggplot2::autoplot(ft, from_time = 0.05, to_time = 0.15)
  expect_s3_class(p, "ggplot")
  layer <- ggplot2::autolayer(ft, from_time = 0.05, to_time = 0.15)
  expect_true(is.list(layer) || inherits(layer, "Layer"))

  # Genuinely out of range: FormantTier's own "no data" warning fires
  # *before* .prep_formant_df is called (rows list stays empty), so this
  # path is unaffected by the paste0 bug documented above.
  expect_warning(p2 <- ggplot2::autoplot(ft, from_time = 10, to_time = 11),
                  "FormantTier has no data")
  expect_s3_class(p2, "ggplot")
  expect_null(ggplot2::autolayer(ft, from_time = 10, to_time = 11))

  # style = "line" with from_time/to_time also exercises the alternate loop.
  p3 <- ggplot2::autoplot(ft, style = "line", from_time = 0.05, to_time = 0.15)
  expect_s3_class(p3, "ggplot")
  layer2 <- ggplot2::autolayer(ft, style = "line", from_time = 0.05,
    to_time = 0.15)
  expect_type(layer2, "list")
})

# ---------------------------------------------------------------------------
# FormantGrid / FormantPath: from_time/to_time filtering (non-empty result)
# ---------------------------------------------------------------------------

test_that(
  "FormantPath autoplot/autolayer respect from_time/to_time (non-empty result)", {
  # FormantGrid's own as_data_frame() has a separate, more severe defect
  # (its "time" and "formant_number" columns are swapped -- verified
  # interactively: `time` holds small integers 1..3 and `formant_number`
  # holds the real 0..1 s time grid) that makes any realistic from_time/
  # to_time window filter to 0 rows and hit the .prep_formant_df crash
  # documented above, so FormantGrid isn't exercised here with a
  # "successfully narrows the range" expectation -- that would require
  # picking filter bounds that coincidentally land in the mislabeled
  # column's tiny 1..3 range, which would be a confusing, bug-dependent test.
  sound <- sound_fixture()
  fp <- sound$to_formant_path()
  p2 <- ggplot2::autoplot(fp, from_time = 0.02, to_time = 0.1)
  expect_s3_class(p2, "ggplot")
  layer2 <- ggplot2::autolayer(fp, from_time = 0.02, to_time = 0.1)
  expect_type(layer2, "list")
})

test_that(
  "FormantPath show_candidates has no effect because as_data_frame() never returns a 'candidate' column", {
  # autoplot.FormantPath/autolayer.FormantPath branch on
  # `show_candidates && "candidate" %in% names(df)`; FormantPath$as_data_frame()
  # (R/formantpath-module.R:122-123, delegating to the C++ module) returns
  # columns time/formant/frequency/bandwidth only -- no "candidate" column
  # ever exists, so the show_candidates=TRUE branch (lines 415-436 / 460-469
  # of R/autoplot-missing.R) is genuinely dead code given this package's
  # actual data shape. Verified interactively; left uncovered per Task 16
  # brief's "genuinely unreachable" allowance. This test just documents that
  # passing show_candidates=TRUE still renders (falls through to the same
  # plot as show_candidates=FALSE), so it isn't silently broken.
  sound <- sound_fixture()
  fp <- sound$to_formant_path()
  expect_false("candidate" %in% names(fp$as_data_frame(max_formants = 3)))
  p <- ggplot2::autoplot(fp, show_candidates = TRUE)
  expect_s3_class(p, "ggplot")
})

# ---------------------------------------------------------------------------
# ComplexSpectrogram: from_time/to_time/from_freq/to_freq filters, empty
# warning, show_phase (patchwork combined plot), and autolayer entirely
# ---------------------------------------------------------------------------

test_that(
  "ComplexSpectrogram autoplot/autolayer respect all four range filters and warn when empty", {
  cs <- sound_fixture()$to_complex_spectrogram()
  p <- ggplot2::autoplot(cs, from_time = 0.01, to_time = 0.15,
                          from_freq = 100, to_freq = 3000)
  expect_s3_class(p, "ggplot")
  expect_true(all(p$data$time >= 0.01 & p$data$time <= 0.15))
  expect_true(all(p$data$frequency >= 100 & p$data$frequency <= 3000))

  expect_warning(p2 <- ggplot2::autoplot(cs, from_time = 100, to_time = 200),
                  "ComplexSpectrogram has no data in range")
  expect_s3_class(p2, "ggplot")

  # autolayer.ComplexSpectrogram is never called elsewhere in the suite.
  p3 <- ggplot2::ggplot() + ggplot2::autolayer(cs, from_time = 0.01,
    to_time = 0.15,
                                                from_freq = 100, to_freq = 3000)
  expect_s3_class(p3, "ggplot")
  expect_null(ggplot2::autolayer(cs, from_time = 100, to_time = 200))
})

test_that(
  "ComplexSpectrogram show_phase=TRUE returns a combined patchwork plot when patchwork is available", {
  skip_if_not_installed("patchwork")
  cs <- sound_fixture()$to_complex_spectrogram()
  p <- ggplot2::autoplot(cs, show_phase = TRUE)
  expect_true(inherits(p, "patchwork") || inherits(p, "gg"))
})

# ---------------------------------------------------------------------------
# Cochleagram: from_time/to_time filter, empty warning, autolayer entirely
# ---------------------------------------------------------------------------

test_that(
  "Cochleagram autoplot/autolayer respect from_time/to_time and warn when empty", {
  cochlea <- sound_fixture()$to_cochleagram(dt = 0.02, df = 1,
    window_length = 0.025,
                                             forward_masking_time = 0.03)
  p <- ggplot2::autoplot(cochlea, from_time = 0.05, to_time = 0.15)
  expect_s3_class(p, "ggplot")
  expect_true(all(p$data$time >= 0.05 & p$data$time <= 0.15))

  expect_warning(
    p2 <- ggplot2::autoplot(cochlea, from_time = 100, to_time = 200),
                  "Cochleagram has no data")
  expect_s3_class(p2, "ggplot")

  p3 <- ggplot2::ggplot() + ggplot2::autolayer(cochlea, from_time = 0.05,
    to_time = 0.15)
  expect_s3_class(p3, "ggplot")
  expect_null(ggplot2::autolayer(cochlea, from_time = 100, to_time = 200))
})

# ---------------------------------------------------------------------------
# PowerCepstrogram: from_time/to_time/quefrency_range filters, empty
# warning, autolayer entirely
# ---------------------------------------------------------------------------

test_that(
  "PowerCepstrogram autoplot/autolayer respect from_time/to_time/quefrency_range and warn when empty", {
  pcg <- sound_fixture()$to_powercepstrogram()
  p <- ggplot2::autoplot(pcg, from_time = 0.05, to_time = 0.15,
                          quefrency_range = c(0.001, 0.01))
  expect_s3_class(p, "ggplot")
  expect_true(all(p$data$quefrency >= 0.001 & p$data$quefrency <= 0.01))

  expect_warning(p2 <- ggplot2::autoplot(pcg, from_time = 100, to_time = 200),
                  "PowerCepstrogram has no data in range")
  expect_s3_class(p2, "ggplot")

  p3 <- ggplot2::ggplot() + ggplot2::autolayer(pcg, from_time = 0.05,
    to_time = 0.15,
                                                quefrency_range = c(0.001,
                                                  0.01))
  expect_s3_class(p3, "ggplot")
  expect_null(ggplot2::autolayer(pcg, from_time = 100, to_time = 200))
})

# ---------------------------------------------------------------------------
# MFCC / LFCC: coefficient_range filter (both directions), empty-after-
# filter warning, autolayer entirely
# ---------------------------------------------------------------------------

test_that(
  "MFCC autoplot/autolayer respect coefficient_range and warn when it excludes everything", {
  mfcc <- sound_fixture()$to_mfcc()
  p <- ggplot2::autoplot(mfcc, coefficient_range = 1:3)
  expect_s3_class(p, "ggplot")
  expect_true(all(p$data$coefficient %in% 1:3))

  expect_warning(p2 <- ggplot2::autoplot(mfcc, coefficient_range = 999),
                  "MFCC has no data")
  expect_s3_class(p2, "ggplot")

  p3 <- ggplot2::ggplot() + ggplot2::autolayer(mfcc, coefficient_range = 1:3)
  expect_s3_class(p3, "ggplot")
  expect_null(ggplot2::autolayer(mfcc, coefficient_range = 999))
})

test_that(
  "LFCC autoplot/autolayer respect coefficient_range and warn when it excludes everything", {
  lpc <- sound_fixture()$to_lpc_burg(prediction_order = 10)
  lfcc <- lpc$to_lfcc()
  p <- ggplot2::autoplot(lfcc, coefficient_range = 1:3)
  expect_s3_class(p, "ggplot")
  expect_true(all(p$data$coefficient %in% 1:3))

  expect_warning(p2 <- ggplot2::autoplot(lfcc, coefficient_range = 999),
                  "LFCC has no data")
  expect_s3_class(p2, "ggplot")

  p3 <- ggplot2::ggplot() + ggplot2::autolayer(lfcc, coefficient_range = 1:3)
  expect_s3_class(p3, "ggplot")
  expect_null(ggplot2::autolayer(lfcc, coefficient_range = 999))
})

# ---------------------------------------------------------------------------
# BarkSpectrogram / MelSpectrogram: autolayer entirely (never called
# elsewhere in the suite)
# ---------------------------------------------------------------------------

test_that("BarkSpectrogram and MelSpectrogram autolayer render", {
  bark <- sound_fixture()$to_bark_spectrogram()
  p <- ggplot2::ggplot() + ggplot2::autolayer(bark)
  expect_s3_class(p, "ggplot")

  mel <- sound_fixture()$to_mel_spectrogram()
  p2 <- ggplot2::ggplot() + ggplot2::autolayer(mel)
  expect_s3_class(p2, "ggplot")
})

# ---------------------------------------------------------------------------
# Matrix: autolayer entirely (never called elsewhere in the suite)
# ---------------------------------------------------------------------------

test_that(
  "Matrix autolayer renders using the same col/row/value auto-detected columns as autoplot", {
  mat <- Matrix(xmin = 0, xmax = 1, nx = 10, dx = 0.1, x1 = 0.05,
                ymin = 0, ymax = 2, ny = 20, dy = 0.1, y1 = 0.05)
  p <- ggplot2::ggplot() + ggplot2::autolayer(mat)
  expect_s3_class(p, "ggplot")
  # Explicit column overrides also exercise the is.null(x_col)/y_col/fill_col
  # `else` (skip auto-detect) path.
  p2 <- ggplot2::ggplot() + ggplot2::autolayer(mat, x_col = "col",
    y_col = "row",
                                                fill_col = "value")
  expect_s3_class(p2, "ggplot")
})

# ---------------------------------------------------------------------------
# PCA / Discriminant: type="scores"/"both" for Discriminant (only "scree"
# tested elsewhere), autolayer for both classes entirely
# ---------------------------------------------------------------------------

test_that(
  "Discriminant autoplot renders for scores/both types too, and autolayer works for PCA and Discriminant", {
  set.seed(1)
  x <- matrix(rnorm(200), nrow = 20)
  pca <- pca_from_matrix(x)
  p_pca <- ggplot2::autolayer(pca)
  expect_true(inherits(p_pca, "Layer") || inherits(p_pca, "geom"))

  data <- matrix(c(rnorm(10, 500), rnorm(10, 700)), ncol = 1,
                  dimnames = list(NULL, "f1"))
  labels <- rep(c("a", "i"), each = 10)
  disc <- discriminant_from_matrix(data, labels)

  expect_s3_class(ggplot2::autoplot(disc, type = "scores"), "ggplot")
  if (requireNamespace("patchwork", quietly = TRUE)) {
    p_both <- ggplot2::autoplot(disc, type = "both")
    expect_true(inherits(p_both, "patchwork") || inherits(p_both, "gg"))
  }

  p_disc_layer <- ggplot2::autolayer(disc)
  expect_true(inherits(p_disc_layer, "Layer") || inherits(p_disc_layer, "geom"))
})

# ---------------------------------------------------------------------------
# FormantModeler: default to_track=0 (means "all tracks"), out-of-range
# track request warns/returns NULL
# ---------------------------------------------------------------------------

test_that(
  "FormantModeler autoplot/autolayer default to_track=0 means 'all tracks', and out-of-range tracks warn/return NULL", {
  sound <- sound_fixture()
  formant <- sound$to_formant_burg()
  fm <- formant$to_formant_modeler()

  # No from_track/to_track given -> default to_track = 0L -> resolved to
  # n_tracks inside .formant_modeler_long_df.
  p <- ggplot2::autoplot(fm)
  expect_s3_class(p, "ggplot")
  expect_gt(nrow(p$data), 0)

  expect_warning(p2 <- ggplot2::autoplot(fm, from_track = 10, to_track = 12),
                  "FormantModeler has no data")
  expect_s3_class(p2, "ggplot")
  expect_null(ggplot2::autolayer(fm, from_track = 10, to_track = 12))
})

# ---------------------------------------------------------------------------
# Electroglottogram: from_time/to_time filter (both directions), empty
# warning, and autolayer with the same filters
# ---------------------------------------------------------------------------

test_that(
  "Electroglottogram autoplot/autolayer respect from_time/to_time and warn when empty", {
  skip_if_not(file.exists(test_path("fixtures/speech_sample.wav")))
  sound <- Sound(test_path("fixtures/speech_sample.wav"))
  egg <- sound$extract_electroglottogram()
  full <- as.data.frame(egg)
  skip_if(nrow(full) < 2, "not enough points to test filtering")
  mid <- mean(range(full$time))

  p <- ggplot2::autoplot(egg, from_time = mid, to_time = max(full$time))
  expect_s3_class(p, "ggplot")
  layer <- ggplot2::autolayer(egg, from_time = mid, to_time = max(full$time))
  expect_true(inherits(layer, "Layer") || inherits(layer, "geom"))

  expect_warning(p2 <- ggplot2::autoplot(egg, from_time = 1e6, to_time = 2e6),
                  "Electroglottogram has no data")
  expect_s3_class(p2, "ggplot")
  expect_null(ggplot2::autolayer(egg, from_time = 1e6, to_time = 2e6))
})

# ---------------------------------------------------------------------------
# LongSound: required from_time/to_time (stop() on NULL), and autolayer
# ---------------------------------------------------------------------------

test_that(
  "LongSound autoplot/autolayer require non-NULL from_time/to_time and autolayer renders a layer", {
  skip_if_not(file.exists(test_path("fixtures/speech_sample.wav")))
  ls_obj <- longsound_open(test_path("fixtures/speech_sample.wav"))

  expect_error(ggplot2::autoplot(ls_obj, from_time = NULL, to_time = 0.1),
               "from_time and to_time are required")
  expect_error(ggplot2::autolayer(ls_obj, from_time = 0, to_time = NULL),
               "from_time and to_time are required")

  layer <- ggplot2::autolayer(ls_obj, from_time = 0, to_time = 0.1)
  expect_true(inherits(layer, "Layer") || inherits(layer, "geom"))
})

# ---------------------------------------------------------------------------
# DTW: alpha_path passthrough (autoplot already covered elsewhere; this just
# exercises a non-default alpha_path value on both autoplot and autolayer)
# ---------------------------------------------------------------------------

test_that("DTW autoplot/autolayer accept a custom alpha_path", {
  sound <- generate_sine_wave(440, 0.1, sampling_rate = 16000)
  dtw <- sounds_to_dtw(sound, sound)
  p <- ggplot2::autoplot(dtw, alpha_path = 0.3)
  expect_s3_class(p, "ggplot")
  layer <- ggplot2::autolayer(dtw, alpha_path = 0.3)
  expect_type(layer, "list")
})

# ---------------------------------------------------------------------------
# Polygon: empty-points warning + autolayer NULL (via a fake object, since
# the real Polygon() constructor rejects 0 points outright)
# ---------------------------------------------------------------------------

test_that(
  "Polygon autoplot/autolayer warn and return an empty/NULL result when as_data_frame() is empty", {
  # Polygon(x = numeric(0), y = numeric(0)) errors at construction time
  # ("At least 1 point required"), so an empty Polygon can't be built via the
  # public constructor. as.data.frame.Polygon (R/polygon-module.R:161-163)
  # just delegates to object$as_data_frame(), so a minimal fake with that
  # one method reaches the same "no points" branch autoplot.Polygon/
  # autolayer.Polygon guard against.
  fake <- structure(
    list(as_data_frame = function() data.frame(x = numeric(0), y = numeric(0))),
    class = "Polygon"
  )
  expect_warning(p <- ggplot2::autoplot(fake), "Polygon has no points")
  expect_s3_class(p, "ggplot")
  expect_null(ggplot2::autolayer(fake))
})

# ---------------------------------------------------------------------------
# VocalTract: plot_type = "line" (only "area", the default, tested elsewhere)
# ---------------------------------------------------------------------------

test_that("VocalTract autoplot supports plot_type = 'line'", {
  vt <- VocalTract(nx = 10L, dx = 0.02)
  p <- ggplot2::autoplot(vt, plot_type = "line")
  expect_s3_class(p, "ggplot")
  expect_true(
    any(vapply(p$layers, function(l) inherits(l$geom, "GeomCol"), logical(1))))
})

# ---------------------------------------------------------------------------
# LPC: non-default frame index
# ---------------------------------------------------------------------------

test_that("LPC autoplot/autolayer accept a non-default frame index", {
  lpc <- sound_fixture()$to_lpc_burg(prediction_order = 8)
  n_frames <- length(lpc$get_all_gains())
  skip_if(n_frames < 2, "not enough frames to test a non-default index")
  p <- ggplot2::autoplot(lpc, frame = 2)
  expect_s3_class(p, "ggplot")
  layer <- ggplot2::autolayer(lpc, frame = 2)
  expect_true(inherits(layer, "Layer") || inherits(layer, "geom"))
})

# ---------------------------------------------------------------------------
# KlattGrid: formant_type restricted to a type with no added points (empty
# formant-data warning), and the matching autolayer NULL branch
# ---------------------------------------------------------------------------

test_that(
  "KlattGrid autoplot/autolayer warn/return NULL when the requested formant_type has no data", {
  kg <- KlattGrid(0, 0.3, numberOfFormants = 3)
  kg$add_pitch_point(0.15, 120)
  kg$add_voicing_amplitude_point(0.15, 90)
  kg$add_formant_point(1, 1, 0.15, 500)  # oral formant 1 only

  expect_warning(p <- ggplot2::autoplot(kg, formant_type = "nasal"),
                  "KlattGrid has no formant data")
  expect_s3_class(p, "ggplot")
  expect_null(ggplot2::autolayer(kg, formant_type = "nasal"))
})
