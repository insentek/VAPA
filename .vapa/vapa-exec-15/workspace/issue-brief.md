# Issue Brief — VEP-0004: vapa-review skill

## Background and problem

VAPA's Review layer (framework Layer 3) defines five review questions and a quality
checklist (Layer 2.3), but no skill supports it. Reviewers must read full issues
manually; feedback is inconsistent and proposals stall in `draft` / `refining`.
README's Contributing section explicitly lists `vapa-review` as a wanted addition.
(Sources: #1, #8, #9 in source-map.md)

## Approved scope

A new `vapa-review` skill that, given an issue number or URL:

1. Fetches the issue's full body and all comments via `gh`.
2. Reviews the proposal against the framework's 5 review questions (Q1–Q5) and the
   2.3 quality checklist, quoting specific issue content as evidence.
3. Automatically posts a structured review comment (`gh issue comment`) — no
   confirmation step (user decision in proposal clarification).
4. Syncs `status:*` labels according to review phase (user decision: comment +
   label updates).
5. Is idempotent on re-run: recognizes its own previous review comment instead of
   spamming.

Also in scope: README and docs/framework.md skill tables updated.

## Explicit non-goals

- No approve / reject / defer decisions — those stay with the human review committee.
- No review of execution workspaces or code (that's `vapa-audit`).
- No modification of the issue body.
- No multi-reviewer committee orchestration (lottery, vote aggregation).
- No Roadmap prioritization.

## Acceptance criteria

| # | Criterion |
|---|-----------|
| AC1 | Installable via `npx skills add insentek/VAPA@vapa-review`; accepts issue number or URL |
| AC2 | Fetches full body + all comments via `gh`; review based on complete context |
| AC3 | Review comment covers Q1–Q5 and the 2.3 checklist, citing specific issue content |
| AC4 | Comment auto-posted; `status:*` labels synced by phase; re-run detects own prior comment (update or note, no spam) |
| AC5 | Never edits issue body; never sets `approved` / `rejected` decision labels |
| AC6 | README + docs/framework.md skill tables gain `vapa-review` row |

## Design requirements

- Follow existing skill layout: `SKILL.md` + `scripts/` (deterministic helpers);
  frontmatter and step-flow style consistent with `vapa-proposal`.
- Review comment format structured and machine-markable (hidden marker for
  idempotency).
- Shell backend mirrors `vapa-proposal.sh` conventions; testable with mocked `gh`
  per `tests/test-vapa-proposal.sh`.

## Implementation requirements

- New: `skills/vapa-review/SKILL.md`, `skills/vapa-review/scripts/vapa-review.sh`,
  `tests/test-vapa-review.sh`.
- Modified: `README.md`, `docs/framework.md` (Agent Skills tables).

## Open questions (from proposal, resolved during execution)

- Which label transitions to automate → decided in plan (ready-for-review →
  in-review on review start; everything else advisory-only).
- Review comment language → follow the issue's dominant language (agent judgment,
  logged).
- Re-run behavior → update existing comment when conclusions unchanged; new round
  comment when materially changed.

## Human decisions already made

1. Execution authorized despite missing in-issue readiness checklist (2026-07-22).
2. Size M executed in a single session with simulated roles; decomposition skipped
   as overhead (2026-07-22).
3. Prior unrelated changes committed to main first (36a483f), branch cut clean.
4. Proposal clarification answers: fully automatic comment posting; comment +
   label updates; Size M.
