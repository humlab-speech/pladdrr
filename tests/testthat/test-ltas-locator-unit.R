## The Ltas locators answer in the bins' own dB; their `unit` argument used to be
## ignored, so unit = "energy" or "sones" silently returned dB (fix/009 review).
## They now accept only "dB", like Praat's own dialogs, which have no unit.

lt <- Sound$new(system.file("extdata/test.wav", package = "pladdrr"))$to_ltas(100)

test_that("the locators refuse a unit they would silently ignore", {
  for (bad in list("energy", "sones", "Hz", NA_character_, 3, c("dB", "dB"))) {
    for (call in list(
      function(u) lt$get_value_at_frequency(1000, unit = u),
      function(u) lt$get_minimum(0, 0, unit = u),
      function(u) lt$get_maximum(0, 0, unit = u))) {
      cond <- tryCatch(call(bad), error = function(e) e)
      expect_s3_class(cond, "pladdrr_input_error")
      expect_identical(cond$param, "unit")
    }
  }
})

test_that("dB in any spelling, and the default, give the same answer as before", {
  base <- c(lt$get_value_at_frequency(1000), lt$get_minimum(0, 0), lt$get_maximum(0, 0))
  expect_true(all(is.finite(base)))
  for (u in c("dB", "db", "DB")) {
    expect_identical(c(lt$get_value_at_frequency(1000, unit = u),
      lt$get_minimum(0, 0, unit = u), lt$get_maximum(0, 0, unit = u)), base)
  }
})

test_that("the averaging queries still take all three units", {
  expect_true(is.finite(lt$get_mean(0, 0, unit = "energy")))
  expect_true(is.finite(lt$get_mean(0, 0, unit = "sones")))
})
