#!/bin/bash
# Migrate from directory symlinks to individual file symlinks

set -e

echo "Removing directory symlinks..."
rm -f dwsys fon kar melder stat sys

echo "Creating directory structure..."
mkdir -p kar melder sys dwsys stat fon

echo "Creating individual file symlinks..."

# Kar
ln -sf ../praat.github.io/kar/longchar.cpp kar/longchar.cpp

# Melder
for file in melder.cpp melder_alloc.cpp melder_str32.cpp melder_colour.cpp \
            melder_ftoa.cpp melder_console.cpp melder_textencoding.cpp melder_atof.cpp \
            melder_files.cpp melder_sort.cpp melder_debug.cpp MelderString.cpp \
            melder_search.cpp melder_info.cpp melder_error.cpp melder_warning.cpp \
            melder_progress.cpp melder_play.cpp melder_help.cpp melder_time.cpp \
            melder_quantity.cpp MelderReadText.cpp melder_tensorio.cpp abcio.cpp \
            melder_sysenv.cpp regularExp.cpp NUMmath.cpp NUMspecfunc.cpp NUMear.cpp \
            NUMinterpol.cpp NUMmetrics.cpp NUMrandom.cpp NUMfilter.cpp NUMlinprog.cpp \
            NUM.cpp STR.cpp VEC.cpp MAT.cpp STRVEC.cpp MelderCat.cpp melder_casual.cpp \
            melder_app.cpp complex.cpp melder_trust.cpp; do
    ln -sf ../praat.github.io/melder/$file melder/$file
done

# Sys
for file in Thing.cpp Data.cpp Simple.cpp Collection.cpp Strings.cpp \
            Formula.cpp Interpreter.cpp Script.cpp; do
    ln -sf ../praat.github.io/sys/$file sys/$file
done

# Stat
for file in Table.cpp TableOfReal.cpp Distributions.cpp; do
    ln -sf ../praat.github.io/stat/$file stat/$file
done

# Fon (large list)
for file in Transition.cpp Distributions_and_Transition.cpp Function.cpp Sampled.cpp \
            SampledXY.cpp Matrix.cpp Vector.cpp Polygon.cpp PointProcess.cpp \
            Matrix_and_PointProcess.cpp Matrix_and_Polygon.cpp AnyTier.cpp RealTier.cpp \
            Sound.cpp PointProcess_and_Sound.cpp Sound_PointProcess.cpp ParamCurve.cpp \
            Pitch.cpp Harmonicity.cpp Intensity.cpp Matrix_and_Pitch.cpp \
            Sound_to_Pitch.cpp Sound_to_Intensity.cpp Sound_to_Harmonicity.cpp \
            Sound_to_Harmonicity_GNE.cpp Sound_to_PointProcess.cpp Pitch_to_PointProcess.cpp \
            Pitch_to_Sound.cpp Pitch_Intensity.cpp PitchTier.cpp Pitch_to_PitchTier.cpp \
            PitchTier_to_PointProcess.cpp PitchTier_to_Sound.cpp Manipulation.cpp \
            Pitch_AnyTier_to_PitchTier.cpp IntensityTier.cpp DurationTier.cpp \
            AmplitudeTier.cpp Spectrum.cpp Ltas.cpp Spectrogram.cpp SpectrumTier.cpp \
            Ltas_to_SpectrumTier.cpp Formant.cpp Image.cpp Sound_to_Formant.cpp \
            Sound_and_Spectrogram.cpp Sound_and_Spectrum.cpp Spectrum_and_Spectrogram.cpp \
            Spectrum_to_Formant.cpp FormantTier.cpp TextGrid.cpp TextGrid_Sound.cpp \
            Label.cpp FormantGrid.cpp Excitation.cpp Cochleagram.cpp \
            Cochleagram_and_Excitation.cpp Excitation_to_Formant.cpp Sound_to_Cochleagram.cpp \
            Spectrum_to_Excitation.cpp VocalTract.cpp VocalTract_to_Spectrum.cpp \
            Sound_enhance.cpp VoiceAnalysis.cpp; do
    ln -sf ../praat.github.io/fon/$file fon/$file
done

echo "Done! Now only specified files will be compiled."
echo "Total files that should be compiled:"
find . -name "*.cpp" -type l | wc -l
