#!/usr/bin/env bash
# validate.sh — reproduce bctx's token savings on a real FastAPI/Python codebase.
# Run it yourself; every number below comes straight from the bctx binary on your machine.
#
#   usage:  ./validate.sh [path-to-python-repo]
#           (defaults to the full-stack-fastapi-template/backend cloned next to this script)
#
# It prints three things:
#   1. SAVINGS BY MODE   — the savings/fidelity spectrum (entropy = high fidelity,
#                          signatures = lossy outline), plus bctx's conservative 1-file summary
#   2. PER-FILE proof      — the structural-outline read of real route/model files
#   3. EXECUTION mechanism — routed command output compressed + recorded into `bctx gain`
# For the SESSION-level wins (multi-file, command output, search) run ./workflow_demo.sh
#
# Nothing here is cherry-picked: it scans your whole target dir and reports token-weighted
# averages. Signatures mode strips function *bodies* and keeps structure — ideal for the
# reading/understanding that dominates an agent's token spend, not for editing a file.

set -euo pipefail

BIN="${BCTX_BIN:-bctx}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="${1:-$HERE/../full-stack-fastapi-template/backend}"

command -v "$BIN" >/dev/null 2>&1 || { echo "bctx not found on PATH (set BCTX_BIN=/path/to/bctx)"; exit 1; }
[ -d "$TARGET" ] || { echo "target dir not found: $TARGET"; exit 1; }

echo "=================================================================="
echo " bctx savings validation  ·  target: $TARGET"
echo "=================================================================="

echo
echo "1) SAVINGS BY MODE  (bctx benchmark — token-weighted over the whole codebase)"
echo "   Each mode trades savings against FIDELITY = how much of the original content"
echo "   survives (bctx's identifier-coverage metric). Read both columns together."
echo "------------------------------------------------------------------"
"$BIN" benchmark "$TARGET" --json > /tmp/bctx_validate_bench.json 2>/dev/null
python3 - <<'PY'
import json, statistics
d=json.load(open('/tmp/bctx_validate_bench.json'))
def wsav(mode):
    b=sum(m['tokens_before'] for f in d['results'] for m in f['modes'] if m['mode']==mode)
    a=sum(m['tokens_after']  for f in d['results'] for m in f['modes'] if m['mode']==mode)
    return 100*(1-a/b) if b else 0.0
def fid(mode):
    q=[m['quality_pct'] for f in d['results'] for m in f['modes'] if m['mode']==mode]
    return statistics.mean(q) if q else 0.0
print(f"   files scanned : {d['files_scanned']}   total tokens : {d['total_tokens']}")
print(f"   {'MODE':<30}{'SAVINGS':>9}{'FIDELITY':>10}")
print(f"   {'entropy (high fidelity)':<30}{wsav('entropy'):>8.0f}%{fid('entropy'):>9.0f}%   <- keeps most content; use when you need bodies too")
print(f"   {'signatures (structural outline)':<30}{wsav('signatures'):>8.0f}%{fid('signatures'):>9.0f}%   <- lossy: bodies dropped, for understanding/navigation")
print(f"   {'bctx 1-file auto-pick':<30}{d['avg_savings_pct']:>8.0f}%{d['avg_quality_pct']:>9.0f}%   <- conservative single-file tradeoff summary")
print("   NOTE: a single file understates it. Run ./workflow_demo.sh for the session")
print("         numbers (multi-file outline ~85%, command compression, code search).")
PY

echo
echo "2) PER-FILE, structural-outline read  (bctx read --mode signatures: full API surface,"
echo "   bodies dropped — what an agent uses to UNDERSTAND a file before editing it)"
echo "------------------------------------------------------------------"
for f in app/api/routes/users.py app/models.py app/crud.py; do
  if [ -f "$TARGET/$f" ]; then
    line=$("$BIN" read "$TARGET/$f" --mode signatures 2>&1 >/dev/null || true)
    printf "   %-32s %s\n" "$f" "$line"
  fi
done

echo
echo "3) EXECUTION MECHANISM  (routed command output compressed + recorded)"
echo "------------------------------------------------------------------"
TMPHOME="$(mktemp -d)"
( cd "$TARGET" && HOME="$TMPHOME" "$BIN" git log -n 25 >/dev/null 2>&1 || true )
( cd "$TARGET" && HOME="$TMPHOME" "$BIN" git status >/dev/null 2>&1 || true )
# honest-accounting check: a bare python execution must NOT pollute gain with a 0% row
( cd "$TARGET" && HOME="$TMPHOME" "$BIN" python3 -c "print('hello'*20)" >/dev/null 2>&1 || true )
HOME="$TMPHOME" "$BIN" gain 2>/dev/null | sed 's/^/   /'
rm -rf "$TMPHOME"

echo
echo "Done. Per-file this shows the savings/fidelity spectrum; the real win is the SESSION —"
echo "run ./workflow_demo.sh for multi-file reads (~85%), command compression, and code search."
