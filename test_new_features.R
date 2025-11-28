library(pladdrr)

cat("Testing new TextGrid extension functions...\n\n")

# Create a test TextGrid
tg <- TextGrid$create(0, 5, "words")
tg$insert_boundary(tier = 1, time = 1.0)
tg$insert_boundary(tier = 1, time = 2.0)
tg$insert_boundary(tier = 1, time = 3.0)
tg$set_interval_text(tier = 1, interval = 1, text = "hello")
tg$set_interval_text(tier = 1, interval = 2, text = "world")
tg$set_interval_text(tier = 1, interval = 3, text = "hello")
tg$set_interval_text(tier = 1, interval = 4, text = "again")

cat("Initial TextGrid:\n")
for (i in 1:tg$get_number_of_intervals(1)) {
  label <- tg$get_interval_text(1, i)
  cat("  Interval", i, ":", label, "\n")
}

# Test 1: change_labels
cat("\nTest 1: change_labels (hello -> hi)\n")
tg$change_labels(tier = 1, search = "hello", replace = "hi")
for (i in 1:tg$get_number_of_intervals(1)) {
  label <- tg$get_interval_text(1, i)
  cat("  Interval", i, ":", label, "\n")
}

# Test 2: get_total_duration_where
cat("\nTest 2: get_total_duration_where\n")
duration_hi <- tg$get_total_duration_where(tier = 1, criterion = "hi")
cat("  Total duration of 'hi':", duration_hi, "seconds\n")

# Test 3: merge_identical_intervals
cat("\nTest 3: merge_identical_intervals\n")
cat("  Before merge: ", tg$get_number_of_intervals(1), "intervals\n")
tg$merge_identical_intervals(tier = 1, label = "hi")
cat("  After merge: ", tg$get_number_of_intervals(1), "intervals\n")
for (i in 1:tg$get_number_of_intervals(1)) {
  label <- tg$get_interval_text(1, i)
  start <- tg$get_interval_start_time(1, i)
  end <- tg$get_interval_end_time(1, i)
  cat("    Interval", i, ":", label, "(", start, "-", end, ")\n")
}

# Test 4: extend_time
cat("\nTest 4: extend_time\n")
cat("  Original duration:", tg$get_total_duration(), "seconds\n")
tg$extend_time(delta_time = 1.0, position = 1)  # extend at end
cat("  After extension:", tg$get_total_duration(), "seconds\n")

# Test 5: Audio quality check
cat("\n\nTesting audio_quality functions...\n")
sound <- Sound$create_simple(
  duration = 1.0,
  sampling_frequency = 22050,
  formula = "0.5 * sin(2*pi*440*x)"  # A440 tone at 50% amplitude
)

quality <- check_audio_quality(sound)
cat("\nAudio Quality Metrics:\n")
cat("  Max amplitude:", round(quality$max_amplitude, 3), "\n")
cat("  Is clipped:", quality$is_clipped, "\n")
cat("  Mean intensity:", round(quality$mean_intensity_db, 1), "dB\n")
cat("  Intensity range:", round(quality$intensity_range_db, 1), "dB\n")
cat("  Duration:", quality$duration, "seconds\n")

# Test report formatting
cat("\n", format_quality_report(quality, detailed = FALSE))

cat("\n✅ All tests passed!\n")
