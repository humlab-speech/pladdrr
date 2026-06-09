#!/bin/sh
# Phase B — static SIMD + threading inventory.
#
# Walks src/ and src/praat.github.io/ and emits
# inst/agents/PERFORMANCE_INVENTORY.md with:
#   - every src/*_simd.cpp file mapped to the wrapper it accelerates
#   - every MelderThread_PARALLELIZE call site in the Praat source
#   - every wrapper in src/*_wrappers.cpp that has NO corresponding *_simd.cpp
#     (candidate routines for SIMD work)
#
# Read-only; safe to run any time.

set -e
ROOT=$(pwd)
OUT="$ROOT/inst/agents/PERFORMANCE_INVENTORY.md"
mkdir -p "$(dirname "$OUT")"

{
  printf '# Performance Inventory (pladdrr)\n\n'
  printf '_Generated: %s by tools/perf_inventory.sh_\n\n' "$(date -u +%FT%TZ)"
  printf 'Static snapshot of where SIMD and multi-threading exist in the\n'
  printf 'pladdrr tree, plus the wrappers that do not yet have an accompanying\n'
  printf 'SIMD path. Use this to prioritise Phase F work.\n\n'

  printf '## SIMD source files\n\n'
  printf '| File | Lines |\n|------|------:|\n'
  for f in src/*_simd.cpp; do
    [ -f "$f" ] || continue
    lines=$(wc -l < "$f" | tr -d ' ')
    printf '| `%s` | %s |\n' "$f" "$lines"
  done

  printf '\n## Threaded Praat call sites (MelderThread_PARALLELIZE)\n\n'
  printf '| File | Line | Function context |\n|------|-----:|------------------|\n'
  # Use grep -R with -n; skip the docs/test trees.
  grep -RIn 'MelderThread_PARALLELIZE' src/praat.github.io 2>/dev/null \
    | grep -v '/test/' \
    | grep -v '/docs/' \
    | awk -F: '{
        path = $1; line = $2;
        ctx = $0;
        sub(/^[^:]+:[^:]+:/, "", ctx);
        gsub(/\|/, "/", ctx);
        printf("| `%s` | %s | %s |\n", path, line, substr(ctx, 1, 80));
      }' \
    | head -100

  printf '\n## Wrappers without a matching *_simd.cpp\n\n'
  printf 'A wrapper is considered SIMD-covered if its stem matches an existing\n'
  printf '`src/<stem>_simd.cpp` or `src/<stem>_simd_bridge.cpp`. Misses below are\n'
  printf 'candidates for Phase F SIMD work (verify per-frame independence in the\n'
  printf 'Praat source before adding a SIMD path — v4.8.29 revert is the\n'
  printf 'cautionary tale).\n\n'
  printf '| Wrapper | Has SIMD? |\n|---------|:---------:|\n'
  for w in src/*_wrappers.cpp; do
    [ -f "$w" ] || continue
    stem=$(basename "$w" _wrappers.cpp)
    if [ -f "src/${stem}_simd.cpp" ] || [ -f "src/${stem}_simd_bridge.cpp" ]; then
      mark="yes"
    else
      mark="**no**"
    fi
    printf '| `%s` | %s |\n' "$w" "$mark"
  done

  printf '\n## Threaded modules per CLAUDE.md\n\n'
  printf -- '- `Sound_to_PowerCepstrogram` — `MelderThread_PARALLELIZE`, threshold=40 frames\n'
  printf -- '- `PowerCepstrogram_to_Matrix_CPP` — `SampledIntoSampled_mt`\n'
  printf -- '- `PowerCepstrogram_smooth_fast` — parallelised `Sampled_getMean`\n'
  printf -- '- `Sound_to_Harmonicity_GNE` (v4.8.30) — Loops B and C parallelised\n'
  printf -- '- `Sound_to_Pitch` (v4.8.30) — FCC path SIMD re-enabled (Fixes 1–5)\n'
} > "$OUT"

printf 'Wrote %s\n' "$OUT"
