# bctx — token-savings evaluation

A reproducible evaluation of **bctx** (better-ctx), a context runtime for AI coding agents.
Every number here reproduces on your own machine with **bctx v0.1.31**.

## Start here
1. **`TO_EVALUATOR.md`** — the 2-minute orientation (and why an earlier test showed only
   `git`, now fixed).
2. **`USER_MANUAL.md`** — the guided walkthrough: install → verify → prove each saving → let
   Claude Code do a real task → check `bctx gain`. Exact commands, exact expected output.
3. **`COMMANDS_REFERENCE.md`** — the full capability catalog: every command, every lens mode,
   all 111 command compressors, all 41 agent skills, and how to extend/customize them.

## Install (any one — all deliver v0.1.31)
```bash
brew tap better-ctx-org/bctx && brew install better-ctx-org/bctx/bctx   # recommended on Mac
# or:  curl -fsSL https://betterctx.com/install.sh | sh
# or:  npm install -g bctx-bin
bctx --version   # must say: bctx 0.1.31
```

## Get the test codebases
The two evals run on public repos you clone yourself (not committed here).

**TypeScript — excalidraw (pinned, exact reproduction):**
```bash
git clone --filter=blob:none https://github.com/excalidraw/excalidraw.git
cd excalidraw && git checkout 51ca8abde450e44f8f0db1b2708e0408915c7ab1 && cd ..
```

**Python — FastAPI fixtures (for the `PROOF/` scripts):**
```bash
git clone --depth 1 https://github.com/fastapi/full-stack-fastapi-template.git
git clone --depth 1 https://github.com/fastapi/fastapi.git
```
> excalidraw is pinned, so its numbers match to the digit. The FastAPI fixtures track their
> latest `main`; the savings/fidelity *spectrum* reproduces, but exact per-file token counts
> may drift slightly as those repos change.

## Reproduce the headline numbers (~2 min each)
```bash
BCTX_BIN=$(command -v bctx) ./PROOF_EXCALIDRAW/validate_ts.sh        # TS spectrum
BCTX_BIN=$(command -v bctx) ./PROOF_EXCALIDRAW/workflow_demo_ts.sh   # TS feature read + command compression
BCTX_BIN=$(command -v bctx) ./PROOF/validate.sh                      # Python/FastAPI
```

## What's here
| Path | Contents |
|---|---|
| `USER_MANUAL.md` | Guided, testable walkthrough |
| `COMMANDS_REFERENCE.md` | Full command/skill/extensibility reference |
| `TO_EVALUATOR.md` | Orientation note |
| `VIDEO_SCRIPT.md` | 5-minute demo script |
| `PROOF_EXCALIDRAW/` | TypeScript proof (scripts, results, benchmark JSON) |
| `PROOF/` | Python/FastAPI proof |
| `RESULTS.json` | Machine-readable summary of both |

## Honesty
Every savings number is stated with its **fidelity** (how much content survives). Lossy
structural-outline numbers (~76–97%) are always labeled lossy (~20% fidelity) and never paired
with the high-fidelity (~89%) figure, which belongs to entropy mode (~34%). Code search is
framed as a relevance tool, not a token saving vs `grep`. No document/image compression is mentioned here as they are on different tier
