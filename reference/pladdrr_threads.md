# Control multi-threading of Praat analyses

Praat's compute kernels (pitch, formant, spectrogram, CPPS, ...) run
multi-threaded by default, using every CPU the process may actually use.
Use this function to cap or disable threading, or to restore the
default.

## Usage

``` r
pladdrr_threads(n = NULL)
```

## Arguments

- n:

  Maximum number of concurrent threads. Use `1` to disable threading,
  `NULL` (default) to leave the setting unchanged and just return the
  current state, or `0` to restore automatic mode (all CPUs this process
  may use). An explicit `n` always wins over the automatic count.

## Value

Invisibly, a list describing the current state:

- processors:

  Number of CPUs this process may use (see Details).

- enabled:

  Whether multi-threading is enabled.

- max_threads:

  Effective maximum concurrent threads.

- min_elements_per_thread:

  Minimum work per thread; 0 means each analysis routine uses its own
  tuned threshold.

## Details

"Every CPU the process may use" is narrower than the machine's core
count wherever the process is confined: on Linux the automatic count is
the CPU affinity mask (container cpusets, `taskset(1)`, SLURM
allocations) intersected with the cgroup CPU quota visible to the
process (`/sys/fs/cgroup/cpu.max`, or cgroup v1 `cpu.cfs_quota_us` /
`cpu.cfs_period_us` — what `docker --cpus` sets). A quota placed on an
ancestor cgroup is not readable from inside the process's own cgroup
view and is therefore not subtracted. Where the platform exposes neither
mask nor quota (Windows, macOS), it is the number of logical cores.
Sizing the pool from the machine instead would leave threads with no CPU
to run on, which costs both time and energy. When the environment
variable `_R_CHECK_LIMIT_CORES_` is set to anything but `false` (as
`R CMD check --as-cran` does), the automatic default is capped at two
threads, the same limit `parallel` applies; an explicit `n` still wins.

The package's own batch helpers
([`analyze_files_parallel()`](https://humlab-speech.github.io/pladdrr/reference/analyze_files_parallel.md),
[`process_sounds_parallel()`](https://humlab-speech.github.io/pladdrr/reference/process_sounds_parallel.md),
[`batch_process()`](https://humlab-speech.github.io/pladdrr/reference/batch_process.md))
already cap each worker's threads automatically, so you only need this
when running your own parallel loop (e.g. a hand-written `mclapply()`
where each worker should stay single-threaded).

Threading never changes results: threads partition analysis frames and
each frame is computed exactly as in single-threaded mode.

## Examples

``` r
pladdrr_threads()      # query current state
pladdrr_threads(1)     # single-threaded (e.g. inside mclapply workers)
pladdrr_threads(0)     # back to automatic (all usable CPUs)
```
