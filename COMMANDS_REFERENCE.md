# bctx — Full Capability Reference

Everything bctx exposes, what each piece does, and how to extend it. This is the "what does
this tool actually support" companion to `USER_MANUAL.md` (which is the guided walkthrough).
All of this is on **v0.1.31**.

bctx saves an AI coding agent tokens in four ways, each covered below:
1. **CLI commands** you run directly (Part A).
2. **Lens modes** — the compression profiles (Part B).
3. **Automatic command-output compression** — 111 tool families (Part C).
4. **41 MCP skills** the agent calls during a session (Part D).
5. **How to extend / customize** all of the above (Part E).

---

## Part A — CLI commands (`bctx <command>`)

Run `bctx <command> --help` for full flags. Grouped by purpose:

**Everyday**
| Command | What it does | Example |
|---|---|---|
| `read` | Run a command or read a file with an explicit lens mode | `bctx read app.ts --mode signatures` |
| `compress` | Compress a file or stdin and print the result | `cat big.log \| bctx compress` |
| `search` | Search the project code index (ranked, symbol-aware) | `bctx search "auth flow"` |
| `index` | Build/update the project code index (run before search) | `bctx index` |
| `gain` | Token-savings summary (local, offline) | `bctx gain` |
| `dashboard` | Live savings dashboard (terminal UI; `q` to quit) | `bctx dashboard` |
| `<any tool>` | Run a supported tool (git/npm/pytest/…) with output compressed | `bctx git log -n 50` |

**Setup & health**
| Command | What it does | Example |
|---|---|---|
| `init` | Install bctx into an AI agent (MCP + hook + Golden Workflow) | `bctx init --agent claude` |
| `doctor` | Diagnose the installation and print how to prove savings | `bctx doctor` |
| `update` | Auto-detect how bctx was installed and upgrade to latest | `bctx update` |
| `uninstall` | Remove bctx config from an agent (reverse of init) | `bctx uninstall` |
| `modes` | List all lens modes with savings estimates and use cases | `bctx modes` |
| `patterns` | List the 111 command compressors by category | `bctx patterns` |

**Memory**
| Command | What it does | Example |
|---|---|---|
| `recall` | Query the Vault (memory) for remembered facts | `bctx recall "text wrapping"` |

**Understanding code**
| Command | What it does | Example |
|---|---|---|
| `plan` | Generate a skill-execution plan for a task | `bctx plan "add rate limiting"` |
| `smells` | Scan code for smells (unwraps, TODOs, unsafe, debug output) | `bctx smells` |
| `discover` | Find commands that ran WITHOUT bctx and estimate missed savings | `bctx discover` |
| `benchmark` | Measure savings + quality across your codebase | `bctx benchmark src/` |

**Cloud (optional — the free local tier needs none of this)**
| Command | What it does |
|---|---|
| `login` / `logout` / `status` | Cloud device-flow auth |
| `sync` | Sync Vault facts with the cloud |
| `mcp` | Start the MCP server (this is what `init` wires into your agent) |

---

## Part B — Lens modes (`--mode`, or `BCTX_MODE=`)

Every read/compression can be steered to a mode. `bctx modes` prints this live:

| Mode | Savings | Fidelity | Use when |
|---|---|---|---|
| `auto` | varies | varies | Default — bctx picks per command |
| `full` | 0% | 100% | You want raw output (debugging, piping) |
| `map` | 0% (expands) | — | Building whole-repo structure context |
| `signatures` | 60–85% | **low (~20%, lossy)** | Understanding a file's API surface (bodies dropped) |
| `entropy` | 50–75%* | **high (~87–89%)** | You need the real bodies, near-lossless |
| `aggressive` | 70–90% | medium | Noisy logs / test output, tight budget |
| `diff` | 30–55% | high | Reviewing a PR / git diff |
| `task` | 40–70% | medium | Filter output to a specific task hint |
| `reference` | 35–60% | high | Building a types/imports context bundle |
| `narrow` | 20–80% | budget-set | Force output into a fixed token budget |
| `lines:N-M` | depends | 100% | Extract a known line range |

*On real codebases we measure entropy at ~26–39% savings; the estimate ranges above are the
tool's built-in guidance. **Always read savings with fidelity** — `signatures` is lossy
(structure only); `entropy` keeps most content.

---

## Part C — Automatic command-output compression (111 tools, 9 categories)

When the agent (or you) runs a supported command through bctx, its output is compressed before
it reaches the model. `bctx patterns` lists all 111. Categories and representative tools:

| Category | Tools (examples) | Typical savings |
|---|---|---|
| **vcs** | git, gh, jj | 70–95% |
| **build** | cargo, go, make, gradle, bazel, nx, vite, turbo, swift, dotnet, … | 55–90% |
| **test** | pytest, jest, vitest, playwright, rspec | 70–90% |
| **lint** | eslint, ruff, mypy, clippy, golangci, biome, semgrep, trivy, … | 50–85% |
| **pkg** | npm, pnpm, yarn, bun, pip, poetry, uv, gem, brew, apt, … | 55–85% |
| **infra** | kubectl, docker, helm, terraform, aws, gcloud, az, pulumi, … | 60–85% |
| **db** | psql, mysql, prisma, redis, mongosh | 55–85% |
| **ai/data** | mlflow, ollama, dbt, spark, alembic, flyway | 55–80% |
| **sys** | curl, jq, env, systemd, mise | 50–80% |

The more verbose the command, the more it saves (a failing test run, a migration, a lint sweep).

---

## Part D — The 41 MCP skills (what the agent calls during a session)

After `bctx init`, these appear in the agent as tools (type `/mcp` in Claude Code). The Golden
Workflow tells the agent to prefer the compressing ones over raw file reads. Grouped:

**Reading & compressing source (10)**
`chisel` extract AST symbols in compact signatures · `blueprint` compact structural outline of
a file · `pinpoint` extract one named symbol · `parallax` read multiple files with per-file
lens · `harvest` batch-read up to 50 files with per-file compression · `condenser` compress a
file/string via a lens stack · `sieve` filter raw output to task-relevant lines · `unfold`
restore a condensed block to original · `thermal` token heatmap of a file · `render` Mermaid/
DOT diagram of the import graph.

**Search & navigation (12)**
`compass` fused BM25 + graph + memory ranked search · `scanner` fuzzy file/symbol finder ·
`resonator` dense-vector semantic search · `cartograph` directory → structured map · `prism`
full incremental AST index · `panorama` high-level project overview · `surveyor` dependency
topology (callers/callees, cycles) · `ripple` impact analysis (what depends on a file) ·
`crossroads` extract API routes · `pathfinder` extract HTTP routes (10+ frameworks) · `drift`
lines changed since a git ref · `flux` structured diff of a file vs last commit.

**Memory & context (8)**
`sediment` persist facts into the Vault · `archivist` query the Vault (read-only) · `meridian`
snapshot current context · `cartridge` package context into a portable bundle · `relay_ctx`
hand off context to another session · `chronicler` narrative of a session · `forecast` predict
files needed next · `diviner` infer intent from access patterns.

**Execution & ops (7)**
`scout` run a shell command with domain-aware compression · `sentinel` static security risk
assessment · `steward` session role + budget management · `ledger` real-time cost estimate ·
`echo` record compression feedback for tuning · `witness` record/replay tool-call sequences ·
`dispatch` meta-tool: call any skill by name.

**Quality & transform (4)**
`arbiter` structured code review from a diff/file · `alchemist` transform noisy content →
structured JSON · `crucible` run compression benchmarks across lenses · `scribe` context-aware
file editor (create/replace/append/delete).

---

## Part E — Extending & customizing bctx

**Force or change compression**
- `bctx read <file|-- cmd> --mode <mode>` — override the auto-picked mode (Part B).
- `BCTX_MODE=map bctx git log` — set a mode via environment for one command.
- `bctx read --mode lines:10-40 -- cat main.rs` — extract a specific range.

**Turn it off where you don't want it**
- `BCTX_BYPASS=1 <cmd>` — run one command with no interception.
- Put an empty `.bctx-bypass` file in a repo root — bctx skips that whole project.

**Steer the agent (the Golden Workflow)**
- `bctx init` writes `~/.claude/rules/bctx.md` with a **mandatory tool-mapping** (use
  `blueprint`/`chisel`/`parallax` over full reads; `compass`/`scanner` over grep; the
  `archivist`-at-start / `sediment`-on-discovery memory ritual). **This file is plain text —
  edit it** to change how aggressively the agent compresses, or add your own project rules.
- `bctx init --agent <name>` supports Claude Code, Cursor, and others; re-run per agent.

**Add memory the agent will reuse**
- The agent calls `sediment` on discovery; you can also seed facts through the MCP `sediment`
  tool. `bctx recall "<query>"` reads them back from the terminal.

**Measure & prove**
- `bctx benchmark <dir> --json` — machine-readable savings/fidelity per file per mode.
- `bctx benchmark <dir> --all-modes` — full per-mode breakdown.
- `bctx gain` / `bctx dashboard` — what you've actually saved locally.
- `bctx discover` — find commands you ran *without* bctx and how much you left on the table.

**Under the hood (for the curious)**
- Command compression is a **FilterMesh** of 111 domain matchers (`bctx patterns`); adding a
  new tool family is a matcher node in the Rust source.
- Modes are **lens stacks** (`bctx modes`); `condenser` lets the agent compose them at runtime.
- Everything runs **locally and offline** by default; the cloud tier only adds cross-machine
  Vault sync and a team dashboard.
