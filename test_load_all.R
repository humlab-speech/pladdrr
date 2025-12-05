# Test with load_all() instead of library()
devtools::load_all()

cat("Testing with load_all()...\n\n")

snd <- Sound$new('inst/extdata/test.wav')
cat("Sound created, duration:", snd$get_duration(), "seconds\n\n")

cat("Testing to_powercepstrogram...\n")
tryCatch({
  pcep <- snd$to_powercepstrogram(
    pitch_floor = 60,
    time_step = 0.002,
    maximum_frequency = 5000,
    pre_emphasis_frequency = 50
  )
  cat("✅ SUCCESS! PowerCepstrogram created!\n\n")

  cpps <- pcep$get_cpps()
  cat("CPPS =", cpps, "dB\n\n")

  cat("🎉 FIX CONFIRMED with load_all()!\n")
}, error = function(e) {
  cat("❌ ERROR:", conditionMessage(e), "\n")
  traceback()
})
