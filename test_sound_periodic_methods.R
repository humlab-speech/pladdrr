library(pladdrr)

cat("═══════════════════════════════════════════════════════\n")
cat("  Testing Sound Periodic Methods\n")
cat("═══════════════════════════════════════════════════════\n\n")

# Create a simple test sound (sine wave at 440 Hz)
cat("Creating test sound...\n")
values <- sin(2*pi*440*seq(0, 0.5, length.out=11025))  # 0.5s at 22050 Hz
sound <- Sound$from_values(values, sampling_rate = 22050)
cat("✅ Sound created (", sound$get_duration(), " seconds)\n\n", sep="")

success <- 0
fail <- 0

test <- function(name, expr) {
  cat(sprintf("%-50s ", name))
  tryCatch({
    result <- expr
    cat("✅\n")
    success <<- success + 1
    TRUE
  }, error = function(e) {
    cat("❌ ", conditionMessage(e), "\n")
    fail <<- fail + 1
    FALSE
  })
}

cat("【New Periodic PointProcess Methods】\n")
cat("───────────────────────────────────────────────────────\n")

test("to_pointprocess_periodic_cc(75, 600)", {
  pp <- sound$to_pointprocess_periodic_cc(75, 600)
  !is.null(pp)
})

test("to_pointprocess_periodic_peaks(75, 600, TRUE, FALSE)", {
  pp <- sound$to_pointprocess_periodic_peaks(75, 600, TRUE, FALSE)
  !is.null(pp)
})

cat("\n【Existing Sound Methods】\n")
cat("───────────────────────────────────────────────────────\n")

test("get_duration()", sound$get_duration() > 0)
test("to_pitch()", !is.null(sound$to_pitch()))
test("to_intensity()", !is.null(sound$to_intensity()))
test("to_spectrum()", !is.null(sound$to_spectrum()))

cat("\n═══════════════════════════════════════════════════════\n")
cat(sprintf("  Results: %d passed, %d failed\n", success, fail))
cat("═══════════════════════════════════════════════════════\n")

if (fail == 0) {
  cat("\n🎉 ALL SOUND METHODS WORKING!\n")
} else {
  cat("\n⚠️  Some methods failed\n")
}
