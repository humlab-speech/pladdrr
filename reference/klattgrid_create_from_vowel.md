# Create KlattGrid from vowel parameters

Creates a KlattGrid pre-configured for synthesizing a vowel sound with
specified formant frequencies and bandwidths.

## Usage

``` r
klattgrid_create_from_vowel(
  duration = 0.5,
  f0start = 100,
  f1 = 500,
  b1 = 50,
  f2 = 1500,
  b2 = 100,
  f3 = 2500,
  b3 = 150,
  f4 = 3500,
  bandWidthFraction = 0.05,
  formantFrequencyInterval = 1000
)

# Deprecated: use klattgrid_create_from_vowel() instead
```

## Arguments

- duration:

  Duration in seconds

- f0start:

  Starting F0 in Hz

- f1:

  First formant frequency in Hz

- b1:

  First formant bandwidth in Hz

- f2:

  Second formant frequency in Hz

- b2:

  Second formant bandwidth in Hz

- f3:

  Third formant frequency in Hz

- b3:

  Third formant bandwidth in Hz

- f4:

  Fourth formant frequency in Hz (optional)

- bandWidthFraction:

  Bandwidth as fraction of frequency (default 0.05)

- formantFrequencyInterval:

  Formant spacing interval in Hz (default 1000)

## Value

KlattGrid object configured for vowel

## Examples

``` r
kg <- klattgrid_create_from_vowel(duration = 0.3, f0start = 120)
sound <- kg$to_sound()
```
