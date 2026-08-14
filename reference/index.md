# Package index

## Core Audio Objects

Primary sound and acoustic representation objects

- [`Sound`](https://humlab-speech.github.io/pladdrr/reference/Sound.md)
  : Sound
- [`LongSound`](https://humlab-speech.github.io/pladdrr/reference/LongSound.md)
  : LongSound
- [`Spectrum`](https://humlab-speech.github.io/pladdrr/reference/Spectrum.md)
  : Spectrum
- [`Spectrogram`](https://humlab-speech.github.io/pladdrr/reference/Spectrogram.md)
  : Spectrogram
- [`Ltas`](https://humlab-speech.github.io/pladdrr/reference/Ltas.md) :
  Ltas
- [`ComplexSpectrogram`](https://humlab-speech.github.io/pladdrr/reference/ComplexSpectrogram.md)
  : ComplexSpectrogram

## Pitch Analysis

Fundamental frequency extraction and manipulation

- [`Pitch`](https://humlab-speech.github.io/pladdrr/reference/Pitch.md)
  : Pitch
- [`PitchModule()`](https://humlab-speech.github.io/pladdrr/reference/PitchModule.md)
  : Create a Pitch Object from Module
- [`PitchTier`](https://humlab-speech.github.io/pladdrr/reference/PitchTier.md)
  : PitchTier
- [`to_pitch_direct()`](https://humlab-speech.github.io/pladdrr/reference/to_pitch_direct.md)
  : Create Pitch from Sound Directly (returns XPtr) - Basic Parameters
- [`get_pitch_at_time()`](https://humlab-speech.github.io/pladdrr/reference/get_pitch_at_time.md)
  : Get pitch at specific time point (DEPRECATED)
- [`get_pitch_at_times()`](https://humlab-speech.github.io/pladdrr/reference/get_pitch_at_times.md)
  : Batch Query Pitch Values at Multiple Times
- [`get_pitch_value_direct()`](https://humlab-speech.github.io/pladdrr/reference/get_pitch_value_direct.md)
  : Get Single Pitch Value Directly
- [`get_pitch_stats_direct()`](https://humlab-speech.github.io/pladdrr/reference/get_pitch_stats_direct.md)
  : Get Pitch Statistics Directly
- [`get_pitch_strengths_at_times()`](https://humlab-speech.github.io/pladdrr/reference/get_pitch_strengths_at_times.md)
  : Batch Query Pitch Strengths at Multiple Times
- [`sound_to_pitch_ac_batch()`](https://humlab-speech.github.io/pladdrr/reference/sound_to_pitch_ac_batch.md)
  : Extract Pitch (AC) from Multiple Sounds in Single C++ Call
- [`sound_to_pitch_batch()`](https://humlab-speech.github.io/pladdrr/reference/sound_to_pitch_batch.md)
  : Extract Pitch from Multiple Sounds in Single C++ Call
- [`sound_to_pitch_cc_batch()`](https://humlab-speech.github.io/pladdrr/reference/sound_to_pitch_cc_batch.md)
  : Extract Pitch (CC) from Multiple Sounds in Single C++ Call
- [`sound_to_pitch_shs_batch()`](https://humlab-speech.github.io/pladdrr/reference/sound_to_pitch_shs_batch.md)
  : Extract Pitch (SHS) from Multiple Sounds
- [`sound_to_pitch_spinet_batch()`](https://humlab-speech.github.io/pladdrr/reference/sound_to_pitch_spinet_batch.md)
  : Extract Pitch (SPINET) from Multiple Sounds
- [`extract_pitch()`](https://humlab-speech.github.io/pladdrr/reference/extract_pitch.md)
  : Extract pitch contour from sound (DEPRECATED)

## Formant Analysis

Resonance frequency tracking and analysis

- [`Formant`](https://humlab-speech.github.io/pladdrr/reference/Formant.md)
  : Formant
- [`FormantPath`](https://humlab-speech.github.io/pladdrr/reference/FormantPath.md)
  : Create a FormantPath object from a Sound
- [`FormantGrid`](https://humlab-speech.github.io/pladdrr/reference/FormantGrid.md)
  : FormantGrid
- [`FormantTier`](https://humlab-speech.github.io/pladdrr/reference/FormantTier.md)
  : FormantTier
- [`to_formant_direct()`](https://humlab-speech.github.io/pladdrr/reference/to_formant_direct.md)
  : Create Formant from Sound Directly (returns XPtr)
- [`get_formant_at_time()`](https://humlab-speech.github.io/pladdrr/reference/get_formant_at_time.md)
  : Get formant frequency at a specific time (DEPRECATED)
- [`get_formants_at_times()`](https://humlab-speech.github.io/pladdrr/reference/get_formants_at_times.md)
  : Batch Query Formant Frequencies at Multiple Times
- [`get_formant_value_direct()`](https://humlab-speech.github.io/pladdrr/reference/get_formant_value_direct.md)
  : Get Single Formant Value Directly
- [`get_formants_direct()`](https://humlab-speech.github.io/pladdrr/reference/get_formants_direct.md)
  : Get Formant F1-F4 at Time Directly
- [`get_formant_bandwidths_at_times()`](https://humlab-speech.github.io/pladdrr/reference/get_formant_bandwidths_at_times.md)
  : Batch Query Formant Bandwidths at Multiple Times
- [`get_mean_formant()`](https://humlab-speech.github.io/pladdrr/reference/get_mean_formant.md)
  : Get mean formant frequency (DEPRECATED)
- [`sound_to_formant_batch()`](https://humlab-speech.github.io/pladdrr/reference/sound_to_formant_batch.md)
  : Extract Formants from Multiple Sounds in Single C++ Call
- [`extract_formants()`](https://humlab-speech.github.io/pladdrr/reference/extract_formants.md)
  : Extract formants from a sound object (DEPRECATED)

## Intensity & Voice Quality

Intensity measurements and voice quality analysis

- [`Intensity`](https://humlab-speech.github.io/pladdrr/reference/Intensity.md)
  : Intensity
- [`IntensityTier`](https://humlab-speech.github.io/pladdrr/reference/IntensityTier.md)
  : Praat IntensityTier Object
- [`Harmonicity`](https://humlab-speech.github.io/pladdrr/reference/Harmonicity.md)
  : Harmonicity
- [`to_intensity_direct()`](https://humlab-speech.github.io/pladdrr/reference/to_intensity_direct.md)
  : Create Intensity from Sound Directly (returns XPtr)
- [`to_harmonicity_direct()`](https://humlab-speech.github.io/pladdrr/reference/to_harmonicity_direct.md)
  : Create Harmonicity from Sound Directly (returns XPtr)
- [`get_intensity_at_time()`](https://humlab-speech.github.io/pladdrr/reference/get_intensity_at_time.md)
  : Get intensity at a specific time (DEPRECATED)
- [`get_intensity_at_times()`](https://humlab-speech.github.io/pladdrr/reference/get_intensity_at_times.md)
  : Batch Query Intensity Values at Multiple Times
- [`get_intensity_value_direct()`](https://humlab-speech.github.io/pladdrr/reference/get_intensity_value_direct.md)
  : Get Single Intensity Value Directly
- [`get_max_intensity()`](https://humlab-speech.github.io/pladdrr/reference/get_max_intensity.md)
  : Get maximum intensity (DEPRECATED)
- [`get_min_intensity()`](https://humlab-speech.github.io/pladdrr/reference/get_min_intensity.md)
  : Get minimum intensity (DEPRECATED)
- [`get_mean_intensity()`](https://humlab-speech.github.io/pladdrr/reference/get_mean_intensity.md)
  : Get mean intensity (DEPRECATED)
- [`get_sd_intensity()`](https://humlab-speech.github.io/pladdrr/reference/get_sd_intensity.md)
  : Get standard deviation of intensity (DEPRECATED)
- [`sound_to_intensity_batch()`](https://humlab-speech.github.io/pladdrr/reference/sound_to_intensity_batch.md)
  : Extract Intensity from Multiple Sounds in Single C++ Call
- [`extract_intensity()`](https://humlab-speech.github.io/pladdrr/reference/extract_intensity.md)
  : Extract intensity from a sound object (DEPRECATED)

## TextGrid & Annotation

Time-aligned phonetic annotation

- [`TextGrid`](https://humlab-speech.github.io/pladdrr/reference/TextGrid.md)
  : Praat TextGrid Object
- [`textgrid_create()`](https://humlab-speech.github.io/pladdrr/reference/textgrid_create.md)
  : Create TextGrid
- [`textgrid_extract_intervals_batch()`](https://humlab-speech.github.io/pladdrr/reference/textgrid_extract_intervals_batch.md)
  : Extract TextGrid Intervals by Label (Batch)
- [`textgrid_filter_xptr()`](https://humlab-speech.github.io/pladdrr/reference/textgrid_filter_xptr.md)
  : Extract TextGrid Intervals Using Custom XPtr Predicate
- [`textgrid_get_all_labels()`](https://humlab-speech.github.io/pladdrr/reference/textgrid_get_all_labels.md)
  : Get All Labels from TextGrid Tier (Batch)
- [`textgrid_get_intervals_where()`](https://humlab-speech.github.io/pladdrr/reference/textgrid_get_intervals_where.md)
  : Extract Intervals from TextGrid Matching Criteria
- [`textgrid_interval_all_features_batch()`](https://humlab-speech.github.io/pladdrr/reference/textgrid_interval_all_features_batch.md)
  : Extract All Acoustic Features for TextGrid Intervals (Batch, SIMD)
- [`textgrid_interval_formant_batch()`](https://humlab-speech.github.io/pladdrr/reference/textgrid_interval_formant_batch.md)
  : Extract Formant Statistics for All TextGrid Intervals (Batch, SIMD)
- [`textgrid_interval_intensity_batch()`](https://humlab-speech.github.io/pladdrr/reference/textgrid_interval_intensity_batch.md)
  : Extract Intensity Statistics for All TextGrid Intervals (Batch,
  SIMD)
- [`textgrid_interval_pitch_batch()`](https://humlab-speech.github.io/pladdrr/reference/textgrid_interval_pitch_batch.md)
  : Extract Pitch Statistics for All TextGrid Intervals (Batch, SIMD)
- [`textgrid_interval_statistics_batch()`](https://humlab-speech.github.io/pladdrr/reference/textgrid_interval_statistics_batch.md)
  : Compute Statistics for All Intervals (Batch, SIMD-Optimized)
- [`textgrid_merge()`](https://humlab-speech.github.io/pladdrr/reference/textgrid_merge.md)
  : Merge Multiple TextGrid Objects
- [`textgrid_simd_enabled()`](https://humlab-speech.github.io/pladdrr/reference/textgrid_simd_enabled.md)
  : Check if SIMD is Enabled for TextGrid
- [`get_textgrid_interval_stats()`](https://humlab-speech.github.io/pladdrr/reference/get_textgrid_interval_stats.md)
  : Get Interval Statistics for All Intervals (Batch)
- [`get_textgrid_labels_all()`](https://humlab-speech.github.io/pladdrr/reference/get_textgrid_labels_all.md)
  : Get All Labels from TextGrid Tier (Batch)
- [`extract_textgrid_intervals()`](https://humlab-speech.github.io/pladdrr/reference/extract_textgrid_intervals.md)
  : Extract Intervals Matching Criteria (Batch)
- [`pair_sound_textgrid()`](https://humlab-speech.github.io/pladdrr/reference/pair_sound_textgrid.md)
  : Pair Sound and TextGrid Files
- [`sound_to_textgrid_silences()`](https://humlab-speech.github.io/pladdrr/reference/sound_to_textgrid_silences.md)
  : Detect Silences in Sound and Create TextGrid

## Speech Synthesis

Parametric speech synthesis with KlattGrid

- [`KlattGrid`](https://humlab-speech.github.io/pladdrr/reference/KlattGrid.md)
  : Create a KlattGrid object
- [`klattgrid_create_example()`](https://humlab-speech.github.io/pladdrr/reference/klattgrid_create_example.md)
  : Create example KlattGrid
- [`klattgrid_create_from_vowel()`](https://humlab-speech.github.io/pladdrr/reference/klattgrid_create_from_vowel.md)
  : Create KlattGrid from vowel parameters
- [`VocalTract`](https://humlab-speech.github.io/pladdrr/reference/VocalTract.md)
  : VocalTract
- [`vocaltract_create_from_phone()`](https://humlab-speech.github.io/pladdrr/reference/vocaltract_create_from_phone.md)
  : Create VocalTract from phone

## Auditory Models

Perceptual and cochlear models

- [`Cochleagram`](https://humlab-speech.github.io/pladdrr/reference/Cochleagram.md)
  : Cochleagram
- [`Excitation`](https://humlab-speech.github.io/pladdrr/reference/Excitation.md)
  : Excitation
- [`Cepstrum`](https://humlab-speech.github.io/pladdrr/reference/Cepstrum.md)
  : Praat Cepstrum Object
- [`PowerCepstrum`](https://humlab-speech.github.io/pladdrr/reference/PowerCepstrum.md)
  : PowerCepstrum
- [`PowerCepstrogram`](https://humlab-speech.github.io/pladdrr/reference/PowerCepstrogram.md)
  : PowerCepstrogram
- [`to_powercepstrogram_fast()`](https://humlab-speech.github.io/pladdrr/reference/to_powercepstrogram_fast.md)
  : Fast PowerCepstrogram Creation (Advanced Performance API)
- [`calculate_cpps_fast()`](https://humlab-speech.github.io/pladdrr/reference/calculate_cpps_fast.md)
  : Smoothed Cepstral Peak Prominence (CPPS) in one call
- [`get_cpps_fast()`](https://humlab-speech.github.io/pladdrr/reference/get_cpps_fast.md)
  : Get CPPS from PowerCepstrogram Pointer (Advanced Performance API)

## Sound Manipulation

Audio processing and transformation

- [`sound_extract_and_formant()`](https://humlab-speech.github.io/pladdrr/reference/sound_extract_and_formant.md)
  : Extract Parts and Analyze Formants in Single C++ Call
- [`sound_extract_and_pitch()`](https://humlab-speech.github.io/pladdrr/reference/sound_extract_and_pitch.md)
  : Extract Parts and Analyze Pitch in Single C++ Call
- [`sound_extract_part()`](https://humlab-speech.github.io/pladdrr/reference/sound_extract_part.md)
  : Extract part of Sound with optional windowing
- [`sound_extract_parts()`](https://humlab-speech.github.io/pladdrr/reference/sound_extract_parts.md)
  : Extract Multiple Parts from a Sound
- [`sound_extract_parts_pooled()`](https://humlab-speech.github.io/pladdrr/reference/sound_extract_parts_pooled.md)
  : Extract multiple Sound parts using object pool
- [`sound_filter_pass_hann_band()`](https://humlab-speech.github.io/pladdrr/reference/sound_filter_pass_hann_band.md)
  : Apply Hann band-pass filter
- [`sound_filter_stop_hann_band()`](https://humlab-speech.github.io/pladdrr/reference/sound_filter_stop_hann_band.md)
  : Apply Hann band-stop filter
- [`sound_concatenate_all()`](https://humlab-speech.github.io/pladdrr/reference/sound_concatenate_all.md)
  : Concatenate Multiple Sounds in Single C++ Call
- [`sounds_append()`](https://humlab-speech.github.io/pladdrr/reference/sounds_append.md)
  : Append two sounds with optional silence
- [`sounds_convolve()`](https://humlab-speech.github.io/pladdrr/reference/sounds_convolve.md)
  : Convolve two sounds
- [`sounds_cross_correlate()`](https://humlab-speech.github.io/pladdrr/reference/sounds_cross_correlate.md)
  : Cross-correlate two sounds
- [`sound_lengthen()`](https://humlab-speech.github.io/pladdrr/reference/sound_lengthen.md)
  : Time-stretch a sound using overlap-add
- [`sound_deepen_band_modulation()`](https://humlab-speech.github.io/pladdrr/reference/sound_deepen_band_modulation.md)
  : Deepen band modulation (hearing enhancement)
- [`sound_create_tone()`](https://humlab-speech.github.io/pladdrr/reference/sound_create_tone.md)
  : Create a pure tone Sound
- [`sound_statistics()`](https://humlab-speech.github.io/pladdrr/reference/sound_statistics.md)
  : Compute comprehensive sound statistics
- [`sound_auto_correlate()`](https://humlab-speech.github.io/pladdrr/reference/sound_auto_correlate.md)
  : Auto-correlate a sound with itself

## Batch & Parallel Operations

High-performance batch processing

- [`analyze_files_parallel()`](https://humlab-speech.github.io/pladdrr/reference/analyze_files_parallel.md)
  : Process Audio Files in Parallel
- [`extract_formant_parallel()`](https://humlab-speech.github.io/pladdrr/reference/extract_formant_parallel.md)
  : Parallel Formant Extraction
- [`extract_intensity_parallel()`](https://humlab-speech.github.io/pladdrr/reference/extract_intensity_parallel.md)
  : Parallel Intensity Extraction
- [`extract_pitch_parallel()`](https://humlab-speech.github.io/pladdrr/reference/extract_pitch_parallel.md)
  : Parallel Pitch Extraction
- [`batch_process()`](https://humlab-speech.github.io/pladdrr/reference/batch_process.md)
  : Batch Process Audio Files
- [`sound_to_formant_batch()`](https://humlab-speech.github.io/pladdrr/reference/sound_to_formant_batch.md)
  : Extract Formants from Multiple Sounds in Single C++ Call
- [`sound_to_intensity_batch()`](https://humlab-speech.github.io/pladdrr/reference/sound_to_intensity_batch.md)
  : Extract Intensity from Multiple Sounds in Single C++ Call
- [`sound_to_pitch_ac_batch()`](https://humlab-speech.github.io/pladdrr/reference/sound_to_pitch_ac_batch.md)
  : Extract Pitch (AC) from Multiple Sounds in Single C++ Call
- [`sound_to_pitch_batch()`](https://humlab-speech.github.io/pladdrr/reference/sound_to_pitch_batch.md)
  : Extract Pitch from Multiple Sounds in Single C++ Call
- [`sound_to_pitch_cc_batch()`](https://humlab-speech.github.io/pladdrr/reference/sound_to_pitch_cc_batch.md)
  : Extract Pitch (CC) from Multiple Sounds in Single C++ Call
- [`sound_to_pitch_shs_batch()`](https://humlab-speech.github.io/pladdrr/reference/sound_to_pitch_shs_batch.md)
  : Extract Pitch (SHS) from Multiple Sounds
- [`sound_to_pitch_spinet_batch()`](https://humlab-speech.github.io/pladdrr/reference/sound_to_pitch_spinet_batch.md)
  : Extract Pitch (SPINET) from Multiple Sounds
- [`textgrid_extract_intervals_batch()`](https://humlab-speech.github.io/pladdrr/reference/textgrid_extract_intervals_batch.md)
  : Extract TextGrid Intervals by Label (Batch)
- [`textgrid_interval_all_features_batch()`](https://humlab-speech.github.io/pladdrr/reference/textgrid_interval_all_features_batch.md)
  : Extract All Acoustic Features for TextGrid Intervals (Batch, SIMD)
- [`textgrid_interval_formant_batch()`](https://humlab-speech.github.io/pladdrr/reference/textgrid_interval_formant_batch.md)
  : Extract Formant Statistics for All TextGrid Intervals (Batch, SIMD)
- [`textgrid_interval_intensity_batch()`](https://humlab-speech.github.io/pladdrr/reference/textgrid_interval_intensity_batch.md)
  : Extract Intensity Statistics for All TextGrid Intervals (Batch,
  SIMD)
- [`textgrid_interval_pitch_batch()`](https://humlab-speech.github.io/pladdrr/reference/textgrid_interval_pitch_batch.md)
  : Extract Pitch Statistics for All TextGrid Intervals (Batch, SIMD)
- [`textgrid_interval_statistics_batch()`](https://humlab-speech.github.io/pladdrr/reference/textgrid_interval_statistics_batch.md)
  : Compute Statistics for All Intervals (Batch, SIMD-Optimized)
- [`sound_pool_stats()`](https://humlab-speech.github.io/pladdrr/reference/sound_pool.md)
  [`sound_pool_clear()`](https://humlab-speech.github.io/pladdrr/reference/sound_pool.md)
  [`sound_pool_resize()`](https://humlab-speech.github.io/pladdrr/reference/sound_pool.md)
  : Sound Object Pool for Batch Processing

## Direct API

Low-level direct C++ access (fastest performance)

- [`get_formant_value_direct()`](https://humlab-speech.github.io/pladdrr/reference/get_formant_value_direct.md)
  : Get Single Formant Value Directly
- [`get_formants_direct()`](https://humlab-speech.github.io/pladdrr/reference/get_formants_direct.md)
  : Get Formant F1-F4 at Time Directly
- [`get_intensity_value_direct()`](https://humlab-speech.github.io/pladdrr/reference/get_intensity_value_direct.md)
  : Get Single Intensity Value Directly
- [`get_pitch_mean_direct()`](https://humlab-speech.github.io/pladdrr/reference/get_pitch_mean_direct.md)
  : Get Pitch Mean Directly (Bypass R6)
- [`get_pitch_quantile_direct()`](https://humlab-speech.github.io/pladdrr/reference/get_pitch_quantile_direct.md)
  : Get Pitch Quantile Directly (Bypass R6)
- [`get_pitch_stats_direct()`](https://humlab-speech.github.io/pladdrr/reference/get_pitch_stats_direct.md)
  : Get Pitch Statistics Directly
- [`get_pitch_stdev_direct()`](https://humlab-speech.github.io/pladdrr/reference/get_pitch_stdev_direct.md)
  : Get Pitch Standard Deviation Directly (Bypass R6)
- [`get_pitch_value_direct()`](https://humlab-speech.github.io/pladdrr/reference/get_pitch_value_direct.md)
  : Get Single Pitch Value Directly
- [`pp_get_mean_period_direct()`](https://humlab-speech.github.io/pladdrr/reference/pp_get_mean_period_direct.md)
  : Get PointProcess Mean Period Directly (Bypass R6)
- [`pp_get_stdev_period_direct()`](https://humlab-speech.github.io/pladdrr/reference/pp_get_stdev_period_direct.md)
  : Get PointProcess Period Standard Deviation Directly (Bypass R6)
- [`praat_direct`](https://humlab-speech.github.io/pladdrr/reference/praat_direct.md)
  : Direct Function Dispatch API
- [`to_formant_direct()`](https://humlab-speech.github.io/pladdrr/reference/to_formant_direct.md)
  : Create Formant from Sound Directly (returns XPtr)
- [`to_harmonicity_direct()`](https://humlab-speech.github.io/pladdrr/reference/to_harmonicity_direct.md)
  : Create Harmonicity from Sound Directly (returns XPtr)
- [`to_intensity_direct()`](https://humlab-speech.github.io/pladdrr/reference/to_intensity_direct.md)
  : Create Intensity from Sound Directly (returns XPtr)
- [`to_ltas_direct()`](https://humlab-speech.github.io/pladdrr/reference/to_ltas_direct.md)
  : Create LTAS from Sound Directly
- [`to_pitch_ac_direct()`](https://humlab-speech.github.io/pladdrr/reference/to_pitch_ac_direct.md)
  : Create Pitch from Sound Directly (Autocorrelation) - Full Parameters
- [`to_pitch_cc_direct()`](https://humlab-speech.github.io/pladdrr/reference/to_pitch_cc_direct.md)
  : Create Pitch from Sound Directly (Cross-Correlation) - Full
  Parameters
- [`to_pitch_direct()`](https://humlab-speech.github.io/pladdrr/reference/to_pitch_direct.md)
  : Create Pitch from Sound Directly (returns XPtr) - Basic Parameters
- [`to_pitch_shs_direct()`](https://humlab-speech.github.io/pladdrr/reference/to_pitch_shs_direct.md)
  : Create Pitch from Sound using Subharmonic Summation (SHS) Directly
  (returns XPtr)
- [`to_pitch_spinet_direct()`](https://humlab-speech.github.io/pladdrr/reference/to_pitch_spinet_direct.md)
  : Create Pitch from Sound using SPINET Directly (returns XPtr)
- [`to_point_process_direct()`](https://humlab-speech.github.io/pladdrr/reference/to_point_process_direct.md)
  : Create PointProcess from Sound Directly (returns XPtr)
- [`to_spectrogram_direct()`](https://humlab-speech.github.io/pladdrr/reference/to_spectrogram_direct.md)
  : Create Spectrogram from Sound Directly (returns XPtr)
- [`to_spectrum_direct()`](https://humlab-speech.github.io/pladdrr/reference/to_spectrum_direct.md)
  : Create Spectrum from Sound Directly (returns XPtr)
- [`apply_transform_xptr()`](https://humlab-speech.github.io/pladdrr/reference/apply_transform_xptr.md)
  : Apply Compiled Transform Function (Advanced Performance API)
- [`apply_window_xptr()`](https://humlab-speech.github.io/pladdrr/reference/apply_window_xptr.md)
  : Apply Compiled Window Function (Advanced Performance API)
- [`create_window_xptr()`](https://humlab-speech.github.io/pladdrr/reference/create_window_xptr.md)
  : Create Common Window Function XPtr
- [`textgrid_filter_xptr()`](https://humlab-speech.github.io/pladdrr/reference/textgrid_filter_xptr.md)
  : Extract TextGrid Intervals Using Custom XPtr Predicate

## Visualization

Plotting methods for acoustic objects

- [`autoplot(`*`<Sound>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autolayer(`*`<Sound>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autoplot(`*`<Pitch>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autolayer(`*`<Pitch>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autoplot(`*`<Formant>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autolayer(`*`<Formant>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autoplot(`*`<Intensity>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autolayer(`*`<Intensity>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autoplot(`*`<Spectrogram>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autolayer(`*`<Spectrogram>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autoplot(`*`<Spectrum>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autolayer(`*`<Spectrum>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autoplot(`*`<Ltas>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autolayer(`*`<Ltas>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autoplot(`*`<Harmonicity>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autolayer(`*`<Harmonicity>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autoplot(`*`<PointProcess>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autolayer(`*`<PointProcess>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autoplot(`*`<PowerCepstrum>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autolayer(`*`<PowerCepstrum>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autoplot(`*`<TextGrid>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autolayer(`*`<TextGrid>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autoplot(`*`<AmplitudeTier>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autolayer(`*`<AmplitudeTier>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autoplot(`*`<DurationTier>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autolayer(`*`<DurationTier>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autoplot(`*`<IntensityTier>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autolayer(`*`<IntensityTier>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autoplot(`*`<PitchTier>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autolayer(`*`<PitchTier>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autoplot(`*`<FormantTier>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autolayer(`*`<FormantTier>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autoplot(`*`<FormantGrid>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autolayer(`*`<FormantGrid>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autoplot(`*`<FormantPath>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autolayer(`*`<FormantPath>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autoplot(`*`<Excitation>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autolayer(`*`<Excitation>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autoplot(`*`<ComplexSpectrogram>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autolayer(`*`<ComplexSpectrogram>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autoplot(`*`<Cepstrum>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autolayer(`*`<Cepstrum>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autoplot(`*`<Cochleagram>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autolayer(`*`<Cochleagram>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autoplot(`*`<PowerCepstrogram>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autolayer(`*`<PowerCepstrogram>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autoplot(`*`<MFCC>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autolayer(`*`<MFCC>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autoplot(`*`<LFCC>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autolayer(`*`<LFCC>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autoplot(`*`<BarkSpectrogram>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autolayer(`*`<BarkSpectrogram>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autoplot(`*`<MelSpectrogram>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autolayer(`*`<MelSpectrogram>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autoplot(`*`<Matrix>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autolayer(`*`<Matrix>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autoplot(`*`<PCA>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autolayer(`*`<PCA>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autoplot(`*`<Discriminant>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autolayer(`*`<Discriminant>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autoplot(`*`<FormantModeler>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autolayer(`*`<FormantModeler>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autoplot(`*`<Electroglottogram>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autolayer(`*`<Electroglottogram>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autoplot(`*`<LongSound>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autolayer(`*`<LongSound>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autoplot(`*`<DTW>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autolayer(`*`<DTW>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autoplot(`*`<Polygon>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autolayer(`*`<Polygon>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autoplot(`*`<VocalTract>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autolayer(`*`<VocalTract>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autoplot(`*`<LPC>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autolayer(`*`<LPC>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autoplot(`*`<KlattGrid>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autolayer(`*`<KlattGrid>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  : Autoplot and Autolayer Methods for pladdrr Objects
- [`plot_cpp_timeseries()`](https://humlab-speech.github.io/pladdrr/reference/plot_cpp_timeseries.md)
  : Plot CPP Time Series
- [`plot_pitch_intensity()`](https://humlab-speech.github.io/pladdrr/reference/plot_pitch_intensity.md)
  : Plot Pitch and Intensity Together
- [`plot_powercepstrogram()`](https://humlab-speech.github.io/pladdrr/reference/plot_powercepstrogram.md)
  : Plot PowerCepstrogram
- [`plot_powercepstrum()`](https://humlab-speech.github.io/pladdrr/reference/plot_powercepstrum.md)
  : Plot PowerCepstrum
- [`plot_sound_pitch()`](https://humlab-speech.github.io/pladdrr/reference/plot_sound_pitch.md)
  : Plot Sound Waveform with Pitch Contour
- [`plot_spectrogram_formants()`](https://humlab-speech.github.io/pladdrr/reference/plot_spectrogram_formants.md)
  : Plot Spectrogram with Formant Overlay
- [`plot_spectrogram_pitch()`](https://humlab-speech.github.io/pladdrr/reference/plot_spectrogram_pitch.md)
  : Plot Spectrogram with Pitch Overlay
- [`plot_textgrid_pitch()`](https://humlab-speech.github.io/pladdrr/reference/plot_textgrid_pitch.md)
  : Plot TextGrid with Pitch Contour
- [`plot_textgrid_sound()`](https://humlab-speech.github.io/pladdrr/reference/plot_textgrid_sound.md)
  : Plot TextGrid with Sound Waveform

## Praat Interpreter

Execute Praat scripts from R

- [`PraatInterpreter`](https://humlab-speech.github.io/pladdrr/reference/PraatInterpreter.md)
  : Praat Script Interpreter
- [`praat_direct`](https://humlab-speech.github.io/pladdrr/reference/praat_direct.md)
  : Direct Function Dispatch API
- [`praat_eval_matrix()`](https://humlab-speech.github.io/pladdrr/reference/praat_eval_matrix.md)
  : Evaluate a matrix Praat expression
- [`praat_eval_numeric()`](https://humlab-speech.github.io/pladdrr/reference/praat_eval_numeric.md)
  : Evaluate a numeric Praat expression
- [`praat_eval_string()`](https://humlab-speech.github.io/pladdrr/reference/praat_eval_string.md)
  : Evaluate a string Praat expression
- [`praat_eval_string_array()`](https://humlab-speech.github.io/pladdrr/reference/praat_eval_string_array.md)
  : Evaluate a string array Praat expression
- [`praat_eval_vector()`](https://humlab-speech.github.io/pladdrr/reference/praat_eval_vector.md)
  : Evaluate a vector Praat expression
- [`praat_init()`](https://humlab-speech.github.io/pladdrr/reference/praat_init.md)
  : Initialize Praat interpreter
- [`praat_initialized()`](https://humlab-speech.github.io/pladdrr/reference/praat_initialized.md)
  : Check if Praat interpreter is initialized
- [`praat_list_objects()`](https://humlab-speech.github.io/pladdrr/reference/praat_list_objects.md)
  : List all objects in Praat object list
- [`praat_object_count()`](https://humlab-speech.github.io/pladdrr/reference/praat_object_count.md)
  : Get count of objects in Praat object list
- [`praat_run_script()`](https://humlab-speech.github.io/pladdrr/reference/praat_run_script.md)
  : Execute a Praat script
- [`praat_version()`](https://humlab-speech.github.io/pladdrr/reference/praat_version.md)
  : Get Praat version information

## Utilities

Helper functions and utilities

- [`aggregate_measurements()`](https://humlab-speech.github.io/pladdrr/reference/aggregate_measurements.md)
  : Aggregate Measurements by Label
- [`extract_measurements()`](https://humlab-speech.github.io/pladdrr/reference/extract_measurements.md)
  : Extract Measurements from Sound and TextGrid Pairs
- [`extract_measurements_custom()`](https://humlab-speech.github.io/pladdrr/reference/extract_measurements_custom.md)
  : Extract Custom Measurements from TextGrid Intervals
- [`pair_files()`](https://humlab-speech.github.io/pladdrr/reference/pair_files.md)
  : Pair Sound and TextGrid Files
- [`create_file_list()`](https://humlab-speech.github.io/pladdrr/reference/create_file_list.md)
  : Create File List (Replaces Praat's Strings Object)
- [`check_audio_quality()`](https://humlab-speech.github.io/pladdrr/reference/check_audio_quality.md)
  : Check Audio Quality Metrics
- [`simd_info()`](https://humlab-speech.github.io/pladdrr/reference/simd_info.md)
  : Get SIMD Capabilities
- [`get_duration()`](https://humlab-speech.github.io/pladdrr/reference/get_duration.md)
  : Get duration of sound object (DEPRECATED)
- [`get_sampling_rate()`](https://humlab-speech.github.io/pladdrr/reference/get_sampling_rate.md)
  : Get sampling rate of sound object (DEPRECATED)
- [`get_n_channels()`](https://humlab-speech.github.io/pladdrr/reference/get_n_channels.md)
  : Get number of channels in sound object (DEPRECATED)
- [`get_n_samples()`](https://humlab-speech.github.io/pladdrr/reference/get_n_samples.md)
  : Get number of samples in sound object (DEPRECATED)

## Data Structures

Additional Praat data types

- [`Matrix`](https://humlab-speech.github.io/pladdrr/reference/Matrix.md)
  : Praat Matrix Object
- [`Table`](https://humlab-speech.github.io/pladdrr/reference/Table.md)
  : Praat Table Object
- [`PointProcess`](https://humlab-speech.github.io/pladdrr/reference/PointProcess.md)
  : Praat PointProcess object
- [`Polygon`](https://humlab-speech.github.io/pladdrr/reference/Polygon.md)
  : Polygon Object
- [`AmplitudeTier`](https://humlab-speech.github.io/pladdrr/reference/AmplitudeTier.md)
  : AmplitudeTier
- [`DurationTier`](https://humlab-speech.github.io/pladdrr/reference/DurationTier.md)
  : DurationTier
- [`Electroglottogram`](https://humlab-speech.github.io/pladdrr/reference/Electroglottogram.md)
  : Electroglottogram
- [`LPC`](https://humlab-speech.github.io/pladdrr/reference/LPC.md) :
  LPC
- [`Manipulation`](https://humlab-speech.github.io/pladdrr/reference/Manipulation.md)
  : Praat Manipulation Object

## Internal & Development

Helper functions and S3 methods

- [`as.data.frame(`*`<Discriminant>`*`)`](https://humlab-speech.github.io/pladdrr/reference/as-data-frame-missing.md)
  [`as.data.frame(`*`<Electroglottogram>`*`)`](https://humlab-speech.github.io/pladdrr/reference/as-data-frame-missing.md)
  [`as.data.frame(`*`<FormantModeler>`*`)`](https://humlab-speech.github.io/pladdrr/reference/as-data-frame-missing.md)
  [`as.data.frame(`*`<PCA>`*`)`](https://humlab-speech.github.io/pladdrr/reference/as-data-frame-missing.md)
  [`as.data.frame(`*`<PowerCepstrogram>`*`)`](https://humlab-speech.github.io/pladdrr/reference/as-data-frame-missing.md)
  [`as.data.frame(`*`<BarkSpectrogram>`*`)`](https://humlab-speech.github.io/pladdrr/reference/as-data-frame-missing.md)
  [`as.data.frame(`*`<Cepstrum>`*`)`](https://humlab-speech.github.io/pladdrr/reference/as-data-frame-missing.md)
  [`as.data.frame(`*`<Cochleagram>`*`)`](https://humlab-speech.github.io/pladdrr/reference/as-data-frame-missing.md)
  [`as.data.frame(`*`<DTW>`*`)`](https://humlab-speech.github.io/pladdrr/reference/as-data-frame-missing.md)
  [`as.data.frame(`*`<KlattGrid>`*`)`](https://humlab-speech.github.io/pladdrr/reference/as-data-frame-missing.md)
  [`as.data.frame(`*`<LPC>`*`)`](https://humlab-speech.github.io/pladdrr/reference/as-data-frame-missing.md)
  [`as.data.frame(`*`<LongSound>`*`)`](https://humlab-speech.github.io/pladdrr/reference/as-data-frame-missing.md)
  [`as.data.frame(`*`<Matrix>`*`)`](https://humlab-speech.github.io/pladdrr/reference/as-data-frame-missing.md)
  [`as.data.frame(`*`<MelSpectrogram>`*`)`](https://humlab-speech.github.io/pladdrr/reference/as-data-frame-missing.md)
  [`as.data.frame(`*`<VocalTract>`*`)`](https://humlab-speech.github.io/pladdrr/reference/as-data-frame-missing.md)
  : as.data.frame Methods for pladdrr Objects
- [`as.data.frame(`*`<Formant>`*`)`](https://humlab-speech.github.io/pladdrr/reference/as.data.frame.Formant.md)
  : Convert R6 Formant to data frame
- [`as.data.frame(`*`<Intensity>`*`)`](https://humlab-speech.github.io/pladdrr/reference/as.data.frame.Intensity.md)
  : Convert R6 Intensity to data frame
- [`as.data.frame(`*`<Pitch>`*`)`](https://humlab-speech.github.io/pladdrr/reference/as.data.frame.Pitch.md)
  [`as.data.frame(`*`<PointProcess>`*`)`](https://humlab-speech.github.io/pladdrr/reference/as.data.frame.Pitch.md)
  [`as.data.frame(`*`<TextGrid>`*`)`](https://humlab-speech.github.io/pladdrr/reference/as.data.frame.Pitch.md)
  [`as.data.frame(`*`<MFCC>`*`)`](https://humlab-speech.github.io/pladdrr/reference/as.data.frame.Pitch.md)
  [`as.data.frame(`*`<LFCC>`*`)`](https://humlab-speech.github.io/pladdrr/reference/as.data.frame.Pitch.md)
  : Convert R6 Pitch to data frame
- [`as.data.frame(`*`<Sound>`*`)`](https://humlab-speech.github.io/pladdrr/reference/as.data.frame.Sound.md)
  : Convert R6 Sound to data frame
- [`as.data.frame(`*`<praat_formant>`*`)`](https://humlab-speech.github.io/pladdrr/reference/as.data.frame.praat_formant.md)
  : Convert praat_formant to data.frame
- [`as.data.frame(`*`<praat_intensity>`*`)`](https://humlab-speech.github.io/pladdrr/reference/as.data.frame.praat_intensity.md)
  : Convert praat_intensity to data.frame
- [`as.data.frame(`*`<praat_sound>`*`)`](https://humlab-speech.github.io/pladdrr/reference/as.data.frame.praat_sound.md)
  : Convert praat_sound to data frame
- [`AmplitudeTier`](https://humlab-speech.github.io/pladdrr/reference/AmplitudeTier.md)
  : AmplitudeTier
- [`BarkSpectrogram()`](https://humlab-speech.github.io/pladdrr/reference/BarkSpectrogram.md)
  : BarkSpectrogram
- [`Cepstrum`](https://humlab-speech.github.io/pladdrr/reference/Cepstrum.md)
  : Praat Cepstrum Object
- [`Cochleagram`](https://humlab-speech.github.io/pladdrr/reference/Cochleagram.md)
  : Cochleagram
- [`ComplexSpectrogram`](https://humlab-speech.github.io/pladdrr/reference/ComplexSpectrogram.md)
  : ComplexSpectrogram
- [`DTW()`](https://humlab-speech.github.io/pladdrr/reference/DTW.md) :
  DTW
- [`Discriminant`](https://humlab-speech.github.io/pladdrr/reference/Discriminant.md)
  : Discriminant
- [`DurationTier`](https://humlab-speech.github.io/pladdrr/reference/DurationTier.md)
  : DurationTier
- [`Electroglottogram`](https://humlab-speech.github.io/pladdrr/reference/Electroglottogram.md)
  : Electroglottogram
- [`Excitation`](https://humlab-speech.github.io/pladdrr/reference/Excitation.md)
  : Excitation
- [`Formant`](https://humlab-speech.github.io/pladdrr/reference/Formant.md)
  : Formant
- [`FormantGrid`](https://humlab-speech.github.io/pladdrr/reference/FormantGrid.md)
  : FormantGrid
- [`FormantModeler`](https://humlab-speech.github.io/pladdrr/reference/FormantModeler.md)
  : FormantModeler
- [`FormantPath`](https://humlab-speech.github.io/pladdrr/reference/FormantPath.md)
  : Create a FormantPath object from a Sound
- [`FormantTier`](https://humlab-speech.github.io/pladdrr/reference/FormantTier.md)
  : FormantTier
- [`Harmonicity`](https://humlab-speech.github.io/pladdrr/reference/Harmonicity.md)
  : Harmonicity
- [`Intensity`](https://humlab-speech.github.io/pladdrr/reference/Intensity.md)
  : Intensity
- [`IntensityTier`](https://humlab-speech.github.io/pladdrr/reference/IntensityTier.md)
  : Praat IntensityTier Object
- [`KlattGrid`](https://humlab-speech.github.io/pladdrr/reference/KlattGrid.md)
  : Create a KlattGrid object
- [`LFCC`](https://humlab-speech.github.io/pladdrr/reference/LFCC.md) :
  LFCC
- [`LPC`](https://humlab-speech.github.io/pladdrr/reference/LPC.md) :
  LPC
- [`LongSound`](https://humlab-speech.github.io/pladdrr/reference/LongSound.md)
  : LongSound
- [`Ltas`](https://humlab-speech.github.io/pladdrr/reference/Ltas.md) :
  Ltas
- [`MFCC`](https://humlab-speech.github.io/pladdrr/reference/MFCC.md) :
  MFCC
- [`Manipulation`](https://humlab-speech.github.io/pladdrr/reference/Manipulation.md)
  : Praat Manipulation Object
- [`Matrix`](https://humlab-speech.github.io/pladdrr/reference/Matrix.md)
  : Praat Matrix Object
- [`MelSpectrogram()`](https://humlab-speech.github.io/pladdrr/reference/MelSpectrogram.md)
  : MelSpectrogram
- [`PCA`](https://humlab-speech.github.io/pladdrr/reference/PCA.md) :
  PCA
- [`Pitch`](https://humlab-speech.github.io/pladdrr/reference/Pitch.md)
  : Pitch
- [`PitchModule()`](https://humlab-speech.github.io/pladdrr/reference/PitchModule.md)
  : Create a Pitch Object from Module
- [`PitchTier`](https://humlab-speech.github.io/pladdrr/reference/PitchTier.md)
  : PitchTier
- [`PointProcess`](https://humlab-speech.github.io/pladdrr/reference/PointProcess.md)
  : Praat PointProcess object
- [`Polygon`](https://humlab-speech.github.io/pladdrr/reference/Polygon.md)
  : Polygon Object
- [`PowerCepstrogram`](https://humlab-speech.github.io/pladdrr/reference/PowerCepstrogram.md)
  : PowerCepstrogram
- [`PowerCepstrum`](https://humlab-speech.github.io/pladdrr/reference/PowerCepstrum.md)
  : PowerCepstrum
- [`PraatInterpreter`](https://humlab-speech.github.io/pladdrr/reference/PraatInterpreter.md)
  : Praat Script Interpreter
- [`Sound`](https://humlab-speech.github.io/pladdrr/reference/Sound.md)
  : Sound
- [`Spectrogram`](https://humlab-speech.github.io/pladdrr/reference/Spectrogram.md)
  : Spectrogram
- [`Spectrum`](https://humlab-speech.github.io/pladdrr/reference/Spectrum.md)
  : Spectrum
- [`SpectrumTier`](https://humlab-speech.github.io/pladdrr/reference/SpectrumTier.md)
  : SpectrumTier
- [`Table`](https://humlab-speech.github.io/pladdrr/reference/Table.md)
  : Praat Table Object
- [`TextGrid`](https://humlab-speech.github.io/pladdrr/reference/TextGrid.md)
  : Praat TextGrid Object
- [`VocalTract`](https://humlab-speech.github.io/pladdrr/reference/VocalTract.md)
  : VocalTract
- [`aggregate_measurements()`](https://humlab-speech.github.io/pladdrr/reference/aggregate_measurements.md)
  : Aggregate Measurements by Label
- [`amplitude_tier_create()`](https://humlab-speech.github.io/pladdrr/reference/amplitude_tier_create.md)
  : Create an empty AmplitudeTier
- [`amplitude_tier_from_point_process()`](https://humlab-speech.github.io/pladdrr/reference/amplitude_tier_from_point_process.md)
  : Create AmplitudeTier from PointProcess and Sound
- [`analyze_files_parallel()`](https://humlab-speech.github.io/pladdrr/reference/analyze_files_parallel.md)
  : Process Audio Files in Parallel
- [`apply_transform_xptr()`](https://humlab-speech.github.io/pladdrr/reference/apply_transform_xptr.md)
  : Apply Compiled Transform Function (Advanced Performance API)
- [`apply_window_xptr()`](https://humlab-speech.github.io/pladdrr/reference/apply_window_xptr.md)
  : Apply Compiled Window Function (Advanced Performance API)
- [`autoplot(`*`<Sound>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autolayer(`*`<Sound>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autoplot(`*`<Pitch>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autolayer(`*`<Pitch>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autoplot(`*`<Formant>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autolayer(`*`<Formant>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autoplot(`*`<Intensity>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autolayer(`*`<Intensity>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autoplot(`*`<Spectrogram>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autolayer(`*`<Spectrogram>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autoplot(`*`<Spectrum>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autolayer(`*`<Spectrum>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autoplot(`*`<Ltas>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autolayer(`*`<Ltas>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autoplot(`*`<Harmonicity>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autolayer(`*`<Harmonicity>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autoplot(`*`<PointProcess>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autolayer(`*`<PointProcess>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autoplot(`*`<PowerCepstrum>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autolayer(`*`<PowerCepstrum>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autoplot(`*`<TextGrid>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autolayer(`*`<TextGrid>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autoplot(`*`<AmplitudeTier>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autolayer(`*`<AmplitudeTier>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autoplot(`*`<DurationTier>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autolayer(`*`<DurationTier>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autoplot(`*`<IntensityTier>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autolayer(`*`<IntensityTier>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autoplot(`*`<PitchTier>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autolayer(`*`<PitchTier>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autoplot(`*`<FormantTier>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autolayer(`*`<FormantTier>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autoplot(`*`<FormantGrid>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autolayer(`*`<FormantGrid>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autoplot(`*`<FormantPath>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autolayer(`*`<FormantPath>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autoplot(`*`<Excitation>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autolayer(`*`<Excitation>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autoplot(`*`<ComplexSpectrogram>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autolayer(`*`<ComplexSpectrogram>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autoplot(`*`<Cepstrum>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autolayer(`*`<Cepstrum>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autoplot(`*`<Cochleagram>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autolayer(`*`<Cochleagram>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autoplot(`*`<PowerCepstrogram>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autolayer(`*`<PowerCepstrogram>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autoplot(`*`<MFCC>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autolayer(`*`<MFCC>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autoplot(`*`<LFCC>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autolayer(`*`<LFCC>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autoplot(`*`<BarkSpectrogram>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autolayer(`*`<BarkSpectrogram>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autoplot(`*`<MelSpectrogram>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autolayer(`*`<MelSpectrogram>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autoplot(`*`<Matrix>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autolayer(`*`<Matrix>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autoplot(`*`<PCA>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autolayer(`*`<PCA>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autoplot(`*`<Discriminant>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autolayer(`*`<Discriminant>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autoplot(`*`<FormantModeler>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autolayer(`*`<FormantModeler>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autoplot(`*`<Electroglottogram>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autolayer(`*`<Electroglottogram>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autoplot(`*`<LongSound>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autolayer(`*`<LongSound>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autoplot(`*`<DTW>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autolayer(`*`<DTW>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autoplot(`*`<Polygon>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autolayer(`*`<Polygon>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autoplot(`*`<VocalTract>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autolayer(`*`<VocalTract>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autoplot(`*`<LPC>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autolayer(`*`<LPC>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autoplot(`*`<KlattGrid>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  [`autolayer(`*`<KlattGrid>`*`)`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  : Autoplot and Autolayer Methods for pladdrr Objects
- [`batch_process()`](https://humlab-speech.github.io/pladdrr/reference/batch_process.md)
  : Batch Process Audio Files
- [`batch_processing`](https://humlab-speech.github.io/pladdrr/reference/batch_processing.md)
  : Batch Processing Utilities for Speaker Package
- [`benchmark_parallel()`](https://humlab-speech.github.io/pladdrr/reference/benchmark_parallel.md)
  : Benchmark Parallel vs Sequential Processing
- [`build_multiband_harmonicity()`](https://humlab-speech.github.io/pladdrr/reference/build_multiband_harmonicity.md)
  : Build reusable multi-band Harmonicity objects
- [`calculate_cpps_fast()`](https://humlab-speech.github.io/pladdrr/reference/calculate_cpps_fast.md)
  : Smoothed Cepstral Peak Prominence (CPPS) in one call
- [`calculate_cpps_ultra()`](https://humlab-speech.github.io/pladdrr/reference/calculate_cpps_ultra.md)
  : Calculate CPPS with Optimized Single-Call (Tier 4 Ultra)
- [`calculate_durations_simd_bridge()`](https://humlab-speech.github.io/pladdrr/reference/calculate_durations_simd_bridge.md)
  : Calculate Interval Durations with SIMD
- [`calculate_f0_stats_ultra()`](https://humlab-speech.github.io/pladdrr/reference/calculate_f0_stats_ultra.md)
  : Calculate F0 Statistic in Single Call (Tier 4 Ultra)
- [`calculate_midpoints_simd_bridge()`](https://humlab-speech.github.io/pladdrr/reference/calculate_midpoints_simd_bridge.md)
  : Calculate Interval Midpoints with SIMD
- [`calculate_minimum_intensity_ultra()`](https://humlab-speech.github.io/pladdrr/reference/calculate_minimum_intensity_ultra.md)
  : Calculate Minimum Intensity in Voiced Regions (Tier 4 Ultra)
- [`calculate_multiband_hnr_ultra()`](https://humlab-speech.github.io/pladdrr/reference/calculate_multiband_hnr_ultra.md)
  : Calculate multi-band HNR in a single call
- [`` `$`( ``*`<sound_constructor>`*`)`](https://humlab-speech.github.io/pladdrr/reference/cash-.sound_constructor.md)
  : \$ method for Sound constructor (enables Sound\$create_tone(), etc.)
- [`` `$`( ``*`<textgrid_constructor>`*`)`](https://humlab-speech.github.io/pladdrr/reference/cash-.textgrid_constructor.md)
  : \$ method for TextGrid constructor (enables TextGrid\$new(),
  TextGrid\$create())
- [`cepstrum_plots`](https://humlab-speech.github.io/pladdrr/reference/cepstrum_plots.md)
  : PowerCepstrum and PowerCepstrogram Visualization Functions
- [`check_audio_quality()`](https://humlab-speech.github.io/pladdrr/reference/check_audio_quality.md)
  : Check Audio Quality Metrics
- [`create_cepstrum_report()`](https://humlab-speech.github.io/pladdrr/reference/create_cepstrum_report.md)
  : Create Cepstrum Report Plot
- [`create_file_list()`](https://humlab-speech.github.io/pladdrr/reference/create_file_list.md)
  : Create File List (Replaces Praat's Strings Object)
- [`create_sound()`](https://humlab-speech.github.io/pladdrr/reference/create_sound.md)
  : Create a sound object from numeric values (DEPRECATED)
- [`create_sound_from_values()`](https://humlab-speech.github.io/pladdrr/reference/create_sound_from_values.md)
  : Create a sound object from numeric vector
- [`create_window_xptr()`](https://humlab-speech.github.io/pladdrr/reference/create_window_xptr.md)
  : Create Common Window Function XPtr
- [`discriminant_from_matrix()`](https://humlab-speech.github.io/pladdrr/reference/discriminant_from_matrix.md)
  : Create Discriminant Analysis from labeled data
- [`duration_statistics_simd_bridge()`](https://humlab-speech.github.io/pladdrr/reference/duration_statistics_simd_bridge.md)
  : Calculate Duration Statistics with SIMD
- [`electroglottogram_create()`](https://humlab-speech.github.io/pladdrr/reference/electroglottogram_create.md)
  : Create an Electroglottogram object
- [`extract_formant_parallel()`](https://humlab-speech.github.io/pladdrr/reference/extract_formant_parallel.md)
  : Parallel Formant Extraction
- [`extract_formants()`](https://humlab-speech.github.io/pladdrr/reference/extract_formants.md)
  : Extract formants from a sound object (DEPRECATED)
- [`extract_intensity()`](https://humlab-speech.github.io/pladdrr/reference/extract_intensity.md)
  : Extract intensity from a sound object (DEPRECATED)
- [`extract_intensity_parallel()`](https://humlab-speech.github.io/pladdrr/reference/extract_intensity_parallel.md)
  : Parallel Intensity Extraction
- [`extract_measurements()`](https://humlab-speech.github.io/pladdrr/reference/extract_measurements.md)
  : Extract Measurements from Sound and TextGrid Pairs
- [`extract_measurements_custom()`](https://humlab-speech.github.io/pladdrr/reference/extract_measurements_custom.md)
  : Extract Custom Measurements from TextGrid Intervals
- [`extract_pitch()`](https://humlab-speech.github.io/pladdrr/reference/extract_pitch.md)
  : Extract pitch contour from sound (DEPRECATED)
- [`extract_pitch_parallel()`](https://humlab-speech.github.io/pladdrr/reference/extract_pitch_parallel.md)
  : Parallel Pitch Extraction
- [`extract_textgrid_intervals()`](https://humlab-speech.github.io/pladdrr/reference/extract_textgrid_intervals.md)
  : Extract Intervals Matching Criteria (Batch)
- [`extract_voiced_segments()`](https://humlab-speech.github.io/pladdrr/reference/extract_voiced_segments.md)
  : Extract Voiced Segments from Speech
- [`extract_voiced_segments_ultra()`](https://humlab-speech.github.io/pladdrr/reference/extract_voiced_segments_ultra.md)
  : Extract Voiced Segments with AVQI Filtering (Tier 4 Ultra)
- [`filter_by_duration_simd_bridge()`](https://humlab-speech.github.io/pladdrr/reference/filter_by_duration_simd_bridge.md)
  : Filter Intervals by Duration Range with SIMD
- [`formanttier_from_formant()`](https://humlab-speech.github.io/pladdrr/reference/formanttier_from_formant.md)
  : Create FormantTier from Formant
- [`format_quality_report()`](https://humlab-speech.github.io/pladdrr/reference/format_quality_report.md)
  : Format Audio Quality Report
- [`generate_noise()`](https://humlab-speech.github.io/pladdrr/reference/generate_noise.md)
  : Generate white noise
- [`generate_sine_wave()`](https://humlab-speech.github.io/pladdrr/reference/generate_sine_wave.md)
  : Generate a sine wave
- [`get_cpps_fast()`](https://humlab-speech.github.io/pladdrr/reference/get_cpps_fast.md)
  : Get CPPS from PowerCepstrogram Pointer (Advanced Performance API)
- [`get_duration()`](https://humlab-speech.github.io/pladdrr/reference/get_duration.md)
  : Get duration of sound object (DEPRECATED)
- [`get_durations_batch()`](https://humlab-speech.github.io/pladdrr/reference/get_durations_batch.md)
  : Get Audio File Durations via WAV Header Reading
- [`get_formant_at_time()`](https://humlab-speech.github.io/pladdrr/reference/get_formant_at_time.md)
  : Get formant frequency at a specific time (DEPRECATED)
- [`get_formant_bandwidths_at_times()`](https://humlab-speech.github.io/pladdrr/reference/get_formant_bandwidths_at_times.md)
  : Batch Query Formant Bandwidths at Multiple Times
- [`get_formant_value_direct()`](https://humlab-speech.github.io/pladdrr/reference/get_formant_value_direct.md)
  : Get Single Formant Value Directly
- [`get_formants_at_times()`](https://humlab-speech.github.io/pladdrr/reference/get_formants_at_times.md)
  : Batch Query Formant Frequencies at Multiple Times
- [`get_formants_direct()`](https://humlab-speech.github.io/pladdrr/reference/get_formants_direct.md)
  : Get Formant F1-F4 at Time Directly
- [`get_intensity_at_time()`](https://humlab-speech.github.io/pladdrr/reference/get_intensity_at_time.md)
  : Get intensity at a specific time (DEPRECATED)
- [`get_intensity_at_times()`](https://humlab-speech.github.io/pladdrr/reference/get_intensity_at_times.md)
  : Batch Query Intensity Values at Multiple Times
- [`get_intensity_value_direct()`](https://humlab-speech.github.io/pladdrr/reference/get_intensity_value_direct.md)
  : Get Single Intensity Value Directly
- [`get_interval_predicate()`](https://humlab-speech.github.io/pladdrr/reference/get_interval_predicate.md)
  : Create Built-in Interval Predicates
- [`get_jitter_shimmer_batch()`](https://humlab-speech.github.io/pladdrr/reference/get_jitter_shimmer_batch.md)
  : Get All Jitter and Shimmer Measures in One Call
- [`get_max_intensity()`](https://humlab-speech.github.io/pladdrr/reference/get_max_intensity.md)
  : Get maximum intensity (DEPRECATED)
- [`get_max_pitch()`](https://humlab-speech.github.io/pladdrr/reference/get_max_pitch.md)
  : Get maximum pitch (DEPRECATED)
- [`get_mean_formant()`](https://humlab-speech.github.io/pladdrr/reference/get_mean_formant.md)
  : Get mean formant frequency (DEPRECATED)
- [`get_mean_intensity()`](https://humlab-speech.github.io/pladdrr/reference/get_mean_intensity.md)
  : Get mean intensity (DEPRECATED)
- [`get_mean_pitch()`](https://humlab-speech.github.io/pladdrr/reference/get_mean_pitch.md)
  : Get mean pitch (DEPRECATED)
- [`get_min_intensity()`](https://humlab-speech.github.io/pladdrr/reference/get_min_intensity.md)
  : Get minimum intensity (DEPRECATED)
- [`get_min_pitch()`](https://humlab-speech.github.io/pladdrr/reference/get_min_pitch.md)
  : Get minimum pitch (DEPRECATED)
- [`get_n_channels()`](https://humlab-speech.github.io/pladdrr/reference/get_n_channels.md)
  : Get number of channels in sound object (DEPRECATED)
- [`get_n_samples()`](https://humlab-speech.github.io/pladdrr/reference/get_n_samples.md)
  : Get number of samples in sound object (DEPRECATED)
- [`get_pitch_at_time()`](https://humlab-speech.github.io/pladdrr/reference/get_pitch_at_time.md)
  : Get pitch at specific time point (DEPRECATED)
- [`get_pitch_at_times()`](https://humlab-speech.github.io/pladdrr/reference/get_pitch_at_times.md)
  : Batch Query Pitch Values at Multiple Times
- [`get_pitch_mean_direct()`](https://humlab-speech.github.io/pladdrr/reference/get_pitch_mean_direct.md)
  : Get Pitch Mean Directly (Bypass R6)
- [`get_pitch_quantile_direct()`](https://humlab-speech.github.io/pladdrr/reference/get_pitch_quantile_direct.md)
  : Get Pitch Quantile Directly (Bypass R6)
- [`get_pitch_quantiles_batch()`](https://humlab-speech.github.io/pladdrr/reference/get_pitch_quantiles_batch.md)
  : Get Multiple Pitch Quantiles in Single Call (NEW for VUV
  Performance)
- [`get_pitch_stats_direct()`](https://humlab-speech.github.io/pladdrr/reference/get_pitch_stats_direct.md)
  : Get Pitch Statistics Directly
- [`get_pitch_stdev_direct()`](https://humlab-speech.github.io/pladdrr/reference/get_pitch_stdev_direct.md)
  : Get Pitch Standard Deviation Directly (Bypass R6)
- [`get_pitch_strengths_at_times()`](https://humlab-speech.github.io/pladdrr/reference/get_pitch_strengths_at_times.md)
  : Batch Query Pitch Strengths at Multiple Times
- [`get_pitch_value_direct()`](https://humlab-speech.github.io/pladdrr/reference/get_pitch_value_direct.md)
  : Get Single Pitch Value Directly
- [`get_pointprocess_intervals()`](https://humlab-speech.github.io/pladdrr/reference/get_pointprocess_intervals.md)
  : Get Inter-Point Intervals from PointProcess
- [`get_pointprocess_nearest_indices()`](https://humlab-speech.github.io/pladdrr/reference/get_pointprocess_nearest_indices.md)
  : Query PointProcess Nearest Indices at Multiple Times
- [`get_pointprocess_times()`](https://humlab-speech.github.io/pladdrr/reference/get_pointprocess_times.md)
  : Get All Point Times from PointProcess
- [`get_sampling_rate()`](https://humlab-speech.github.io/pladdrr/reference/get_sampling_rate.md)
  : Get sampling rate of sound object (DEPRECATED)
- [`get_sd_intensity()`](https://humlab-speech.github.io/pladdrr/reference/get_sd_intensity.md)
  : Get standard deviation of intensity (DEPRECATED)
- [`get_sound_times_fast()`](https://humlab-speech.github.io/pladdrr/reference/get_sound_times_fast.md)
  : Get Sound Sample Times (Fast Computation)
- [`get_sound_values_fast()`](https://humlab-speech.github.io/pladdrr/reference/get_sound_values_fast.md)
  : Get Sound Values (Fast Copy)
- [`get_spectral_moments_batch()`](https://humlab-speech.github.io/pladdrr/reference/get_spectral_moments_batch.md)
  : Get spectral moments for all frames of a Spectrogram
- [`get_textgrid_interval_stats()`](https://humlab-speech.github.io/pladdrr/reference/get_textgrid_interval_stats.md)
  : Get Interval Statistics for All Intervals (Batch)
- [`get_textgrid_labels_all()`](https://humlab-speech.github.io/pladdrr/reference/get_textgrid_labels_all.md)
  : Get All Labels from TextGrid Tier (Batch)
- [`get_voice_quality_ultra()`](https://humlab-speech.github.io/pladdrr/reference/get_voice_quality_ultra.md)
  : Get Voice Quality Metrics in Single Call (Tier 4 Ultra)
- [`intensity_tier_to_amplitude_tier()`](https://humlab-speech.github.io/pladdrr/reference/intensity_tier_to_amplitude_tier.md)
  : Convert IntensityTier to AmplitudeTier
- [`is_fast_access()`](https://humlab-speech.github.io/pladdrr/reference/is_fast_access.md)
  : Check if Vector is a Fast-Access Vector
- [`is_fast_vector()`](https://humlab-speech.github.io/pladdrr/reference/is_fast_vector.md)
  : Check if Vector is a Fast-Access Vector
- [`is_praat_formant()`](https://humlab-speech.github.io/pladdrr/reference/is_praat_formant.md)
  : Check if object is a valid Formant (R6 or legacy S3)
- [`is_praat_intensity()`](https://humlab-speech.github.io/pladdrr/reference/is_praat_intensity.md)
  : Check if object is a valid Intensity (R6 or legacy S3)
- [`is_praat_pitch()`](https://humlab-speech.github.io/pladdrr/reference/is_praat_pitch.md)
  : Check if object is a valid Pitch (R6 or legacy S3)
- [`is_praat_sound()`](https://humlab-speech.github.io/pladdrr/reference/is_praat_sound.md)
  : Check if object is a valid Sound (R6 or legacy S3)
- [`klattgrid_create_example()`](https://humlab-speech.github.io/pladdrr/reference/klattgrid_create_example.md)
  : Create example KlattGrid
- [`klattgrid_create_from_vowel()`](https://humlab-speech.github.io/pladdrr/reference/klattgrid_create_from_vowel.md)
  : Create KlattGrid from vowel parameters
- [`longsound_get_buffer_size_pref_seconds()`](https://humlab-speech.github.io/pladdrr/reference/longsound_get_buffer_size_pref_seconds.md)
  : Get the LongSound streaming buffer size preference
- [`longsound_open()`](https://humlab-speech.github.io/pladdrr/reference/longsound_open.md)
  : Open a LongSound from file
- [`longsound_set_buffer_size_pref_seconds()`](https://humlab-speech.github.io/pladdrr/reference/longsound_set_buffer_size_pref_seconds.md)
  : Set the LongSound streaming buffer size preference
- [`ltas_average()`](https://humlab-speech.github.io/pladdrr/reference/ltas_average.md)
  : Average multiple Ltas objects
- [`matrix_create()`](https://humlab-speech.github.io/pladdrr/reference/matrix_create.md)
  : Create a Praat Matrix with full parameters
- [`matrix_create_simple()`](https://humlab-speech.github.io/pladdrr/reference/matrix_create_simple.md)
  : Create a simple Praat Matrix
- [`matrix_read()`](https://humlab-speech.github.io/pladdrr/reference/matrix_read.md)
  : Read a Matrix from file
- [`mfccs_to_dtw()`](https://humlab-speech.github.io/pladdrr/reference/mfccs_to_dtw.md)
  : Create DTW from two MFCC objects
- [`multiband_hnr_stats()`](https://humlab-speech.github.io/pladdrr/reference/multiband_hnr_stats.md)
  : Query reusable multiband HNR statistics
- [`pair_files()`](https://humlab-speech.github.io/pladdrr/reference/pair_files.md)
  : Pair Sound and TextGrid Files
- [`pair_sound_textgrid()`](https://humlab-speech.github.io/pladdrr/reference/pair_sound_textgrid.md)
  : Pair Sound and TextGrid Files
- [`pca_from_matrix()`](https://humlab-speech.github.io/pladdrr/reference/pca_from_matrix.md)
  : Create PCA from data matrix
- [`pitches_to_dtw()`](https://humlab-speech.github.io/pladdrr/reference/pitches_to_dtw.md)
  : Create DTW from two Pitch objects
- [`pladdrr_simd()`](https://humlab-speech.github.io/pladdrr/reference/pladdrr_simd.md)
  : Get or set runtime SIMD usage
- [`pladdrr_threads()`](https://humlab-speech.github.io/pladdrr/reference/pladdrr_threads.md)
  : Control multi-threading of Praat analyses
- [`plot(`*`<Formant>`*`)`](https://humlab-speech.github.io/pladdrr/reference/plot.Formant.md)
  : Plot Formant Tracks
- [`plot(`*`<Harmonicity>`*`)`](https://humlab-speech.github.io/pladdrr/reference/plot.Harmonicity.md)
  : Plot Harmonicity (HNR) Contour
- [`plot(`*`<Intensity>`*`)`](https://humlab-speech.github.io/pladdrr/reference/plot.Intensity.md)
  : Plot Intensity Contour
- [`plot(`*`<Ltas>`*`)`](https://humlab-speech.github.io/pladdrr/reference/plot.Ltas.md)
  : Plot Long-Term Average Spectrum
- [`plot(`*`<Matrix>`*`)`](https://humlab-speech.github.io/pladdrr/reference/plot.Matrix.md)
  : Plot Matrix as Heatmap
- [`plot(`*`<Pitch>`*`)`](https://humlab-speech.github.io/pladdrr/reference/plot.Pitch.md)
  : Plot Pitch Contour
- [`plot(`*`<PointProcess>`*`)`](https://humlab-speech.github.io/pladdrr/reference/plot.PointProcess.md)
  : Plot PointProcess Events
- [`plot(`*`<PowerCepstrum>`*`)`](https://humlab-speech.github.io/pladdrr/reference/plot.PowerCepstrum.md)
  : Plot PowerCepstrum
- [`plot(`*`<Sound>`*`)`](https://humlab-speech.github.io/pladdrr/reference/plot.Sound.md)
  : Plot Sound Waveform
- [`plot(`*`<Spectrogram>`*`)`](https://humlab-speech.github.io/pladdrr/reference/plot.Spectrogram.md)
  : Plot Spectrogram Heatmap
- [`plot(`*`<Spectrum>`*`)`](https://humlab-speech.github.io/pladdrr/reference/plot.Spectrum.md)
  : Plot Spectrum
- [`plot(`*`<TextGrid>`*`)`](https://humlab-speech.github.io/pladdrr/reference/plot.TextGrid.md)
  : Plot TextGrid Annotations
- [`plot_cpp_timeseries()`](https://humlab-speech.github.io/pladdrr/reference/plot_cpp_timeseries.md)
  : Plot CPP Time Series
- [`plot_pitch_intensity()`](https://humlab-speech.github.io/pladdrr/reference/plot_pitch_intensity.md)
  : Plot Pitch and Intensity Together
- [`plot_powercepstrogram()`](https://humlab-speech.github.io/pladdrr/reference/plot_powercepstrogram.md)
  : Plot PowerCepstrogram
- [`plot_powercepstrum()`](https://humlab-speech.github.io/pladdrr/reference/plot_powercepstrum.md)
  : Plot PowerCepstrum
- [`plot_sound_pitch()`](https://humlab-speech.github.io/pladdrr/reference/plot_sound_pitch.md)
  : Plot Sound Waveform with Pitch Contour
- [`plot_spectrogram_formants()`](https://humlab-speech.github.io/pladdrr/reference/plot_spectrogram_formants.md)
  : Plot Spectrogram with Formant Overlay
- [`plot_spectrogram_pitch()`](https://humlab-speech.github.io/pladdrr/reference/plot_spectrogram_pitch.md)
  : Plot Spectrogram with Pitch Overlay
- [`plot_textgrid_pitch()`](https://humlab-speech.github.io/pladdrr/reference/plot_textgrid_pitch.md)
  : Plot TextGrid with Pitch Contour
- [`plot_textgrid_sound()`](https://humlab-speech.github.io/pladdrr/reference/plot_textgrid_sound.md)
  : Plot TextGrid with Sound Waveform
- [`plotting-combined`](https://humlab-speech.github.io/pladdrr/reference/plotting-combined.md)
  : Combined Visualization Functions
- [`plotting-methods`](https://humlab-speech.github.io/pladdrr/reference/plotting-methods.md)
  : S3 Plot Methods for pladdrr Objects
- [`pp_get_mean_period_direct()`](https://humlab-speech.github.io/pladdrr/reference/pp_get_mean_period_direct.md)
  : Get PointProcess Mean Period Directly (Bypass R6)
- [`pp_get_stdev_period_direct()`](https://humlab-speech.github.io/pladdrr/reference/pp_get_stdev_period_direct.md)
  : Get PointProcess Period Standard Deviation Directly (Bypass R6)
- [`praat_direct`](https://humlab-speech.github.io/pladdrr/reference/praat_direct.md)
  : Direct Function Dispatch API
- [`praat_eval_matrix()`](https://humlab-speech.github.io/pladdrr/reference/praat_eval_matrix.md)
  : Evaluate a matrix Praat expression
- [`praat_eval_numeric()`](https://humlab-speech.github.io/pladdrr/reference/praat_eval_numeric.md)
  : Evaluate a numeric Praat expression
- [`praat_eval_string()`](https://humlab-speech.github.io/pladdrr/reference/praat_eval_string.md)
  : Evaluate a string Praat expression
- [`praat_eval_string_array()`](https://humlab-speech.github.io/pladdrr/reference/praat_eval_string_array.md)
  : Evaluate a string array Praat expression
- [`praat_eval_vector()`](https://humlab-speech.github.io/pladdrr/reference/praat_eval_vector.md)
  : Evaluate a vector Praat expression
- [`praat_init()`](https://humlab-speech.github.io/pladdrr/reference/praat_init.md)
  : Initialize Praat interpreter
- [`praat_initialized()`](https://humlab-speech.github.io/pladdrr/reference/praat_initialized.md)
  : Check if Praat interpreter is initialized
- [`praat_list_objects()`](https://humlab-speech.github.io/pladdrr/reference/praat_list_objects.md)
  : List all objects in Praat object list
- [`praat_object_count()`](https://humlab-speech.github.io/pladdrr/reference/praat_object_count.md)
  : Get count of objects in Praat object list
- [`praat_run_script()`](https://humlab-speech.github.io/pladdrr/reference/praat_run_script.md)
  : Execute a Praat script
- [`praat_version()`](https://humlab-speech.github.io/pladdrr/reference/praat_version.md)
  : Get Praat version information
- [`print(`*`<fast_vector>`*`)`](https://humlab-speech.github.io/pladdrr/reference/print.fast_vector.md)
  : Print Method for Fast-Access Vectors
- [`print(`*`<praat_formant>`*`)`](https://humlab-speech.github.io/pladdrr/reference/print.praat_formant.md)
  : Print method for praat_formant objects
- [`print(`*`<praat_intensity>`*`)`](https://humlab-speech.github.io/pladdrr/reference/print.praat_intensity.md)
  : Print method for praat_intensity objects
- [`print(`*`<praat_pitch>`*`)`](https://humlab-speech.github.io/pladdrr/reference/print.praat_pitch.md)
  : Print method for praat_pitch objects
- [`print(`*`<praat_sound>`*`)`](https://humlab-speech.github.io/pladdrr/reference/print.praat_sound.md)
  : Print method for praat_sound objects
- [`print(`*`<zerocopy_vector>`*`)`](https://humlab-speech.github.io/pladdrr/reference/print.zerocopy_vector.md)
  : Print method for legacy zerocopy_vector class (deprecated)
- [`process_sounds_parallel()`](https://humlab-speech.github.io/pladdrr/reference/process_sounds_parallel.md)
  : Batch Process Sounds in Parallel
- [`read_sound()`](https://humlab-speech.github.io/pladdrr/reference/read_sound.md)
  : Read sound from audio file (DEPRECATED)
- [`set_textgrid_simd_enabled_bridge()`](https://humlab-speech.github.io/pladdrr/reference/set_textgrid_simd_enabled_bridge.md)
  : Enable/Disable SIMD for TextGrid Operations
- [`simd_info()`](https://humlab-speech.github.io/pladdrr/reference/simd_info.md)
  : Get SIMD Capabilities
- [`sound_as_matrix_fast()`](https://humlab-speech.github.io/pladdrr/reference/sound_as_matrix_fast.md)
  : Convert Sound to Matrix (Fast Copy)
- [`sound_auto_correlate()`](https://humlab-speech.github.io/pladdrr/reference/sound_auto_correlate.md)
  : Auto-correlate a sound with itself
- [`sound_concatenate_all()`](https://humlab-speech.github.io/pladdrr/reference/sound_concatenate_all.md)
  : Concatenate Multiple Sounds in Single C++ Call
- [`sound_create_pure_tone()`](https://humlab-speech.github.io/pladdrr/reference/sound_create_pure_tone.md)
  : Create a pure tone with fade in/out
- [`sound_create_tone()`](https://humlab-speech.github.io/pladdrr/reference/sound_create_tone.md)
  : Create a pure tone Sound
- [`sound_create_tone_complex()`](https://humlab-speech.github.io/pladdrr/reference/sound_create_tone_complex.md)
  : Create a tone complex (harmonic series)
- [`sound_deepen_band_modulation()`](https://humlab-speech.github.io/pladdrr/reference/sound_deepen_band_modulation.md)
  : Deepen band modulation (hearing enhancement)
- [`sound_extract_and_formant()`](https://humlab-speech.github.io/pladdrr/reference/sound_extract_and_formant.md)
  : Extract Parts and Analyze Formants in Single C++ Call
- [`sound_extract_and_pitch()`](https://humlab-speech.github.io/pladdrr/reference/sound_extract_and_pitch.md)
  : Extract Parts and Analyze Pitch in Single C++ Call
- [`sound_extract_part()`](https://humlab-speech.github.io/pladdrr/reference/sound_extract_part.md)
  : Extract part of Sound with optional windowing
- [`sound_extract_parts()`](https://humlab-speech.github.io/pladdrr/reference/sound_extract_parts.md)
  : Extract Multiple Parts from a Sound
- [`sound_extract_parts_pooled()`](https://humlab-speech.github.io/pladdrr/reference/sound_extract_parts_pooled.md)
  : Extract multiple Sound parts using object pool
- [`sound_filter_pass_hann_band()`](https://humlab-speech.github.io/pladdrr/reference/sound_filter_pass_hann_band.md)
  : Apply Hann band-pass filter
- [`sound_filter_stop_hann_band()`](https://humlab-speech.github.io/pladdrr/reference/sound_filter_stop_hann_band.md)
  : Apply Hann band-stop filter
- [`sound_from_values()`](https://humlab-speech.github.io/pladdrr/reference/sound_from_values.md)
  : Create Sound from numeric values
- [`sound_get_zcr()`](https://humlab-speech.github.io/pladdrr/reference/sound_get_zcr.md)
  : Calculate Zero Crossing Rate for Sound
- [`sound_lengthen()`](https://humlab-speech.github.io/pladdrr/reference/sound_lengthen.md)
  : Time-stretch a sound using overlap-add
- [`sound_load_window()`](https://humlab-speech.github.io/pladdrr/reference/sound_load_window.md)
  : Load Sound Window from File with Optional Resampling
- [`sound_max()`](https://humlab-speech.github.io/pladdrr/reference/sound_max.md)
  : Compute maximum amplitude
- [`sound_mean()`](https://humlab-speech.github.io/pladdrr/reference/sound_mean.md)
  : Compute mean amplitude
- [`sound_min()`](https://humlab-speech.github.io/pladdrr/reference/sound_min.md)
  : Compute minimum amplitude
- [`sound_pool_stats()`](https://humlab-speech.github.io/pladdrr/reference/sound_pool.md)
  [`sound_pool_clear()`](https://humlab-speech.github.io/pladdrr/reference/sound_pool.md)
  [`sound_pool_resize()`](https://humlab-speech.github.io/pladdrr/reference/sound_pool.md)
  : Sound Object Pool for Batch Processing
- [`sound_rms()`](https://humlab-speech.github.io/pladdrr/reference/sound_rms.md)
  : Compute RMS (root mean square) amplitude
- [`sound_statistics()`](https://humlab-speech.github.io/pladdrr/reference/sound_statistics.md)
  : Compute comprehensive sound statistics
- [`sound_times_fast()`](https://humlab-speech.github.io/pladdrr/reference/sound_times_fast.md)
  : Fast Sound Time Vector
- [`sound_to_formant_batch()`](https://humlab-speech.github.io/pladdrr/reference/sound_to_formant_batch.md)
  : Extract Formants from Multiple Sounds in Single C++ Call
- [`sound_to_intensity_batch()`](https://humlab-speech.github.io/pladdrr/reference/sound_to_intensity_batch.md)
  : Extract Intensity from Multiple Sounds in Single C++ Call
- [`sound_to_pitch_ac_batch()`](https://humlab-speech.github.io/pladdrr/reference/sound_to_pitch_ac_batch.md)
  : Extract Pitch (AC) from Multiple Sounds in Single C++ Call
- [`sound_to_pitch_batch()`](https://humlab-speech.github.io/pladdrr/reference/sound_to_pitch_batch.md)
  : Extract Pitch from Multiple Sounds in Single C++ Call
- [`sound_to_pitch_cc_batch()`](https://humlab-speech.github.io/pladdrr/reference/sound_to_pitch_cc_batch.md)
  : Extract Pitch (CC) from Multiple Sounds in Single C++ Call
- [`sound_to_pitch_shs_batch()`](https://humlab-speech.github.io/pladdrr/reference/sound_to_pitch_shs_batch.md)
  : Extract Pitch (SHS) from Multiple Sounds
- [`sound_to_pitch_spinet_batch()`](https://humlab-speech.github.io/pladdrr/reference/sound_to_pitch_spinet_batch.md)
  : Extract Pitch (SPINET) from Multiple Sounds
- [`sound_to_textgrid_silences()`](https://humlab-speech.github.io/pladdrr/reference/sound_to_textgrid_silences.md)
  : Detect Silences in Sound and Create TextGrid
- [`sound_values_fast()`](https://humlab-speech.github.io/pladdrr/reference/sound_values_fast.md)
  : Fast Sound Sample Access
- [`sounds_append()`](https://humlab-speech.github.io/pladdrr/reference/sounds_append.md)
  : Append two sounds with optional silence
- [`sounds_convolve()`](https://humlab-speech.github.io/pladdrr/reference/sounds_convolve.md)
  : Convolve two sounds
- [`sounds_cross_correlate()`](https://humlab-speech.github.io/pladdrr/reference/sounds_cross_correlate.md)
  : Cross-correlate two sounds
- [`sounds_to_dtw()`](https://humlab-speech.github.io/pladdrr/reference/sounds_to_dtw.md)
  : Create DTW from two Sound objects
- [`spectrograms_to_dtw()`](https://humlab-speech.github.io/pladdrr/reference/spectrograms_to_dtw.md)
  : Create DTW from two Spectrogram objects
- [`spectrum_cepstral_smoothing()`](https://humlab-speech.github.io/pladdrr/reference/spectrum_cepstral_smoothing.md)
  : Apply cepstral smoothing to spectrum
- [`spectrum_pass_hann_band()`](https://humlab-speech.github.io/pladdrr/reference/spectrum_pass_hann_band.md)
  : Apply Hann band-pass filter to spectrum (in-place)
- [`spectrum_stop_hann_band()`](https://humlab-speech.github.io/pladdrr/reference/spectrum_stop_hann_band.md)
  : Apply Hann band-stop filter to spectrum (in-place)
- [`summary(`*`<praat_formant>`*`)`](https://humlab-speech.github.io/pladdrr/reference/summary.praat_formant.md)
  : Summary method for praat_formant objects
- [`summary(`*`<praat_intensity>`*`)`](https://humlab-speech.github.io/pladdrr/reference/summary.praat_intensity.md)
  : Summary method for praat_intensity objects
- [`summary(`*`<praat_pitch>`*`)`](https://humlab-speech.github.io/pladdrr/reference/summary.praat_pitch.md)
  : Summary method for praat_pitch objects
- [`summary(`*`<praat_sound>`*`)`](https://humlab-speech.github.io/pladdrr/reference/summary.praat_sound.md)
  : Summary method for praat_sound objects
- [`table_create()`](https://humlab-speech.github.io/pladdrr/reference/table_create.md)
  : Create a Praat Table
- [`textgrid_create()`](https://humlab-speech.github.io/pladdrr/reference/textgrid_create.md)
  : Create TextGrid
- [`textgrid_extract_intervals_batch()`](https://humlab-speech.github.io/pladdrr/reference/textgrid_extract_intervals_batch.md)
  : Extract TextGrid Intervals by Label (Batch)
- [`textgrid_filter_xptr()`](https://humlab-speech.github.io/pladdrr/reference/textgrid_filter_xptr.md)
  : Extract TextGrid Intervals Using Custom XPtr Predicate
- [`textgrid_get_all_labels()`](https://humlab-speech.github.io/pladdrr/reference/textgrid_get_all_labels.md)
  : Get All Labels from TextGrid Tier (Batch)
- [`textgrid_get_intervals_where()`](https://humlab-speech.github.io/pladdrr/reference/textgrid_get_intervals_where.md)
  : Extract Intervals from TextGrid Matching Criteria
- [`textgrid_interval_all_features_batch()`](https://humlab-speech.github.io/pladdrr/reference/textgrid_interval_all_features_batch.md)
  : Extract All Acoustic Features for TextGrid Intervals (Batch, SIMD)
- [`textgrid_interval_formant_batch()`](https://humlab-speech.github.io/pladdrr/reference/textgrid_interval_formant_batch.md)
  : Extract Formant Statistics for All TextGrid Intervals (Batch, SIMD)
- [`textgrid_interval_intensity_batch()`](https://humlab-speech.github.io/pladdrr/reference/textgrid_interval_intensity_batch.md)
  : Extract Intensity Statistics for All TextGrid Intervals (Batch,
  SIMD)
- [`textgrid_interval_pitch_batch()`](https://humlab-speech.github.io/pladdrr/reference/textgrid_interval_pitch_batch.md)
  : Extract Pitch Statistics for All TextGrid Intervals (Batch, SIMD)
- [`textgrid_interval_statistics_batch()`](https://humlab-speech.github.io/pladdrr/reference/textgrid_interval_statistics_batch.md)
  : Compute Statistics for All Intervals (Batch, SIMD-Optimized)
- [`textgrid_merge()`](https://humlab-speech.github.io/pladdrr/reference/textgrid_merge.md)
  : Merge Multiple TextGrid Objects
- [`textgrid_simd_enabled()`](https://humlab-speech.github.io/pladdrr/reference/textgrid_simd_enabled.md)
  : Check if SIMD is Enabled for TextGrid
- [`to_formant_direct()`](https://humlab-speech.github.io/pladdrr/reference/to_formant_direct.md)
  : Create Formant from Sound Directly (returns XPtr)
- [`to_harmonicity_direct()`](https://humlab-speech.github.io/pladdrr/reference/to_harmonicity_direct.md)
  : Create Harmonicity from Sound Directly (returns XPtr)
- [`to_intensity_direct()`](https://humlab-speech.github.io/pladdrr/reference/to_intensity_direct.md)
  : Create Intensity from Sound Directly (returns XPtr)
- [`to_ltas_direct()`](https://humlab-speech.github.io/pladdrr/reference/to_ltas_direct.md)
  : Create LTAS from Sound Directly
- [`to_pitch_ac_direct()`](https://humlab-speech.github.io/pladdrr/reference/to_pitch_ac_direct.md)
  : Create Pitch from Sound Directly (Autocorrelation) - Full Parameters
- [`to_pitch_cc_direct()`](https://humlab-speech.github.io/pladdrr/reference/to_pitch_cc_direct.md)
  : Create Pitch from Sound Directly (Cross-Correlation) - Full
  Parameters
- [`to_pitch_direct()`](https://humlab-speech.github.io/pladdrr/reference/to_pitch_direct.md)
  : Create Pitch from Sound Directly (returns XPtr) - Basic Parameters
- [`to_pitch_shs_direct()`](https://humlab-speech.github.io/pladdrr/reference/to_pitch_shs_direct.md)
  : Create Pitch from Sound using Subharmonic Summation (SHS) Directly
  (returns XPtr)
- [`to_pitch_spinet_direct()`](https://humlab-speech.github.io/pladdrr/reference/to_pitch_spinet_direct.md)
  : Create Pitch from Sound using SPINET Directly (returns XPtr)
- [`to_point_process_direct()`](https://humlab-speech.github.io/pladdrr/reference/to_point_process_direct.md)
  : Create PointProcess from Sound Directly (returns XPtr)
- [`to_point_process_from_sound_and_pitch()`](https://humlab-speech.github.io/pladdrr/reference/to_point_process_from_sound_and_pitch.md)
  : Create PointProcess from Sound and Pitch (Cross-Correlation)
- [`to_powercepstrogram_fast()`](https://humlab-speech.github.io/pladdrr/reference/to_powercepstrogram_fast.md)
  : Fast PowerCepstrogram Creation (Advanced Performance API)
- [`to_spectrogram_direct()`](https://humlab-speech.github.io/pladdrr/reference/to_spectrogram_direct.md)
  : Create Spectrogram from Sound Directly (returns XPtr)
- [`to_spectrum_direct()`](https://humlab-speech.github.io/pladdrr/reference/to_spectrum_direct.md)
  : Create Spectrum from Sound Directly (returns XPtr)
- [`two_pass_adaptive_pitch()`](https://humlab-speech.github.io/pladdrr/reference/two_pass_adaptive_pitch.md)
  : Two-Pass Adaptive Pitch Extraction
- [`vad`](https://humlab-speech.github.io/pladdrr/reference/vad.md) :
  Voice Activity Detection Functions
- [`vocaltract_create_from_phone()`](https://humlab-speech.github.io/pladdrr/reference/vocaltract_create_from_phone.md)
  : Create VocalTract from phone
- [`with_pladdrr_errors()`](https://humlab-speech.github.io/pladdrr/reference/with_pladdrr_errors.md)
  : Run an expression, reclassifying tagged pladdrr C++ errors/warnings.
