# Runtime contracts for SIMD dispatch: empty inputs and the scalar fallback.
# These exercise the branches that a SIMD-enabled CI build otherwise skips.

test_that("duration statistics: empty input and scalar fallback agree", {
  stats_fn <- pladdrr:::duration_statistics_simd_bridge

  empty <- stats_fn(numeric(0))
  expect_named(empty, c("mean", "stdev", "min", "max"))
  expect_true(all(is.na(vapply(empty, identity, numeric(1)))))

  durations <- c(0.1, 0.2, 0.3, 0.4, 0.5, 0.6)
  simd <- stats_fn(durations)

  on.exit(pladdrr:::set_textgrid_simd_enabled_bridge(TRUE), add = TRUE)
  pladdrr:::set_textgrid_simd_enabled_bridge(FALSE)
  scalar <- stats_fn(durations)

  expect_equal(scalar$mean, mean(durations), tolerance = 1e-12)
  expect_equal(scalar$stdev, sd(durations), tolerance = 1e-12)
  expect_equal(scalar$min, min(durations))
  expect_equal(scalar$max, max(durations))
  expect_equal(simd, scalar, tolerance = 1e-10)
})

test_that("duration filter: empty input and scalar fallback agree", {
  filter_fn <- pladdrr:::filter_by_duration_simd_bridge

  expect_identical(filter_fn(numeric(0), 0.1, 0.2), integer(0))

  durations <- c(0.05, 0.1, 0.15, 0.2, 0.25, 0.3)
  simd <- filter_fn(durations, 0.1, 0.2)

  on.exit(pladdrr:::set_textgrid_simd_enabled_bridge(TRUE), add = TRUE)
  pladdrr:::set_textgrid_simd_enabled_bridge(FALSE)
  scalar <- filter_fn(durations, 0.1, 0.2)

  expect_identical(simd, which(durations >= 0.1 & durations <= 0.2))
  expect_identical(scalar, simd)
})

test_that("interval statistics and quantiles match base R", {
  intervals <- list(c(1, 2, 3), c(4, 5, 6, 7))

  stats <- pladdrr:::calculate_interval_statistics_simd_bridge(
    intervals, "all"
  )
  expect_equal(stats[, "mean"], vapply(intervals, mean, numeric(1)))
  expect_equal(stats[, "stdev"], vapply(intervals, sd, numeric(1)))
  expect_equal(stats[, "min"], vapply(intervals, min, numeric(1)))
  expect_equal(stats[, "max"], vapply(intervals, max, numeric(1)))

  quantiles <- pladdrr:::calculate_interval_quantiles_simd_bridge(
    intervals, c(0.25, 0.5, 0.75)
  )
  for (i in seq_along(intervals)) {
    expect_equal(
      unname(quantiles[i, ]),
      unname(quantile(intervals[[i]], c(0.25, 0.5, 0.75), type = 7)),
      tolerance = 1e-12
    )
  }

  expect_length(
    pladdrr:::calculate_interval_statistics_simd_bridge(list(), "all"), 0
  )
})

test_that("sound mix scalar fallback matches the SIMD path", {
  s1 <- Sound$create_tone(frequency = 200, duration = 0.2)
  s2 <- Sound$create_tone(frequency = 300, duration = 0.2)

  on.exit(pladdrr:::set_global_simd_enabled(TRUE), add = TRUE)

  simd <- s1$mix(s2, balance = 1)$get_values()
  pladdrr:::set_global_simd_enabled(FALSE)
  scalar <- s1$mix(s2, balance = 1)$get_values()

  expect_equal(scalar, simd, tolerance = 1e-12)
  expect_length(scalar, s1$get_number_of_samples())
})
