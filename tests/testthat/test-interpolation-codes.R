## Value interpolation (kVector_valueInterpolation: 0 nearest, 1 linear, 2 cubic,
## 3 sinc70, 4 sinc700).
## 5.1.x: Intensity$get_value_at_time(t, "cubic") -- the default -- returned the
## linear value, because the module passed the code to Sampled_getValueAtX, whose
## last parameter is a bool; get_intensity_value_direct() selected a numeric code
## by position (2 -> linear); and any unknown name ("banana", or 0) silently
## became cubic.

make_intensity <- function() Sound$create_tone(1.0, 22050, 150, 0.5)$to_intensity()
t0 <- 0.4035

test_that("Intensity interpolation methods differ and agree across doors", {
  it <- make_intensity()
  v <- vapply(c("nearest", "linear", "cubic", "sinc70", "sinc700"),
    function(m) it$get_value_at_time(t0, interpolation = m), numeric(1))
  expect_false(isTRUE(all.equal(v[["cubic"]], v[["linear"]], tolerance = 1e-12)))
  for (m in names(v)) {
    expect_equal(get_intensity_value_direct(it$.xptr, t0, m), v[[m]],
      tolerance = 1e-12, info = m)
    expect_equal(it$get_values_at_times(t0, interpolation = m), v[[m]],
      tolerance = 1e-12, info = m)
  }
  # the default is cubic
  expect_identical(it$get_value_at_time(t0), v[["cubic"]])
})

test_that("a numeric interpolation code means the same as its name", {
  it <- make_intensity()
  for (code in 0:4) {
    nm <- c("nearest", "linear", "cubic", "sinc70", "sinc700")[code + 1L]
    expect_identical(get_intensity_value_direct(it$.xptr, t0, code),
      get_intensity_value_direct(it$.xptr, t0, nm), info = nm)
    expect_identical(it$get_value_at_time(t0, interpolation = code),
      it$get_value_at_time(t0, interpolation = nm), info = nm)
  }
})

test_that("an unknown interpolation is an input error, never cubic", {
  it <- make_intensity()
  for (bad in list("banana", "", NA_character_, 7, -1, 1.5, c("linear", "cubic"))) {
    for (door in list(
      function() it$get_value_at_time(t0, interpolation = bad),
      function() it$get_values_at_times(t0, interpolation = bad),
      function() get_intensity_value_direct(it$.xptr, t0, bad))) {
      cond <- tryCatch(door(), error = function(e) e)
      expect_s3_class(cond, "pladdrr_input_error")
      expect_match(conditionMessage(cond), "Unknown interpolation")
    }
  }
})
