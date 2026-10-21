# Decomposition — #<parent-id>: <parent title>

> Template for `.vapa/vapa-exec-<parent-id>/workspace/decomposition.md`.
> Use it only for tracker decomposition: children that humans should see, track
> or validate separately. Internal breakdown and helper agents need no
> decomposition file and no approval; record them in the plan instead.
> Present this document to the human for approval BEFORE creating any tracker
> sub-issue. It is the execution record for the split; tracker linkage is only
> the visibility layer.

## Tracker linkage

- Method: `github-native-sub-issues` | `task-list-in-parent-body + first-line-parent-reference`
- Parent issue: #<parent-id>

## Cross-cutting contracts

[Interfaces, schemas, events and design tokens that every child must respect.
Point to the parent plan's Design section; do not redefine them here.]

## Decomposition benefit check

- Why tracker issues instead of inline work or helper agents: <what humans gain:
  separate validation, visibility/ownership, or an isolated risk boundary>
- Cohesive delivery/acceptance boundaries: <capabilities, including their necessary layers>
- Coordination cost: <planning, worktrees, test/build, child audits and integration>
- Merge-back review: <which candidates share changes or acceptance and why they stay separate>
- Calibration: <comparable existing work or first completed children; revise estimates when observed>

All children ship in the parent's single PR, so splitting does not shrink the
human review unit. If the only benefit is agent parallelism or context
isolation, use helper agents instead. Do not split to meet a count or a size;
preserve real risk boundaries.

## Sub-issues

### Sub-issue #<id>: <title>

- delivers: <independently acceptable capability>
- owner: <responsible role and affected area>
- split_benefit: <concrete value of a separate tracker issue>
- internal_steps: <work that stays inside this issue, including helper-agent assignments>
- depends_on: []             <!-- real prerequisites only; fixed order -->
- conflicts_with: []         <!-- optional: file overlap; serialize, any order -->
- resources: []              <!-- optional named exclusive resources, not fake dependencies -->
- acceptance: <what "done" means for this sub-issue>

<!-- Repeat per sub-issue. The graph must be acyclic; it is validated at approval time. -->

## Dispatch and integration

- Recompute the ready set after each integration or worker/resource release.
- Start a child once all direct prerequisites are audited and integrated,
  capacity is free and nothing conflicting is active or selected. Do not wait for
  a whole topological level. Refresh the worktree from the verified current
  parent base.
- Name any integration milestone that genuinely needs multiple children; do not
  make every milestone a global scheduling barrier.
- Link versioned child state/events and parent-owned integration receipts using
  [the execution contract](execution-state.md). Keep detailed histories in reports.

## Integration criteria

[What defines "the parent issue is done": how the children must compose, and
what the integrated test suite must demonstrate.]

## Parent PR closing references

- Expected closing set: parent issue plus every approved, integrated child above.
- Emit a separate `Closes #<id>` line for each issue (use full URLs if needed).
- Compare against the complete native tracker child list before publication and
  read back the PR body afterward. Resolve missing/extra IDs; do not infer a range
  or close unrelated prerequisites. Do not close issues before merge/acceptance.

## Approval

- Presented to: @<human> on <YYYY-MM-DD>
- Decision: approved | changes requested
- Tracker sub-issues created on: <YYYY-MM-DD>, as #<id-list>
