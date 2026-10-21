---
name: vapa-exec
description: Implement or resume an approved or explicitly authorized VAPA issue, including execution planning and implementation revisions. Keeps a project-local .vapa execution record; the Agent chooses how to execute while humans keep authority over scope and acceptance. Use vapa-proposal for proposal drafting and vapa-review for proposal assessment.
---

# VAPA Issue Execution

## Overview

`vapa-exec` turns an approved VAPA proposal into a traceable implementation. It keeps the contract, the decisions and the evidence in a project-local workspace:

```text
.vapa/vapa-exec-<issue-id>/workspace/
```

The workspace is intended to be committed with the implementation when it contains no secrets or private data. It lets a fresh session resume the work and lets reviewers see what was promised, what was decided and what was proven.

## When to Use

- A user pastes a VAPA issue URL and asks for implementation, execution planning, or revisions to its implementation.
- The issue body or comments include proposal context, design notes, implementation constraints, screenshots, or acceptance criteria.
- The user asks for Agent execution after a proposal has been approved or explicitly authorizes execution.

If the user asks only to create or improve a proposal, use `vapa-proposal` instead. If implementation is complete and the user asks whether it is ready for PR or validation, use `vapa-audit`.

## Core Principle

Humans decide what is worth doing and what counts as done. The Agent decides how to get there and proves it.

Only three kinds of rules in this skill are binding:

- **Authority.** Approval, scope, acceptance criteria, non-goals, confirmed designs and new dependencies belong to humans. Changing any of them requires a human decision.
- **Facts.** Branches, worktrees, tracker semantics, single-writer records and closing-keyword behavior work the way they work. Respect them.
- **Evidence.** Every claim that something works is backed by an observation recorded in the workspace: a diff, command output or a rendered screenshot. Unknown or interrupted is never passed.

Everything else is the Agent's judgment: how to explore, when to prototype, whether to use helper agents, how to break down and order the work. Make the call, record non-obvious choices with their reasons, and keep going. Do not recreate human-organization rituals, such as phase handoffs between roles, sign-offs on purely technical breakdowns or size-based splitting, where they add neither authority nor evidence.

## Lifecycle

Phases describe what has been evidenced, not a mandatory order of thinking:

```text
approved
  -> readiness-check   authorization and contract verified
  -> context-ready     sources snapshotted, brief written
  -> plan-ready        contract-affecting decisions recorded
  -> implementing -> implemented
  -> testing -> tested
  -> audited
```

The audit verdict is recorded separately in `state.json` `audit`, not as a phase: `READY_FOR_PR`, `READY_TO_INTEGRATE`, `NEEDS_REVISION` or `BLOCKED_FOR_HUMAN_DECISION`.

Exploration is allowed in any phase, including before the plan: reading code, running the application and writing throwaway spikes in a scratch worktree. A scratch worktree is a separate Git worktree or throwaway branch, never the issue branch. Its findings feed the plan. Spike code becomes delivery code only after the plan records the decisions it embodies (see Step 4).

The current state must always be recoverable from the workspace alone. A new session resumes from verified artifacts and the event cursor, never from assumed completion.

## Workspace

Ensure the workspace exists. If `vapa-design` ran first, it already holds a `design/` archive of the confirmed design comments; reuse it and never wipe or restart it. Use the GitHub issue number as `<issue-id>` when available; otherwise use a stable slug such as `<host>-<project>-<id>`.

```text
.vapa/vapa-exec-<issue-id>/workspace/
  state.json            # versioned snapshot
  events.jsonl          # append-only observed events
  issue.json            # raw issue snapshot
  comments/             # one file per comment, chronological
  images/               # referenced screenshots and design assets, when any
  issue-brief.md        # contract, sources and readiness verdict
  VAPA_EXEC_PLAN.md     # decisions, contracts, criteria mapping, test strategy
  VAPA_EXEC_LOG.md      # judgments, deviations and blockers, not a diff summary
  TEST_REPORT.md
  evidence/             # command output, screenshots, recordings
  PR_DRAFT.md
```

Conditional artifacts:

- `ui-spec.md` when the change touches user-facing UI (see Frontend Execution Requirements).
- `decomposition.md` when the work is split into tracker sub-issues (see Tracker Decomposition).
- `design/` when `vapa-design` ran first. The issue comments remain the canonical record; treat the directory as read-only input.

`VAPA_AUDIT.md` is produced by `vapa-audit`.

Scale depth to risk and ambiguity, not to a template. A low-risk change may have a one-screen brief and plan. Do not restate what Git history, the event stream or the diff already record.

Older workspaces may contain `source-map.md`, `readiness-report.md` or `codebase-survey.md`. Keep them and continue in place; do not move their content just to change the layout.

### State and events

Before initializing, resuming or handing over execution, read [references/execution-state.md](references/execution-state.md). It defines the version 1 snapshot, append-only events, single-writer ownership, legacy migration and read-only checks. Keep lifecycle phase, worker activity, audit verdict, integration and tracker status separate, and link reports instead of growing `state.json`.

Update the snapshot and append an event at each actual transition. Record tests and audits against their tested source. Stale observations, failed sync and interrupted tests stay visible. Validate with the installed `scripts/exec-state.py check <workspace>`; no background service is required.

## Execution Flow

### Step 1: Snapshot the Sources

1. Fetch the raw issue with metadata, labels, body, comments and author information (prefer `gh issue view --json`) and save it as `issue.json`.
2. Save each comment under `comments/`, numbered chronologically.
3. Download referenced images into `images/` when permitted.
4. Record `size` (from the issue's `Size` field, or estimated), `domain` (frontend, backend, mixed or docs) and `risk` in `state.json`. Frontend or mixed work triggers the Frontend Execution Requirements; high risk triggers the extended design coverage in Step 4.

Do not rely on memory or remote-only context after this step.

### Step 2: Write the Contract

Write `issue-brief.md` with:

- **Background and problem**
- **Contract**: acceptance criteria, boundary constraints, "this is not" exclusions, confirmed design decisions and human decisions already made. Quote each one word for word with its source reference. Interpretation may sit next to a quote but never replaces it.
- **Approved scope**
- **Open questions**
- **Sources**: issue body, comments, images, linked documents, important code references and any redactions.
- **Readiness** (Step 3)

Confirmed design comments (`<!-- vapa-design: ... status=confirmed -->`) are part of the contract. When several versions exist, the highest `v=` wins, and the plan may not contradict it.

After writing, re-read the raw sources once in the reverse direction: every substantive requirement, constraint and later-comment amendment appears in the brief or is listed under "Deliberately excluded" with a reason.

The brief is a working index, not the authority. Whoever plans, implements, tests or audits works from the quoted contract and goes back to `issue.json` and `comments/` for anything the brief only summarizes. If they conflict, the raw source wins; append a dated correction to the brief.

### Step 3: Readiness Gate

Record `Readiness: READY` or `Readiness: BLOCKED` in the brief, with the reason.

Blocking checks:

- The issue is `status: approved`, or it is a sub-issue listed in the approved parent's `decomposition.md`, or the user explicitly authorizes execution.
- The Agent execution readiness checklist exists in the issue body or comments, or the user explicitly accepts its absence.
- Acceptance criteria are concrete enough to test or verify manually.
- Boundaries are stated: what must not change, compatibility requirements and out-of-scope work.
- No new information invalidates the proposal's core assumptions.
- The scope is one deliverable. If the proposal bundles several independently valuable outcomes that cannot be accepted as one whole, as `Size: XL` proposals often do, return it to the Proposal/Review layer for re-scoping. This is a decision about value, not a sizing rule.
- For UI work, design references exist (screenshots, mockups or an explicit "follow the existing design system"), or the gap is recorded as a human decision point.
- In a defect-fix round (see Defect Handling), the human has confirmed the fix list built from defect comments added since the last run.

Record but do not block:

- The `Size` field: a human estimate used for calibration. It does not select the execution strategy.
- A non-trivial design surface without confirmed `vapa-design` comments: recommend running `vapa-design` first.
- A dirty working tree or a base behind the default branch: record it and handle it deliberately.

When blocked, stop delivery work and ask for the missing decision. Exploration that helps the human decide may continue.

### Step 4: Plan

Write `VAPA_EXEC_PLAN.md`. You may write it after exploring or prototyping when that produces better decisions. It must exist, with the decisions below recorded, before delivery code lands on the issue branch, because these decisions are expensive to reverse and reviewers must check them:

- **Objective and non-goals**, referencing the contract.
- **Codebase findings**: impact area, existing patterns and the closest analogs to follow, reusable assets, boundary contracts and their dependents, and build, lint or CI constraints. New code follows the closest existing analog unless the plan justifies deviating.
- **Design**:
  - Interfaces and contracts: function/API signatures, component props, events or schema changes.
  - Data: model changes, migrations and backward compatibility.
  - Error handling and edge cases at system boundaries.
  - Key decisions: for each non-obvious choice, the selected option, at least one rejected alternative and why. High-risk changes (data models, public APIs, auth, payments, shared infrastructure) also cover security, performance and rollout.
  - New dependencies: each needs a justification and is a human decision point unless the proposal already approved it.
- **Execution strategy** and why (Step 5).
- **Acceptance criteria mapping**: each criterion to its implementation area and its verification.
- **Test strategy and commands.**
- **Risks and rollback.**
- **Human decision points.**

For UI work, reference `ui-spec.md` and map acceptance criteria to concrete screens and states.

Implementation order and internal steps are working notes; keep them only as long as they help. Revise the plan by appending dated notes, not by rewriting history.

### Step 5: Choose an Execution Strategy

Choose based on the work and record the reason in the plan:

| Strategy | Use when |
|---|---|
| Inline | One agent can hold the context and the work is mostly sequential. This is the default at any `Size`. |
| Helper agents | Independent parts can proceed in parallel, alternatives are worth exploring side by side, or a side investigation would flood the main context. The coordinator integrates; no tracker issues are created. |
| Tracker decomposition | The work contains deliverables that humans should see, track or validate separately, or a risk boundary needs its own audit. Requires `decomposition.md` and human approval (see Tracker Decomposition). |

Multi-agent work pays off in two ways: parallel work on independent parts, and independent verification. Always prefer a separate agent or session for `vapa-audit`. Do not divide work by phase into role handoffs (context, then planning, then implementation, then testing); each handoff loses context and adds no evidence.

When delegating, give the receiver the quoted contract, paths to the raw sources, the interfaces it must respect, its worktree and its definition of done, not just a summary.

Helper agents follow the facts of shared work:

- Parallel writers use separate worktrees. Helpers never write directly to the issue branch or to `state.json`/`events.jsonl`.
- The coordinator merges a helper's work only after checking it against its definition of done and running the affected tests.
- Record helper assignments in the log only when they shaped the result.

If the work proves larger than estimated but the contract is unchanged, keep going: break it down internally and record the recalibration. Only a contract change needs a human.

### Step 6: Implement

Git discipline:

- Work on a dedicated branch named `vapa/<issue-id>-<slug>` unless the repository has its own convention. Tracker sub-issues land on the parent's branch.
- Commit in coherent, buildable increments that reference the issue number. Commit workspace updates with the work they describe.

Handle deviations by whether they touch the contract:

1. **Within the contract** (structure, file layout, ordering, extra steps, a technical approach the plan left open): decide. Log the decision if it is non-obvious, and append a plan revision note if it changes a recorded decision.
2. **Contract change** (scope grows, an acceptance criterion or a confirmed design cannot be met as written, the approved approach cannot work, an unapproved new dependency is needed, or a public contract must change beyond the approved scope): stop and request a human decision. Never silently change direction or expand scope.

`VAPA_EXEC_LOG.md` records what Git cannot: key judgments and their reasons, deviations, spikes and what they showed, helper outcomes that shaped the result, blockers, human confirmations and deferred follow-ups. Reference commits instead of restating file lists or step-by-step history.

At actual transitions, append the event, update the snapshot and log as needed, then commit. On resume, check the event cursor; preserve and reconcile recording faults without inventing history.

### Step 7: Test

Run the relevant checks and write `TEST_REPORT.md`:

- Commands run, with actual output captured in `evidence/`
- Pass/fail results
- Manual verification performed
- Acceptance criteria coverage: every criterion maps to a test, a manual check or an explicitly recorded gap
- Regression check: the existing test suite and lint/build for the impacted area still pass
- Known gaps or tests not run, with reasons

Reuse existing verification only when the tested source and relevant inputs are unchanged; name its source and evidence. Re-run affected checks after changes. Documentation-only checkpoints do not justify repeating a build or test run.

For UI work, testing also requires visual evidence (see Frontend Execution Requirements).

If tests fail because of the implementation, fix and re-test. If they fail because the proposal needs a decision, stop and record the blocker.

### Step 8: Prepare the PR Draft

Write `PR_DRAFT.md` with:

- Suggested PR title (`[#<issue>] verb + object`)
- Linked issue
- Implementation summary
- Acceptance criteria mapping
- Test evidence, including visual evidence for UI changes
- Known limitations
- VAPA workspace path
- Suggested contribution records

For a decomposed parent, organize the summary and criteria mapping by sub-issue so reviewers can review the PR segment by segment. Include an explicit closing reference for the parent **and every approved sub-issue delivered by the PR**, one per line with the keyword repeated (`Closes #42`, `Closes #43`, `Closes #44`). Use full issue URLs when repository identity would be ambiguous. A range, an ordinary mention, a task list or a native parent-child link does not replace these lines.

Before creating or updating the PR, reconcile the closing set against the approved decomposition, the integrated child records and the complete tracker child list (including pagination). Resolve missing or extra children; do not close unrelated references or prerequisites. Read back the published PR body to confirm the set. Keep issues open until the normal merge and acceptance flow.

GitHub interprets closing keywords only for PRs targeting its default branch. For an intentionally different integration target, keep the references, disclose that merging will not auto-close the issues and follow the repository's closure flow. See [GitHub's closing-keyword semantics](https://docs.github.com/en/issues/tracking-your-work-with-issues/using-issues/linking-a-pull-request-to-an-issue).

Do not claim the work is ready for PR until `vapa-audit` returns `READY_FOR_PR`.

## Tracker Decomposition

Tracker sub-issues are delivery units that humans see, not agent assignments. Because every child ships in the parent's single PR, splitting does not shrink what a human reviews. If the only benefit is agent parallelism or context isolation, use helper agents instead.

1. **Benefit first.** Each child has its own acceptance boundary and a concrete benefit: independent validation, separate visibility or ownership for humans, or isolation of a real risk boundary. Weigh that benefit against the cost of planning, worktrees, audits and integration (see the benefit check in [references/decomposition.md](references/decomposition.md)). Keep a cohesive capability, such as its API, necessary UI and tests, together. There is no target child count and no size requirement for children.
2. **Human approval before issue creation.** Present `decomposition.md` (template: `references/decomposition.md`, relative to this installed `SKILL.md`) with the children, their dependency edges and the integration criteria for the parent. Create tracker sub-issues only after approval, and record both in the log. Later, reconfirm only changes to the child set or to acceptance; do not re-ask for authorization already granted.
3. **Tracker linkage.** On GitHub, use native sub-issues. Elsewhere, use a task list in the parent body plus a first-line parent reference in each child. Record the method in `decomposition.md`. The workspace remains the execution record; tracker linkage is for visibility.
4. **Approval coverage.** The parent's approval covers the children listed in `decomposition.md`. A child outside that list is a scope change and requires a human decision.
5. **One tracker level.** Children are not split into further tracker issues, but a child may use helper agents and internal breakdown freely. A child that only proves larger than estimated keeps going. If its acceptance boundary proves wrong (it cannot be accepted on its own, or it needs scope outside its listing), that changes the decomposition and requires a human decision.
6. **Contracts first.** Cross-cutting interfaces, schemas, events and design tokens are defined in the parent plan before child implementation starts.
7. **Dual entry.** `vapa-exec` accepts a parent URL (orchestration: reconcile state, dispatch ready children, integrate, prepare the parent audit) or a child URL (execute only that child after reading the parent's `decomposition.md` and contracts). If the parent workspace is missing locally, direct the user to run `vapa-exec` on the parent first.
8. **Single writer.** Only the coordinator writes the parent `state.json`, parent events and parent roll-up comments. Children write their own workspace and their own issue comments.
9. **Lightweight child records.** A child workspace keeps the same files, but its brief quotes the child's acceptance from `decomposition.md` and links the parent contract, and its plan reuses the parent's codebase findings instead of repeating them.
10. **Integration gate.** A child is merged into the parent branch only after its audit returns `READY_TO_INTEGRATE`. The coordinator merges with commits that reference the child and records the integration receipt. Children never write to the parent branch.
11. **Dependency-ready dispatch.** Use `scripts/exec-state.py ready <parent-workspace> --capacity <worker-slots>` for candidates and waiting reasons, and follow the dispatch rules in [references/execution-state.md](references/execution-state.md). In short: `depends_on` lists only real prerequisites; file or resource conflicts are not dependencies; a child starts once its direct prerequisites are audited and integrated, a slot is free and nothing conflicting is active; its worktree is refreshed from the current parent revision; topological levels are never barriers. Verify Git and report evidence before dispatching.
12. **Integration pass.** After every child is merged, verify that the parts compose, run the full test suite and record the result in the parent `TEST_REPORT.md` before the parent audit.

## Revision and Escalation

- `NEEDS_REVISION` returns the work to implementation or testing; increment `revision_count`.
- Escalate when progress stalls, not at a fixed count: the same underlying finding survives two revision attempts without a materially different approach or new evidence, or a finding traces back to the contract (ambiguous criteria, an approach that cannot work). Repeated failure on one finding is evidence of a broken assumption.
- Fixing distinct findings in successive rounds is progress; continue.
- In decomposed mode, each child counts its own rounds and the parent counts only integration rounds.

## Frontend Execution Requirements

These apply whenever the domain is frontend or mixed.

### ui-spec.md

Before implementation, translate all design inputs (images, mockups, textual descriptions) into `ui-spec.md`:

- **Screens and components affected**, each mapped to its closest existing component or screen. Prefer extending existing components over creating bespoke ones, and inventory the component library, theme and token files used.
- **Layout and visual intent**: spacing, hierarchy, alignment and the design tokens that apply. Never hardcode values that exist as tokens.
- **Interaction states** for the elements the change introduces or alters: default, hover, focus, active, disabled, loading, empty and error. Resolve an ambiguous state from the design system's conventions or raise it as a human decision point; do not guess silently.
- **Responsive behavior**: breakpoints in scope and how the layout adapts. If the proposal is silent, follow the repository's conventions and record that judgment.
- **Accessibility baseline**: keyboard operability and focus order, accessible names and roles for new controls, and color contrast for new visual elements.
- **Motion**: transitions or animations if specified; otherwise follow existing patterns.

### Visual verification

`TEST_REPORT.md` for UI work must include, stored under `evidence/`:

- Screenshots of every affected screen or component in its primary state, at one desktop and one mobile viewport when responsive behavior is in scope.
- Screenshots or notes for the non-default states the change introduces (loading, empty, error, disabled).
- A comparison against the design reference when one exists, explaining intentional deviations.
- Confirmation of keyboard navigation through new interactive flows.

Capture real rendered output with a browser tool whenever the environment allows. If rendering is impossible, record that as an explicit verification gap for the human validator rather than skipping it silently.

## Issue Status Sync and Progress Reporting

Execution facts, local events and tracker labels must agree at handoffs:

- At implementation start, replace the issue's old `status:` label with `status: in-progress`, preserving all non-status labels. Status labels are mutually exclusive; adding a second one is not a successful transition.
- After `READY_FOR_PR` and PR submission, set the parent and every included, integrated child to `status: in-validation`. `READY_TO_INTEGRATE` alone does not mark a child done. Closure and `status: done` follow the repository's human acceptance and merge policy.
- On resume, at meaningful transitions and at final handoff, read back the tracker status and native child linkage, and record desired and observed values plus the sync outcome. If sync fails or permissions are missing, leave it pending, failed or unavailable, continue independent local work and never report it as complete.
- Post concise comments at execution start, at genuine blockers, when tested or audited, and at final handoff, within the user's publication authorization. Link detailed evidence; do not post heartbeats or mirror every local event.

For decomposed work, the coordinator posts material child outcomes with links to the child details, batches related roll-ups and, when something is blocked, states which paths are affected and which continue. The final summary lists child verdicts, integration results and the parent verdict. Defect fixes still post fixing receipts.

## Defect Handling

| Timing | Channel | Handling |
|---|---|---|
| Before the issue's PR merges (validation) | A defect comment on the issue | Re-run `vapa-exec` on the issue for a defect-fix round: enumerate new defect comments since the last run, get human confirmation of the fix list, fix on the same branch, reply to each defect comment with the fixing commit and verification evidence, then run a delta re-audit |
| After the issue's PR merges | A standalone issue using the lightweight defect template | Standard `vapa-exec` pipeline with its own branch, workspace, audit and PR. Reference the source issue and comment; tracker linkage is optional |

Boundaries:

- Problems found by `vapa-exec`'s own testing are fixed in place; they do not use either defect channel.
- `NEEDS_REVISION` findings stay in the normal revision loop.
- `defect_fix_rounds` in `state.json` counts defect-fix rounds. The workspace's single writer increments it when the human confirms a round's fix list, appending a `checkpoint` event that references the confirmed list. When defects keep reappearing in the same area across rounds, raise it with the human as a systemic question about the implementation or the acceptance criteria instead of only patching symptoms.
- Defect issues use the template at `references/defect-report.md`, relative to this installed `SKILL.md`: symptom, expected behavior, reproduction steps and source. Approval still requires a human; acceptance is "symptom eliminated without regression".

## Safety and Traceability

- The `.vapa` workspace is commit-worthy by default, but never commit secrets, private user data, production exports or unreleasable third-party material.
- If sensitive information appears in an issue, summarize it and record the redaction in the brief's Sources section.
- Do not delete or rewrite workspace artifacts to hide mistakes; append corrections.
- Do not expand scope just because implementation is easy. Scope changes require human approval or a proposal update.
- If the default branch moves significantly during execution, rebase or merge deliberately, re-run the impacted tests and record it in the log.

## Handoff to Audit

After implementation and tests, invoke or recommend `vapa-audit` with the workspace path. The handoff is ready when these exist:

- `state.json` (versioned; phase `tested`) with consistent `events.jsonl`
- `issue-brief.md` with the verbatim contract and `Readiness: READY`
- `VAPA_EXEC_PLAN.md`
- `VAPA_EXEC_LOG.md`
- `TEST_REPORT.md` and `evidence/`
- `PR_DRAFT.md`
- `ui-spec.md` when the task touches UI
- `decomposition.md` when the task uses tracker decomposition

Audit verdicts:

- `READY_FOR_PR`: move toward human validation and PR submission.
- `READY_TO_INTEGRATE`: child-level verdict; authorizes the coordinator to merge the child into the parent branch. Never treated as PR readiness.
- `NEEDS_REVISION`: return to implementation or testing (see Revision and Escalation).
- `BLOCKED_FOR_HUMAN_DECISION`: stop and ask the human to decide.

For decomposed work, each child is audited in its own workspace and must reach `READY_TO_INTEGRATE` before merging. The parent audit covers the integrated whole; until every child is integrated, it returns a not-ready list instead of a verdict.

Any code change after an audit verdict, including defect-fix rounds, invalidates that verdict. Run a delta re-audit of the changed surface plus regression evidence. Delta re-audits do not increment `revision_count`.

## Red Flags

Contract and authority:

- Paraphrasing acceptance criteria, boundaries or exclusions instead of quoting them.
- Treating the brief as authority when the raw issue or comments say otherwise.
- Treating comments or design screenshots as optional context.
- Expanding scope, changing a confirmed design or adding an unapproved dependency without a human decision.
- Creating tracker sub-issues before the human approves `decomposition.md`, or adding children outside it under the parent's approval.

Evidence:

- Claiming tests, audits or UI criteria pass without captured output or rendered screenshots.
- Implementing only the happy-path UI state.
- Reusing a verdict after code changed, or treating stale heartbeats and unknown workers as completion.
- Leaving the tracker silent, or letting status labels and child linkage drift without a read-back check.

Facts of shared work:

- Helpers or children writing to the issue/parent branch, `state.json` or events directly.
- Dispatching a child before its prerequisites are integrated, or from a stale worktree base.
- Submitting the parent PR before every child reached `READY_TO_INTEGRATE` and was merged.

Ritual that slows the Agent without adding authority or evidence:

- Splitting into tracker sub-issues because of `Size` alone, or creating a tracker issue for each coding step.
- Stopping for human approval of a purely technical breakdown, or because work turned out larger than estimated while the contract is unchanged.
- Handing work between phase roles with summaries instead of the contract and raw sources.
- Delaying a cheap spike to finish a speculative plan, or landing contract-affecting code before its decisions are recorded.
- Narrating file lists and step history that Git already records, or growing the snapshot with ad hoc fields.
- Escalating after a fixed number of rounds while distinct findings are still being resolved, or iterating on the same finding without a new approach.
- Imposing whole-wave barriers on independent dependency-ready work.
