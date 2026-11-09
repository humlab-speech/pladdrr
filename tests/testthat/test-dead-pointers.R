# An external pointer that went through serialize()/unserialize() (readRDS(),
# saveRDS(), a parallel worker's result, a restored session) is NULL inside.
# Every compiled entry point must turn that into an R error, not dereference it.
# These four used to segfault R (found by autotest, 2026-11).

dead <- function(x) unserialize(serialize(x, NULL))

test_that("a NULL external pointer is an R error in the tier and EGG entry points", {
  snd <- generate_sine_wave(200, 0.3, sampling_rate = 16000, amplitude = 0.5)
  pp <- snd$to_point_process_periodic_cc(75, 600)
  d <- dead(pp$.xptr)

  expect_error(pladdrr:::point_process_sound_to_amplitude_tier_point_cpp(d, snd$.xptr),
               "Invalid PointProcess pointer \\(NULL\\)")
  expect_error(pladdrr:::point_process_sound_to_amplitude_tier_point_cpp(pp$.xptr, dead(snd$.xptr)),
               "Invalid Sound pointer \\(NULL\\)")
  expect_error(pladdrr:::intensity_tier_to_amplitude_tier_cpp(d),
               "Invalid IntensityTier pointer \\(NULL\\)")
  expect_error(pladdrr:::sound_extract_electroglottogram_cpp(dead(snd$.xptr), 1L, FALSE),
               "Invalid Sound pointer \\(NULL\\)")
})

test_that("a dead object passed to the public wrappers is an R error", {
  snd <- generate_sine_wave(200, 0.3, sampling_rate = 16000, amplitude = 0.5)
  pp <- snd$to_point_process_periodic_cc(75, 600)
  pp$.xptr <- dead(pp$.xptr)
  expect_error(amplitude_tier_from_point_process(pp, snd), "pointer \\(NULL\\)")
})
