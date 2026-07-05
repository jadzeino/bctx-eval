# bctx — User Manual (whole product, start to finish, on a Mac)

**What this is.** A step-by-step guide to install **bctx** (better-ctx), connect it to Claude
Code, and *prove for yourself* how many tokens it saves an AI coding agent — on a real
TypeScript codebase (**excalidraw**). Every command is copy-paste. Every step shows the
**exact output you should see**. If a number doesn't match, the Troubleshooting section
(Part 8) tells you why.

**You do not need to be a programmer.** You need a Mac, the Terminal app, and about 20
minutes. Follow the parts in order.

**What you'll prove (Some parts of the product, as testing the whole product is hard to fully cover):**
1. bctx automatically **compresses noisy command output** (git, npm, …) — up to **98–99%**.
2. bctx **compresses source files** an agent reads — a 5-file feature drops **~97%** as an
   outline, or **~38%** while keeping ~89% of the content.
3. bctx gives the agent **code search** and **persistent memory** across sessions.
4. bctx **reports the savings** (`bctx gain`).

**A word on honesty.** bctx has several compression modes with different trade-offs. We label
every number with its **fidelity** (how much of the original content survives). We never dress
up a lossy number as a lossless one. Read Part 7 (the number-by-number map) if you want to
audit every claim.

---

## Part 0 — Before you start (2 min)

1. Open the **Terminal** app (press `Cmd+Space`, type `Terminal`, hit Return).
2. Check you have **Homebrew** (the standard Mac package manager). Paste this and press Return:

   ```bash
   brew --version
   ```

   - If you see something like `Homebrew 5.x.x`, you're good — skip to Part 1.
   - If you see `command not found`, install Homebrew by pasting this one line, then follow
     its on-screen instructions (it may ask for your Mac password):

     ```bash
     /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
     ```

3. You'll also want **Claude Code** installed (Parts 3, 5, 6). If you don't have it, that's
   fine — Parts 1, 2, 4 (the token-savings proof) work without it.

---

## Part 1 — Install bctx (3 min)

Paste these two lines:

```bash
brew tap better-ctx-org/bctx
brew install better-ctx-org/bctx/bctx
```

**Verify the version.** This is important — the numbers in this manual are for **v0.1.31**:

```bash
bctx --version
```

Expected output (must say **0.1.31**):

```
bctx 0.1.31
```

> If it prints an older version, run `brew upgrade better-ctx-org/bctx/bctx` and check again.
> If `bctx` is "command not found", see Troubleshooting → *bctx not found*.

**Health check.** Run:

```bash
bctx doctor
```

You'll see a health report. On a fresh machine a few lines have a `✗` or `·` — **that is
normal** (bctx hasn't stored anything yet, and you may not use every optional integration).
The lines that matter should be `✓`:

```
  Environment
  ───────────
  ✓  HOME set
  ✓  bctx in PATH
  ✓  git in PATH
  ...
```

---

## Part 2 — Get the test codebase (excalidraw), pinned (3 min)

We pin excalidraw to one exact commit so **your token numbers match this manual to the digit**.

```bash
cd ~/Desktop
git clone --filter=blob:none https://github.com/excalidraw/excalidraw.git
cd excalidraw
git checkout 51ca8abde450e44f8f0db1b2708e0408915c7ab1
```

`--filter=blob:none` makes the clone fast (a few seconds) while keeping full history so the
git demos below work. Verify you're on the right commit:

```bash
git rev-parse HEAD
```

Expected (exactly this):

```
51ca8abde450e44f8f0db1b2708e0408915c7ab1
```

Stay in this `~/Desktop/excalidraw` folder for the rest of the manual.

---

## Part 3 — Connect bctx to Claude Code (2 min · optional but recommended)

*(Skip to Part 4 if you don't have Claude Code — the savings proof doesn't need it.)*

```bash
bctx init --agent claude
```

Expected output (paths will show your username):

```
  ✓ ~/.claude/mcp.json
  ✓ hook script → …/.claude/bctx-hook.sh
  ✓ settings.json hook registered
  ✓ settings.json permissions updated (41 skills)
  ✓ CLAUDE.md written
  ✓ rules/bctx.md written (Golden Workflow + 41 skills)
  → Restart Claude Code to activate.
```

This installs bctx's **41 skills** as tools for Claude Code, plus the **Golden Workflow** — a
rule set that tells the agent to use bctx's compressing readers (`blueprint`/`chisel`/
`parallax`) instead of reading whole files, and to use memory. **Restart Claude Code now.**

Inside Claude Code, type:

```
/mcp
```

You should see a server named **`bctx`** listed as **connected**, exposing **41 tools**.
(If it's missing, see Troubleshooting → */mcp shows nothing*.)

---

## Part 4 — Prove the savings (10 min)

Each demo below shows the command, the **exact output**, and **what it proves**. Run them
from inside `~/Desktop/excalidraw`.

### 4A — Automatic command-output compression

AI agents run lots of noisy commands (`git`, `npm`, tests). bctx compresses that output before
it reaches the agent. Run:

```bash
bctx git log -n 150
```

You'll see a compressed log, and at the very end a line like this (this is bctx reporting what
it saved):

```
[bctx: 29343 → 599 tokens, 98% saved]
```

Now a bigger one — a 40-commit diff:

```bash
bctx git diff HEAD~40 HEAD
```

Ends with (the "before" number may differ by ~1% depending on your git version; the savings
stays 99%):

```
[bctx: 189311 → 1888 tokens, 99% saved]
```

**What it proves:** noisy command output is compressed **98–99%** automatically. The more
verbose the command, the more it saves.

> **Privacy note:** these commands record their savings to a local database at `~/.bctx` on
> your own machine (nothing leaves your computer). If you'd rather not touch it during testing,
> prefix any command with a throwaway home, e.g. `HOME=$(mktemp -d) bctx git log -n 150` — the
> per-command `[bctx: …]` number is identical either way.

### 4B — Source-file compression (one file)

An agent that reads `textWrapping.ts` in full spends ~5,500 tokens. As a structural **outline**:

```bash
bctx read packages/element/src/textWrapping.ts --mode signatures
```

You'll see the file's API surface (imports, function/type signatures — bodies removed), then:

```
[bctx: 5501 → 95 tokens, 98% saved]
```

That's the **lossy outline** mode (great for *understanding* a file; ~20% of content
survives). When the agent needs the real code with high fidelity, it uses **entropy** mode:

```bash
bctx read packages/element/src/textWrapping.ts --mode entropy
```

```
[bctx: 5501 → 3518 tokens, 36% saved]
```

**What it proves:** you choose the trade-off. Outline = huge savings, structure only. Entropy
= modest savings, keeps ~89% of the content. *(This one file saves 36% in entropy mode; across
the whole 5-file feature in 4C it averages 38% — same mode, different file mix.)*

### 4C — Multi-file feature read (the number that matters)

To understand one feature, an agent opens several files. Here are the 5 files of excalidraw's
**text-element** feature. Run this block (copy all of it):

```bash
for f in textElement textWrapping textMeasurements newElement bounds; do
  bctx read packages/element/src/$f.ts --mode signatures 2>&1 >/dev/null
done
```

Expected (5 lines):

```
[bctx: 3773 → 103 tokens, 97% saved]
[bctx: 5501 → 95 tokens, 98% saved]
[bctx: 1543 → 75 tokens, 95% saved]
[bctx: 3468 → 80 tokens, 98% saved]
[bctx: 10932 → 491 tokens, 96% saved]
```

Add up the "before" (25,217) and "after" (844): understanding this whole feature as outlines
costs **~97% fewer tokens** (25,217→844 is exactly 96.7%). The same 5 files in high-fidelity
entropy mode total 15,578 tokens (**38% fewer**, ~89% of content kept). **Both numbers are
real; they're different trade-offs.**

> Want it done for you? Run the bundled script (it prints the totals and both modes):
> ```bash
> BCTX_BIN=$(command -v bctx) ~/Desktop/bctx-eval/PROOF_EXCALIDRAW/workflow_demo_ts.sh
> ```

### 4D — Whole-directory benchmark (nothing cherry-picked)

Scan an entire directory (47 files) and see the honest spectrum:

```bash
bctx benchmark packages/element/src
```

At the bottom you'll see an `average` row and a note. The key figures:

```
  average    82%    33%    11%    82%    24%
             SIGNAT ENTROP AGGRES BEST QUALITY
```

Read this honestly:
- **entropy 33%** savings at high fidelity (the `QUALITY` for entropy files is ~87–89%).
- **signatures 82%** savings — but note the **⚠** next to nearly every signatures cell and the
  low overall `QUALITY 24%`: bctx is **flagging that this mode is lossy** (structure only).
- Some files show `0%` in signatures (e.g. `index.ts`, `types.ts`) — bctx honestly falls back
  to full text when its outline parser can't handle a file; it doesn't fake a number.

> `bctx benchmark` averages each file equally. The bundled `validate_ts.sh` instead weights by
> token count (big files count more), giving signatures **76%** / entropy **34%**. Both are
> honest — they just average differently. Run it to see:
> ```bash
> BCTX_BIN=$(command -v bctx) ~/Desktop/bctx-eval/PROOF_EXCALIDRAW/validate_ts.sh
> ```

### 4E — Code search (relevance, not raw dump)

```bash
bctx index
bctx search "text wrapping" --top-k 5
```

You'll see ranked, symbol-aware locations across the whole repo, e.g.:

```
  1. ./packages/excalidraw/wysiwyg/textWysiwyg.test.tsx  ::updateTextEditor  (score: 73.00)
  2. ./packages/excalidraw/components/App.tsx  ::textWysiwyg  (score: 45.00)
  ...
```

**What it proves — honestly:** this is a **relevance** tool. It ranks locations by a concept,
not just a literal string match like `grep`. (For a narrow literal string, `grep` prints
fewer characters — we're **not** claiming search saves tokens over grep. Its value is finding
the *right* place when you don't know the exact string.)

### 4F — Memory you can see (sediment → recall)

This is bctx's compounding win: the agent **remembers** what it learns, so the next session
doesn't re-read the same files. You'll watch a fact go in through Claude Code and come back out
from the terminal.

**Step 1 — in Claude Code, paste this prompt:**

```
Use the bctx `sediment` tool to remember this fact, then stop:
key = "excalidraw text wrapping location",
value = "text-wrapping logic lives in packages/element/src/textWrapping.ts (wrapText)".
```

Claude will call the `sediment` tool and confirm it stored 1 fact.

**Step 2 — back in the Terminal, read it back:**

```bash
bctx recall "text wrapping"
```

Expected:

```
bctx recall: "text wrapping" — 1 result(s)

  [resonant] codebase/excalidraw text wrapping location  (confidence: 95%)
    text-wrapping logic lives in packages/element/src/textWrapping.ts (wrapText)
    tags: ...
```

**What it proves:** the agent's memory is real and persists **outside** the chat — a different
process (your terminal) reads the same fact. Next session, the agent recalls it instead of
re-reading the code.

### 4G — See your savings totals

```bash
bctx gain
```

You'll see a summary of tokens saved, compression %, and estimated cost avoided, with `git` at
the top of "TOP COMMANDS". (Your totals depend on how many commands you've run — the important
part is that the commands from 4A appear and show ~98% compression.)

For a live dashboard:
make sure you signed in the betterctx.com

```bash
bctx dashboard
```

(Press `q` to quit.)

---

## Part 5 — Let Claude Code do a real task (5 min · optional)

This shows bctx working *during* real agent work.

1. In Claude Code (inside `~/Desktop/excalidraw`), ask:

   ```
   Explain how excalidraw wraps text inside a container. Use the bctx blueprint/chisel
   tools to read the relevant files as outlines instead of reading them in full, and
   sediment one fact about where the logic lives.
   ```

2. Watch the tool calls: you should see bctx skills like `blueprint`, `chisel`, or `parallax`
   (compressed reads) and a `sediment` call — not full-file reads.

3. When it's done, check that your savings grew:

   ```bash
   bctx gain
   ```

**What it proves:** in a real session the agent reads code through bctx's compressors and
records memory — exactly the behavior the Golden Workflow (Part 3) installs.

---

## Part 6 — What you just proved (summary)

| Capability | Command | Result |
|---|---|---|
| Command-output compression | `bctx git log -n 150` | **98%** (29343→599) |
| " (big diff) | `bctx git diff HEAD~40 HEAD` | **99%** (~189K→~1.9K) |
| Feature read, outline (lossy) | 5-file loop / `workflow_demo_ts.sh` | **97%** (25217→844) |
| Feature read, high fidelity | entropy mode | **38%** (25217→15578, ~89% kept) |
| Whole-dir spectrum | `bctx benchmark packages/element/src` | entropy **33%**@~89% · signatures **82%** (lossy, ⚠) |
| Code search | `bctx search "text wrapping"` | ranked relevance (not a token claim) |
| Memory | `sediment` → `bctx recall` | fact persists cross-process |

---

## Part 7 — Every number, and how to reproduce it (auditor's map)

All numbers are with **bctx 0.1.31** on **excalidraw @ 51ca8abde450e44f8f0db1b2708e0408915c7ab1**.

| Claim | Reproduce with | Tolerance |
|---|---|---|
| git log −n150: 29343→599 (98%) | `bctx git log -n 150` (in the pinned clone) | exact |
| git diff HEAD~40: ~189K→~1.9K (99%) | `bctx git diff HEAD~40 HEAD` | before ±1% (git version); savings 99% |
| textWrapping.ts sig: 5501→95 (98%) | `bctx read packages/element/src/textWrapping.ts --mode signatures` | exact |
| 5-file feature, sig: 25217→844 (97%) | loop in 4C, or `workflow_demo_ts.sh` | exact |
| 5-file feature, entropy: →15578 (38%) | `workflow_demo_ts.sh` | exact |
| element/src benchmark: entropy 33%, sig 82%, quality 24% | `bctx benchmark packages/element/src` (`average` row) | ±1% |
| element/src token-weighted: entropy 34%, sig 76% | `validate_ts.sh` | ±1% |

**Fidelity, stated plainly:** "signatures"/"outline" mode keeps the API surface and drops
function *bodies* — roughly **20% of the content survives**. It's for *understanding and
navigating* code (where agents spend most tokens), not for editing. "entropy" mode keeps
**~89%** of the content at a smaller (~33%) saving. We never pair the big outline % with the
high fidelity %; they are different modes.

---

## Part 8 — Troubleshooting

| Symptom | Fix |
|---|---|
| `brew tap` or `brew install` fails | Make sure you're online, run `brew update`, and retry. Confirm the formula resolves: `brew info better-ctx-org/bctx/bctx` should show `stable 0.1.31`. Fallback install (needs Node.js): `npm install -g bctx-bin` — also installs 0.1.31. |
| `bctx: command not found` after brew install | Run `brew --prefix`/`echo $PATH`; ensure `/opt/homebrew/bin` (Apple Silicon) or `/usr/local/bin` (Intel) is on PATH. Open a new Terminal window. |
| `bctx --version` shows an old version | `brew upgrade better-ctx-org/bctx/bctx`, then re-check. |
| `git checkout 51ca8ab…` says "did not match" | Your clone was too shallow. Re-clone with the exact Part 2 command (it uses `--filter=blob:none`, not `--depth 1`). |
| `git diff HEAD~40 HEAD` errors "unknown revision" | Same cause — you need full history; re-clone per Part 2. |
| `/mcp` shows no `bctx` server | You didn't restart Claude Code after `bctx init`. Fully quit and reopen it. Then `bctx doctor` should show `✓ Claude Code mcp.json`. |
| `bctx search` prints "no results" | Run `bctx index` first (Part 4E). |
| Numbers are slightly off | Confirm `bctx --version` = 0.1.31 **and** `git rev-parse HEAD` = the pinned commit. Both must match. Small ±1% drift on git diff / benchmark averages is expected (Part 7). |
| I don't want bctx touching my real data during a test | Prefix a command with an isolated home: `HOME=$(mktemp -d) bctx git log -n 150`. This writes to a throwaway folder, not your `~/.bctx`. |

---

## Appendix — the two companion evals

This manual walks the **TypeScript** proof (excalidraw). There is a parallel **Python** proof
(FastAPI) in `~/Desktop/bctx-eval/PROOF/`, showing the same capabilities land in the same
honest bands in another language. Scripts you can run yourself:

- `PROOF_EXCALIDRAW/validate_ts.sh` — whole-dir savings/fidelity spectrum (TypeScript)
- `PROOF_EXCALIDRAW/workflow_demo_ts.sh` — feature read + command compression + search
- `PROOF/validate.sh`, `PROOF/workflow_demo.sh` — the same for Python/FastAPI

Machine-readable results: `PROOF_EXCALIDRAW/RESULTS.json` and `PROOF/RESULTS.json`.
