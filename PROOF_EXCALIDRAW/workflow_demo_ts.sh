#!/usr/bin/env bash
# workflow_demo_ts.sh — the token wins that `bctx benchmark` does NOT capture, on excalidraw.
#
# The benchmark only measures single-file structural compression. A real agent session saves
# far more through: (1) reading many files as one budgeted outline, (2) compressing noisy
# command output, (3) searching the code index for relevance instead of grepping, and
# (4) memory across turns. This script shows 1-3 with live numbers on the excalidraw repo.
#
#   usage:  BCTX_BIN=$(command -v bctx) ./workflow_demo_ts.sh [path-to-excalidraw-repo]
#
# Pin for exact reproduction: excalidraw @ 51ca8abde450e44f8f0db1b2708e0408915c7ab1

set -euo pipefail
BIN="${BCTX_BIN:-bctx}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="${1:-$HERE/../excalidraw}"
cd "$REPO"

echo "=================================================================="
echo " bctx workflow demo (TypeScript)  ·  $REPO"
echo " (the wins bctx benchmark does not measure)"
echo "=================================================================="

echo
echo "1) MULTI-FILE OUTLINE READ — understand the 'text element' feature"
echo "   An agent typically opens ~5 files to understand one feature. bctx signature"
echo "   outlines (what blueprint/chisel/parallax emit) vs the full files:"
echo "------------------------------------------------------------------"
FILES="packages/element/src/textElement.ts packages/element/src/textWrapping.ts packages/element/src/textMeasurements.ts packages/element/src/newElement.ts packages/element/src/bounds.ts"
sig_b=0; sig_a=0; ent_b=0; ent_a=0
for f in $FILES; do
  [ -f "$f" ] || continue
  sline=$("$BIN" read "$f" --mode signatures 2>&1 >/dev/null)
  sb=$(echo "$sline" | sed -n 's/.*bctx: \([0-9]*\) →.*/\1/p'); sa=$(echo "$sline" | sed -n 's/.*→ \([0-9]*\) tokens.*/\1/p')
  eline=$("$BIN" read "$f" --mode entropy 2>&1 >/dev/null)
  ea=$(echo "$eline" | sed -n 's/.*→ \([0-9]*\) tokens.*/\1/p')
  sig_b=$((sig_b + ${sb:-0})); sig_a=$((sig_a + ${sa:-0}))
  ent_b=$((ent_b + ${sb:-0})); ent_a=$((ent_a + ${ea:-0}))
  printf "   %-24s %6s -> sig %-5s  entropy %-5s\n" "${f##*/}" "${sb:-?}" "${sa:-?}" "${ea:-?}"
done
if [ "$sig_b" -gt 0 ]; then
  sp=$(python3 -c "print(f'{100*(1-$sig_a/$sig_b):.0f}')")
  ep=$(python3 -c "print(f'{100*(1-$ent_a/$ent_b):.0f}')")
  echo "   ----------------------------------------------------------------"
  printf "   %-24s %6s -> sig %-5s  entropy %-5s\n" "TOTAL (5 files)" "$sig_b" "$sig_a" "$ent_a"
  echo "   signatures (LOSSY outline, ~20% fidelity — structure only) : ${sp}% fewer tokens"
  echo "   entropy    (HIGH fidelity ~89% — keeps bodies)             : ${ep}% fewer tokens"
fi

echo
echo "2) COMMAND-OUTPUT COMPRESSION — noisy git commands (isolated HOME)"
echo "   The bigger/noisier the output, the more bctx strips. Recorded to bctx gain:"
echo "------------------------------------------------------------------"
export HOME="$(mktemp -d)"
"$BIN" git log -n 150 >/dev/null 2>/tmp/wdts.txt || true
"$BIN" git diff HEAD~40 HEAD >/dev/null 2>>/tmp/wdts.txt || true
grep -o '\[bctx:[^]]*\]' /tmp/wdts.txt | sed 's/^/   /' || true
"$BIN" gain 2>/dev/null | sed -n '2,9p' | sed 's/^/   /'

echo
echo "3) CODE SEARCH — ranked, symbol-aware locations across the WHOLE indexed repo"
echo "   NOTE: this is a RELEVANCE tool, not a token-savings tool. For a narrow literal"
echo "   string grep is smaller; bctx search wins when you know the concept, not the string."
echo "------------------------------------------------------------------"
"$BIN" index >/dev/null 2>&1 || true
echo "   query: \"text wrapping\"  (top 5, paths + relevance score)"
"$BIN" search "text wrapping" --top-k 5 2>/dev/null | grep -E '^\s+[0-9]+\.' | sed 's/^/  /' || echo "   (index/search unavailable)"

echo
echo "4) MEMORY (compounding win) — an agent calls the 'sediment' MCP tool on discovery,"
echo "   then 'bctx recall <query>' reads it back from the terminal (cross-process),"
echo "   so the NEXT session never re-reads the same files. See USER_MANUAL.md for the"
echo "   concrete sediment -> recall walkthrough."
echo
echo "Takeaway: benchmark measures ONE file. A session multiplies (1)+(2)+(3)+(4)."
