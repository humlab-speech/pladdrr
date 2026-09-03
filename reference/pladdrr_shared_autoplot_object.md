# Shared parameter docs for the dispatch object in autoplot.\* methods

All `autoplot.*` methods share a single `@rdname` (and thus one merged
Rd topic), so per-type `@param object` text collapses to whichever block
roxygen2 resolves last; a shared, type-neutral description avoids that
silent collision.

## Usage

``` r
pladdrr_shared_autoplot_object(object = NULL)
```

## Arguments

- object:

  A pladdrr S3 analysis object (Sound, Pitch, Formant, Intensity,
  Spectrogram, Spectrum, Ltas, Harmonicity, PointProcess, PowerCepstrum,
  or TextGrid)
