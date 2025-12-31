## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  fig.width = 7,
  fig.height = 5
)

## ----setup--------------------------------------------------------------------
library(pladdrr)

## ----simd-info----------------------------------------------------------------
# Get SIMD information
info <- simd_info()
print(info)

## ----fft-benchmark, eval=FALSE------------------------------------------------
# # Create test sound
# sound <- Sound$new(440, duration = 1.0, sampling_frequency = 44100)
# 
# # Benchmark FFT (used in Spectrum creation)
# library(microbenchmark)
# 
# result <- microbenchmark(
#   spectrum = sound$to_spectrum(),
#   times = 100
# )
# 
# print(result)

## ----formant-benchmark, eval=FALSE--------------------------------------------
# sound <- Sound$new("speech.wav")
# 
# result <- microbenchmark(
#   burg = sound$to_formant_burg(),
#   willems = sound$to_formant_willems(),
#   sl = sound$to_formant_sl(),
#   times = 50
# )
# 
# print(result)

## ----cochleagram-benchmark, eval=FALSE----------------------------------------
# sound <- Sound$new(440, duration = 2.0, sampling_frequency = 22050)
# 
# result <- microbenchmark(
#   standard = sound$to_cochleagram(dt = 0.01, df = 0.1),
#   edb = sound$to_cochleagram_edb(dtime = 0.01, dfreq = 0.1),
#   times = 20
# )
# 
# print(result)

## ----sample-rate, eval=FALSE--------------------------------------------------
# # For speech analysis, 16-22 kHz is often sufficient
# sound_22k <- Sound$new("speech.wav", sampling_frequency = 22050)
# formant_22k <- sound_22k$to_formant_burg()  # Faster
# 
# # 48 kHz only needed for music/high-quality audio
# sound_48k <- Sound$new("music.wav", sampling_frequency = 48000)
# formant_48k <- sound_48k$to_formant_burg()  # Slower but higher quality

## ----time-step, eval=FALSE----------------------------------------------------
# # Standard time step (good balance)
# formant_standard <- sound$to_formant_burg(time_step = 0.005)  # 5 ms
# 
# # Coarse time step (faster, less detail)
# formant_coarse <- sound$to_formant_burg(time_step = 0.010)    # 10 ms
# 
# # Fine time step (slower, more detail)
# formant_fine <- sound$to_formant_burg(time_step = 0.002)      # 2 ms

## ----batch-processing, eval=FALSE---------------------------------------------
# # Load all sounds first
# sound_files <- list.files("data/", pattern = "\.wav$", full.names = TRUE)
# sounds <- lapply(sound_files, Sound$new)
# 
# # Process in batch (better CPU cache usage)
# formants <- lapply(sounds, function(s) {
#   s$to_formant_burg(time_step = 0.005)
# })
# 
# # Extract F1 and F2
# f1_f2 <- do.call(rbind, lapply(formants, function(f) {
#   data.frame(
#     f1 = f$get_mean(1, 0, 0, unit = "hertz"),
#     f2 = f$get_mean(2, 0, 0, unit = "hertz")
#   )
# }))

## ----reuse-objects, eval=FALSE------------------------------------------------
# # Good: Reuse sound object
# sound <- Sound$new("speech.wav")
# pitch <- sound$to_pitch()
# formant <- sound$to_formant_burg()
# intensity <- sound$to_intensity()
# 
# # Less efficient: Reload each time
# pitch <- Sound$new("speech.wav")$to_pitch()
# formant <- Sound$new("speech.wav")$to_formant_burg()
# intensity <- Sound$new("speech.wav")$to_intensity()

## ----fft-size, eval=FALSE-----------------------------------------------------
# # FFT is most efficient with power-of-2 sizes
# # But pladdrr handles all sizes correctly
# 
# # If you can choose duration:
# # Good: 2^N / sample_rate
# duration_good <- 1024 / 16000  # 0.064 s, 1024 samples
# 
# # Also fine: any duration
# duration_any <- 0.05  # 800 samples (not power of 2, still works)

## ----basic-timing, eval=FALSE-------------------------------------------------
# # Time a single operation
# start_time <- Sys.time()
# formant <- sound$to_formant_burg()
# end_time <- Sys.time()
# print(end_time - start_time)

## ----profiling, eval=FALSE----------------------------------------------------
# library(profvis)
# 
# profvis({
#   # Load sound
#   sound <- Sound$new("speech.wav")
# 
#   # Perform analysis
#   pitch <- sound$to_pitch()
#   formant <- sound$to_formant_burg()
#   intensity <- sound$to_intensity()
#   spectrum <- sound$to_spectrum()
# 
#   # Extract values
#   f0_mean <- pitch$get_mean(0, 0, unit = "hertz")
#   f1_mean <- formant$get_mean(1, 0, 0, unit = "hertz")
# })

## ----benchmark-methods, eval=FALSE--------------------------------------------
# library(microbenchmark)
# 
# sound <- Sound$new("speech.wav")
# 
# # Compare formant extraction methods
# result <- microbenchmark(
#   burg = sound$to_formant_burg(),
#   willems = sound$to_formant_willems(number_of_formants = 5),
#   sl = sound$to_formant_sl(),
#   times = 20
# )
# 
# print(result)
# boxplot(result)

## ----simd-accuracy, eval=FALSE------------------------------------------------
# sound <- Sound$new(440, duration = 0.5, sampling_frequency = 22050)
# 
# # Run same analysis twice
# formant1 <- sound$to_formant_burg()
# formant2 <- sound$to_formant_burg()
# 
# # Extract values
# f1_1 <- formant1$get_value_at_time(1, 0.25, unit = "hertz")
# f1_2 <- formant2$get_value_at_time(1, 0.25, unit = "hertz")
# 
# # Should be identical (within floating-point precision)
# identical(f1_1, f1_2)  # TRUE

## ----fallback, eval=FALSE-----------------------------------------------------
# # This code works identically on all systems
# formant <- sound$to_formant_burg()
# 
# # SIMD system: 2-5x faster
# # Non-SIMD system: Same results, slower

## ----troubleshoot, eval=FALSE-------------------------------------------------
# # Check SIMD availability
# pladdrr:::.has_simd()
# 
# # If FALSE, possible reasons:
# # 1. Binary package not compiled with SIMD
# #    Solution: install.packages("pladdrr", type = "source")
# #
# # 2. Old CPU without SIMD support
# #    Solution: Use package as-is (scalar fallback)
# #
# # 3. Rosetta 2 on Apple Silicon
# #    Solution: Install ARM64 native R

## ----session------------------------------------------------------------------
sessionInfo()

