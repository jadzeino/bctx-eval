bctx — reproducible token-savings eval (and why you saw only `git` last time)

Hi Fakher Alddin,

Thanks again for taking a real look at bctx. When you tried it, you saw savings only on `git`.
You were right — and it was a bug from last release, not a capability gap. I found it, fixed it,
shipped it, and put together a package so you can verify everything yourself, end to end, with
numbers that reproduce to the digit.

I've shared it as a repo. Everything below lives in it.

## Please Note: Bctx work out of the box.
After instalation the bctx work with the defualt settings and can be customized to user need later, which make it saving more and perfor better, this mean the test that you ran before should run normaly now after you install the latest version.
however i also run the tests and provided a quick guid to test from the point view of senior developer like you.

## First: re-run exactly what you did before (it's fixed now)

The fix ships in the latest release. Update, re-init, and repeat your original test:

```bash
bctx update            # or reinstall (see below); gets you to v0.1.31
bctx --version         # must say: bctx 0.1.31
bctx init --agent claude   # re-installs the hook + the new "Golden Workflow" steering
# restart Claude Code
```

Then do what you did before on your FastAPI repo. Two things changed:
- The command hook now covers the whole dev loop (uvicorn, pytest, ruff, mypy, alembic, …),
  not just `git`, and it no longer logs misleading 0% rows.
- `bctx init` now installs a **mandatory tool-mapping** that makes the agent actually use
  bctx's compressing readers and memory instead of reading whole files. That's the part that
  was idle before — it's where most of the savings are.

**The one thing that matters: you must be on v0.1.31.** On older versions you'll see the old
behavior. `bctx --version` confirms it.

## Then: follow the manual (start here)

**`USER_MANUAL.md`** is the guided path — install → verify → see each saving → let Claude Code
do a real task → check `bctx gain`. Every step has the exact command and the exact expected
output. It runs on **excalidraw** (TypeScript), pinned to one commit so your numbers match mine
exactly. It's deliberately written so anyone can follow it, so please forgive the hand-holding.

Install (any one — all three deliver v0.1.31; I tested each):
```bash
# Homebrew (recommended on a Mac)
brew tap better-ctx-org/bctx && brew install better-ctx-org/bctx/bctx
# or curl
curl -fsSL https://betterctx.com/install.sh | sh
# or npm
npm install -g bctx-bin
```

## What's in the repo

| File | What it is |
|---|---|
| `USER_MANUAL.md` | **Start here.** Whole-product walkthrough, exact outputs, troubleshooting. |
| `COMMANDS_REFERENCE.md` | Every command, every lens mode, all 111 command compressors, all 41 agent skills, and **how to extend/customize** any of it. |
| `PROOF_EXCALIDRAW/` | TypeScript proof (excalidraw): `validate_ts.sh`, `workflow_demo_ts.sh`, results + raw benchmark JSON. |
| `PROOF/` | The Python/FastAPI proof — *your* original repo type, now with the gap fixed. |
| `RESULTS.json` | Machine-readable summary of both. |

Reproduce the headline numbers in ~2 minutes each:
```bash
BCTX_BIN=$(command -v bctx) ./PROOF_EXCALIDRAW/validate_ts.sh        # TS: savings/fidelity spectrum
BCTX_BIN=$(command -v bctx) ./PROOF_EXCALIDRAW/workflow_demo_ts.sh   # TS: feature read + command compression
BCTX_BIN=$(command -v bctx) ./PROOF/validate.sh                      # Python/FastAPI: same
```

## The numbers, stated honestly

I've labeled every number with its **fidelity** (how much of the original content survives),
because I know you'll check and because a number without that context is meaningless:

- **Command output:** git log −150 = **98%**, git diff = **99%** (automatic, any language).
- **Understanding a feature** (5 files an agent opens): as structural **outlines** it's **~97%**
  fewer tokens — but that mode is **lossy** (~20% fidelity, structure only; great for
  understanding, not for editing). The **same** files at **high fidelity** (entropy mode) are
  **~38%** fewer while keeping **~89%** of the content. Two honest trade-offs; I never dress
  one up as the other.
- **Whole-directory, nothing cherry-picked:** entropy **~34% @ ~89%** fidelity; the lossy
  outline mode **~76%**. bctx even reports **0%** on files it can't cleanly parse instead of
  faking a number.
- **Not Python-specific:** the same honest bands show up in both the TypeScript and Python
  proofs.

One thing I'm explicitly *not* claiming: code search isn't a token win over `grep` for a
narrow string — its value is relevance/ranking. It's framed that way in the docs. I'd rather
under-claim than have you catch me over-claiming.

Everything is pinned to a version and a commit, with a reproduce command for every figure.
Happy to walk through it live whenever suits you.

Best,
Ahmed Zeno
