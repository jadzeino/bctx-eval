# Layer 2 — task-outcome A/B protocol

This is the part that directly answers the investor's question: *is the agent's end result the
same with compression ON vs OFF?* Layer 1 proves no facts are dropped at the source; layer 2
proves the **answer** is unchanged when the model reads compressed context.

## What is compared

For every task in [`tasks.json`](tasks.json) the model answers the **same prompt twice**:

- **ON** — context = `bctx read --mode <on_mode>` output (compressed).
- **OFF** — context = the raw file / `BCTX_BYPASS=1` command output (full).

Nothing else differs: same prompt, same model, same instructions. The only variable is whether
the context was compressed. This isolates the one thing under test — *did compression change the
answer?*

## How it was run (controlled-context subagents)

1. `python3 build_bundles.py` writes, per task, the exact text each condition sees:
   `bundles/<id>/ON.txt`, `bundles/<id>/OFF.txt`, and `meta.json` (bytes + %-smaller). These are
   committed, so you can diff ON vs OFF yourself and see precisely what compression removed.
2. A lean multi-agent run (`bctx-equivalence-ab` workflow) spawns, for each task and each
   condition, **3 independent subagents** (reps, for the stochastic framing in
   [`../METHODOLOGY.md`](../METHODOLOGY.md)). Each subagent is given **only** its bundle file as
   context and the task prompt, and returns its answer.
3. Scoring:
   - **Deterministic tasks** — a code oracle (substring match on the known-correct answer). No
     opinion involved. Success rate = fraction of reps that pass, computed for ON and OFF.
   - **Free-form task** — a **blind LLM judge** is shown both answers with the ON/OFF labels
     removed and the order alternated, and decides whether they are substantively equivalent.
4. Results (success-rate ON vs OFF, equivalence, every divergence) are written to
   [`RESULTS.json`](RESULTS.json).

## Reproducing / re-running with your own model

The bundles are model-agnostic. To replay with any model: for each task, send the model
`bundles/<id>/ON.txt` (or `OFF.txt`) as context plus the task's `prompt`, collect the answer, and
apply the same `checker` from `tasks.json`. The committed `RESULTS.json` records what our run
produced; the deterministic checkers make most of it verifiable without any model at all.

## Honesty rule

If any deterministic task shows a **different success rate ON vs OFF**, or the judge finds a
free-form pair **not equivalent**, it is recorded verbatim in `RESULTS.json` under `divergences`
with the offending answers — never tuned away. The claim this eval defends is stated precisely in
[`../METHODOLOGY.md`](../METHODOLOGY.md): *no measurable drop in success rate and no dropped
facts* — not byte-identical outputs.
