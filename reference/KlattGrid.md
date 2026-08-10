# Create a KlattGrid object

A KlattGrid is a speech synthesizer based on the Klatt formant
synthesizer. It allows detailed control over phonation, vocal tract
resonances, frication, and other articulatory parameters.

## Arguments

- tmin:

  Start time in seconds

- tmax:

  End time in seconds

- numberOfFormants:

  Number of oral formants (typically 6)

- numberOfNasalFormants:

  Number of nasal formants (typically 1)

- numberOfNasalAntiFormants:

  Number of nasal antiformants (typically 1)

- numberOfTrachealFormants:

  Number of tracheal formants (typically 1)

- numberOfTrachealAntiFormants:

  Number of tracheal antiformants (typically 1)

- numberOfFricationFormants:

  Number of frication formants (typically 6)

- numberOfDeltaFormants:

  Number of delta formants (typically 1)

## Value

KlattGrid object with S3 class

## Examples

``` r
# \donttest{
# Create empty KlattGrid
kg <- KlattGrid(0, 1, numberOfFormants = 6)

# Set pitch contour and voicing amplitude (both required for synthesis)
kg$add_pitch_point(0.5, 100)      # 100 Hz at 0.5s
kg$add_voicing_amplitude_point(0.5, 90)

# Set oral formant frequencies (formantType 1 = ORAL)
kg$add_formant_point(1, 1, 0.5, 500)  # F1 = 500 Hz
kg$add_formant_point(1, 2, 0.5, 1500) # F2 = 1500 Hz

# Synthesize
sound <- kg$to_sound()
# }
```
