# tests/testthat/test-zzz-gaps.R
# Coverage gap-fill for R/zzz.R: the get_module error branch. The
# remaining uncovered lines (.onLoad/.onAttach bodies) execute at package
# load and are not unit-testable in-process.

test_that("get_module caches loaded modules", {
  m1 <- pladdrr:::get_module("pitch_module")
  m2 <- pladdrr:::get_module("pitch_module")
  expect_identical(m1, m2)
})
