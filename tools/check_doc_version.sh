#!/bin/sh
# Verify inst/agents/AGENT_GUIDE.md and inst/agents/PRAAT_MODIFICATIONS.md
# carry a Version header that is >= DESCRIPTION's Version.
#
# Design principle 5: AGENT_GUIDE is the canonical re-implementation reference;
# if the code ships ahead of the doc, agents get stale guidance.

set -e

DESC_VER=$(grep -E '^Version:' DESCRIPTION | head -n1 | awk '{print $2}')
if [ -z "$DESC_VER" ]; then
  echo "check_doc_version: cannot read DESCRIPTION Version" >&2
  exit 1
fi

# AGENT_GUIDE: "**Version:** X.Y.Z"
GUIDE_VER=$(grep -m1 -E '^\*\*Version:\*\*' inst/agents/AGENT_GUIDE.md 2>/dev/null | sed -E 's/.*\*\*Version:\*\*[[:space:]]+([0-9.]+).*/\1/')

# PRAAT_MODIFICATIONS: "**Package Version:** X.Y.Z"
MODS_VER=$(grep -m1 -E '^\*\*Package Version:\*\*' inst/agents/PRAAT_MODIFICATIONS.md 2>/dev/null | sed -E 's/.*\*\*Package Version:\*\*[[:space:]]+([0-9.]+).*/\1/')

fail=0
ver_lt() {
  # returns 0 if $1 < $2 (using dotted version compare)
  [ "$1" = "$2" ] && return 1
  smaller=$(printf '%s\n%s\n' "$1" "$2" | sort -V | head -n1)
  [ "$smaller" = "$1" ]
}

if [ -z "$GUIDE_VER" ]; then
  echo "check_doc_version: WARN — AGENT_GUIDE.md has no '**Version:**' header" >&2
elif ver_lt "$GUIDE_VER" "$DESC_VER"; then
  echo "check_doc_version: FAIL — AGENT_GUIDE.md=$GUIDE_VER < DESCRIPTION=$DESC_VER" >&2
  fail=1
fi

if [ -z "$MODS_VER" ]; then
  echo "check_doc_version: WARN — PRAAT_MODIFICATIONS.md has no '**Package Version:**' header" >&2
elif ver_lt "$MODS_VER" "$DESC_VER"; then
  echo "check_doc_version: FAIL — PRAAT_MODIFICATIONS.md=$MODS_VER < DESCRIPTION=$DESC_VER" >&2
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "check_doc_version: OK (DESCRIPTION=$DESC_VER, AGENT_GUIDE=$GUIDE_VER, PRAAT_MODIFICATIONS=$MODS_VER)"
fi
exit $fail
