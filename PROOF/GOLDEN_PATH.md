# bctx on Python / FastAPI — the tested path to large token savings

You saw savings only on `git`. That was a **setup gap, not a capability gap** — and it's
fixed. This guide is the exact, reproduced path to large savings on a FastAPI/Python repo.
Every number here was measured with the bctx binary on a fresh clone of
`fastapi/full-stack-fastapi-template` and the `fastapi` framework; reproduce them yourself
with `./validate.sh`.

## Why you only saw git savings before

bctx saves tokens two ways, and only one of them was firing for you:

1. **Shell hook** — compresses the output of *commands* the agent runs. It shipped with a
   fixed allowlist (`git`, `cargo`, `npm`, `pytest`, …). Your FastAPI dev loop
   (`uvicorn`, `python app.py`) wasn't covered, and a bare `python` even recorded a
   misleading **0%** row. So `git` was the only thing you saw move.
2. **MCP skills** — compress *source files* (`blueprint`, `chisel`, `parallax`) and hold
   **memory** (`sediment`/`archivist`). **This is where most of the savings are**, because
   an agent spends most of its tokens *reading code* — but nothing told your agent to use
   them instead of its native Read. They sat idle.

What changed (now in the build):
- **Coverage + honesty:** FastAPI dev servers (`uvicorn`/`gunicorn`/`fastapi dev`/
  `flask run`/`python -m uvicorn`/`manage.py runserver`) stream correctly instead of being
  buffered; commands with no real compressor no longer pollute `bctx gain` with 0% rows; an
  `alembic` migration compressor was wired in.
- **Activation:** `bctx init` now installs a **mandatory tool-mapping** block into
  `~/.claude/CLAUDE.md` — the agent is told to use `blueprint`/`chisel`/`parallax` instead
  of Read and to run the memory ritual. That's what turns the idle skills on.

## The numbers (reproducible in 30s with `bctx benchmark`, no app deps)

bctx compresses source at several fidelity levels. **Read savings and fidelity together** —
fidelity = how much of the original content survives (bctx's identifier-coverage metric).
Measured token-weighted over the whole codebase:

| Mode | backend (20 files) | fastapi repo (497 files) | fidelity |
|---|---|---|---|
| entropy (**high fidelity** — keeps bodies) | 39% | 26% | ~87% |
| signatures (structural outline, *lossy*) | 86% | 79% | ~20% |
| bctx 1-file auto-pick (tradeoff summary) | 44% | 63% | 63% / 40% |

**Two honest headlines, depending on what the agent needs:**
- **High fidelity (entropy): ~26–39% fewer tokens while keeping ~87% of the content** — use
  when the agent needs the actual bodies. Beats "git-only" comfortably with almost no loss.
- **Structural outline (signatures/blueprint): ~79–86% fewer tokens, but *lossy*** — keeps the
  full API surface (every class + function signature, imports, types) and drops function
  *bodies*, so ~20% of content survives. It's for the *understanding/navigation* that
  dominates an agent's token spend; when it needs a body it pulls that one symbol (`pinpoint`)
  or the full file. Don't present 86% as if it were high-fidelity — it's structure-only.

The `bctx benchmark` "auto-pick" (44–63%) is a **conservative single-file tradeoff summary**,
not the number that matters — a real session multiplies across files (see below).

**The number that actually matters — understanding a whole feature.** An agent opens ~5 files
to understand one feature. As signature outlines that's **3910 → 569 tokens = 85% fewer**:

```
app/api/routes/users.py    1729 → 137 tokens   (92%)
app/models.py               913 → 202 tokens   (78%)
app/crud.py                 615 →  67 tokens   (89%)
app/api/deps.py             427 →  94 tokens   (78%)
app/core/security.py        226 →  69 tokens   (69%)
TOTAL (5 files)            3910 → 569 tokens   (85% fewer to understand the feature)
```
(From `bctx read --mode signatures` — the exact path an agent uses via `blueprint`/`parallax`.
Run `./workflow_demo.sh` to reproduce this plus command-output compression and code search.
`bctx benchmark` normalizes each file first, so its per-file counts differ slightly from the
raw-read numbers above; both land in the same 78–92% band.)

## Setup (once)

```bash
bctx init --agent claude      # installs MCP server + shell hook + the Golden Workflow steering
# restart Claude Code
/mcp                          # confirm the `bctx` server is connected (41 tools)
bctx doctor                   # hook installed? MCP registered? prints how to prove savings
```

After `init`, `~/.claude/rules/bctx.md` leads with **"Golden Workflow — MANDATORY tool
mapping"**. That block is what makes the agent actually use compression + memory.

## The in-session workflow that produces the savings

This is the multiplier — it converts the structural ceiling above into real session savings:

- **Reading code:** the agent uses `blueprint`/`chisel` (signatures) instead of full Read,
  `pinpoint` for one symbol, `parallax` for several files at once. A route file drops from
  ~1700 to ~140 tokens.
- **Search:** `compass`/`scanner` instead of dumping `grep` output.
- **Memory ritual:** `archivist` at task start to load prior facts (schema, auth flow,
  conventions); `sediment` when it learns something durable — so the *next* session is cheap.

## Running commands (the shell hook, now FastAPI-aware)

Routed commands have their noisy output compressed and recorded to `bctx gain`:
`git`, `pytest`, `ruff`, `mypy`, `pip`, `alembic`, `docker`, `kubectl`, … The more verbose
the output (a failing test run, a migration, a lint sweep), the more it saves. Dev servers
(`uvicorn app.main:app --reload`, `fastapi dev`) now pass straight through and stream.

```bash
bctx gain     # real, all-time token savings recorded locally
```

## Prove it yourself

```bash
BCTX_BIN=$(command -v bctx) ./validate.sh      /path/to/your/fastapi/repo   # per-file spectrum
BCTX_BIN=$(command -v bctx) ./workflow_demo.sh /path/to/your/fastapi/repo   # session multipliers
```

- **`validate.sh`** scans your whole target (no cherry-picking) and prints the savings/fidelity
  spectrum, per-file outline reads, and the `gain` summary.
- **`workflow_demo.sh`** shows what a single-file benchmark can't: reading a whole feature as
  outlines (~85%), command-output compression, and code search instead of grep. This is the
  closest thing to what an agent actually experiences in a session.
