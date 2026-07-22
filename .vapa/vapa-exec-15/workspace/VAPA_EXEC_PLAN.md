# VAPA_EXEC_PLAN — VEP-0004: vapa-review skill

## Objective

Deliver the `vapa-review` skill approved in issue #15: full-context proposal review
(body + comments), structured review comment auto-posted to the issue, phase-based
`status:*` label sync, idempotent re-runs, and doc updates — with zero authority
over approve/reject decisions.

## Non-goals

Per proposal: no decisions, no issue-body edits, no execution-workspace review,
no committee orchestration, no roadmap work. Also out of scope: publishing to npm
(the `npx skills add` mechanism already exists; we only add the skill directory).

## Acceptance criteria mapping

| AC | Implementation element | Verification |
|----|------------------------|--------------|
| AC1 installable, takes number/URL | `skills/vapa-review/SKILL.md` with valid frontmatter; Step 1 parses issue ref | Manual: frontmatter lint + skill dir layout check; argument-parsing unit tests |
| AC2 full body + comments | script `context` subcommand (gh issue view --json incl. comments) | Unit test with mocked gh asserting the json fields requested |
| AC3 Q1–Q5 + checklist with citations | SKILL.md review step + `references/review-comment.md` template | Manual: template contains all 5 questions + 6 checklist items |
| AC4 auto-post, label sync, idempotency | script `post` / `update` / `start` / `find-comment` subcommands; `<!-- vapa-review -->` marker | Unit tests: marker detection, label-transition decision matrix |
| AC5 no body edits, no decision labels | script exposes no issue-edit command; `start` only handles ready-for-review → in-review | Unit test: decision-label inputs produce refusal/no-op |
| AC6 docs rows | README.md + docs/framework.md edits | Manual diff review |

## Design

### Interfaces and contracts

`scripts/vapa-review.sh` subcommands (all take `--repo owner/repo`):

- `context --issue N` → prints `gh issue view` JSON (number, title, body, labels,
  author, comments). Single network call for full context (AC2).
- `find-comment --issue N` → prints the comment ID of the most recent comment
  containing `<!-- vapa-review -->`, or empty output if none. (Idempotency, AC4.)
- `post --issue N --body-file F` → `gh issue comment` with body from file.
- `update --comment-id ID --body-file F` → `gh api .../issues/comments/ID -X PATCH`.
- `start --issue N` → label sync: if `status: ready-for-review` present, remove it
  and add `status: in-review`, print what happened; any other status → no-op with
  printed explanation. Never touches other labels (AC5).

SKILL.md flow (agent-driven): parse issue ref → fetch context → assess against
Q1–Q5 + checklist, quoting issue content → write comment body from the
`references/review-comment.md` template to a `mktemp` file → `find-comment`;
none → `start` + `post`; exists → compare conclusions, `update` if unchanged in
substance or `post` a new round if materially changed → report.

### Data

No persistence, no migrations. Review state lives in the issue itself (marker
comment + labels) — consistent with "transparency replaces reporting".

### Error handling and edge cases

- Not a git repo / no `--repo` / `VAPA_REPO` unset → clear error (same as
  vapa-proposal).
- Issue fetch failure (bad number, auth) → surface `gh` stderr, stop.
- Issue in terminal/decision states (`approved`, `rejected`, `done`,
  `in-progress`, `in-validation`) → review comment still allowed (advisory), but
  `start` is a no-op and SKILL.md tells the agent to note the unusual state.
- `draft` / `refining` → comment only, no label change (proposer hasn't declared
  readiness).
- Missing `--body-file` or unreadable file → usage error, non-zero exit.

### Key decisions

1. **Label automation limited to ready-for-review → in-review.**
   Rejected alternative: also auto-set `refining` when major gaps are found.
   Why: proposal says decisions stay human; bouncing a proposal backward is a
   judgment call, not a phase marker. Review *starts* is objective; *outcomes*
   are not.
2. **Idempotency via hidden HTML marker `<!-- vapa-review -->`.**
   Rejected alternative: matching on author + comment title text. Why: author is
   shared with human comments and titles get edited; a hidden marker is
   unambiguous and invisible to readers.
3. **Re-run updates in place when conclusions are unchanged, posts a new round
   when materially changed.**
   Rejected alternative: always update the single comment. Why: a visible round
   history preserves the deliberation trail VAPA cares about; pure noise
   (identical re-runs) is the only thing suppressed.
4. **Review language follows the issue's dominant language.**
   Rejected alternative: fixed English. Why: this repo's proposals are Chinese;
   fixed language would degrade exactly the reports meant for proposers.
5. **Template in `references/review-comment.md`** rather than inline in SKILL.md.
   Rejected alternative: inline. Why: matches vapa-proposal's references pattern;
   keeps SKILL.md focused on workflow.

### New dependencies

None. Uses `gh` + `python3`, already required by the repo.

## Files and modules likely to change

- `skills/vapa-review/SKILL.md` (new)
- `skills/vapa-review/scripts/vapa-review.sh` (new)
- `skills/vapa-review/references/review-comment.md` (new)
- `tests/test-vapa-review.sh` (new)
- `README.md` (Included Skills table, layout tree, typical flow)
- `docs/framework.md` (Agent Skills table)
- `.vapa/vapa-exec-15/workspace/*` (artifacts, committed alongside)

## Implementation steps

1. `vapa-review.sh` backend + make executable → unit-testable functions first.
2. `tests/test-vapa-review.sh` → run, green.
3. `references/review-comment.md` template.
4. `SKILL.md` wiring the flow.
5. README.md + docs/framework.md rows.
6. Commit incrementally; update workspace artifacts per step.

Each step leaves the repo consistent; tests pass after step 2 and stay green.

## Test strategy and commands

- `bash tests/test-vapa-review.sh` — mocked `gh`, covers: arg parsing, context
  JSON fields, marker detection (found / not-found / latest-of-several), label
  decision matrix (each status → action), refusal of decision labels, body-file
  validation.
- `bash tests/test-vapa-proposal.sh` — regression: existing suite still passes.
- `bash -n skills/vapa-review/scripts/vapa-review.sh` — syntax.
- Frontmatter/layout manual check against vapa-proposal conventions.
- No live posting test (would spam issues); manual verification option recorded
  as a gap for the human validator.

## Risks and rollback

| Risk | Mitigation | Rollback |
|------|-----------|----------|
| Script posts to a real issue if misused during dev | No live calls in tests; live call only via explicit user invocation of the skill | Delete comment via gh |
| Label contract drift vs vapa-labels.py | Reuse exact label names from taxonomy; test matrix pins them | Revert commit |
| Marker format collides with future skills | Marker namespaced `vapa-review` | — |

Whole change is additive; rollback = revert the branch commits.

## Human decision points

- None expected during implementation. If label-transition scope feels wrong
  mid-build (broken-assumption class), stop and ask rather than expanding.
