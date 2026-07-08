---
name: vapa-exec
description: Use when handed a VAPA issue link and asked to implement, plan, fix, or refine an approved proposal. Orchestrates artifact-driven execution using a project-local .vapa workspace, with multi-agent execution preferred and single-session execution allowed only as a fallback for small tasks.
---

# VAPA Issue Execution

## Overview

`vapa-exec` turns an approved VAPA proposal into a traceable implementation. It is an execution orchestrator, not merely a coding shortcut.

The skill must preserve the reasoning trail in a project-local workspace:

```text
.vapa/vapa-exec-<issue-id>/workspace/
```

This workspace is intended to be committed with the implementation when it contains no secrets or private data. It lets the team inspect how the Agent understood the proposal, planned the work, executed it, tested it, and prepared it for audit.

## When to Use

- A user pastes a VAPA issue URL and asks to implement, plan, fix, or refine it.
- The issue body or comments include proposal context, design notes, implementation constraints, screenshots, or acceptance criteria.
- The user asks for Agent execution after a proposal has been approved or explicitly authorizes execution.

If the user asks only to create or improve a proposal, use `vapa-proposal` instead. If implementation is complete and the user asks whether it is ready for PR or validation, use `vapa-audit`.

## Core Principle

Agent execution should be multi-agent by default, artifact-driven always, and single-session only as a fallback for small tasks.

```text
approved
  -> readiness-check
  -> context-ready
  -> plan-ready
  -> implemented
  -> tested
  -> audit-ready
```

## Required Workspace

Create a workspace at:

```text
.vapa/vapa-exec-<issue-id>/workspace/
```

Use the GitHub issue number as `<issue-id>` when available. If the source is not GitHub, use a stable slug such as `<host>-<project>-<id>`.

Required structure:

```text
.vapa/vapa-exec-<issue-id>/workspace/
  issue.json
  comments/
  images/
  issue-brief.md
  source-map.md
  readiness-report.md
  VAPA_EXEC_PLAN.md
  VAPA_EXEC_LOG.md
  TEST_REPORT.md
  PR_DRAFT.md
```

`VAPA_AUDIT.md` is produced by `vapa-audit` after implementation and tests are complete.

## Execution Flow

### Step 1: Fetch the Source of Truth

1. Fetch the raw issue with metadata, labels, body, comments, and author information.
   - Prefer `gh issue view --json` for GitHub issues.
   - Preserve a raw snapshot as `issue.json`.
2. Save each comment separately under `comments/`, numbered in chronological order.
3. Download referenced images into `images/` when permitted.
4. Record every source in `source-map.md`, including issue body, comments, images, linked documents, and important code references.

Do not rely on memory or remote-only context after this step.

### Step 2: Run the Readiness Gate

Before implementation, write `readiness-report.md` and decide whether execution may proceed.

Required checks:

- Issue is `status: approved`, or the user explicitly authorizes execution.
- Agent execution readiness checklist exists in the issue body or comments, or the user explicitly accepts the missing checklist.
- Acceptance criteria are concrete enough to test or manually verify.
- Boundaries are stated: what must not change, compatibility requirements, and out-of-scope work.
- Required context is available: relevant code, APIs, data structures, designs, or linked documents.
- `Size: M` or larger proposals are split into `Size: S` sub-issues, or the reason for continuing is explicitly documented.
- No new information invalidates the proposal's core assumptions.

If any blocking item fails, stop implementation. Produce `readiness-report.md` with `Verdict: BLOCKED` and ask for the missing human decision.

### Step 3: Synthesize the Brief

Write `issue-brief.md` with these sections:

- Background and problem
- Approved scope
- Explicit non-goals
- Acceptance criteria
- Design requirements
- Implementation requirements
- Open questions
- Human decisions already made

Every non-obvious claim should point back to `source-map.md`.

### Step 4: Plan

Write `VAPA_EXEC_PLAN.md` before editing code.

Required sections:

- Objective
- Non-goals
- Acceptance criteria mapping
- Files and modules likely to change
- Implementation steps
- Test strategy and commands
- Risks and rollback plan
- Human decision points

For `Size: S`, a single session may plan and implement inline. For `Size: M`, prefer separate Planner, Implementation, and Audit roles. For `Size: L` or `XL`, stop and request decomposition unless the issue already points to a smaller approved sub-issue.

### Step 5: Implement

Implement according to the plan. Keep changes scoped to the approved proposal.

Maintain `VAPA_EXEC_LOG.md` with:

- Files changed
- Steps completed
- Deviations from plan and why
- Key Agent-made judgments
- Human confirmations or blockers
- Follow-up items deferred out of scope

If the implementation reveals that the proposal's assumptions are wrong, stop and request a human decision instead of silently changing direction.

### Step 6: Test

Run the relevant checks and write `TEST_REPORT.md`.

Include:

- Commands run
- Pass/fail results
- Manual verification performed
- Acceptance criteria coverage
- Known gaps or tests not run, with reasons

If tests fail because of the implementation, return to Step 5. If tests fail because the proposal needs a decision, stop and record the blocker.

### Step 7: Prepare PR Draft

Write `PR_DRAFT.md` with:

- Suggested PR title
- Linked issue
- Implementation summary
- Acceptance criteria mapping
- Test evidence
- Known limitations
- VAPA workspace path
- Suggested contribution records

Do not claim the work is ready for PR until `vapa-audit` returns `READY_FOR_PR`.

## Multi-Agent Roles

Use separate agents or separate sessions when the environment supports it:

| Role | Responsibility | Output |
|---|---|---|
| Orchestrator | Gatekeeping, workspace setup, phase transitions | `readiness-report.md` |
| Context Agent | Issue/comment/image/repo context capture | `issue-brief.md`, `source-map.md` |
| Planner Agent | Plan and test strategy | `VAPA_EXEC_PLAN.md` |
| Implementation Agent | Code changes and execution log | code, `VAPA_EXEC_LOG.md` |
| Test Agent | Verification | `TEST_REPORT.md` |
| PR Agent | PR draft | `PR_DRAFT.md` |

When true multi-agent execution is unavailable, simulate these roles sequentially in one session and keep the same artifacts.

## Safety and Traceability

- The `.vapa` workspace is commit-worthy by default, but never commit secrets, private user data, production exports, or unreleasable third-party material.
- If sensitive information appears in an issue, summarize it and record the redaction in `source-map.md`.
- Do not delete or rewrite workspace artifacts to hide mistakes. Append corrections or add a new section explaining the revision.
- Do not expand scope just because implementation is easy. Scope changes require human approval or a proposal update.

## Handoff to Audit

After implementation and tests, invoke or recommend `vapa-audit` with the workspace path.

The handoff is ready only when these files exist:

- `issue-brief.md`
- `source-map.md`
- `readiness-report.md`
- `VAPA_EXEC_PLAN.md`
- `VAPA_EXEC_LOG.md`
- `TEST_REPORT.md`
- `PR_DRAFT.md`

Expected audit verdicts:

- `READY_FOR_PR`: move toward human validation and PR submission.
- `NEEDS_REVISION`: return to implementation or test.
- `BLOCKED_FOR_HUMAN_DECISION`: stop and ask the human to decide.

## Common Mistakes / Red Flags

- Starting code edits before `readiness-report.md` and `VAPA_EXEC_PLAN.md` exist.
- Treating comments as optional context.
- Using `/tmp` as the only execution record.
- Losing track of acceptance criteria during implementation.
- Auditing your own work without writing a separate audit artifact.
- Preparing a PR that lacks traceability back to the proposal.
