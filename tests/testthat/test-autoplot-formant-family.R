# test-autoplot-formant-family.R
# Tests for autoplot/autolayer/as.data.frame on FormantTier, FormantGrid,
# FormantPath, FormantModeler, KlattGrid

library(testthat)
library(pladdrr)

test_that("FormantGrid autoplot/autolayer/as.data.frame work", {
  grid <- FormantGrid(tmin = 0, tmax = 1, number_of_formants = 3)
  grid$add_formant_point(1, 0.5, 500)
  grid$add_formant_point(2, 0.5, 1500)
  grid$add_formant_point(3, 0.5, 2500)
  df <- as.data.frame(grid)
  expect_gt(nrow(df), 0)
  p <- ggplot2::autoplot(grid)
  expect_s3_class(p, "ggplot")
  p2 <- ggplot2::ggplot() + ggplot2::autolayer(grid)
  expect_s3_class(p2, "ggplot")
})

test_that("FormantTier speckle (default) and line styles both work and use the right geom", {
  sound <- generate_sine_wave(440, 0.3, sampling_rate = 16000)
  formant <- sound$to_formant_burg()
  ft <- FormantTier$from_formant(formant)  # R/formanttier-wrapper.R:152-171; the `down_to_formant_tier()` bullet in R/formant-wrapper.R:47's
  # roxygen is stale/aspirational doc text, not an implemented method — verified during SDD Task 10,
  # downsamples all formants to a FormantTier
  p_speckle <- ggplot2::autoplot(ft)
  p_line <- ggplot2::autoplot(ft, style = "line")
  expect_s3_class(p_speckle$layers[[1]]$geom, "GeomPoint")
  expect_true(any(vapply(p_line$layers, function(l) inherits(l$geom, "GeomLine"),
                         logical(1))))

  layer_speckle <- ggplot2::autolayer(ft)
  expect_true(is.list(layer_speckle) || inherits(layer_speckle, "Layer"))
  layer_line <- ggplot2::autolayer(ft, style = "line")
  expect_true(is.list(layer_line) || inherits(layer_line, "Layer"))
})

test_that("KlattGrid autoplot produces non-empty data after Task 2's formantType fix", {
  kg <- KlattGrid(0, 0.3, numberOfFormants = 3)
  kg$add_pitch_point(0.15, 120)
  kg$add_voicing_amplitude_point(0.15, 90)
  kg$add_formant_point(1, 1, 0.15, 500)
  kg$add_formant_point(1, 2, 0.15, 1500)
  kg$add_formant_point(1, 3, 0.15, 2500)
  expect_equal(kg$get_formant_at_time(1, 1, 0.15), 500, tolerance = 1)
  df <- as.data.frame(kg)
  expect_false(all(is.na(df$frequency)))
  p <- ggplot2::autoplot(kg)
  expect_s3_class(p, "ggplot")
  p2 <- ggplot2::ggplot() + ggplot2::autolayer(kg)
  expect_s3_class(p2, "ggplot")
})

test_that("KlattGrid with an unrecognized formant_type errors clearly instead of silently returning NA", {
  kg <- KlattGrid(0, 0.3, numberOfFormants = 3)
  expect_error(ggplot2::autoplot(kg, formant_type = "not_a_real_type"))
})

test_that("FormantPath autoplot/autolayer work", {
  sound <- generate_sine_wave(440, 0.3, sampling_rate = 16000)
  fp <- sound$to_formant_path()  # R/sound-wrapper.R:539
  p <- ggplot2::autoplot(fp)
  expect_s3_class(p, "ggplot")
  expect_gt(nrow(p$data), 0)
  p2 <- ggplot2::ggplot() + ggplot2::autolayer(fp)
  expect_s3_class(p2, "ggplot")
})

test_that("FormantModeler autoplot/autolayer work with from_track/to_track", {
  sound <- generate_sine_wave(440, 0.3, sampling_rate = 16000)
  formant <- sound$to_formant_burg()
  fm <- formant$to_formant_modeler()  # R/formant-wrapper.R:209
  p <- ggplot2::autoplot(fm, from_track = 1, to_track = 2)
  expect_s3_class(p, "ggplot")
  expect_gt(nrow(p$data), 0)
  expect_setequal(unique(p$data$formant_number), c(1, 2))
  p2 <- ggplot2::ggplot() + ggplot2::autolayer(fm, from_track = 1, to_track = 2)
  expect_s3_class(p2, "ggplot")
})

test_that(".formant_modeler_long_df degrades gracefully on edge-case inputs", {
  # 0-row wide frame must not error -- must degrade to an empty long df,
  # which downstream triggers the "no data" warning + empty-plot path.
  wide_empty <- data.frame(time = numeric(0), F1_modeled = numeric(0),
                            F2_modeled = numeric(0))
  res_empty <- pladdrr:::.formant_modeler_long_df(wide_empty, 1, 0, 2)
  expect_identical(nrow(res_empty), 0L)
  expect_setequal(names(res_empty), c("time", "formant_number", "frequency"))

  # from_track > to_track must not count backward (R's `:` operator would);
  # it must produce 0 rows, matching the pre-refactor subsetting behavior.
  sound <- generate_sine_wave(440, 0.3, sampling_rate = 16000)
  formant <- sound$to_formant_burg()
  fm <- formant$to_formant_modeler()
  wide <- as.data.frame(fm)
  res_backwards <- pladdrr:::.formant_modeler_long_df(wide, 3, 1, 3)
  expect_identical(nrow(res_backwards), 0L)
})
