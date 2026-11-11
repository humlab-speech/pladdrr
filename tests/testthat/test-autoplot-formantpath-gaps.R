# autoplot/autolayer.FormantPath: the reachable branches not covered by the
# generic autoplot-family tests (empty time window, no-candidate path).

test_that("autoplot.FormantPath plots the path and handles an empty window", {
  skip_if_not_installed("ggplot2")

  sound <- Sound$create_tone(frequency = 200, duration = 0.3)
  path <- sound$to_formant_path(num_steps_up_down = 2)

  plot <- ggplot2::autoplot(path)
  expect_s3_class(plot, "ggplot")
  expect_gte(length(plot$layers), 1)

  plot_no_candidates <- ggplot2::autoplot(path, show_candidates = FALSE)
  expect_s3_class(plot_no_candidates, "ggplot")
  expect_gte(length(plot_no_candidates$layers), 1)

  expect_warning(
    empty <- ggplot2::autoplot(path, from_time = 10, to_time = 11),
    "FormantPath has no data"
  )
  expect_s3_class(empty, "ggplot2::ggplot")
  expect_length(empty$layers, 0)

  layer <- ggplot2::autolayer(path)
  expect_type(layer, "list")
})
