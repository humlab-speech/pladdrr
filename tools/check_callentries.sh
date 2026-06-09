#!/bin/sh
# Verify src/RcppExports.cpp keeps the v4.8.32 patch:
# CallEntries[] must be `extern const` (not `static const`) so
# src/module_init.cpp can read it and build the combined registration table.
#
# If Rcpp::compileAttributes() regenerates RcppExports.cpp, this guard fails
# and the patch must be re-applied. See inst/agents/PRAAT_MODIFICATIONS.md v4.8.32.

set -e
F="src/RcppExports.cpp"
if [ ! -f "$F" ]; then
  echo "check_callentries: $F missing" >&2
  exit 1
fi
if grep -q '^static const R_CallMethodDef CallEntries\[\]' "$F"; then
  echo "check_callentries: FAIL — CallEntries is 'static const'; must be 'extern const'." >&2
  echo "  Re-apply the v4.8.32 patch (see inst/agents/PRAAT_MODIFICATIONS.md)." >&2
  exit 2
fi
if ! grep -q '^extern const R_CallMethodDef CallEntries\[\]' "$F"; then
  echo "check_callentries: FAIL — could not find 'extern const R_CallMethodDef CallEntries[]' in $F." >&2
  exit 3
fi
echo "check_callentries: OK"
