---
name: vapa-proposal
description: Create or list VAPA proposals on a GitHub repository. Use as /vapa-proposal "subject" or /vapa-proposal "subject" "Issue Type" or /vapa-proposal to list pending proposals.
disable-model-invocation: true
allowed-tools: Bash(${CLAUDE_SKILL_DIR}/scripts/vapa-proposal.sh *)
---

# /vapa-proposal

Create a new VAPA proposal or list pending proposals in a GitHub repository.

## Modes

- **With a subject**: create a new proposal issue using the bundled template that matches the requested issue type. The issue title is automatically prefixed with the next `VEP-XXXX` number.
- **With a subject and issue type**: create a proposal with a specific VAPA issue type, e.g. `Vision Amendment`, `Problem`, `Experiment`.
- **Without arguments**: list all pending proposals (`status: draft`, `status: refining`, `status: ready-for-review`).

## Proposal numbering

Every new proposal receives a `VEP-XXXX` prefix in its issue title:

- **Format**: `VEP-XXXX <subject>` (4-digit, zero-padded).
- **Source of truth**: existing issue titles in the repository.
- **Algorithm**: scan all open and closed issues for titles starting with `VEP-<number>`, take the maximum number, and add 1.
- **Double-prefix protection**: if the subject already begins with `VEP-XXXX `, that prefix is stripped and a fresh number is assigned.

The first proposal in a repo is titled `VEP-0001`.

## Usage

```
/vapa-proposal "为订单列表增加批量导出能力"
# creates an issue titled: VEP-0001 为订单列表增加批量导出能力

/vapa-proposal "调整 Q3 战略重心" "Vision Amendment"
# creates an issue titled: VEP-0002 调整 Q3 战略重心

/vapa-proposal
```

## Requirements

- `gh` CLI installed and authenticated.
- Run from inside a git repo, or set `VAPA_REPO=owner/repo`.
- The organization must have the required VAPA issue types and issue fields (`Align`, `Size`, `Shaper`, `Reviewed By`, `Validator`, `Sponsor`).

## Execution

Run the bundled script with the user-provided argument (if any):

```bash
${CLAUDE_SKILL_DIR}/scripts/vapa-proposal.sh $ARGUMENTS
```

The script will:

1. Detect the repository from `git remote get-url origin` or `VAPA_REPO`.
2. Determine the issue type (default: `Feature`).
3. Scan existing issue titles to compute the next `VEP-XXXX` number.
4. Create the issue with the native type, the `status: draft` label, and the `VEP-XXXX` prefixed title.

The issue author is implicitly the Proposer; no separate contributor field is set automatically.

## Output handling

- On success, report the assigned `VEP-XXXX` number and the created issue URL.
- On failure, show the script output and explain the likely cause (e.g., missing `gh` auth, no repo detected, invalid issue type, missing org-level issue fields).

## References

The proposal templates are bundled at `${CLAUDE_SKILL_DIR}/references/`:

- `feature-proposal.md`
- `problem-statement.md`
- `vision-amendment.md`
- `experiment.md`
