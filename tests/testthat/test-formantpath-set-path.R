# Regression test for FormantPath set_path()/set_optimal_path() -> extract_formant().
# FormantPath_setPath() (praat.github.io/LPC/FormantPath.cpp) used to write the
# candidate's ceiling *frequency* into the path TextGrid interval label instead
# of the candidate *index*. extract_formant() parses that label back as an
# integer candidate index and uses it as an unchecked array index into
# formantCandidates, so a bogus frequency-sized value (e.g. 5500) caused an
# out-of-bounds read and crashed the R session.

test_that("extract_formant() after set_path() does not crash and returns valid data", {
  sound <- Sound$create_tone(frequency = 150, duration = 0.5)
  fp <- sound$to_formant_path(num_steps_up_down = 2L)

  fp$set_path(tmin = 0.1, tmax = 0.3, selected_candidate = 3)
  frm <- fp$extract_formant()

  expect_s3_class(frm, "Formant")
  expect_equal(frm$get_number_of_frames(), fp$get_nx(), tolerance = sqrt(.Machine$double.eps))

  f1 <- frm$get_value_at_time(1, 0.2, "hertz")
  expect_type(f1, "double")
  expect_false(is.na(f1))
})

test_that("extract_formant() after set_optimal_path() does not crash", {
  sound <- Sound$create_tone(frequency = 150, duration = 0.5)
  fp <- sound$to_formant_path(num_steps_up_down = 2L)

  fp$set_optimal_path(tmin = fp$get_xmin(), tmax = fp$get_xmax(),
                       parameters = c(1, 1, 1, 1, 1), powerf = 1.25)
  frm <- fp$extract_formant()

  expect_s3_class(frm, "Formant")
  expect_equal(frm$get_number_of_frames(), fp$get_nx(), tolerance = sqrt(.Machine$double.eps))
})
