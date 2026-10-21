# Decomposition — #<parent-id>: <parent title>

> Template for `.vapa/vapa-exec-<parent-id>/workspace/decomposition.md`.
> This document must be presented to the human for approval BEFORE any tracker
> sub-issue is created. It is the execution source of truth for the split; the
> tracker linkage is only the visibility layer.

## Tracker linkage

- Method: `github-native-sub-issues` | `task-list-in-parent-body + first-line-parent-reference`
- Parent issue: #<parent-id>

## Cross-cutting contracts

[Interfaces, schemas, events, and design tokens that every sub-issue must
respect. Point to the parent plan's Design section; do not redefine here.]

## Decomposition benefit check

- Cohesive delivery/acceptance boundary: <capability, including its necessary layers>
- Alternatives considered: <keep inline, combine related work, or split>
- Coordination cost: <planning, worktrees, test/build, audit and integration>
- Expected benefit: <independent validation, actual parallelism or risk isolation>
- Merge-back review: <which candidates share changes/acceptance and why they stay separate>
- Calibration: <existing comparable work or first approved units; revise estimates when observed>

A child Issue is not an agent assignment. Keep implementation steps and ordinary
DTO/component/helper work inside a delivery unit. Do not split merely to increase
parallelism or meet an arbitrary count; preserve S size and real risk boundaries.

## Sub-issues

### Sub-issue #<id>: <title>

- delivers: <independently verifiable capability>
- owner: <responsible role and affected area>
- split_benefit: <concrete value of a separate tracker issue>
- internal_steps: <work that stays inside this issue, including agent assignments>
- depends_on: []             <!-- logical dependencies; fixed order -->
- conflicts_with: []         <!-- optional: file overlap; serialize, any order -->
- resources: []              <!-- optional named exclusive resources, not fake dependencies -->
- acceptance: <what "done" means for this sub-issue>

<!-- Repeat per sub-issue. The graph must be acyclic; it is validated at approval time. -->

## Dispatch and integration

- Recompute the ready set after each integration or worker/resource release.
- Start only after all direct prerequisites are audited and integrated, capacity
  is free, and neither active nor selected tasks conflict. Do not wait for a whole
  topological level. Refresh the worktree from the verified current parent base.
- Name any integration milestone that genuinely needs multiple children; do not
  make every milestone a global scheduling barrier.
- Link versioned child state/events and parent-owned integration receipts using
  [the execution contract](execution-state.md). Keep detailed histories in reports.

## Integration criteria

[What defines "the parent issue is done": how the sub-implementations must
compose, and what the integrated test suite must demonstrate.]

## Approval

- Presented to: @<human> on <YYYY-MM-DD>
- Decision: approved | changes requested
- Tracker sub-issues created on: <YYYY-MM-DD>, as #<id-list>
