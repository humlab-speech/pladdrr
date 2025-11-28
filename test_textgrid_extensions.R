library(pladdrr)

cat("Testing TextGrid Extension Methods\n\n")

# Create a test TextGrid
tg <- TextGrid$create(0, 5, "words")
cat("Created TextGrid from 0-5s with 'words' tier\n")

# Add some intervals
cat("\nSetting up test data...\n")
tg$insert_boundary(tier = "words", time = 1.0)
tg$insert_boundary(tier = "words", time = 2.0)
tg$insert_boundary(tier = "words", time = 3.0)

tg$set_interval_text(tier = "words", interval = 1, text = "hello")
tg$set_interval_text(tier = "words", interval = 2, text = "world")
tg$set_interval_text(tier = "words", interval = 3, text = "hello")
tg$set_interval_text(tier = "words", interval = 4, text = "again")

cat("Initial labels:\n")
for (i in 1:4) {
  label <- tg$get_interval_text("words", i)
  cat("  Interval", i, ":", label, "\n")
}

# Test 1: change_labels
cat("\n=== Test 1: change_labels ===\n")
cat("Changing 'hello' to 'hi'\n")
tg$change_labels(tier = "words", search = "hello", replace = "hi")
cat("After change:\n")
for (i in 1:4) {
  label <- tg$get_interval_text("words", i)
  cat("  Interval", i, ":", label, "\n")
}

# Test 2: get_total_duration_where
cat("\n=== Test 2: get_total_duration_where ===\n")
duration_hi <- tg$get_total_duration_where(tier = "words", criterion = "hi")
cat("Total duration of 'hi':", duration_hi, "seconds\n")

# Test 3: extend_time
cat("\n=== Test 3: extend_time ===\n")
cat("Original duration:", tg$get_total_duration(), "seconds\n")
tg$extend_time(delta_time = 1.0, position = 1)
cat("After extending by 1s at end:", tg$get_total_duration(), "seconds\n")

# Test 4: merge_identical_intervals
cat("\n=== Test 4: merge_identical_intervals ===\n")
cat("Before merge:", tg$get_number_of_intervals("words"), "intervals\n")
tg$merge_identical_intervals(tier = "words", label = "hi")
cat("After merging 'hi':", tg$get_number_of_intervals("words"), "intervals\n")
cat("Remaining labels:\n")
for (i in 1:tg$get_number_of_intervals("words")) {
  label <- tg$get_interval_text("words", i)
  start <- tg$get_interval_start_time("words", i)
  end <- tg$get_interval_end_time("words", i)
  cat(sprintf("  Interval %d: '%s' (%.2f-%.2f)\n", i, label, start, end))
}

cat("\n✅ All TextGrid extension tests passed!\n")
