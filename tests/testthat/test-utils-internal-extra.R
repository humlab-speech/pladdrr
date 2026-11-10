# test-utils-internal-extra.R - Extra branches of R/utils-internal.R not
# already hit incidentally by other tests (extract_xptr fallback paths).

test_that("extract_xptr uses the .xptr field when present", {
  sound <- Sound$create_tone(frequency = 150, duration = 0.1,
    sampling_rate = 8000)
  ptr <- pladdrr:::extract_xptr(sound, "Sound")
  expect_type(ptr, "externalptr")
})

test_that("extract_xptr passes external pointers through unchanged", {
  sound <- Sound$create_tone(frequency = 150, duration = 0.1,
    sampling_rate = 8000)
  ptr <- pladdrr:::extract_xptr(sound$.xptr, "Sound")
  expect_identical(ptr, sound$.xptr)
})

test_that("extract_xptr falls back to get_xptr() when .xptr is absent", {
  fake <- structure(list(get_xptr = function() "fake-pointer"), class = "Fake")
  expect_identical(pladdrr:::extract_xptr(fake, "Fake"), "fake-pointer")
})

test_that(
  "extract_xptr falls back to .pointer when neither .xptr nor get_xptr() work", {
  fake <- structure(list(.pointer = "fake-pointer-2"), class = "Fake")
  expect_identical(pladdrr:::extract_xptr(fake, "Fake"), "fake-pointer-2")
})

test_that(
  "extract_xptr errors when no pointer can be found on a classed object", {
  fake <- structure(list(nothing = "here"), class = "Fake")
  expect_error(pladdrr:::extract_xptr(fake, "Fake"),
    "Could not extract external pointer")
})

test_that("extract_xptr errors for non-object, non-pointer input", {
  expect_error(pladdrr:::extract_xptr(42, "Sound"),
    "Expected Sound or externalptr")
})
