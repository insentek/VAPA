---
name: vapa-audit
description: Use after VAPA execution to independently audit implementation, tests, scope, traceability, and PR readiness. Produces VAPA_AUDIT.md and returns READY_FOR_PR, NEEDS_REVISION, or BLOCKED_FOR_HUMAN_DECISION.
---

# VAPA Audit

## Overview

`vapa-audit` is the independent validation gate between Agent execution and human validation. It reviews the implementation against the approved proposal, execution plan, tests, and PR draft.

The audit does not replace human authority. It gives humans a concise, evidence-backed answer to: "Is this implementation ready for PR review or validation?"

Agent audit gives confidence. Human validation gives authority.

## When to Use

- `vapa-exec` has completed implementation and tests.
- A `.vapa/vapa-exec-<issue-id>/workspace/` directory exists.
- The user asks whether an Agent-executed change is ready for PR, validation, or merge.
- The user asks for a review of a VAPA execution workspace.

If there is no implementation yet, use `vapa-exec`. If there is no approved proposal, use `vapa-proposal` or a future `vapa-review` skill.

## Required Inputs

Audit from the execution workspace:

```text
.vapa/vapa-exec-<issue-id>/workspace/
  state.json
  issue-brief.md
  source-map.md
  readiness-report.md
  codebase-survey.md
  VAPA_EXEC_PLAN.md
  VAPA_EXEC_LOG.md
  TEST_REPORT.md
  evidence/
  PR_DRAFT.md
```

Conditional inputs, required when applicable:

- `ui-spec.md` — required when the change touches user-facing UI.
- `decomposition.md` — required in the parent workspace when the task was executed as decomposed sub-issues.

Also inspect the actual repository diff and relevant files. Do not rely only on the execution log.

Check `state.json` before starting: the phase should be `tested`, and `revision_count` tells you how many audit round-trips have already happened. If `revision_count` is already 2 or more and the same underlying finding persists, prefer `BLOCKED_FOR_HUMAN_DECISION` over another `NEEDS_REVISION` — repeated failed revisions are evidence of a broken assumption, not a coding problem.

## Verdicts

Return exactly one verdict in `VAPA_AUDIT.md`:

| Verdict | Meaning | Next Step |
|---|---|---|
| `READY_FOR_PR` | Implementation, tests, traceability, and PR draft are sufficient for human validation | Move to `status: in-validation` or open PR |
| `NEEDS_REVISION` | Agent can fix the identified issues without a product/vision decision | Return to `vapa-exec` implementation or test phase |
| `BLOCKED_FOR_HUMAN_DECISION` | Direction, scope, acceptance criteria, or risk requires human judgment | Stop and ask the human to decide |

## Audit Flow

### Step 1: Validate Workspace Completeness

Check that required workspace files exist and are internally consistent. Determine the task's domain (frontend, backend, mixed) and execution mode (inline or decomposed) from `state.json` and the plan, then verify the conditional artifacts that apply: `ui-spec.md` and `evidence/` for UI work, `decomposition.md` for decomposed work.

Fail with `NEEDS_REVISION` if execution artifacts are missing but can be recreated. Use `BLOCKED_FOR_HUMAN_DECISION` only if the missing artifact prevents a judgment that an Agent cannot safely infer.

### Step 2: Reconstruct the Proposal Contract

From `issue-brief.md`, `source-map.md`, and the raw issue snapshot, extract:

- Approved scope
- Explicit non-goals
- Acceptance criteria
- Design constraints
- Implementation constraints
- Human decisions already made

While reconstructing, verify the brief against the raw snapshot: acceptance criteria, boundary constraints, and exclusions in `issue-brief.md` must be verbatim quotes from the issue or comments, and no substantive requirement or later-comment amendment in the raw sources may be missing from the brief without a recorded exclusion reason. A brief that paraphrased or dropped contract items is a finding — the implementation may have been built against a distorted contract.

If the issue was not approved and no explicit execution authorization exists, return `BLOCKED_FOR_HUMAN_DECISION`.

### Step 3: Inspect the Diff

Review actual repository changes, not just logs.

Check:

- Files changed match the expected impact area.
- No unrelated refactors, formatting churn, or opportunistic scope expansion.
- No secrets, private data, generated noise, or unsuitable artifacts are added.
- `.vapa` workspace content is safe to commit or clearly marked for redaction.

Also check architecture conformance against `codebase-survey.md` and the plan's Design section:

- New code follows the existing patterns the survey identified (layering, naming, error handling, test structure), or the deviation is justified in the plan or log.
- Existing components, utilities, and design tokens were reused where the survey said equivalents exist; bespoke reinventions are findings.
- Interfaces, schemas, or events changed in the diff match the contracts defined in the plan's Design section. Undeclared contract changes are at least `P1`.
- New dependencies introduced by the diff were approved in the plan or by a recorded human decision. Unapproved dependencies are at least `P1`.

### Step 4: Trace Acceptance Criteria

For each acceptance criterion, identify evidence:

- Implementation location
- Test or manual verification evidence
- Status: pass, partial, fail, or unverified

Partial or unverified criteria normally require `NEEDS_REVISION` unless the missing proof requires human judgment.

### Step 5: Review Tests

Inspect `TEST_REPORT.md` and run additional checks when reasonable.

Validate:

- Commands are relevant to the changed surface.
- Failures are explained and not hidden.
- Tests map to acceptance criteria.
- Manual verification is described when automated tests are impossible.
- Claimed command output is backed by captures in `evidence/`, not just asserted in prose.

If tests were not run, the audit may still pass only when the reason is strong, low-risk, and the acceptance criteria have other evidence.

### Step 5a: Review UI Evidence (frontend or mixed tasks)

For changes that touch user-facing UI, audit against `ui-spec.md`:

- Rendered screenshots exist in `evidence/` for every affected screen or component, at the viewports the spec put in scope. UI acceptance criteria without rendered evidence are unverified, not passed.
- Non-default interaction states introduced by the change (loading, empty, error, disabled) have evidence or an explicit recorded gap. Happy-path-only evidence is a finding.
- When a design reference exists in `images/`, the report compares implementation against it and explains intentional deviations.
- Design tokens and existing components were used as the spec required; hardcoded values duplicating tokens are findings.
- Keyboard operability of new interactive flows is confirmed or recorded as a gap.

If rendering was impossible in the execution environment, the gap must be explicitly recorded for the human validator. A silent skip is `NEEDS_REVISION`; an explicitly recorded rendering gap can pass with a note in Human Review Notes.

### Step 5b: Review Decomposition Integration (decomposed tasks)

When the work was executed as sub-issues per `decomposition.md`:

- Each sub-issue has its own complete workspace and, where required, its own audit.
- The cross-cutting contracts defined in the parent plan were respected by all sub-implementations.
- An integration pass was run after the last sub-issue: full test suite results are recorded in the parent `TEST_REPORT.md`.
- The parent issue's acceptance criteria are traced against the integrated whole, not just the union of sub-issue claims.

### Step 6: Review PR Draft

Check `PR_DRAFT.md` for:

- Correct linked issue.
- Clear implementation summary.
- Acceptance criteria mapping.
- Test evidence, including visual evidence pointers for UI changes.
- Known limitations.
- VAPA workspace path.
- Contribution record suggestions.

The PR draft should make human validation faster, not merely summarize that work was done.

### Step 7: Write `VAPA_AUDIT.md`

Write the audit report into the workspace.

After writing the report, update `state.json`: set `phase` to `audited`, and if the verdict is `NEEDS_REVISION`, increment `revision_count` so the revision budget stays enforceable across sessions.

Required format:

```markdown
# VAPA Audit Report

## Verdict
READY_FOR_PR | NEEDS_REVISION | BLOCKED_FOR_HUMAN_DECISION

## Summary
[One paragraph summary of the audit result.]

## Proposal Traceability
| Acceptance Criterion | Evidence | Status |
|---|---|---|

## Scope Review
- In scope:
- Out-of-scope changes detected:
- Workspace commit safety:

## Test Review
- Commands reviewed or run:
- Results:
- Missing coverage:

## UI Evidence Review (when the change touches UI)
- Screens/states with rendered evidence:
- States or viewports missing evidence:
- Design reference comparison:
- Accessibility and keyboard checks:

## Findings
| Severity | Finding | Required Action |
|---|---|---|

## Human Review Notes
- Decisions needed:
- Risks to inspect manually:

## PR Recommendation
- Suggested title:
- Suggested body changes:
- Ready to open PR: yes/no
```

## Severity Guidance

- `P0`: Must block PR. The implementation is unsafe, wrong, or violates proposal boundaries.
- `P1`: Must fix before PR unless human explicitly accepts the risk.
- `P2`: Should fix, but may not block validation if documented.
- `P3`: Nice-to-have cleanup or clarity improvement.

## Common Mistakes / Red Flags

- Trusting `VAPA_EXEC_LOG.md` without inspecting the diff.
- Treating passing tests as proof that acceptance criteria are met.
- Passing UI acceptance criteria on the strength of code review alone, without rendered visual evidence.
- Skipping the `ui-spec.md` and `evidence/` checks because the diff "looks like a small UI change".
- Ignoring architecture conformance — new bespoke components or undeclared contract changes slipping through as style preferences.
- Auditing a decomposed task's sub-issues individually but never checking the integrated whole.
- Returning `NEEDS_REVISION` a third time for the same finding instead of escalating to a human.
- Allowing scope expansion because the implementation looks useful.
- Marking `READY_FOR_PR` while PR body lacks traceability.
- Ignoring unsafe content in `.vapa` workspace artifacts.
- Asking humans to review basic checklist gaps that the Agent could fix itself.
