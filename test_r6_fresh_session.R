#!/usr/bin/env Rscript
# Test R6 methods in completely fresh session

cat("═══════════════════════════════════════════════════════\n")
cat("  R6 Method Access Test - Fresh Session\n")
cat("═══════════════════════════════════════════════════════\n\n")

cat("Loading pladdrr...\n")
library(pladdrr)

cat("\n【1】 Test TextGrid Methods\n")
cat("───────────────────────────────────────────────────────\n")

cat("Creating TextGrid...\n")
tg <- TextGrid$create(0, 5, "words")
cat("✅ Created\n")

cat("\nTesting insert_boundary()...\n")
tryCatch({
  tg$insert_boundary(1, 1.0)
  cat("✅ insert_boundary works!\n")
}, error = function(e) {
  cat("❌ ERROR:", conditionMessage(e), "\n")
})

cat("\nTesting set_interval_text()...\n")
tryCatch({
  tg$set_interval_text(1, 1, "hello")
  cat("✅ set_interval_text works!\n")
}, error = function(e) {
  cat("❌ ERROR:", conditionMessage(e), "\n")
})

cat("\nTesting get_total_duration()...\n")
tryCatch({
  dur <- tg$get_total_duration()
  cat("✅ get_total_duration works! Duration:", dur, "\n")
}, error = function(e) {
  cat("❌ ERROR:", conditionMessage(e), "\n")
})

cat("\nTesting change_labels()...\n")
tryCatch({
  tg$change_labels(1, "hello", "hi")
  cat("✅ change_labels works!\n")
}, error = function(e) {
  cat("❌ ERROR:", conditionMessage(e), "\n")
})

cat("\nTesting to_table()...\n")
tryCatch({
  table <- tg$to_table()
  cat("✅ to_table works! Class:", paste(class(table), collapse=", "), "\n")
}, error = function(e) {
  cat("❌ ERROR:", conditionMessage(e), "\n")
})

cat("\n【2】 Test Sound Methods\n")
cat("───────────────────────────────────────────────────────\n")

cat("Creating Sound from values...\n")
values <- sin(2*pi*440*seq(0, 0.1, length.out=2205))
tryCatch({
  sound <- Sound$from_values(values, sampling_rate = 22050)
  cat("✅ Sound created\n")
  
  cat("\nTesting get_total_duration()...\n")
  dur <- sound$get_total_duration()
  cat("✅ get_total_duration works! Duration:", dur, "\n")
  
  cat("\nTesting to_pitch()...\n")
  pitch <- sound$to_pitch()
  cat("✅ to_pitch works! Class:", paste(class(pitch), collapse=", "), "\n")
  
  cat("\nTesting to_pointprocess_periodic_cc()...\n")
  pp <- sound$to_pointprocess_periodic_cc(75, 600)
  cat("✅ to_pointprocess_periodic_cc works! Points:", pp$get_number_of_points(), "\n")
  
}, error = function(e) {
  cat("❌ ERROR:", conditionMessage(e), "\n")
})

cat("\n═══════════════════════════════════════════════════════\n")
cat("  Test Complete\n")
cat("═══════════════════════════════════════════════════════\n")
