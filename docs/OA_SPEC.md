# oa — Requirements Spec

oa is the single entry point for installing, deploying, and verifying the
agent setup. Source of truth = `registry/`. Each requirement maps to tests
in `tests/test_oa.py`.

## R1 — Deploy (`oa deploy`)

- Copies `config/{opencode,tui,fallback,oh-my-opencode-slim}.json` and
  `agents/**.md` into `$OA_HOME/.config/opencode/` (default `~/.config/opencode/`).
- Substitutes `${VAR}` placeholders using the target's `.env`
  (via `scripts/substitute_env_in_json.py`).
- Verifies every deployed JSON parses; exits 1 on any failure.
- Reports per-file status.

## R2 — Doctor (`oa doctor`)

Verifies the active profile end-to-end (exit 1 on any FAIL):

- A profile resolves (`.oa.yaml` > global > base-only is WARN, not FAIL).
- Repo `opencode.json` (the project override) parses as JSON.
- Every local MCP command in that file resolves on PATH; remote URLs skipped.
- Project-local skill dirs match the resolved profile.

## R3 — oa owns the flow

- `make deploy` / `make doctor` delegate to oa; `make validate` already
  lints the registry + fallback coverage.
