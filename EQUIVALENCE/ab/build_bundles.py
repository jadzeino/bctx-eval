#!/usr/bin/env python3
"""
Layer 2 (part 1) - deterministic context-bundle builder. NO model, free, reproducible.

For every task in tasks.json it writes the exact text each condition sees:
  bundles/<id>/OFF.txt   full raw context (BCTX_BYPASS command output / raw file)
  bundles/<id>/ON.txt    the same context passed through `bctx read --mode <on_mode>`
  bundles/<id>/meta.json bytes + %-smaller + mode, so the compression is on the record

The A/B run (run_equivalence, executed with controlled-context subagents) feeds ON.txt to
one agent and OFF.txt to another with the identical task prompt, then scores both. Committing
the bundles means the evaluator can see precisely what differs between ON and OFF, and can
replay the A/B with any model of their choosing.
"""

import json
import os
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
EVAL_ROOT = HERE.parent.parent  # ~/Desktop/bctx-eval
BCTX = os.environ.get("BCTX_BIN", "bctx")


def resolve(argv: list[str]) -> list[str]:
    return [a.replace("{fastapi}", str(EVAL_ROOT / "fastapi")).replace("{excalidraw}", str(EVAL_ROOT / "excalidraw")) for a in argv]


def full_context(ctx: dict) -> str:
    if ctx["type"] == "file":
        return (EVAL_ROOT / ctx["path"]).read_text()
    argv = resolve(ctx["argv"])
    env = dict(os.environ, BCTX_BYPASS="1")
    return subprocess.run(argv, capture_output=True, text=True, timeout=180, env=env).stdout


def on_context(ctx: dict) -> str:
    mode = ctx["on_mode"]
    if ctx["type"] == "file":
        argv = ["cat", str(EVAL_ROOT / ctx["path"])]
    else:
        argv = resolve(ctx["argv"])
    cmd = [BCTX, "read", "--mode", mode, "--"] + argv
    return subprocess.run(cmd, capture_output=True, text=True, timeout=180).stdout


def main() -> int:
    tasks = json.loads((HERE / "tasks.json").read_text())["tasks"]
    index = []
    for t in tasks:
        d = HERE / "bundles" / t["id"]
        d.mkdir(parents=True, exist_ok=True)
        off = full_context(t["context"])
        on = on_context(t["context"])
        (d / "OFF.txt").write_text(off)
        (d / "ON.txt").write_text(on)
        pct = round(100 * (1 - len(on) / max(1, len(off))))
        meta = {
            "id": t["id"],
            "repo": t["repo"],
            "kind": t["kind"],
            "on_mode": t["context"]["on_mode"],
            "off_bytes": len(off),
            "on_bytes": len(on),
            "pct_smaller": pct,
        }
        (d / "meta.json").write_text(json.dumps(meta, indent=2) + "\n")
        index.append(meta)
        print(f"{t['id']:<34} {t['context']['on_mode']:<11} {len(off):>8} -> {len(on):>8}  ({pct:>3}% smaller)")

    (HERE / "bundles" / "INDEX.json").write_text(json.dumps({"bctx": Path(BCTX).name, "bundles": index}, indent=2) + "\n")
    print(f"\nwrote {len(index)} bundles under {(HERE / 'bundles').relative_to(EVAL_ROOT)}/")
    return 0


if __name__ == "__main__":
    sys.exit(main())
