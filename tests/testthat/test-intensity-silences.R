# Intensity$to_textgrid_silences(): the silence/sounding transition loop.
# Build a 0.2 s silence / 0.2 s tone / 0.2 s silence signal so the detector
# has to close both a silent and a sounding interval.

silence_fixture <- function() {
  silence <- rep(0, 8000)
  tone <- sin(2 * pi * 200 * seq(0, 0.2, length.out = 8000))
  Sound$from_values(c(silence, tone, silence), sampling_rate = 40000)
}

test_that("Intensity to_textgrid_silences detects both transitions", {
  tier <- silence_fixture()$to_intensity()$to_textgrid_silences(
    min_silence_duration = 0.1, min_sounding_duration = 0.05
  )

  expect_s3_class(tier, "TextGrid")
  expect_equal(tier$get_number_of_tiers(), 1)
  expect_equal(tier$get_tier_name(1), "silences")
  expect_equal(tier$get_number_of_intervals(1), 3)

  labels <- vapply(
    seq_len(3),
    function(i) tier$get_interval_text(1, i),
    character(1)
  )
  expect_equal(labels, c("silent", "sounding", "silent"))

  starts <- vapply(
    seq_len(3),
    function(i) tier$get_interval_start_time(1, i),
    numeric(1)
  )
  ends <- vapply(
    seq_len(3),
    function(i) tier$get_interval_end_time(1, i),
    numeric(1)
  )
  expect_equal(starts[1], 0, tolerance = 1e-9)
  expect_equal(ends[3], 0.6, tolerance = 1e-9)
  expect_equal(ends[-3], starts[-1], tolerance = 1e-9)
})
