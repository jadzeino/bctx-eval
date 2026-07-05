#!/usr/bin/env bash
# workflow_demo.sh — demonstrate the token wins that `bctx benchmark` does NOT capture.
#
# The benchmark only measures single-file structural compression. A real agent session
# saves far more through: (1) reading many files as one budgeted outline, (2) compressing
# noisy command output, (3) searching the code index instead of dumping grep, and
# (4) memory across turns. This script shows 1-3 with live numbers on your repo.
#
#   usage:  BCTX_BIN=$(command -v bctx) ./workflow_demo.sh [path-to-fastapi-backend]

set -euo pipefail
BIN="${BCTX_BIN:-bctx}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP="${1:-$HERE/../full-stack-fastapi-template/backend}"
cd "$APP"

echo "=================================================================="
echo " bctx workflow demo  ·  $APP"
echo " (the wins bctx benchmark does not measure)"
echo "=================================================================="

echo
echo "1) MULTI-FILE OUTLINE READ — understand the 'users' feature"
echo "   An agent typically opens ~5 files to understand one feature. Full reads vs"
echo "   bctx signature outlines (blueprint/chisel/parallax emit exactly this):"
echo "------------------------------------------------------------------"
FILES="app/api/routes/users.py app/models.py app/crud.py app/api/deps.py app/core/security.py"
full_total=0; out_total=0
for f in $FILES; do
  [ -f "$f" ] || continue
  full=$("$BIN" read "$f" --mode full 2>/dev/null | python3 -c "import sys; print(len(sys.stdin.read())//4)")
  line=$("$BIN" read "$f" --mode signatures 2>&1 >/dev/null)
  after=$(echo "$line" | sed -n 's/.*→ \([0-9]*\) tokens.*/\1/p')
  before=$(echo "$line" | sed -n 's/.*bctx: \([0-9]*\) →.*/\1/p')
  full_total=$((full_total + ${before:-0}))
  out_total=$((out_total + ${after:-0}))
  printf "   %-32s %6s -> %-5s tokens\n" "$f" "${before:-?}" "${after:-?}"
done
if [ "$full_total" -gt 0 ]; then
  pct=$(python3 -c "print(f'{100*(1-$out_total/$full_total):.0f}')")
  echo "   ----------------------------------------------------------------"
  printf "   %-32s %6s -> %-5s tokens   (%s%% fewer to understand the feature)\n" "TOTAL (5 files)" "$full_total" "$out_total" "$pct"
fi

echo
echo "2) COMMAND-OUTPUT COMPRESSION — noisy dev commands (isolated HOME)"
echo "   The bigger/noisier the output, the more bctx strips. Recorded to bctx gain:"
echo "------------------------------------------------------------------"
export HOME="$(mktemp -d)"
"$BIN" git log -n 40 >/dev/null 2>/tmp/wd_c.txt || true
"$BIN" git diff HEAD >/dev/null 2>>/tmp/wd_c.txt || true
if command -v pip3 >/dev/null; then "$BIN" pip3 install --dry-run fastapi >/dev/null 2>>/tmp/wd_c.txt || true; fi
grep -o '\[bctx:[^]]*\]' /tmp/wd_c.txt | sed 's/^/   /' || true
"$BIN" gain 2>/dev/null | sed -n '2,8p' | sed 's/^/   /'

echo
echo "3) CODE SEARCH INSTEAD OF GREP — ranked locations, not a raw dump"
echo "------------------------------------------------------------------"
"$BIN" index >/dev/null 2>&1 || true
echo "   query: \"password hashing\""
"$BIN" search "password hashing" 2>/dev/null | head -6 | sed 's/^/   /' || echo "   (index/search unavailable)"

echo
echo "4) MEMORY (in-session, via MCP) — not shown here because sediment/archivist run"
echo "   inside the agent, but this is the compounding win: the agent calls archivist at"
echo "   task start and sediment on discovery, so it never re-reads the same files across"
echo "   turns. 'bctx recall <query>' queries the same Vault from the CLI."
echo
echo "Takeaway: benchmark measures ONE file. A session multiplies (1)+(2)+(3)+(4)."
