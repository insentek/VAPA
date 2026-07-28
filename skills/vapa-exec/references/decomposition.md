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

## Sub-issues

### Sub-issue #<id>: <title>

- delivers: <what this sub-issue delivers>
- depends_on: []             <!-- logical dependencies; fixed order -->
- conflicts_with: []         <!-- optional: file overlap; serialize, any order -->
- acceptance: <what "done" means for this sub-issue>

<!-- Repeat per sub-issue. The graph must be acyclic; it is validated at approval time. -->

## Integration criteria

[What defines "the parent issue is done": how the sub-implementations must
compose, and what the integrated test suite must demonstrate.]

## Approval

- Presented to: @<human> on <YYYY-MM-DD>
- Decision: approved | changes requested
- Tracker sub-issues created on: <YYYY-MM-DD>, as #<id-list>
