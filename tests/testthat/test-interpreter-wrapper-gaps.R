# tests/testthat/test-interpreter-wrapper-gaps.R
# Coverage gap-fill for R/praat-interpreter-wrapper.R: the
# .praat_object_xptr getter fallbacks, and the set_variable / eval /
# set_object validation branches.

test_that(".praat_object_xptr extracts pointers from all object shapes", {
  snd <- Sound$create_tone(frequency = 220, duration = 0.3, sampling_rate = 16000)
  ptr <- snd$.xptr
  # direct .xptr field
  expect_identical(pladdrr:::.praat_object_xptr(list(.xptr = ptr)), ptr)
  # get_xptr function
  obj2 <- list(get_xptr = function() ptr)
  expect_identical(pladdrr:::.praat_object_xptr(obj2), ptr)
  # get_ptr function
  obj3 <- list(get_ptr = function() ptr)
  expect_identical(pladdrr:::.praat_object_xptr(obj3), ptr)
  # neither -> error
  expect_error(pladdrr:::.praat_object_xptr(list()), "Could not extract")
})

test_that("set_variable validates its name", {
  interp <- PraatInterpreter$new()
  expect_error(interp$set_variable(42, 1), "single non-empty character")
  expect_error(interp$set_variable("", 1), "single non-empty character")
  interp$set_variable("ok_var", 7)
  expect_equal(interp$get_variable("ok_var"), 7, tolerance = sqrt(.Machine$double.eps))
})

test_that("eval validates its expression", {
  interp <- PraatInterpreter$new()
  expect_error(interp$eval(123), "single non-empty character")
  expect_error(interp$eval(""), "single non-empty character")
  expect_equal(interp$eval("1 + 1"), 2, tolerance = sqrt(.Machine$double.eps))
})

test_that("set_object validates and sends PraatObjects", {
  interp <- PraatInterpreter$new()
  expect_error(interp$set_object("s", "not an object"), "must be a PraatObject")
  s <- Sound$create_tone(frequency = 220, duration = 0.3, sampling_rate = 16000)
  # NOTE: set_object registers the object in Praat's global object list;
  # remove it afterwards or later tests asserting an empty list fail.
  id <- interp$set_object("gap_test_tone", s)
  expect_type(id, "integer")
  interp$remove_object("gap_test_tone")
  expect_identical(nrow(interp$list_objects()), 0L)
})
