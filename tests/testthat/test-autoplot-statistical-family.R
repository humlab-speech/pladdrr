# test-autoplot-statistical-family.R
library(testthat)
library(pladdrr)

test_that("Matrix as.data.frame uses real xmin/dx/ymin/dy axis values (Task 6 regression guard)", {
  mat <- Matrix(xmin = 0, xmax = 1, nx = 10, dx = 0.1, x1 = 0.05,
                ymin = 0, ymax = 2, ny = 20, dy = 0.1, y1 = 0.05)
  df <- as.data.frame(mat)
  expect_lte(max(df$col), 1.0)
  expect_gte(min(df$col), 0)
  expect_lte(max(df$row), 2.0)
  expect_gte(min(df$row), 0)
  expect_false(isTRUE(all.equal(sort(unique(df$col)), 1:10)))
  expect_s3_class(ggplot2::autoplot(mat), "ggplot")
})

test_that("VocalTract as.data.frame respects real dx, not hardcoded 0.01 (Task 9 regression guard)", {
  vt <- VocalTract(nx = 10L, dx = 0.02)
  df <- as.data.frame(vt)
  # Section centers per Praat's Matrix_init half-section-offset convention
  # (src/praat.github.io/fon/VocalTract.cpp:33): 0.5*dx, 1.5*dx, ..., not
  # 0, dx, 2dx, ...
  expect_equal(max(df$distance), 0.01 + 9 * 0.02, tolerance = 1e-9)
  expect_equal(min(df$distance), 0.01, tolerance = 1e-9)
  expect_s3_class(ggplot2::autoplot(vt), "ggplot")
  p2 <- ggplot2::ggplot() + ggplot2::autolayer(vt)
  expect_s3_class(p2, "ggplot")
})

test_that("DTW autoplot/autolayer render and degrade gracefully on empty path (Task 5 regression guard)", {
  sound <- generate_sine_wave(440, 0.1, sampling_rate = 16000)
  dtw <- sounds_to_dtw(sound, sound)
  p <- ggplot2::autoplot(dtw)
  expect_s3_class(p, "ggplot")
  layer <- ggplot2::autolayer(dtw)
  expect_type(layer, "list")
  expect_length(layer, 2)

  fake <- structure(list(get_path = function() NULL), class = "DTW")
  expect_warning(p2 <- ggplot2::autoplot(fake))
  expect_s3_class(p2, "ggplot")
  expect_null(ggplot2::autolayer(fake))
})

test_that("Polygon autoplot/autolayer render, fill_color vs fill_col are distinct params", {
  poly <- Polygon(x = c(0, 1, 1, 0), y = c(0, 0, 1, 1))
  p <- ggplot2::autoplot(poly, fill_polygon = TRUE, fill_color = "steelblue")
  expect_s3_class(p, "ggplot")
  p2 <- ggplot2::ggplot() + ggplot2::autolayer(poly)
  expect_s3_class(p2, "ggplot")
})

test_that("PCA autoplot renders for scree/scores/both type", {
  set.seed(1)
  x <- matrix(rnorm(200), nrow = 20)
  pca <- pca_from_matrix(x)  # R/pca-wrapper.R:155
  expect_s3_class(ggplot2::autoplot(pca, type = "scree"), "ggplot")
  expect_s3_class(ggplot2::autoplot(pca, type = "scores"), "ggplot")
  # "both" requires patchwork (Suggests); skip cleanly if not installed,
  # matching the package's own requireNamespace("patchwork") guard.
  if (requireNamespace("patchwork", quietly = TRUE)) {
    expect_s3_class(ggplot2::autoplot(pca, type = "both"), "ggplot")
  }
})

test_that("Discriminant autoplot renders", {
  set.seed(1)
  data <- matrix(c(rnorm(10, 500), rnorm(10, 700)), ncol = 1,
                  dimnames = list(NULL, "f1"))
  labels <- rep(c("a", "i"), each = 10)
  disc <- discriminant_from_matrix(data, labels)  # R/discriminant-wrapper.R:174
  expect_s3_class(ggplot2::autoplot(disc), "ggplot")
})
