#!/bin/sh
# Ensure src/RcppExports.cpp keeps the v4.8.32 patch:
# CallEntries[] must be `extern const` (not `static const`) so
# src/module_init.cpp can read it and build the combined registration table.
#
# Rcpp::compileAttributes() regenerates RcppExports.cpp with `static` every
# time it's re-run. This script self-heals: it patches `static` back to
# `extern` in place before the build compiles the file, so the fix survives
# regeneration without manual intervention. See inst/agents/PRAAT_MODIFICATIONS.md v4.8.32.

set -e
F="src/RcppExports.cpp"
if [ ! -f "$F" ]; then
  echo "check_callentries: $F missing" >&2
  exit 1
fi

if grep -q '^static const R_CallMethodDef CallEntries\[\]' "$F"; then
  echo "check_callentries: 'static' CallEntries found — auto-patching to 'extern'..."
  sed -i.bak 's/^static const R_CallMethodDef CallEntries\[\]/extern const R_CallMethodDef CallEntries[]/' "$F"
  rm -f "$F.bak"
fi

if ! grep -q '^extern const R_CallMethodDef CallEntries\[\]' "$F"; then
  echo "check_callentries: FAIL — could not find 'extern const R_CallMethodDef CallEntries[]' in $F." >&2
  echo "  CallEntries[] declaration shape changed; the v4.8.32 patch needs manual review." >&2
  exit 3
fi

echo "check_callentries: OK"
