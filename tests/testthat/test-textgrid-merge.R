# test-textgrid-merge.R - Tests for textgrid_merge() in R/batch-ops.R
# (drives src/textgrid_merge.cpp, otherwise unreachable from any other path)

test_that("textgrid_merge validates its arguments", {
  expect_error(textgrid_merge(list()), "non-empty list")
  expect_error(textgrid_merge("not a list"), "non-empty list")

  tg <- textgrid_create(0, 1, "words")
  expect_error(textgrid_merge(list(tg), equalize_domains = "yes"), "TRUE or FALSE")
})

test_that("textgrid_merge combines tiers from multiple TextGrids", {
  tg1 <- textgrid_create(0, 1, "words")
  tg1$insert_boundary("words", 0.4)
  tg1$set_interval_text("words", 1, "hello")
  tg1$set_interval_text("words", 2, "world")

  tg2 <- textgrid_create(0, 1, "tones", "tones")
  tg2$insert_point("tones", 0.25, "H*")

  merged <- textgrid_merge(list(tg1, tg2))

  expect_s3_class(merged, "TextGrid")
  expect_identical(merged$get_number_of_tiers(), 2L)
})

test_that("textgrid_merge with equalize_domains = TRUE extends shorter grids", {
  tg1 <- textgrid_create(0, 1, "words")
  tg2 <- textgrid_create(0, 2, "tones", "tones")

  merged <- textgrid_merge(list(tg1, tg2), equalize_domains = TRUE)

  expect_s3_class(merged, "TextGrid")
  expect_equal(merged$get_end_time(), 2, tolerance = sqrt(.Machine$double.eps))
})
