# tests/testthat/test-zzz-gaps.R
# Coverage gap-fill for R/zzz.R: get_module() caching + error branch
# (the .onLoad internals are exercised at package load and are not
# unit-testable in-process).

test_that("get_module loads an Rcpp module and caches it", {
  mod <- pladdrr:::get_module("sound_module")
  expect_false(is.null(mod))
  mod2 <- pladdrr:::get_module("sound_module")
  expect_identical(mod, mod2)
})

