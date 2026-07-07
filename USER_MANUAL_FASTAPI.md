# bctx — User Manual (Python / FastAPI)

This is the **Python** companion to `USER_MANUAL.md` (which uses TypeScript / excalidraw). It's
aimed at re-running the scenario you tried first — a FastAPI repo — and it deliberately makes
**three points the git-only first impression missed**:

1. `bctx gain` shows savings from **many tools, not just `git`** (here `ruff` dominates).
2. bctx uses `bctx patterns` — **111 supported tools**, each with a real compressor.
3. The **biggest** savings — the agent reading source code — happen through **MCP skills** and
   are **not** in `bctx gain` at all. You measure those a different way. (This applies to the
   TypeScript project too.)

Everything is on **bctx v0.1.32**. Read every savings number with its **fidelity**.

---

## Part 1 — Install & verify (same as the TS manual)

If you haven't installed bctx yet, do Part 1 of `USER_MANUAL.md` (Homebrew / curl / npm), then:

```bash
bctx --version        # must say: bctx 0.1.32
```

You'll also want a Python **virtual environment** ("venv") with a few dev tools. A venv is just a
folder that holds Python tools without touching the rest of your system. We put it at a fixed
path so you can re-activate it from anywhere later:

```bash
python3 -m venv ~/Desktop/bctx-venv          # 1. create it (once)
source ~/Desktop/bctx-venv/bin/activate      # 2. activate it — your prompt now shows (bctx-venv)
pip install ruff mypy pytest                 # 3. install the three tools into it
which ruff                                    # 4. verify → .../Desktop/bctx-venv/bin/ruff
```

If step 4 prints a path ending in `bctx-venv/bin/ruff`, you're set.

> **Every new Terminal window starts fresh** — the venv is *not* active until you run
> `source ~/Desktop/bctx-venv/bin/activate` again (prompt shows `(bctx-venv)`). If any command
> below says `command not found: ruff` (or `mypy`/`pytest`), that's the fix.

---

## Part 2 — Get the FastAPI codebases, pinned

Two repos: the **framework** (for the command demos) and a realistic **app template** (for the
source-read demos). Pinned so your numbers are stable.

```bash
cd ~/Desktop
git clone --filter=blob:none https://github.com/fastapi/fastapi.git
( cd fastapi && git checkout cecd96d9c6c318e0df1c40cedbc2e953381ddfd3 )      # v0.139.0

git clone --filter=blob:none https://github.com/fastapi/full-stack-fastapi-template.git
( cd full-stack-fastapi-template && git checkout 3685fb66259fa12f8436ae7f88379fd64ca7cdbd )
```

### Where things live — keep this straight (important if Python is new to you)

| Folder | What it is | Used in |
|---|---|---|
| `~/Desktop/bctx-venv` | the Python **virtual environment** holding `ruff`/`mypy`/`pytest` | Part 4 (activate it!) |
| `~/Desktop/fastapi` | the FastAPI **framework** — for the command demos | Part 4 |
| `~/Desktop/full-stack-fastapi-template/backend` | a realistic **app** — for the source-read demos | Part 5 |

**The golden rule (two steps, every new Terminal window):**
1. Activate the tools: `source ~/Desktop/bctx-venv/bin/activate` — your prompt then shows
   `(bctx-venv)` at the front. If you skip this, you'll get `command not found: ruff`.
2. `cd` into the folder the step names. **Every step below starts with the exact `cd` you need**,
   so you can copy-paste top to bottom.

---

## Part 3 — bctx compresses 111 tools, not just git

*(Run from anywhere — `bctx patterns` is built in, no venv or repo needed.)*

```bash
bctx patterns
```

You'll see 9 categories — **vcs, build, test, lint, pkg, infra, db, ai/data, sys** — with tools
and typical savings, e.g. `pytest 70–90%`, `ruff 60–85%`, `mypy 55–75%`, `pip 60–80%`,
`alembic`, `docker`, `kubectl`, … The point: bctx isn't a "git thing." The more verbose a
command's output, the more it saves.

---

## Part 4 — See `bctx gain` fill up with **non-git** savings

The savings scale with how noisy the output is. A clean repo's lint/type checks are quiet
(little to compress); a **realistically noisy** run compresses enormously. We'll run a full-rule
lint sweep — the kind of output a legacy repo produces — through bctx.

Copy-paste this whole block (it activates the venv, moves into the framework folder, and runs
the lint sweep). If `source` errors, you skipped Part 1's venv step:

```bash
source ~/Desktop/bctx-venv/bin/activate   # activate the tools → prompt shows (bctx-venv)
cd ~/Desktop/fastapi                       # the FastAPI FRAMEWORK folder
which ruff                                 # sanity check → .../bctx-venv/bin/ruff

# Isolate the gain ledger with a throwaway HOME as a PER-COMMAND prefix (do NOT `export HOME`
# — that would break every `~/…` path afterwards). Set it once as a shell variable:
TMPH=$(mktemp -d)
HOME="$TMPH" bctx ruff check --select ALL --no-cache fastapi/    # a deliberately noisy, all-rules lint
```

The compressed summary ends with a line like (your **before** count depends on your ruff
version; the savings is ~100% because lint output is extremely repetitive):

```
[bctx: 237223 → 83 tokens, 100% saved]
```

Now check the ledger — same `HOME="$TMPH"` prefix, so you read the *isolated* ledger you just
wrote (not your all-time history):

```bash
HOME="$TMPH" bctx gain
```

```
  TOKEN SAVINGS  (local · all time)
  ─────────────────────────────────────────────────
  Tokens saved      237.1K    Compression    99%
  ...
  TOP COMMANDS
  ruff          ████████████████    237.1K saved  100%
```

**No `git` in sight.** That's the point of this section: `bctx gain` reflects whatever tools
you actually run.

**(Optional — skip if Python is new to you.)** Add more from your own dev loop — **run these in
the same `~/Desktop/fastapi` folder, with the Part-1 venv active**. Note the first one is a full
dependency install (slow, downloads a lot):

```bash
bctx pip install -e ".[all]"   # install the framework + extras INTO your venv — very verbose
bctx pytest -v                 # run the framework's test suite (needs the install above) — verbose
bctx mypy fastapi/             # type-check the package ('fastapi/' is the package dir, here)
```

> **Honest note:** on a *clean* repo, `pytest`/`mypy`/`pip` may print very little, so they
> compress little (bctx passes tiny output straight through and records ~0% — it doesn't fake a
> number). Their big wins show up on **noisy** runs: a failing test suite, a real dependency
> install, a migration (`alembic`). Run them against real work and watch `bctx gain` grow.

---

## Part 5 — The **other half** of the savings (MCP), which `bctx gain` does NOT show

This is the most important — and most missed — point.

`bctx gain` only tracks **shell command output** (Part 4). But an AI agent spends most of its
tokens **reading source code**, and bctx compresses that through its **MCP skills**
(`blueprint`, `chisel`, `parallax`, `pinpoint`) — which the agent calls directly. **Those
savings never appear in `bctx gain`.** If you run an agent session and then check `bctx gain`,
you'll only see the shell commands — and wrongly conclude the skills did nothing.

*(No venv needed for this Part — `bctx read` is built into bctx. Just `cd` into the app's
`backend` folder.)*

**First, see it on one file.** `--mode full` is what a normal Read costs the agent;
`--mode signatures`/`entropy` is what the skills return (same engine). The difference is the
saving:

```bash
cd ~/Desktop/full-stack-fastapi-template/backend
bctx read app/api/routes/users.py --mode full         # [bctx: 1729 → 1729]  agent's normal cost
bctx read app/api/routes/users.py --mode signatures   # [bctx: 1729 →  137]  blueprint/chisel → 92%
bctx read app/api/routes/users.py --mode entropy      # [bctx: 1729 → 1052]  high-fidelity → 39%
```

**Then across a whole feature.** Understanding one feature means reading ~5 files; as structural
outlines (exactly what `blueprint`/`parallax` emit):

```bash
for f in app/api/routes/users.py app/models.py app/crud.py app/api/deps.py app/core/security.py; do
  bctx read "$f" --mode signatures 2>&1 >/dev/null
done
```

```
[bctx: 1729 → 137 tokens, 92% saved]
[bctx:  913 → 202 tokens, 78% saved]
[bctx:  615 →  67 tokens, 89% saved]
[bctx:  427 →  94 tokens, 78% saved]
[bctx:  226 →  69 tokens, 69% saved]
```

Totals: **3,910 → 569 tokens = 85% fewer** to understand the feature (lossy outline, ~20%
fidelity — structure only). Need the real bodies at high fidelity instead? Use `--mode entropy`
(~26–39% fewer, ~87% of content kept). Reproduce the full spectrum with the bundled script
(pass your template's `backend` folder — the script otherwise looks for one next to itself):

```bash
BCTX_BIN=$(command -v bctx) ~/Desktop/bctx-eval/PROOF/validate.sh ~/Desktop/full-stack-fastapi-template/backend
```

**In a real agent session**, this is automatic: after `bctx init` the Golden Workflow tells the
agent to use `blueprint`/`chisel`/`parallax` instead of full reads. To confirm it's happening,
watch the agent's **tool calls** in Claude Code (you'll see `bctx` skills, not full-file reads)
— that's the saving, even though `bctx gain` won't count it.

---

## Part 6 — Memory (same as the TS manual)

The agent stores facts via the `sediment` MCP skill; you read them back from the terminal:

```bash
bctx recall "auth flow"
```

(After an agent session where it sedimented something. See `USER_MANUAL.md` Part 4F for the
full sediment → recall walkthrough.)

---

## Part 7 — Every number, how to reproduce it

All on **bctx v0.1.32**, fixtures pinned in Part 2.

| Claim | Reproduce with | Tolerance |
|---|---|---|
| ruff all-rules sweep ≈ 100% (~237K→~80) | `bctx ruff check --select ALL --no-cache fastapi/` | `before` varies with ruff version; savings ~100% |
| `bctx gain` shows ruff (not git) on top | the isolated-HOME sequence in Part 4 | exact ordering |
| feature read 3910→569 = 85% (lossy) | the 5-file loop in Part 5, or `PROOF/validate.sh` | exact at pinned template |
| entropy high-fidelity ~26–39% @ ~87% | `PROOF/validate.sh` | ±1% |
| 111 supported tools | `bctx patterns` | exact |

**Two sources of savings, stated plainly:**
- **Shell** (in `bctx gain`): whatever tools you run, scaled by output noise. Not git-specific.
- **Source reads** (NOT in `bctx gain`): the agent's MCP skill reads — the bigger, quieter win,
  measured with `bctx read` / `bctx benchmark`.

**Fidelity:** "signatures"/outline mode is **lossy** (~20% content, structure only) — for
understanding, not editing. "entropy" keeps **~87%**. We never pair the big outline % with the
high fidelity %.
