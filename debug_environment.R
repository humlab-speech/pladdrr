library(pladdrr)

snd <- Sound$new('inst/extdata/test.wav')

# Get the environment of to_pitch (works)
env_pitch <- environment(snd$to_pitch)
cat("to_pitch environment:\n")
cat("  Has 'private':", exists("private", env_pitch, inherits = FALSE), "\n")
cat("  Has 'self':", exists("self", env_pitch, inherits = FALSE), "\n\n")

# Get the environment of to_powercepstrogram (doesn't work)
env_pcep <- environment(snd$to_powercepstrogram)
cat("to_powercepstrogram environment:\n")
cat("  Has 'private':", exists("private", env_pitch, inherits = FALSE), "\n")
cat("  Has 'self':", exists("self", env_pcep, inherits = FALSE), "\n\n")

# Try to call each
cat("Calling to_pitch()...\n")
tryCatch({
  pitch <- snd$to_pitch()
  cat("  SUCCESS\n\n")
}, error = function(e) cat("  ERROR:", conditionMessage(e), "\n\n"))

cat("Calling to_powercepstrogram()...\n")
tryCatch({
  pcep <- snd$to_powercepstrogram()
  cat("  SUCCESS\n\n")
}, error = function(e) cat("  ERROR:", conditionMessage(e), "\n\n"))

# Compare parent environments
cat("Parent environments:\n")
cat("  to_pitch parent:", environmentName(parent.env(env_pitch)), "\n")
cat("  to_powercepstrogram parent:", environmentName(parent.env(env_pcep)), "\n")
