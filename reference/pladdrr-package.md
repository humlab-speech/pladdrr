# pladdrr: Direct Access to Praat's Core Algorithms from R

Praat's C/C++ engine, called directly from R via Rcpp. No external Praat
installation, no scripting layer, no shelling out. pladdrr links against
Praat's own analysis code, so results match Praat to within a tight
numerical tolerance, and covers most of what Praat can do: acoustic
analysis, voice quality, articulatory synthesis, annotation and
multivariate statistics.

## Acoustic Analysis

- **Sound**: read/write WAV, AIFF, FLAC, MP3, NIST; generate tones and
  noise; `LongSound` for streaming files too large to hold in memory

- **Pitch**: F0 contours, autocorrelation and cross-correlation methods,
  quality-aware tracking

- **Formant**: F1-F5 via LPC and Burg estimation, `FormantPath` for
  robust tracking, `FormantModeler`

- **Intensity, Harmonicity, Spectrum/Spectrogram, Ltas, Cepstrum**: the
  standard Praat contour and spectral objects

## Voice Quality

- CPPS (smoothed cepstral peak prominence) and AVQI (Acoustic Voice
  Quality Index), both parameter-matched to Praat

- Jitter, shimmer and HNR in a single batched call

- Voice activity detection

## Synthesis, Annotation and Multivariate Tools

- `Manipulation` (PSOLA resynthesis) and `KlattGrid` (formant synthesis)

- `TextGrid` for reading, writing and querying annotations

- `PCA`, `DTW` and `Discriminant` for multivariate and comparative
  analysis

- `PraatInterpreter` to run raw Praat scripts when you need something
  pladdrr doesn't wrap directly

## Performance

Batch queries (e.g. formants or pitch at many time points) run in a
single C++ call rather than one R-level call per point. The
CPPS/PowerCepstrogram path is multi-threaded via Praat's own
`MelderThread`, and
[`pladdrr_threads`](https://humlab-speech.github.io/pladdrr/reference/pladdrr_threads.md)
controls how many cores it uses.
[`simd_info`](https://humlab-speech.github.io/pladdrr/reference/simd_info.md)
reports whether the installed build is using SIMD kernels.

## Object Model

Objects are lightweight S3 lists (e.g. class
`c("Sound", "PraatObject")`) with a custom `$` method that dispatches to
a shared method table: this gives R6-style `sound$get_pitch()` call
syntax at a fraction of R6's per-object memory cost. `PraatInterpreter`
is a plain R6 class, since its state (a live Praat interpreter session)
doesn't fit the shared-table pattern.

## Undefined Values

Following R conventions, undefined analysis values (e.g. pitch in
unvoiced segments, formants in silence) are returned as `NA`. Quality
warnings are issued when a result may be unreliable, and can be
suppressed with the usual R warning-control mechanisms.

## Getting Started

[`vignette("getting-started", package = "pladdrr")`](https://humlab-speech.github.io/pladdrr/articles/getting-started.md)
is the place to start. Other vignettes worth knowing about:

- [`vignette("formant-analysis")`](https://humlab-speech.github.io/pladdrr/articles/formant-analysis.md) -
  formant tracking, including `FormantPath`

- [`vignette("speech-synthesis-klattgrid")`](https://humlab-speech.github.io/pladdrr/articles/speech-synthesis-klattgrid.md) -
  articulatory synthesis

- [`vignette("textgrid-workflows")`](https://humlab-speech.github.io/pladdrr/articles/textgrid-workflows.md) -
  reading and querying annotations

- [`vignette("performance-optimization")`](https://humlab-speech.github.io/pladdrr/articles/performance-optimization.md) -
  batching, threading, SIMD

- [`vignette("migration-from-praat")`](https://humlab-speech.github.io/pladdrr/articles/migration-from-praat.md)
  and
  [`vignette("migration-from-parselmouth")`](https://humlab-speech.github.io/pladdrr/articles/migration-from-parselmouth.md) -
  for those coming from Praat scripting or Python

## License and Attribution

pladdrr is licensed under GPL-3, compatible with Praat's own GPL-2+
license. Praat was created by Paul Boersma and David Weenink at the
Institute of Phonetic Sciences, University of Amsterdam, and its source
is bundled here under `src/praat.github.io/`.

Run `citation("pladdrr")` for up-to-date citation details for both
pladdrr and the bundled Praat version.

## See also

Useful links:

- <https://github.com/humlab-speech/pladdrr>

- <https://humlab-speech.github.io/pladdrr/>

- Report bugs at <https://github.com/humlab-speech/pladdrr/issues>

## Author

**Maintainer**: Fredrik Nylén <fredrik.nylen@umu.se>
([ORCID](https://orcid.org/0000-0003-3373-0934))

Authors:

- Fredrik Nylén <fredrik.nylen@umu.se>
  ([ORCID](https://orcid.org/0000-0003-3373-0934))

Other contributors:

- Paul Boersma (Author of the bundled Praat sources in
  src/praat.github.io) \[copyright holder\]

- David Weenink (Author of the bundled Praat sources in
  src/praat.github.io) \[copyright holder\]

- Max-Planck-Society (Copyright holder of the bundled pocketfft headers
  in src/pocketfft) \[copyright holder\]

- Xiph.Org Foundation (Copyright holder of the bundled Vorbis/Ogg and
  Opusfile sources) \[copyright holder\]

- Free Software Foundation (Copyright holder of the GNU Scientific
  Library, linked but not bundled) \[copyright holder\]
