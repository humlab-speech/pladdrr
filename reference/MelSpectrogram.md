# MelSpectrogram Object

Praat MelSpectrogram: mel-scale spectrogram commonly used in speech
technology (ASR, speaker identification).

## Usage

``` r
MelSpectrogram(.xptr = NULL)
```

## Arguments

- .xptr:

  Internal use only - external pointer to C++ MelSpectrogram object

## Value

A MelSpectrogram object

## Examples

``` r
snd <- Sound$create_tone(frequency = 150, duration = 0.3)
mel <- snd$to_mel_spectrogram()

# Convert to MFCC
mfcc <- mel$to_mfcc(number_of_coefficients = 12)

# Export as matrix
mat <- mel$as_matrix()
```
