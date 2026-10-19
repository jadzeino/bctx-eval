#!/usr/bin/env bash
# fetch_corpora.sh — clone the two audited codebases at the commits this audit is pinned to.
#
# Each is a shallow fetch (20 commits, so `git log -n5` has five lines) checked out as a branch
# named `main`, so `git branch` prints a `* main` line: the exact line the historical ClarityLens
# bug dropped. A clone that
# already exists is accepted only at its pinned commit; anything else is an error, because the
# audit's numbers are only comparable on the same sources.
#
#   usage:  ./fetch_corpora.sh        (clones next to EQUIVALENCE/, at the bctx-eval root)

set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

fetch() {
  local name="$1" url="$2" sha="$3" dir="$ROOT/$1" head
  if [ -d "$dir/.git" ]; then
    head="$(git -C "$dir" rev-parse HEAD)"
    if [ "$head" != "$sha" ]; then
      echo "$name is at $head, not the pinned $sha; check it out or remove the folder" >&2
      return 1
    fi
    echo "$name: already at ${sha:0:12}"
    return 0
  fi
  git init -q "$dir"
  git -C "$dir" remote add origin "$url"
  git -C "$dir" fetch -q --depth 20 origin "$sha"
  git -C "$dir" -c advice.detachedHead=false checkout -q -B main FETCH_HEAD
  echo "$name: fetched ${sha:0:12}"
}

fetch fastapi https://github.com/fastapi/fastapi.git cecd96d9c6c318e0df1c40cedbc2e953381ddfd3          # v0.139.0
fetch excalidraw https://github.com/excalidraw/excalidraw.git 51ca8abde450e44f8f0db1b2708e0408915c7ab1
