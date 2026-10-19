#!/usr/bin/env python3
"""
Layer 1 - Compressor coverage audit (deterministic, no model).

For each (source or command, compression mode) it independently derives the set of facts
the mode PROMISES to keep, then asserts every one survives bctx's compressed output. No LLM
is involved: the oracle is `ast` / a TS export regex / the raw command output itself, so the
result reproduces byte-for-byte on any machine.

Why this exists: the rest of bctx-eval measures token savings + fidelity (bctx's own
identifier-coverage %). Fidelity is a proxy. The historical ClarityLens bug dropped the
`* main` line from `git branch` yet still scored well on fidelity. This audit checks the
promised facts directly, so that class of data loss is caught at the source, for free.

Two tiers of check, deliberately kept separate:

  STRICT  (gates the exit code) — what an agent actually gets:
    * command output (git ...) under the default pipeline  -> must be preserved verbatim
    * `auto` mode on source files                          -> must keep every symbol
    A loss here is a real regression.

  OUTLINE (reported, never gates the exit code) — the opt-in, labeled-lossy `signatures`
    mode. It is a structural outline (~20% fidelity, bodies stripped) used for understanding,
    never the product's headline. We quantify EXACTLY how much it keeps (incl. where it drops
    arrow-function / class-container names in TS) so the tradeoff is on the table, not hidden.

Run via ./run_coverage_audit.sh (sets BCTX_BIN). Exit code is non-zero if a STRICT check
finds unexplained data loss, a target is missing (run ./fetch_corpora.sh), a command prints
nothing to check, or the regression fixture stops catching the known bug.
"""

from __future__ import annotations

import ast
import json
import os
import re
import subprocess
import sys
import tempfile
from contextlib import contextmanager
from pathlib import Path

HERE = Path(__file__).resolve().parent
EVAL_ROOT = HERE.parent.parent  # ~/Desktop/bctx-eval
BCTX = os.environ.get("BCTX_BIN", "bctx")
# bctx records executions and may sync them; the audit must touch neither the user's
# stats nor the cloud, so every bctx call gets a throwaway home and a closed-port endpoint.
SANDBOX_HOME = tempfile.mkdtemp(prefix="bctx-audit-home-")
BCTX_ENV = {
    k: v for k, v in os.environ.items() if k != "BCTX_BYPASS"
} | {"HOME": SANDBOX_HOME, "BCTX_ENDPOINT": "http://127.0.0.1:9", "BCTX_CLOUD_ENDPOINT": "http://127.0.0.1:9"}

# ------------------------------------------------------------------ helpers


def bctx_version() -> str:
    try:
        out = subprocess.run([BCTX, "--version"], capture_output=True, text=True, timeout=30)
        return out.stdout.strip() or out.stderr.strip()
    except Exception as e:  # noqa: BLE001
        return f"unknown ({e})"


def read_mode(mode: str, argv: list[str], cwd: Path | None = None) -> str:
    """`bctx read --mode <mode> -- <argv>` -> compressed text."""
    cmd = [BCTX, "read", "--mode", mode, "--"] + argv
    return subprocess.run(cmd, capture_output=True, text=True, timeout=180, env=BCTX_ENV, cwd=cwd or EVAL_ROOT).stdout


def hook_form(argv: list[str], cwd: Path) -> str:
    """What an agent gets: the shell hook rewrites `git status` to `bctx git status`."""
    return subprocess.run([BCTX] + argv, capture_output=True, text=True, timeout=180, env=BCTX_ENV, cwd=cwd).stdout


def read_default(path: Path) -> str:
    """`bctx read <file>` with no mode: what an agent gets when it reads a file through bctx."""
    return subprocess.run([BCTX, "read", str(path)], capture_output=True, text=True, timeout=180, env=BCTX_ENV, cwd=EVAL_ROOT).stdout


def bypass_file() -> Path | None:
    """bctx passes output through untouched when a `.bctx-bypass` file sits in its working
    directory or any parent (BCTX_BYPASS is already removed from BCTX_ENV). Every bctx call
    here runs inside EVAL_ROOT, so one such file would make each check compare raw output
    with raw output and pass whatever the compressors do."""
    for d in [EVAL_ROOT.resolve(), *EVAL_ROOT.resolve().parents]:
        if (d / ".bctx-bypass").exists():
            return d / ".bctx-bypass"
    for name in GIT_REPOS:
        if (EVAL_ROOT / name / ".bctx-bypass").exists():
            return EVAL_ROOT / name / ".bctx-bypass"
    return None


def run_off(argv: list[str], cwd: Path | None = None) -> str:
    """Raw command output with bctx fully bypassed (the ground truth)."""
    env = dict(os.environ, BCTX_BYPASS="1")
    return subprocess.run(argv, capture_output=True, text=True, timeout=180, env=env, cwd=cwd).stdout


# ------------------------------------------------------------------ oracles


def python_symbols(path: Path) -> list[str]:
    """Every real def/class name (independent oracle = the Python parser itself)."""
    tree = ast.parse(path.read_text())
    names = [
        n.name
        for n in ast.walk(tree)
        if isinstance(n, (ast.FunctionDef, ast.AsyncFunctionDef, ast.ClassDef))
    ]
    return sorted(set(names))


TS_FN = re.compile(r"\bexport\s+(?:async\s+)?(?:function|const|let|var)\s+([A-Za-z_$][\w$]*)")
TS_TYPE = re.compile(r"\bexport\s+(?:abstract\s+)?(?:class|interface|type|enum)\s+([A-Za-z_$][\w$]*)")


def ts_symbols(path: Path) -> tuple[list[str], list[str]]:
    """(exported function/const names, exported class/interface/type/enum names)."""
    src = path.read_text()
    return sorted(set(TS_FN.findall(src))), sorted(set(TS_TYPE.findall(src)))


def present(name: str, blob: str) -> bool:
    return re.search(r"\b" + re.escape(name) + r"\b", blob) is not None


# ------------------------------------------------ STRICT: auto mode on source


def strict_python_auto(rel: str) -> dict:
    path = EVAL_ROOT / rel
    promised = python_symbols(path)
    out = read_mode("auto", ["cat", str(path)])
    missing = [n for n in promised if not present(n, out)]
    return {
        "tier": "strict",
        "kind": "python-auto",
        "target": rel,
        "mode": "auto",
        "promised": len(promised),
        "kept": len(promised) - len(missing),
        "coverage_pct": round(100 * (len(promised) - len(missing)) / max(1, len(promised)), 1),
        "missing": missing,
        "status": "PASS" if not missing else "DATA_LOSS",
    }


def strict_ts_auto(rel: str) -> dict:
    path = EVAL_ROOT / rel
    fns, types = ts_symbols(path)
    out = read_mode("auto", ["cat", str(path)])
    fn_missing = [n for n in fns if not present(n, out)]
    ty_missing = [n for n in types if not present(n, out)]
    missing = fn_missing + ty_missing
    return {
        "tier": "strict",
        "kind": "ts-auto",
        "target": rel,
        "mode": "auto",
        "promised": len(fns) + len(types),
        "kept": len(fns) + len(types) - len(missing),
        "coverage_pct": round(
            100 * (len(fns) + len(types) - len(missing)) / max(1, len(fns) + len(types)), 1
        ),
        "missing": missing,
        "status": "PASS" if not missing else "DATA_LOSS",
    }


# ------------------------------------------------ STRICT: git command output


def strict_git_command(repo: Path, argv: list[str], label: str, path: str) -> dict:
    """Every non-blank line of the raw output must survive in the compressed output.

    git listing/status output is meant to be preserved verbatim (no lossy compression),
    so a missing line is real data loss. `path` is how the output reaches the agent:
    "hook" (`bctx git ...`, the form the shell hook rewrites every git command to) or
    "read-auto" (`bctx read --mode auto -- git ...`).
    """
    off = run_off(argv, repo)
    on = hook_form(argv, repo) if path == "hook" else read_mode("auto", argv, repo)
    off_lines = [ln.rstrip() for ln in off.splitlines() if ln.strip()]
    on_lines = [ln.rstrip() for ln in on.splitlines()]
    announced_trunc = bool(re.search(r"\.\.\.|\bmore\b", on))
    missing = [ln for ln in off_lines if ln not in on_lines]
    return {
        "tier": "strict",
        "kind": "git-command",
        "target": f"{label} [{path}]",
        "mode": "hook (bctx " + " ".join(argv) + ")" if path == "hook" else "auto",
        "promised_lines": len(off_lines),
        "kept_lines": len(off_lines) - len(missing),
        "missing_lines": missing,
        "announced_truncation": announced_trunc,
        # An empty raw output would make every line "kept": a vacuous pass, not a check.
        "status": "EMPTY_OUTPUT" if not off_lines else "PASS" if not missing else "DATA_LOSS",
    }


@contextmanager
def git_state(repo: Path):
    """A deterministic, multi-line git state: two extra branches, a modified tracked file and
    an untracked file. One-line outputs (a fresh clone's `* main`) are too small for bctx to
    compress at all, so they would pass whatever the compressors do. Restored afterwards."""
    git = ["git", "-C", str(repo)]
    for branch in ("eval/feature-a", "eval/feature-b"):
        subprocess.run(git + ["branch", "-f", branch, "HEAD"], check=True, capture_output=True)
    readme = repo / "README.md"
    original = readme.read_bytes()
    untracked = repo / "EQUIVALENCE_AUDIT_UNTRACKED.txt"
    readme.write_bytes(original + b"\nequivalence audit edit\n")
    untracked.write_text("untracked file for the equivalence audit\n")
    try:
        yield
    finally:
        readme.write_bytes(original)
        untracked.unlink(missing_ok=True)


# ------------------------------------------------ OUTLINE: signatures mode


def outline_python_signatures(rel: str) -> dict:
    path = EVAL_ROOT / rel
    promised = python_symbols(path)
    out = read_mode("signatures", ["cat", str(path)])
    missing = [n for n in promised if not present(n, out)]
    return {
        "tier": "outline",
        "kind": "python-signatures",
        "target": rel,
        "mode": "signatures",
        "promised": len(promised),
        "kept": len(promised) - len(missing),
        "coverage_pct": round(100 * (len(promised) - len(missing)) / max(1, len(promised)), 1),
        "missing": missing,
        "status": "FULL_OUTLINE" if not missing else "LOSSY_OUTLINE",
    }


def outline_ts_signatures(rel: str) -> dict:
    path = EVAL_ROOT / rel
    fns, types = ts_symbols(path)
    out = read_mode("signatures", ["cat", str(path)])
    fn_missing = [n for n in fns if not present(n, out)]
    ty_missing = [n for n in types if not present(n, out)]
    note = None
    if fn_missing:
        note = (
            "signatures does not parse `export const NAME = () => ...` arrow exports as named "
            f"definitions, so it dropped {len(fn_missing)} function name(s). This is a lossy "
            "outline (bodies stripped, ~20% fidelity); the default `auto` mode keeps them "
            "(see the strict ts-auto check)."
        )
    return {
        "tier": "outline",
        "kind": "ts-signatures",
        "target": rel,
        "mode": "signatures",
        "fn_promised": len(fns),
        "fn_kept": len(fns) - len(fn_missing),
        "fn_coverage_pct": round(100 * (len(fns) - len(fn_missing)) / max(1, len(fns)), 1),
        "fn_missing": fn_missing,
        "type_promised": len(types),
        "type_kept": len(types) - len(ty_missing),
        "type_coverage_pct": round(100 * (len(types) - len(ty_missing)) / max(1, len(types)), 1),
        "type_missing": ty_missing,
        "note": note,
        "status": "FULL_OUTLINE" if not fn_missing and not ty_missing else "LOSSY_OUTLINE",
    }


def outline_read_default(rel: str) -> dict:
    """`bctx read <file>` without --mode resolves to the `signatures` outline for files.
    Reported here, never gating, so the default an agent actually receives is on the record."""
    path = EVAL_ROOT / rel
    if rel.endswith(".py"):
        promised = python_symbols(path)
    else:
        fns, types = ts_symbols(path)
        promised = fns + types
    out = read_default(path)
    missing = [n for n in promised if not present(n, out)]
    return {
        "tier": "outline",
        "kind": "read-default",
        "target": rel,
        "mode": "bctx read <file> (default)",
        "promised": len(promised),
        "kept": len(promised) - len(missing),
        "coverage_pct": round(100 * (len(promised) - len(missing)) / max(1, len(promised)), 1),
        "missing": missing,
        "status": "FULL_OUTLINE" if not missing else "LOSSY_OUTLINE",
    }


# ------------------------------------------------ regression fixture


def check_regression_fixture() -> dict:
    """Prove the audit catches the real historical bug (dropped `* main`)."""
    fx = HERE / "regression_fixtures"
    expected = [ln.rstrip() for ln in (fx / "git_branch_expected.txt").read_text().splitlines() if ln.strip()]
    buggy = [ln.rstrip() for ln in (fx / "git_branch_buggy.txt").read_text().splitlines()]
    missing = [ln for ln in expected if ln not in buggy]
    caught = bool(missing)
    return {
        "tier": "regression",
        "kind": "regression-fixture",
        "target": "historical git-branch ClarityLens bug (pre-0.1.32)",
        "promised_lines": len(expected),
        "missing_lines": missing,
        "audit_caught_the_bug": caught,
        "status": "PASS" if caught else "REGRESSION_AUDIT_BROKEN",
    }


# ------------------------------------------------------------------ manifest

PYTHON_TARGETS = [
    "fastapi/fastapi/param_functions.py",
    "fastapi/fastapi/routing.py",
    "fastapi/fastapi/applications.py",
    "fastapi/fastapi/encoders.py",
]

TS_TARGETS = [
    "excalidraw/packages/excalidraw/history.ts",
    "excalidraw/packages/element/src/bounds.ts",
    "excalidraw/packages/common/src/utils.ts",
]

GIT_COMMANDS = [
    (["git", "branch", "-a"], "git branch -a"),
    (["git", "status", "-sb"], "git status -sb"),
    (["git", "log", "-n", "5", "--oneline"], "git log -n5 --oneline"),
]
GIT_REPOS = ["fastapi", "excalidraw"]


def missing_target(rel: str, kind: str) -> dict:
    """A target that is not on disk fails the audit: skipping it would pass while checking nothing."""
    return {
        "tier": "strict",
        "kind": kind,
        "target": rel,
        "status": "MISSING_TARGET",
        "hint": "run ./fetch_corpora.sh first (clones the corpora at their pinned commits)",
    }


def main() -> int:
    blocker = bypass_file()
    if blocker is not None:
        print(f"REFUSED: {blocker} turns bctx compression off for everything under it, so every")
        print("check would compare raw output with raw output. Run the audit from a folder")
        print("outside it (in better-ctx CI: copy bctx-eval to $RUNNER_TEMP first).")
        return 1

    strict, outline = [], []

    for rel in PYTHON_TARGETS:
        if (EVAL_ROOT / rel).exists():
            strict.append(strict_python_auto(rel))
            outline.append(outline_python_signatures(rel))
            outline.append(outline_read_default(rel))
        else:
            strict.append(missing_target(rel, "python-auto"))
    for rel in TS_TARGETS:
        if (EVAL_ROOT / rel).exists():
            strict.append(strict_ts_auto(rel))
            outline.append(outline_ts_signatures(rel))
            outline.append(outline_read_default(rel))
        else:
            strict.append(missing_target(rel, "ts-auto"))
    for name in GIT_REPOS:
        repo = EVAL_ROOT / name
        if not (repo / ".git").exists():
            strict.append(missing_target(name + ": git", "git-command"))
            continue
        with git_state(repo):
            for argv, label in GIT_COMMANDS:
                for path in ("hook", "read-auto"):
                    strict.append(strict_git_command(repo, argv, f"{name}: {label}", path))

    regression = check_regression_fixture()

    strict_loss = [r for r in strict if r["status"] != "PASS"]
    gate_fail = strict_loss or regression["status"] != "PASS"

    report = {
        "layer": "1 - compressor coverage audit (deterministic, no model)",
        "bctx_version": bctx_version(),
        "bctx_bin": Path(BCTX).name,
        "claim": "in the modes an agent actually gets (auto + command output), every promised "
        "fact survives; the opt-in `signatures` outline is separately quantified",
        "strict_checks": len(strict),
        "strict_data_loss": len(strict_loss),
        "regression_fixture": regression,
        "strict_results": strict,
        "outline_results": outline,
        "verdict": "NO DATA LOSS in agent-facing modes" if not gate_fail else "DATA LOSS DETECTED",
    }
    out_path = HERE / "coverage_audit_RESULTS.json"
    out_path.write_text(json.dumps(report, indent=2) + "\n")

    # ---- human summary
    print(f"bctx: {report['bctx_version']}  ({BCTX})")
    print()
    print("STRICT  — modes an agent actually gets (auto mode + raw command output):")
    print("-" * 70)
    for r in strict:
        if r["status"] == "MISSING_TARGET":
            print(f"  [  MISSING] {r['target']}  ({r['hint']})")
        elif r["kind"] in ("python-auto", "ts-auto"):
            print(f"  [{r['status']:>9}] {r['target']}  symbols {r['kept']}/{r['promised']} ({r['coverage_pct']}%)")
            if r["missing"]:
                print(f"               MISSING: {r['missing']}")
        else:
            print(f"  [{r['status']:>9}] {r['target']}  lines {r['kept_lines']}/{r['promised_lines']}")
            if r["status"] == "EMPTY_OUTPUT":
                print("               the raw command printed nothing, so there was nothing to check")
            if r["missing_lines"]:
                print(f"               MISSING LINES: {r['missing_lines']}")
    print()
    print("OUTLINE — opt-in `signatures` mode (labeled lossy, ~20% fidelity; NOT the headline):")
    print("-" * 70)
    for r in outline:
        if r["kind"] in ("python-signatures", "read-default"):
            label = "bctx read <file>" if r["kind"] == "read-default" else "signatures"
            print(f"  [{r['status']:>12}] {r['target']}  {label}: {r['kept']}/{r['promised']} ({r['coverage_pct']}%)")
        else:
            print(
                f"  [{r['status']:>12}] {r['target']}  fn {r['fn_kept']}/{r['fn_promised']} "
                f"({r['fn_coverage_pct']}%)  types {r['type_kept']}/{r['type_promised']} ({r['type_coverage_pct']}%)"
            )
            if r["note"]:
                print(f"               note: {r['note']}")
    print()
    rf = regression
    print("REGRESSION — does the audit still catch the historical bug?")
    print("-" * 70)
    verdict = f"caught dropped {rf['missing_lines']}" if rf["audit_caught_the_bug"] else "FAILED to catch"
    print(f"  [{rf['status']:>9}] {rf['target']}  ({verdict})")
    print()
    print("=" * 70)
    print(f"VERDICT: {report['verdict']}")
    print(f"  strict checks: {len(strict)} run, {len(strict_loss)} failed (data loss, missing target or empty output)")
    print(f"  wrote {out_path.relative_to(EVAL_ROOT)}")

    return 1 if gate_fail else 0


if __name__ == "__main__":
    sys.exit(main())
