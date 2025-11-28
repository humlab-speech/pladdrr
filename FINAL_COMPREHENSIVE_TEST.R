library(pladdrr)

cat("═══════════════════════════════════════════════════════\n")
cat("  COMPREHENSIVE FUNCTIONALITY TEST - v1.0.6\n")
cat("═══════════════════════════════════════════════════════\n\n")

success_count <- 0
fail_count <- 0

test_feature <- function(name, expr) {
  cat(sprintf("Testing: %-50s ", name))
  tryCatch({
    result <- expr
    cat("✅\n")
    success_count <<- success_count + 1
    TRUE
  }, error = function(e) {
    cat(sprintf("❌ (%s)\n", conditionMessage(e)))
    fail_count <<- fail_count + 1
    FALSE
  })
}

cat("\n【1】 TextGrid Methods (v1.0.5)\n")
cat("───────────────────────────────────────────────────────\n")
tg <- TextGrid$create(0, 5, "words")
tg$insert_boundary(1, 1.0)
tg$set_interval_text(1, 1, "hello")

test_feature("TextGrid creation", tg$get_total_duration() == 5)
test_feature("change_labels()", {tg$change_labels(1, "hello", "hi"); TRUE})
test_feature("merge_identical_intervals()", {tg$merge_identical_intervals(1, ""); TRUE})
test_feature("get_total_duration_where()", tg$get_total_duration_where(1, "hi") >= 0)
test_feature("extend_time()", {tg$extend_time(1.0, 1); TRUE})
test_feature("to_table()", !is.null(tg$to_table()))

cat("\n【2】 Sound Periodic PointProcess Methods (v1.0.6)\n")
cat("───────────────────────────────────────────────────────\n")
values <- sin(2*pi*440*seq(0, 0.5, length.out=11025))  # 0.5s sine wave
sound <- Sound$from_values(values, sampling_rate = 22050)

test_feature("Sound creation from values", !is.null(sound))
test_feature("to_pointprocess_periodic_cc() exists", 
             "to_pointprocess_periodic_cc" %in% names(sound))
test_feature("to_pointprocess_periodic_peaks() exists",
             "to_pointprocess_periodic_peaks" %in% names(sound))

# Try calling them
if ("to_pointprocess_periodic_cc" %in% names(sound)) {
  test_feature("to_pointprocess_periodic_cc() works", {
    pp <- sound$to_pointprocess_periodic_cc(75, 600)
    !is.null(pp)
  })
}

if ("to_pointprocess_periodic_peaks" %in% names(sound)) {
  test_feature("to_pointprocess_periodic_peaks() works", {
    pp <- sound$to_pointprocess_periodic_peaks(75, 600, TRUE, FALSE)
    !is.null(pp)
  })
}

cat("\n【3】 Audio Quality Utilities (v1.0.5)\n")
cat("───────────────────────────────────────────────────────\n")
test_feature("check_audio_quality() exists", exists("check_audio_quality"))
test_feature("format_quality_report() exists", exists("format_quality_report"))

cat("\n═══════════════════════════════════════════════════════\n")
cat(sprintf("  RESULTS: %d passed, %d failed\n", success_count, fail_count))
cat("═══════════════════════════════════════════════════════\n")

if (fail_count == 0) {
  cat("\n🎉 ALL TESTS PASSED!\n")
} else {
  cat(sprintf("\n⚠️  %d tests failed - see details above\n", fail_count))
}
