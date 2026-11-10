# G5.2b: constructors refuse to build an object without the pointer or inputs
# it needs, and say which factory function to use instead.

test_that("class constructors called without inputs name the factory to use", {
  expect_error(AmplitudeTier(), "AmplitudeTier objects must be created using", fixed = TRUE)
  expect_error(BarkSpectrogram(), "BarkSpectrogram objects must be created from", fixed = TRUE)
  expect_error(Cochleagram(), "Cochleagram objects should be created via", fixed = TRUE)
  expect_error(Discriminant(), "Discriminant objects must be created using", fixed = TRUE)
  expect_error(DTW(), "DTW objects must be created via", fixed = TRUE)
  expect_error(Excitation(), "Excitation objects should be created via", fixed = TRUE)
  expect_error(Formant(), "Formant objects must be created from a Sound", fixed = TRUE)
  expect_error(FormantModeler(), "FormantModeler objects must be created from a Formant", fixed = TRUE)
  expect_error(Harmonicity(), "Harmonicity objects should be created from Sound", fixed = TRUE)
  expect_error(Intensity(), "Intensity objects should be created from Sound", fixed = TRUE)
  expect_error(LPC(), "LPC objects must be created from a Sound", fixed = TRUE)
  expect_error(LFCC(), "LFCC objects must be created from an LPC", fixed = TRUE)
  expect_error(Ltas(), "Ltas objects must be created from a Sound or Spectrum", fixed = TRUE)
  expect_error(Manipulation(), "Manipulation objects must be created from a Sound", fixed = TRUE)
  expect_error(MelSpectrogram(), "MelSpectrogram objects must be created from", fixed = TRUE)
  expect_error(MFCC(), "MFCC objects must be created from a Sound", fixed = TRUE)
  expect_error(PCA(), "PCA objects must be created using", fixed = TRUE)
  expect_error(PitchModule(), "Pitch objects must be created from Sound$to_pitch()", fixed = TRUE)
  expect_error(Pitch(), "Pitch objects must be created from a Sound object using", fixed = TRUE)
  expect_error(PointProcess(), "PointProcess objects must be created from a Sound or Pitch", fixed = TRUE)
  expect_error(Spectrogram(), "Spectrogram objects must be created from", fixed = TRUE)
  expect_error(Spectrum(), "Spectrum objects must be created from Sound", fixed = TRUE)
  expect_error(SpectrumTier(), "SpectrumTier objects must be created from an Ltas", fixed = TRUE)
})

test_that("constructors that take either bounds, a path or a pointer say what is missing", {
  expect_error(DurationTier(), "DurationTier(): Must provide either (tmin, tmax) or .xptr", fixed = TRUE)
  expect_error(IntensityTier(), "IntensityTier(): Must provide either (tmin, tmax) or .xptr", fixed = TRUE)
  expect_error(PitchTier(), "PitchTier(): Must provide either (tmin, tmax) or .xptr", fixed = TRUE)
  expect_error(Sound(), "Sound(): Must provide either path or .xptr", fixed = TRUE)
  expect_error(TextGrid(), "TextGrid(): Must provide either path or .xptr", fixed = TRUE)
  expect_error(Matrix(), "Either provide (numberOfRows, numberOfColumns)", fixed = TRUE)
})

test_that("pointer-wrapping constructors require an external pointer", {
  expect_error(Cepstrum(.xptr = 1), "Cepstrum(): .xptr must be an external pointer", fixed = TRUE)
  expect_error(PowerCepstrum(.xptr = 1), "PowerCepstrum(): .xptr must be an external pointer", fixed = TRUE)
  expect_error(PowerCepstrogram(.xptr = 1), "PowerCepstrogram(): .xptr must be an external pointer", fixed = TRUE)
})

test_that("Polygon, ComplexSpectrogram, PCA and Discriminant check their inputs", {
  expect_error(Polygon(x = 1), "Both x and y coordinates required", fixed = TRUE)
  expect_error(Polygon(x = 1:2, y = 1), "x and y must have same length", fixed = TRUE)
  expect_error(ComplexSpectrogram(1), "First argument must be a Sound object", fixed = TRUE)
  expect_error(pca_from_matrix(matrix(1:3, 1)), "Need at least 2 observations", fixed = TRUE)
  expect_error(pca_from_matrix(matrix(1:3, 3)), "Need at least 2 variables", fixed = TRUE)
  expect_error(discriminant_from_matrix(matrix(numeric(0), 4, 0), c("a", "a", "b", "b")),
               "Need at least 1 variable", fixed = TRUE)
})
