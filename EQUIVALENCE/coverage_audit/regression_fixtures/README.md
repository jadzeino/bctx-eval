# Regression fixture — the bug fidelity did not catch

In an early build, bctx's `ClarityLens` treated `#`/`*`/`//`-prefixed lines as strippable
"comments" on **all** text, not just source code. Running it over `git branch` output
therefore dropped the current-branch line (`* main`). bctx's fidelity metric
(identifier coverage) still scored the output well — the branch names were all still there —
so **fidelity alone did not flag the loss**. It was fixed in v0.1.32 via content-kind routing
(comments are only stripped for `SourceCode`, never command output).

This fixture is the permanent, model-free proof that the layer-1 audit catches that class of
bug:

- `git_branch_expected.txt` — the raw truth (what `git branch -a` actually prints, incl. `* main`).
- `git_branch_buggy.txt` — the pre-fix compressed output, with `* main` dropped.

`coverage_audit.py::check_regression_fixture()` runs the same line-coverage logic used on the
live git checks against these two files. It must report `* main` as missing, i.e.
`audit_caught_the_bug: true`. The check is marked `PASS` precisely because the audit **did**
catch the historical data loss — which is the whole point: outcome/line coverage catches what
identifier fidelity missed.
