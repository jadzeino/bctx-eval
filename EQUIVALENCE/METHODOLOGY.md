# Equivalence eval — proving "same AI results, no data loss"

> The investor's question: *how do you measure the AI's result WITH compression vs WITHOUT, and
> assure the results are the same, with no data loss?*

The rest of bctx-eval proves two things: bctx **saves tokens**, and it keeps a high **fidelity**
score (bctx's own identifier-coverage metric — how much of the original content survives). Both
matter, but neither is the thing the investor asked about. **Fidelity is a proxy.** A high
fidelity score means "most identifiers are still there," not "the agent reaches the same answer."

We know the gap is real because we hit it. An earlier build's `ClarityLens` treated `#`/`*`/`//`
lines as strippable comments on *all* text, so `git branch` lost its current-branch line
(`* main`). Fidelity still scored that output well — the branch *names* were all present — yet a
real fact was gone. Content coverage ≠ outcome equivalence. This folder measures outcome
equivalence directly, in three layers.

---

## Layer 1 — Compressor coverage audit (deterministic, no model, free)

**Question:** does every fact a compression mode *promises to keep* actually survive?

For each source file and command, we derive the promised facts **independently of bctx** — Python
def/class names via the `ast` module, TypeScript exports via a regex, git output lines from the
raw command itself — and assert each one is present in bctx's compressed output. No model is
involved, so it reproduces byte-for-byte on any machine.

It is split into two tiers so the numbers are never conflated:

- **Strict** — the modes an agent actually gets: the default `auto` mode on source files, and raw
  command output as it reaches the agent. Command output is checked on both paths: the shell hook
  (`git status` is rewritten to `bctx git status`, which routes through the domain compressors)
  and `bctx read --mode auto -- git ...`. Each git check runs on a deterministic multi-line state
  (two extra branches, a modified file, an untracked file), because a one-line output is too
  small to be compressed at all and would pass whatever the compressors did. A loss here is a
  real regression and fails the audit. *(Result: 0 losses; the
  `auto` mode keeps 100% of symbols, declining to lossily compress arrow-function-heavy TS rather
  than drop names.)*
- **Outline** — the opt-in `signatures` mode, a deliberately lossy structural outline (bodies
  stripped, ~20% fidelity, never the product's headline). We quantify exactly how much it keeps.
  For Python it keeps 100% of def/class names; for TypeScript it keeps `function`-keyword defs and
  class methods but does **not** parse `export const NAME = () => …` arrow exports as named
  definitions, so it drops those names. We report that in full rather than hide it — and note that
  the default `auto` mode keeps them. `bctx read <file>` without `--mode` resolves to this outline
  for files, so it is reported here too, as what an agent reading a file through bctx receives.

A **regression fixture** replays the historical `* main` bug through the same logic and confirms
the audit catches it — the exact data loss that fidelity missed.

*Correction, 2026-10-19:* the first published version checked command output only through
`bctx read --mode auto`, on one-line outputs. A deliberate mutation that made the hook path drop
`git status`'s `## main` line passed it. The audit now checks the hook path on multi-line state,
and the same mutation fails it (`DATA_LOSS: ['## main']`).

Run it: `cd coverage_audit && ./fetch_corpora.sh && BCTX_BIN=<bctx> ./run_coverage_audit.sh` →
`coverage_audit_RESULTS.json`. `fetch_corpora.sh` clones FastAPI and Excalidraw at the pinned commits
(about 6 seconds). A missing target or a command with no output fails the audit instead of being
skipped, so a passing run always means every check ran. better-ctx CI runs this audit on every pull
request that touches its compression crates.

## Layer 2 — Task-outcome A/B (controlled-context subagents)

**Question:** given compressed vs full context, does the model reach the same answer?

Each task in [`ab/tasks.json`](ab/tasks.json) is answered twice from an identical prompt — once
with bctx-**compressed** context (ON), once with **full** raw context (OFF) — and the two outcomes
are compared:

- **Deterministic checkers** wherever possible (the oracle is code, not opinion): "name the
  function that builds a query parameter" (grep-verifiable), "list the HTTP method decorators",
  "which branch is checked out" (the exact `* main` bug class), "which class records history."
- A **blind LLM judge** for the one free-form summarization task, shown both answers unlabeled.

Each condition is run **3×** and we compare **rates**, not single outputs (see Layer 3). The
committed context bundles ([`ab/bundles/`](ab/bundles/)) show precisely what compression removed;
the protocol is in [`ab/run_equivalence.md`](ab/run_equivalence.md); results in
[`ab/RESULTS.json`](ab/RESULTS.json).

## Layer 3 — Honest statistical framing

LLMs are stochastic: the same prompt can yield differently-worded answers even with **no**
compression. So the claim is deliberately **not** "byte-identical answers." The claim is:

> **No measurable drop in success rate, and no dropped facts.**

That is why layer 2 runs each condition multiple times and compares success *rates*, and why layer
1 exists at all — it is the deterministic backstop that catches dropped facts a stochastic answer
might otherwise paper over. If compression ever changes an outcome — a lower success rate ON than
OFF, or a judge marking a pair non-equivalent — it is recorded verbatim in `RESULTS.json` under
`divergences`, with the offending answers, never tuned away.

---

## What this proves, and what it does not

- **Proves:** in the modes an agent actually uses, bctx drops no promised facts (layer 1), and on
  a concrete task set the agent's success rate and answers are unchanged with compression on
  (layer 2) — while consuming materially fewer tokens (per-task compression is recorded in each
  bundle's `meta.json`).
- **Does not prove:** that *every* mode is lossless (the `signatures` outline is lossy by design —
  we quantify it), nor that outputs are byte-identical (they are not, and shouldn't be expected to
  be). The task set is small and honest; it is meant to be extended, not to stand as a universal
  guarantee.
