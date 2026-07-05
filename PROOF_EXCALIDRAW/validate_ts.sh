#!/usr/bin/env bash
# validate_ts.sh — reproduce bctx's token savings on a real TypeScript codebase (excalidraw).
# Run it yourself; every number comes straight from the bctx binary on your machine.
#
#   usage:  BCTX_BIN=$(command -v bctx) ./validate_ts.sh [path-to-ts-dir]
#           (defaults to ../excalidraw/packages/element/src cloned next to this script)
#
# Pin for exact reproduction: the excalidraw clone must be at commit
#   51ca8abde450e44f8f0db1b2708e0408915c7ab1  (see USER_MANUAL.md step for the clone command).
#
# It prints three things:
#   1. SAVINGS BY MODE   — savings/fidelity spectrum (entropy = high fidelity,
#                          signatures = lossy outline), plus bctx's conservative 1-file summary
#   2. PER-FILE proof      — structural-outline reads of real .ts files (incl. an honest fallback)
#   3. EXECUTION mechanism — routed git output compressed + recorded into `bctx gain`
# For the SESSION-level wins (multi-file read, command output) run ./workflow_demo_ts.sh
#
# Nothing is cherry-picked: SAVINGS BY MODE scans the whole target dir and reports
# token-weighted averages. Signatures mode strips function *bodies* and keeps structure —
# ideal for the reading/understanding that dominates an agent's token spend, not for editing.

set -euo pipefail

BIN="${BCTX_BIN:-bctx}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="${1:-$HERE/../excalidraw/packages/element/src}"

command -v "$BIN" >/dev/null 2>&1 || { echo "bctx not found on PATH (set BCTX_BIN=/path/to/bctx)"; exit 1; }
[ -d "$TARGET" ] || { echo "target dir not found: $TARGET"; exit 1; }

echo "=================================================================="
echo " bctx savings validation (TypeScript)  ·  target: $TARGET"
echo "=================================================================="

echo
echo "1) SAVINGS BY MODE  (bctx benchmark — token-weighted over the whole dir)"
echo "   Each mode trades savings against FIDELITY = how much of the original content"
echo "   survives (bctx's identifier-coverage metric). Read both columns together."
echo "------------------------------------------------------------------"
"$BIN" benchmark "$TARGET" --json > /tmp/bctx_validate_ts.json 2>/dev/null
python3 - "$TARGET" <<'PY'
import json, statistics, sys
d=json.load(open('/tmp/bctx_validate_ts.json'))
def wsav(mode):
    b=sum(m['tokens_before'] for f in d['results'] for m in f['modes'] if m['mode']==mode)
    a=sum(m['tokens_after']  for f in d['results'] for m in f['modes'] if m['mode']==mode)
    return 100*(1-a/b) if b else 0.0
def fid(mode):
    q=[m['quality_pct'] for f in d['results'] for m in f['modes'] if m['mode']==mode]
    return statistics.mean(q) if q else 0.0
def zero(mode):
    return sum(1 for f in d['results'] for m in f['modes'] if m['mode']==mode and m['savings_pct']<5)
print("   files scanned : %d   total tokens : %d" % (d['files_scanned'], d['total_tokens']))
print("   %-30s%9s%10s" % ('MODE','SAVINGS','FIDELITY'))
print("   %-30s%8.0f%%%9.0f%%   <- keeps most content; use when you need bodies too" % ('entropy (high fidelity)', wsav('entropy'), fid('entropy')))
print("   %-30s%8.0f%%%9.0f%%   <- lossy: bodies dropped, for understanding/navigation" % ('signatures (structural outline)', wsav('signatures'), fid('signatures')))
print("   %-30s%8.0f%%%9.0f%%   <- conservative single-file tradeoff summary" % ('bctx 1-file auto-pick', d['avg_savings_pct'], d['avg_quality_pct']))
print("   honest note: %d of %d files fall back to ~0%% in signatures mode (barrel/type" % (zero('signatures'), d['files_scanned']))
print("                files + a few large ones the TS outline parser skips). The")
print("                token-weighted averages above already INCLUDE those files.")
print("   For the session numbers (multi-file read ~97%, command compression) run")
print("   ./workflow_demo_ts.sh")
PY

echo
echo "2) PER-FILE, structural-outline read  (bctx read --mode signatures: full API surface,"
echo "   bodies dropped — what an agent uses to UNDERSTAND a file before editing it)"
echo "   The last line is an HONEST fallback: some files don't compress in this mode."
echo "------------------------------------------------------------------"
for f in textElement.ts textWrapping.ts bounds.ts linearElementEditor.ts; do
  if [ -f "$TARGET/$f" ]; then
    line=$("$BIN" read "$TARGET/$f" --mode signatures 2>&1 >/dev/null || true)
    printf "   %-26s %s\n" "$f" "$line"
  fi
done

echo
echo "3) EXECUTION MECHANISM  (routed git output compressed + recorded to bctx gain)"
echo "------------------------------------------------------------------"
REPO_ROOT="$(cd "$TARGET" && git rev-parse --show-toplevel 2>/dev/null || echo "$TARGET")"
TMPHOME="$(mktemp -d)"
( cd "$REPO_ROOT" && HOME="$TMPHOME" "$BIN" git log -n 150 >/dev/null 2>&1 || true )
( cd "$REPO_ROOT" && HOME="$TMPHOME" "$BIN" git status >/dev/null 2>&1 || true )
# honest-accounting check: a no-compressor command must NOT pollute gain with a 0% row
( cd "$REPO_ROOT" && HOME="$TMPHOME" "$BIN" node -e "console.log('x'.repeat(50))" >/dev/null 2>&1 || true )
HOME="$TMPHOME" "$BIN" gain 2>/dev/null | sed 's/^/   /'
rm -rf "$TMPHOME"

echo
echo "Done. Per-file this shows the savings/fidelity spectrum; the real win is the SESSION —"
echo "run ./workflow_demo_ts.sh for the multi-file feature read (~97%) and command compression."
