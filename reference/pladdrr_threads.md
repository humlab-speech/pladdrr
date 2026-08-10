# Control multi-threading of Praat analyses

Praat's compute kernels (pitch, formant, spectrogram, CPPS, ...) run
multi-threaded by default, using all available processor cores. Use this
function to cap or disable threading, or to restore the default.

## Usage

``` r
pladdrr_threads(n = NULL)
```

## Arguments

- n:

  Maximum number of concurrent threads. Use \`1\` to disable threading,
  \`NULL\` (default) to leave the setting unchanged and just return the
  current state, or \`0\` to restore automatic mode (all cores).

## Value

Invisibly, a list describing the current state:

- processors:

  Number of logical cores detected.

- enabled:

  Whether multi-threading is enabled.

- max_threads:

  Effective maximum concurrent threads.

- min_elements_per_thread:

  Minimum work per thread; 0 means each analysis routine uses its own
  tuned threshold.

## Details

The package's own batch helpers (\`analyze_files_parallel()\`,
\`process_sounds_parallel()\`, \`batch_process()\`) already cap each
worker's threads automatically, so you only need this when running your
own parallel loop (e.g. a hand-written \`mclapply()\` where each worker
should stay single-threaded).

Threading never changes results: threads partition analysis frames and
each frame is computed exactly as in single-threaded mode.

## Examples

``` r
pladdrr_threads()      # query current state
pladdrr_threads(1)     # single-threaded (e.g. inside mclapply workers)
pladdrr_threads(0)     # back to automatic (all cores)
```
