# Helper functions for testing R/plotting-combined.R

#' Assert that a combined-plot function returned a plausible plot object
#'
#' Centralizes the "is this any kind of renderable plot" check used across
#' plot_textgrid_sound()/plot_textgrid_pitch()/plot_sound_pitch() tests
#' (patchwork if available, otherwise a gridExtra gtable/grob, or a bare
#' ggplot for single-panel results). When patchwork produced the result,
#' also asserts it actually stacked multiple panels rather than merely
#' inheriting the "patchwork" class.
#'
#' @param p Object returned by one of the combined-plot functions
expect_combined_plot <- function(p) {
  testthat::expect_true(
    inherits(p, "patchwork") || inherits(p, "ggplot") ||
      inherits(p, "gtable") || inherits(p, "grob"),
    info = "Object should be a patchwork, ggplot, gtable, or grob"
  )

  if (requireNamespace("patchwork", quietly = TRUE) && inherits(p, "patchwork")) {
    testthat::expect_true(
      length(p$patches$plots) >= 1,
      info = "patchwork object should have stacked multiple panels"
    )
  }

  invisible(TRUE)
}
