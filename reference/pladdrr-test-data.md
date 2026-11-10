# Data files shipped with pladdrr, and how the tests use them

The package ships a few small files so that the examples and the test
suite can be run, and any test result reproduced, by a user. Find them
with [`system.file()`](https://rdrr.io/r/base/system.file.html); none is
loaded into the session automatically.

## Details

- `system.file("extdata", "test.wav", package = "pladdrr")`: a
  one-second, 44.1 kHz recording used by the examples.

- `system.file("extdata", "test.TextGrid", package = "pladdrr")`: a
  small TextGrid used by the TextGrid examples and tests.

- `system.file("extdata", "benchmarkdata1min.TextGrid", package = "pladdrr")`:
  a one-minute TextGrid used for the batch-query benchmarks.

- `system.file("testdata", "speech_sample_pitch_reference.csv", package = "pladdrr")`:
  reference pitch values (time, frequency, strength) that the
  faithfulness tests compare against.

- `system.file("signalfiles", "DSI", "input", package = "pladdrr")`: the
  voice recordings of the Dysphonia Severity Index example.

Most tests need no file at all: they build their signals with
[`generate_sine_wave`](https://humlab-speech.github.io/pladdrr/reference/generate_sine_wave.md),
[`generate_noise`](https://humlab-speech.github.io/pladdrr/reference/generate_noise.md),
[`sound_create_pure_tone`](https://humlab-speech.github.io/pladdrr/reference/sound_create_pure_tone.md)
or
[`klattgrid_create_from_vowel`](https://humlab-speech.github.io/pladdrr/reference/klattgrid_create_from_vowel.md),
whose output is known exactly (a tone of given frequency and amplitude,
or a vowel with given formant targets). Those generators are exported so
that a user can recreate every synthetic test signal; the faithfulness
tests (`tests/testthat/test-praat-faithfulness.R`) compare pladdrr with
the Praat application on such signals and on `test.wav`.

## Value

No return value; this page only documents the shipped data files.

## See also

[`pladdrr-references`](https://humlab-speech.github.io/pladdrr/reference/pladdrr-references.md)

## Examples

``` r
file.exists(system.file("extdata", "test.wav", package = "pladdrr"))
#> [1] TRUE
```
