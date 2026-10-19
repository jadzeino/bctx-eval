#!/usr/bin/env bash
# run_coverage_audit.sh — Layer 1 of the equivalence eval (deterministic, no model, free).
#
# Independently derives the facts each compression mode PROMISES to keep (via Python `ast`,
# a TS export regex, and the raw git output itself) and asserts every one survives bctx's
# compressed output. Catches data loss at the source — including the exact class of bug
# (dropped `* main`) that bctx's fidelity metric did not flag.
#
#   usage:  ./fetch_corpora.sh && BCTX_BIN=/path/to/bctx ./run_coverage_audit.sh
#           (defaults to `bctx` on PATH)
#
# Exit code is non-zero if any UNEXPLAINED data loss is found, or if a target is missing.

set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN="${BCTX_BIN:-bctx}"

command -v "$BIN" >/dev/null 2>&1 || { echo "bctx not found on PATH (set BCTX_BIN=/path/to/bctx)"; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "python3 required"; exit 1; }

echo "=================================================================="
echo " bctx equivalence eval · Layer 1 · compressor coverage audit"
echo "=================================================================="
BCTX_BIN="$BIN" python3 "$HERE/coverage_audit.py"
