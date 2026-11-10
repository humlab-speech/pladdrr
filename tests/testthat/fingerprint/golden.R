# Fidelity fingerprint of the *installed* pladdrr build, run by
# tests/testthat/test-fidelity-fingerprint.R and runnable on its own:
#   Rscript tests/testthat/fingerprint/golden.R > /tmp/fingerprint.txt
# "key<TAB>value" at full precision (%.17g). Deterministic: synthetic signal, no
# RNG, one thread, no wall-clock. A row that errors prints "ERR:<message>", and
# the test refuses any ERR/NA/NONFINITE row, so a row can no longer go dead
# unnoticed (12 of the original 77 had: they called their API wrongly inside a
# tryCatch that returned NA, and the fingerprint recorded NA as "expected").
suppressMessages(library(pladdrr))
if (exists("pladdrr_threads")) invisible(try(pladdrr_threads(1), silent = TRUE))

fmt <- function(key, value) {
	v <- tryCatch(suppressWarnings(suppressMessages(value)), error = function(e) paste0("ERR:", substr(conditionMessage(e), 1, 30)))
	if (is.list(v)) v <- if (length(v) && is.numeric(v[[1]])) v[[1]][1] else length(v)
	if (length(v) != 1L) v <- length(v)
	if (is.numeric(v) && !is.finite(v)) v <- paste0("NONFINITE:", format(v))
	cat(sprintf("%s\t%s\n", key, if (is.numeric(v)) sprintf("%.17g", v) else as.character(v)))
}
dfsum <- function(x) sum(as.numeric(unlist(as.data.frame(x))))
matsum <- function(x) sum(as.numeric(as.vector(x$as_matrix())), na.rm = TRUE)

sr <- 44100L
tt <- seq(0, 1 - 1 / sr, length.out = sr)
sig <- 0.6 * sin(2 * pi * 120 * tt) + 0.25 * sin(2 * pi * 240 * tt) +
	0.12 * sin(2 * pi * 360 * tt) + 0.06 * sin(2 * pi * 600 * tt) +
	0.02 * sin(2 * pi * 1200 * tt) * (tt > 0.4)
s <- Sound$from_values(sig, sr)
s2 <- Sound$from_values(sig * 0.5 + 0.05 * sin(2 * pi * 400 * tt), sr)
spec <- s$to_spectrum()

fmt("sound.duration", s$get_total_duration())
fmt("sound.nx", s$get_number_of_samples())
fmt("sound.sampling_frequency", s$get_sampling_frequency())
fmt("sound.dx", s$get_dx())
fmt("sound.mean", s$get_mean())
fmt("sound.rms", s$get_rms())
fmt("sound.energy", s$get_energy())
fmt("sound.power", s$get_power())
fmt("sound.maximum", s$get_maximum())
fmt("sound.minimum", s$get_minimum())
fmt("sound.value_at_0.5", s$get_value_at_time(0.5))
fmt("sound.df_sum", dfsum(s))
fmt("sound.df_rows", nrow(as.data.frame(s)))

p <- s$to_pitch()
fmt("pitch.nframes", p$get_number_of_frames())
fmt("pitch.dt", p$get_time_step())
fmt("pitch.mean", p$get_mean())
fmt("pitch.stdev", p$get_standard_deviation())
fmt("pitch.quantile90", p$get_quantile(0, 0, 0.9))
fmt("pitch.voiced", p$count_voiced_frames())
fmt("pitch.df_sum", dfsum(p))
# Non-hertz units (kPitch_unit). A wrong code answers in another unit with no
# error, and a row with unit = "hertz" cannot see it. Checked against Praat 6.4.47
# on the same samples (see NEWS 5.2.0).
fmt("pitch.q50_semitones", p$get_quantile(0, 0, 0.5, unit = "semitones"))
fmt("pitch.q50_erb", p$get_quantile(0, 0, 0.5, unit = "erb"))
fmt("pitch.mean_loghertz", get_pitch_mean_direct(p$.xptr, 0, 0, "loghertz"))
pt <- p$down_to_pitch_tier()
pt$shift_frequencies(1, "semitones")
fmt("tier.shift_semitones", pt$get_value_at_index(48))
fmt("pitch_ac.mean", s$to_pitch_ac()$get_mean())
fmt("pitch_ac.nframes", s$to_pitch_ac()$get_number_of_frames())
fmt("pitch_shs.mean", tryCatch(s$to_pitch_shs()$get_mean(), error = function(e) NA))

f <- s$to_formant_burg()
for (i in 1:4) fmt(sprintf("formant.f%d_at_0.5", i), f$get_value_at_time(i, 0.5))
fmt("formant.nframes", f$get_number_of_frames())
fmt("formant.df_sum", dfsum(f))
fmt("formantpath.f1_at_0.5", tryCatch(s$to_formant_robust()$get_value_at_time(1, 0.5), error = function(e) NA))

it <- s$to_intensity()
fmt("intensity.mean", it$get_mean())
fmt("intensity.maximum", it$get_maximum())
fmt("intensity.stdev", it$get_standard_deviation())
fmt("intensity.q25", it$get_quantile(0.25))
fmt("intensity.mean_db", it$get_mean(0, 0, averaging_method = "db"))
# Cubic, not linear: Praat gives 87.41129728213643; 5.1.x returned the linear value.
fmt("intensity.value_cubic", it$get_value_at_time(0.4035, interpolation = "cubic"))

# Ltas: the averaging unit, the dB code and the non-interpolating window are
# what fix/009 moved; without these keys the guard could not see a 3-decade
# unit error or an 8 dB band-average shift.
lt <- s$to_ltas(bandwidth = 100)
fmt("ltas.full.mean_db", lt$get_mean(0, 0, unit = "dB"))
fmt("ltas.full.mean_energy", lt$get_mean(0, 0, unit = "energy"))
fmt("ltas.band.mean_db", lt$get_mean(500, 2000, unit = "dB"))
fmt("ltas.full.sd_energy", lt$get_standard_deviation(0, 0, unit = "energy"))
fmt("ltas.slope_db", lt$get_slope(0, 1000, 1000, 4000, unit = "dB"))
fmt("ltas.slope_energy", lt$get_slope(0, 1000, 1000, 4000, unit = "energy"))
# environment must end before the peak window starts (Praat 6.4.27 errors
# otherwise; pladdrr does not -- filed as a separate validation gap)
fmt("ltas.local_peak", lt$get_local_peak_height(0, 5000, 1000, 2000, unit = "dB"))
fmt("ltas.full.mean_sones", lt$get_mean(0, 0, unit = "sones"))

hh <- s$to_harmonicity_cc()
fmt("hnr.nframes", hh$get_number_of_frames())
fmt("hnr.mean", hh$get_mean())
fmt("hnr.df_sum", dfsum(hh))
fmt("gne.mean", tryCatch(s$to_harmonicity_gne()$get_mean(), error = function(e) NA))

sp <- s$to_spectrogram()
fmt("spec.ntime", sp$get_number_of_time_bins())
fmt("spec.nfreq", sp$get_number_of_frequency_bins())
fmt("spec.power_at_0.5_1000", sp$get_power_at(0.5, 1000))
fmt("spec.df_sum", dfsum(sp))
fmt("ltas.df_sum", dfsum(s$to_ltas(300)))
fmt("spectrum.bins", tryCatch(spec$get_number_of_bins(), error = function(e) NA))
fmt("spectrum.df_sum", dfsum(spec))

fmt("mfcc.df_sum", dfsum(s$to_mfcc()))
fmt("powercepstrum.mat_sum", matsum(spec$to_power_cepstrum()))
fmt("lpc_burg.df_sum", dfsum(s$to_lpc_burg(prediction_order = 10)))
fmt("cochleagram.df_sum", dfsum(s$to_cochleagram(dt = 0.02, df = 1)))
fmt("excitation.df_sum", tryCatch(dfsum(spec$to_excitation(0.1)), error = function(e) NA))
fmt("bark_spec.df_sum", tryCatch(dfsum(s$to_bark_spectrogram()), error = function(e) NA))

pp <- s$to_point_process_periodic_cc()
fmt("pp.count", pp$get_number_of_points())
fmt("pp.period_mean", pp$get_mean_period())
fmt("pp.jitter_local", pp$get_jitter_local())
fmt("pp.jitter_ppq5", pp$get_jitter_ppq5())
fmt("pp.jitter_rap", pp$get_jitter_rap())
fmt("pp.jitter_ddp", pp$get_jitter_ddp())
fmt("pp.shimmer_local_with_sound", tryCatch(pp$get_shimmer_local(s), error = function(e) NA))
fmt("pp.shimmer_apq3_with_sound", tryCatch(pp$get_shimmer_apq3(s), error = function(e) NA))

# tier 2 / 3 / 4 over the same signal — these must track the tier-1 numbers
fmt("t2.pitch_cc_direct_mean", Pitch(.xptr = to_pitch_cc_direct(s))$get_mean())
fmt("t2.pitch_mean_direct", get_pitch_mean_direct(s$to_pitch()$.xptr, 0, 0, "hertz"))
fmt("t2.formant_direct_f1_at_0.5", get_formants_direct(s$to_formant_burg()$.xptr, 0.5, "hertz")[1])
fmt("t2.intensity_at_0.5", get_intensity_value_direct(it$.xptr, 0.5, "cubic"))
fmt("t3.pitch_cc_batch_mean", sound_to_pitch_cc_batch(list(s), pitch_ceiling = 600, return_r6 = TRUE)[[1]]$get_mean())
fmt("t3.intensity_batch_mean", sound_to_intensity_batch(list(s), return_r6 = TRUE)[[1]]$get_mean())
fmt("t4.cpps_ultra", tryCatch(calculate_cpps_ultra(s), error = function(e) NA))
fmt("t4.f0_stats_mean", calculate_f0_stats_ultra(s, "mean"))
fmt("t4.min_intensity", tryCatch(unlist(calculate_minimum_intensity_ultra(s))[1], error = function(e) NA))
fmt("t4.multiband_hnr_first", tryCatch(unlist(calculate_multiband_hnr_ultra(s))[1], error = function(e) NA))
fmt("t4.voice_quality_first", tryCatch(unlist(get_voice_quality_ultra(s))[1], error = function(e) NA))
fmt("t4.jitter_shimmer_batch_first", unlist(get_jitter_shimmer_batch(pp, s))[1])

fmt("dtw.weighted_distance", sounds_to_dtw(s, s2)$get_weighted_distance())
fmt("pca.eigenvalue_sum", sum(pca_from_matrix(sapply(1:5, function(j) sin(j * seq(0.1, 10, length.out = 50) + j^2)))$get_eigenvalues()))
tgfile <- system.file("extdata/test.TextGrid", package = "pladdrr")
fmt("textgrid.total_duration", TextGrid$new(tgfile)$get_total_duration())
fmt("textgrid.nrows_df", nrow(TextGrid$new(tgfile)$as_data_frame()))

fmt("simd.arch", tryCatch(unname(unlist(simd_info())[1]), error = function(e) NA))
fmt("simd.debug_build", tryCatch(isTRUE(simd_info()$debug_build), error = function(e) NA))
cat("GOLDEN_END\n")
