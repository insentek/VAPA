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
  issue-brief.md
  source-map.md
  readiness-report.md
  VAPA_EXEC_PLAN.md
  VAPA_EXEC_LOG.md
  TEST_REPORT.md
  PR_DRAFT.md
```

Also inspect the actual repository diff and relevant files. Do not rely only on the execution log.

## Verdicts

Return exactly one verdict in `VAPA_AUDIT.md`:

| Verdict | Meaning | Next Step |
|---|---|---|
| `READY_FOR_PR` | Implementation, tests, traceability, and PR draft are sufficient for human validation | Move to `status: in-validation` or open PR |
| `NEEDS_REVISION` | Agent can fix the identified issues without a product/vision decision | Return to `vapa-exec` implementation or test phase |
| `BLOCKED_FOR_HUMAN_DECISION` | Direction, scope, acceptance criteria, or risk requires human judgment | Stop and ask the human to decide |

## Audit Flow

### Step 1: Validate Workspace Completeness

Check that required workspace files exist and are internally consistent.

Fail with `NEEDS_REVISION` if execution artifacts are missing but can be recreated. Use `BLOCKED_FOR_HUMAN_DECISION` only if the missing artifact prevents a judgment that an Agent cannot safely infer.

### Step 2: Reconstruct the Proposal Contract

From `issue-brief.md`, `source-map.md`, and the raw issue snapshot, extract:

- Approved scope
- Explicit non-goals
- Acceptance criteria
- Design constraints
- Implementation constraints
- Human decisions already made

If the issue was not approved and no explicit execution authorization exists, return `BLOCKED_FOR_HUMAN_DECISION`.

### Step 3: Inspect the Diff

Review actual repository changes, not just logs.

Check:

- Files changed match the expected impact area.
- No unrelated refactors, formatting churn, or opportunistic scope expansion.
- No secrets, private data, generated noise, or unsuitable artifacts are added.
- `.vapa` workspace content is safe to commit or clearly marked for redaction.

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

If tests were not run, the audit may still pass only when the reason is strong, low-risk, and the acceptance criteria have other evidence.

### Step 6: Review PR Draft

Check `PR_DRAFT.md` for:

- Correct linked issue.
- Clear implementation summary.
- Acceptance criteria mapping.
- Test evidence.
- Known limitations.
- VAPA workspace path.
- Contribution record suggestions.

The PR draft should make human validation faster, not merely summarize that work was done.

### Step 7: Write `VAPA_AUDIT.md`

Write the audit report into the workspace.

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
- Allowing scope expansion because the implementation looks useful.
- Marking `READY_FOR_PR` while PR body lacks traceability.
- Ignoring unsafe content in `.vapa` workspace artifacts.
- Asking humans to review basic checklist gaps that the Agent could fix itself.
