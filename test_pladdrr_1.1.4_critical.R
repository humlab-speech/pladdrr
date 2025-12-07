#!/usr/bin/env Rscript
#
# Test pladdrr 1.1.4 for critical two-object command support
#

library(pladdrr)

cat("pladdrr 1.1.4 Critical Feature Test\n")
cat("====================================\n\n")

cat("Testing with DSI ppq file (sustained vowel):\n")
sound <- Sound$new("signalfiles/DSI/input/ppq1.wav")

# Create pitch with DSI parameters
pitch <- sound$to_pitch_cc(
  time_step = 0,
  pitch_floor = 70,
  max_candidates = 15,
  very_accurate = FALSE,
  silence_threshold = 0.03,
  voicing_threshold = 0.8,
  octave_cost = 0.01,
  octave_jump_cost = 0.35,
  voiced_unvoiced_cost = 0.14,
  pitch_ceiling = 600
)

cat("Sound duration:", sound$get_duration(), "s\n")
cat("Pitch voiced frames:", pitch$count_voiced_frames(), "\n\n")

cat("1. Testing Pitch$to_pointprocess_cc (two-object method):\n")
if ("to_pointprocess_cc" %in% ls(pitch)) {
  cat("   ✅ Method EXISTS!\n")
  cat("   Signature:\n   ")
  str(pitch$to_pointprocess_cc)

  cat("\n   Testing with sound parameter:\n")
  tryCatch({
    pp <- pitch$to_pointprocess_cc(sound = sound)
    cat("   ✅ SUCCESS!\n")
    cat("   Points:", pp$get_number_of_points(), "\n")

    if (pp$get_number_of_points() > 0) {
      cat("\n   Creating VUV TextGrid:\n")
      tg <- pp$to_textgrid_vuv(
        max_voiced_period = 0.02,
        max_unvoiced_period = 0.01
      )

      n_intervals <- tg$get_number_of_intervals(1)
      cat("   Intervals:", n_intervals, "\n\n")

      v_count <- 0
      u_count <- 0
      cat("   First 5 intervals:\n")
      for (i in 1:min(5, n_intervals)) {
        label <- tg$get_interval_text(1, i)
        start_t <- tg$get_interval_start_time(1, i)
        end_t <- tg$get_interval_end_time(1, i)
        cat(sprintf("     %d: [%.3f-%.3f] '%s'\n", i, start_t, end_t, label))
        if (label == "V") v_count <- v_count + 1
        if (label == "U") u_count <- u_count + 1
      }

      cat(sprintf("\n   ✅✅✅ BREAKTHROUGH! Found %d voiced, %d unvoiced intervals!\n", v_count, u_count))

      if (v_count > 0) {
        cat("\n   Testing extract_intervals_where:\n")
        intervals <- sound$extract_intervals_where(
          textgrid = tg,
          tier_number = 1,
          criterion = "is equal to",
          text = "V",
          preserve_times = FALSE
        )
        cat("   Extracted intervals:", length(intervals), "\n")
        if (length(intervals) > 0) {
          cat("   ✅✅✅ COMPLETE PIPELINE WORKS!\n")
        }
      }
    }

  }, error = function(e) {
    cat("   ❌ ERROR:", e$message, "\n")
  })

} else {
  cat("   ❌ Method does not exist\n")
}

cat("\n2. Testing to_textgrid_silences parameters:\n")
cat("   Current signature:\n   ")
str(pitch$to_textgrid_silences)

cat("\n   Testing with extended parameters:\n")
tryCatch({
  tg2 <- pitch$to_textgrid_silences(
    min_pitch = 50,
    time_step = 0.003,
    silence_threshold = -25,
    min_silent_duration = 0.1,
    min_sounding_duration = 0.1
  )
  cat("   ✅ SUCCESS with 5+ parameters!\n")

  n_intervals <- tg2$get_number_of_intervals(1)
  cat("   Intervals:", n_intervals, "\n")

  if (n_intervals > 1) {
    cat("\n   First 3 intervals:\n")
    for (i in 1:min(3, n_intervals)) {
      label <- tg2$get_interval_text(1, i)
      start_t <- tg2$get_interval_start_time(1, i)
      end_t <- tg2$get_interval_end_time(1, i)
      cat(sprintf("     %d: [%.3f-%.3f] '%s'\n", i, start_t, end_t, label))
    }
  }

}, error = function(e) {
  cat("   ❌ Still only 2 parameters:", e$message, "\n")
})

cat("\n3. Testing generic praat_call function:\n")
if (exists("praat_call", where = "package:pladdrr")) {
  cat("   ✅ praat_call EXISTS!\n")
  cat("   Signature:\n   ")
  str(praat_call)
} else {
  cat("   (not found as standalone function)\n")
}

cat("\n====================================\n")
cat("Test complete!\n")
