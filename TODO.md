# TODO

## Decide CRAN submission strategy (blocks optimization flags)

The source tarball is ~52 MB — far past CRAN's ~5 MB limit — because it bundles
the full Praat source tree (`src/praat.github.io/`). This gates two decisions:

- **If CRAN is the target:** the vendored Praat source needs a different
  distribution strategy (e.g. system dependency, thinned tree, or a data
  package) before submission is possible. `Makevars` deliberately forgoes
  `-O3` / `-march=native` / `-flto` to respect CRAN policy.
- **If CRAN is NOT the target:** those optimization flags are a free
  performance win and can be enabled (validate against the faithfulness suite).

Related: global `-ffp-contract=off` could be scoped to only the order-sensitive
reduction kernels, speeding up everything else — but it touches output fidelity
(design goal #1), so it needs a measured decision against the faithfulness
suite, not a blind change.
