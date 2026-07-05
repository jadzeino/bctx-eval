Subject: bctx — the whole product, reproducible, in two languages (with an install→verify manual)

Hi,

Your first look at bctx showed savings only on `git`. That was a setup/coverage gap, not a
capability gap — I found it, fixed it, shipped it (v0.1.31), and this package proves the whole
product with numbers you can reproduce end to end. I've deliberately built it so a non-expert
can run every step; the honesty is the point, so I've labeled every trade-off.

**Start here: `../USER_MANUAL.md`** (one level up from this folder). It takes you from a clean
Mac through install → verify → seeing each saving → letting Claude Code do a real task → the
savings report. Copy-paste commands, exact expected output per step, troubleshooting. It runs
on **excalidraw** (TypeScript), pinned to one commit so every number matches to the digit.

**bctx is a whole product, not one trick. What the package proves:**
1. **Automatic command-output compression.** The agent runs `git`/`npm`/tests; bctx compresses
   the output. On excalidraw: `git log -n 150` = **98%** (29343→599), `git diff HEAD~40 HEAD`
   = **99%** (~189K→~1.9K). 111 tool families covered.
2. **Source-file compression** via MCP skills the agent actually uses (the Golden Workflow that
   `bctx init` now installs steers `blueprint`/`chisel`/`parallax` over full reads).
3. **Code search** (`compass`/`scanner`) — ranked, symbol-aware. *Relevance*, not a token
   claim (I'm explicit about that in the manual).
4. **Memory** — the agent stores facts via `sediment`; `bctx recall` reads them back from the
   terminal, cross-process. Demonstrated concretely, not hand-waved.
5. **Savings reporting** — `bctx gain` / `bctx dashboard`.

**The numbers, with fidelity spelled out (because you'll check):**
- **Understanding a feature** (the number that matters). An agent opens ~5 files to understand
  one feature. As signature outlines, excalidraw's text-element feature is **25217 → 844
  tokens = 97%** — but that's the **lossy** outline (structure only, ~20% of content survives;
  for understanding/navigation, not editing). The **same** 5 files in **high-fidelity entropy**
  mode: **38% fewer, keeping ~89%** of the content. Two honest headlines, different needs.
- **Whole-directory, nothing cherry-picked** (`bctx benchmark packages/element/src`, 47 files):
  entropy **~34% @ ~89%** fidelity; signatures **~76% token-weighted (⚠ lossy, ~20%)**. A
  second dir (`packages/excalidraw/actions`, 36 files) lands in the same bands — entropy
  34%@89%. bctx even reports **0%** on files its outline parser can't handle instead of faking
  a number.
- The `bctx benchmark` single-file "auto-pick" summary is a **conservative** per-file tradeoff,
  not the headline — a real session multiplies across files, command output, and memory.

**Not Python-specific.** The existing Python/FastAPI proof lives in *this* folder (`PROOF/`);
the new TypeScript proof is in `../PROOF_EXCALIDRAW/`. Same capabilities, same honest bands,
two languages.

**Install is real and public — v0.1.31 on all three paths** (verified): Homebrew
(`brew tap better-ctx-org/bctx && brew install …`), `install.sh`, and `npm install -g
bctx-bin`. The manual uses Homebrew (most robust for a non-expert on a Mac).

**Reproduce it yourself (≈2 min each):**
```bash
BCTX_BIN=$(command -v bctx) ../PROOF_EXCALIDRAW/validate_ts.sh       # TS: savings/fidelity spectrum
BCTX_BIN=$(command -v bctx) ../PROOF_EXCALIDRAW/workflow_demo_ts.sh  # TS: feature read + cmd compression
BCTX_BIN=$(command -v bctx) ./validate.sh                            # Python/FastAPI: same
```

Everything I claim is in those scripts and in `USER_MANUAL.md` — they scan whole directories,
no cherry-picking, and every number is pinned. Happy to walk through it live.
