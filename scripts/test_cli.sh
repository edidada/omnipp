#!/usr/bin/env bash
# Tests the 'ogrep' CLI (built from omnipp). The binary must be available on
# PATH -- this script is intentionally independent of any build directory layout.
set -euo pipefail

# Resolve ogrep from PATH so the test is not coupled to a specific build path.
BIN="$(command -v ogrep 2>/dev/null || true)"
if [ -z "$BIN" ]; then
  echo "ERROR: 'ogrep' not found on PATH. Build it first and put it on PATH." >&2
  exit 1
fi
echo "Using CLI: $BIN"

# Sanity: empty invocation should print the tool banner.
BANNER="$("$BIN" 2>/dev/null || true)"
if [ "$BANNER" != "omnipp" ]; then
  echo "WARN: empty-invocation banner was '$BANNER' (expected 'omnipp')"
fi

# Prepare a sample directory with known content.
SAMPLE="$(mktemp -d)"
trap 'rm -rf "$SAMPLE"' EXIT
cat > "$SAMPLE/sample.cpp" <<'SAMPLEEOF'
struct foo {
    int x;
};

class bar {};

struct point {
    double x, y;
};
SAMPLEEOF

# Run ogrep: search for struct definitions (multiline ^ matches line starts).
OUT="$("$BIN" '^\s*struct\s+[a-z_]+\s*{' "$SAMPLE")"
echo "----- ogrep output -----"
echo "$OUT"
echo "------------------------"

rc=0

if echo "$OUT" | grep -q 'struct foo'; then
  echo "PASS: found 'struct foo'"
else
  echo "FAIL: did not find 'struct foo'" >&2
  rc=1
fi

if echo "$OUT" | grep -q 'struct point'; then
  echo "PASS: found 'struct point'"
else
  echo "FAIL: did not find 'struct point'" >&2
  rc=1
fi

if echo "$OUT" | grep -q 'class bar'; then
  echo "FAIL: incorrectly matched 'class bar'" >&2
  rc=1
else
  echo "PASS: correctly ignored 'class bar'"
fi

if [ "$rc" -eq 0 ]; then
  echo "ALL TESTS PASSED"
else
  echo "SOME TESTS FAILED" >&2
fi
exit "$rc"
