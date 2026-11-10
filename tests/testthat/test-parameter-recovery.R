# G5.6: parameter-recovery tests. Signals with known properties go in, the
# analysis has to give the known value back within a stated tolerance
# (G5.6a). Noise is drawn under several fixed seeds (G5.5, G5.6b).
#
# Tolerances were set from measured recovery on 2026-11-09 (Praat 6.4.x
# sources, macOS arm64), with headroom for platform rounding:
#   F0 (pure tone, 60-600 Hz search range): worst error 0.008 Hz -> 0.05 Hz
#   formants (Klatt vowel, Burg):           worst error 25.9 Hz (F2 of /i/-like 300/2300) -> 40 Hz
#   intensity (sine, energy mean):          worst error 0.0002 dB -> 0.01 dB
#   harmonicity vs. injected SNR:           worst error 0.5 dB   -> 1.5 dB

test_that("pitch recovers the F0 of a pure tone across the speech range", {
  for (f0 in c(80, 120, 200, 330, 440)) {
    tone <- generate_sine_wave(f0, 1, sampling_rate = 44100)
    pitches <- list(
      cc = tone$to_pitch_cc(pitch_floor = 60, pitch_ceiling = 600),
      ac = tone$to_pitch_ac(pitch_floor = 60, pitch_ceiling = 600))
    for (method in names(pitches)) {
      expect_equal(pitches[[method]]$get_mean(0, 0, "Hertz"), f0,
                   tolerance = 0.05 / f0, info = paste(method, f0, "Hz"))
    }
  }
})

test_that("Burg formants recover the targets of a synthesised vowel", {
  targets <- list(c(700, 1200), c(300, 2300), c(500, 1500))
  for (tg in targets) {
    kg <- klattgrid_create_from_vowel(
      duration = 0.5, f0start = 120,
      f1 = tg[1], b1 = 60, f2 = tg[2], b2 = 90, f3 = 2800, b3 = 150, f4 = 3500)
    formant <- kg$to_sound()$to_formant_burg(max_formants = 5, max_frequency = 5000)
    f1 <- formant$get_value_at_time(1, 0.25, "hertz")
    f2 <- formant$get_value_at_time(2, 0.25, "hertz")
    expect_lt(abs(f1 - tg[1]), 40, label = paste("F1 for", tg[1], tg[2]))
    expect_lt(abs(f2 - tg[2]), 40, label = paste("F2 for", tg[1], tg[2]))
  }
})

test_that("intensity of a sine matches 20*log10(rms / 2e-5)", {
  for (amp in c(0.1, 0.5, 0.9)) {
    tone <- generate_sine_wave(220, 1, sampling_rate = 44100, amplitude = amp)
    expected <- 20 * log10(amp / sqrt(2) / 2e-5)
    got <- tone$to_intensity(minimum_pitch = 100)$get_mean(0, 0, "energy")
    expect_lt(abs(got - expected), 0.01, label = paste("amplitude", amp))
  }
})

test_that("harmonicity tracks the injected signal-to-noise ratio (3 seeds)", {
  tone_values <- generate_sine_wave(150, 1, sampling_rate = 44100,
                                    amplitude = 0.5)$get_values()
  for (seed in c(1L, 2L, 3L)) {
    withr::local_seed(seed)
    noise <- rnorm(length(tone_values))
    hnr <- vapply(c(30, 10, 0), function(snr) {
      scaled <- noise * stats::sd(tone_values) / stats::sd(noise) * 10^(-snr / 20)
      Sound$from_values(tone_values + scaled, 44100)$
        to_harmonicity_cc(time_step = 0.01, min_pitch = 75)$get_mean(0, 0)
    }, numeric(1))
    expect_lt(max(abs(hnr - c(30, 10, 0))), 1.5, label = paste("seed", seed))
    expect_true(all(diff(hnr) < 0), info = paste("monotone in SNR, seed", seed))
  }
})

test_that("F0 error of a noisy tone shrinks as the recording gets longer (G5.7)", {
  mean_error <- function(duration, snr_db = 0, seeds = 1:8) {
    mean(vapply(seeds, function(seed) {
      withr::with_seed(seed, {
        sr <- 16000
        t <- (seq_len(round(duration * sr)) - 1) / sr
        x <- sin(2 * pi * 150 * t)
        noise <- stats::rnorm(length(x))
        noise <- noise * stats::sd(x) / stats::sd(noise) * 10^(-snr_db / 20)
        y <- x + noise
        snd <- Sound$from_values(0.5 * y / max(abs(y)), sr)
        abs(snd$to_pitch_cc(pitch_floor = 75, pitch_ceiling = 600)$get_mean(0, 0, "Hertz") - 150)
      })
    }, numeric(1)), na.rm = TRUE)
  }
  # measured on 2026-11-09: 0.3 s -> 1.00 Hz, 3 s -> 0.21 Hz (8 seeds, 0 dB SNR)
  expect_lt(mean_error(3), 0.5 * mean_error(0.3))
})
