# Codebase Survey — vapa-review implementation

## Impact area

| Path | Current responsibility | Change |
|------|------------------------|--------|
| `skills/vapa-review/` | does not exist | **new** — SKILL.md + scripts/vapa-review.sh |
| `tests/` | holds `test-vapa-proposal.sh` | **new** `test-vapa-review.sh` |
| `README.md` | project overview, Included Skills table (4 rows) | add `vapa-review` row; layout tree mention |
| `docs/framework.md` | framework spec, Agent Skills table (4 rows) | add `vapa-review` row |

## Existing patterns

- **Skill layout** (README "Repository Layout"): `skill-name/SKILL.md` + optional
  `scripts/` + `references/`. `vapa-proposal` and `vapa-init` follow this;
  `vapa-exec`/`vapa-audit` are SKILL.md-only. `vapa-review` has deterministic
  helpers (fetch/post/label), so it gets a `scripts/` dir like `vapa-proposal`.
- **SKILL.md style** (`vapa-proposal` as closest analog — user-invoked workflow
  skill): YAML frontmatter with `name`, `description`, `disable-model-invocation:
  true`, `allowed-tools`; body organized as Modes / Requirements / Execution steps
  / Output handling / References.
- **Shell backend** (`vapa-proposal.sh`): `set -euo pipefail`, usage header,
  flag parsing loop, `gh` for all GitHub I/O, python3 inline for JSON
  construction, `main` guarded so tests can source functions.
- **Tests** (`tests/test-vapa-proposal.sh`): bash, `set -euo pipefail`, source the
  script under test, override `gh()` with a stub, `assert_eq` helper, count
  failures.
- **Temp files**: unique via `mktemp` (lesson from the vapa-proposal fix); never
  fixed `/tmp` paths.

## Reusable assets

- `vapa-proposal.sh` argument-parsing and error-message idioms — copy the shape.
- Label names canonical in `skills/vapa-init/scripts/vapa-labels.py` — review
  transitions must use exactly these names.
- Review content source: `docs/framework.md` Layer 2.3 checklist + Layer 3.3
  Q1–Q5 — the SKILL.md must instruct the agent to cover exactly these.

## Contracts at the boundary

- **GitHub Issues via `gh`**: `gh issue view --json`, `gh issue comment`,
  `gh api` for comment PATCH and label add/remove. No new API surface introduced.
- **Status label taxonomy**: `status: draft | refining | ready-for-review |
  in-review | approved | in-progress | in-validation | done | deferred |
  rejected` — skill may only *remove* `ready-for-review` and *add* `in-review`;
  all other transitions are human-owned (proposal non-goal + AC5).
- **Review comment marker**: new contract `<!-- vapa-review -->` (hidden HTML
  comment) — owned by this skill; used for idempotency.
- **skills distribution**: `skills/` is the canonical surface for
  `npx skills add insentek/VAPA@vapa-review` (AC1). `.agents/` and `.claude/`
  are untracked local install mirrors, not edited by this change.

## Constraints discovered

- No CI in repo; `tests/` scripts are run manually. Keep them self-contained and
  network-free (mock `gh`).
- `gh` CLI + python3 are established requirements (README) — the script may rely
  on both.
- README and framework.md are user-facing docs in English and Chinese
  respectively; match each file's existing language.
