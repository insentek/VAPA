---
name: vapa-review
description: Review a VAPA proposal issue in full (body + all comments) against the framework's five review questions and quality checklist, auto-post a structured review comment, and sync status labels. Advisory only — never makes approve/reject decisions.
disable-model-invocation: true
allowed-tools: Bash(git remote get-url origin) Bash(${CLAUDE_SKILL_DIR}/scripts/vapa-review.sh *) Read Write AskUserQuestion
---

# /vapa-review

Review a VAPA proposal issue end-to-end and publish the review as a structured
issue comment. The skill reads the **complete** issue — body and every comment —
assesses it against the framework's review five questions (Layer 3.3) and the
proposal quality checklist (Layer 2.3), posts the review automatically, and syncs
the `status:*` label when a review formally starts.

The review is **advisory**: it gives the review committee a consistent,
evidence-backed baseline. It never sets `status: approved`, `status: rejected`,
or any other decision label, and never edits the issue body.

## Usage

```
/vapa-review 15
/vapa-review https://github.com/insentek/VAPA/issues/15
```

## Requirements

- `gh` CLI installed and authenticated with permission to comment on and label
  issues in the target repo.
- Run from inside a git repo, or set `VAPA_REPO=owner/repo`.
- The repo should carry the VAPA `status:*` label taxonomy (see `vapa-init`).

## Execution

### Step 1: Detect repository and issue

Run:

```bash
git remote get-url origin
```

Parse `owner/repo`. If detection fails, ask the user to run from a git repo with
a GitHub origin remote, or set `VAPA_REPO=owner/repo`.

Parse the issue reference from the user's argument — a plain number or a full
issue URL both work (the backend normalizes either form).

### Step 2: Fetch the full context

```bash
${CLAUDE_SKILL_DIR}/scripts/vapa-review.sh context --issue <ref> --repo <owner/repo>
```

This returns the issue's number, title, state, author, labels, **body, and all
comments** in one call. Read every field. The review must be based on the
complete context — never review from the title alone. Unanswered substantive
questions in the comments are themselves a checklist finding.

### Step 3: Assess the proposal

Evaluate the issue against the template at
`${CLAUDE_SKILL_DIR}/references/review-comment.md`:

1. **Quality checklist** (framework Layer 2.3) — all six items, each with a
   ✅ / ⚠️ / ❌ verdict **and a quote from the issue or comments as evidence**.
   Never write a verdict without pointing at the text that justifies it.
2. **Review five questions** (framework Layer 3.3): is the problem real, are the
   acceptance criteria verifiable, what is the strategic relationship, are there
   hidden risks or dependencies, is the timing right.
3. **Findings** — concrete gaps, each with severity (阻塞 / 建议 / 可选) and a
   specific suggestion.
4. **Overall advisory conclusion** — 🟢 ready for formal review /
   🟡 supplement first / 🔴 directional questions to discuss. This is a
   recommendation to humans, not a state change.

Write the review in the issue's dominant language (Chinese issue → Chinese
review, English issue → English review).

### Step 4: Check for a previous review (idempotency)

```bash
${CLAUDE_SKILL_DIR}/scripts/vapa-review.sh find-comment --issue <ref> --repo <owner/repo>
```

- **No output** → this is the first review round. Proceed to Step 5.
- **A comment ID** → a previous `vapa-review` comment exists. Compare your new
  conclusions with it:
  - *Conclusions materially unchanged* → update the existing comment in place
    (Step 6, update mode). Do not add a new comment.
  - *Conclusions changed, or the proposal was revised since* → post a new round
    (Step 6, post mode), filling in the "评审轮次" line and summarizing what
    changed relative to the previous round.

Never post a duplicate review. The hidden marker `<!-- vapa-review -->` (already
in the template) is how re-runs recognize their own comments — keep it as the
first line of the body.

### Step 5: Sync the review-start label

Only on the **first** review round:

```bash
${CLAUDE_SKILL_DIR}/scripts/vapa-review.sh start --issue <ref> --repo <owner/repo>
```

The backend applies exactly one automated transition:
`status: ready-for-review` → `status: in-review`. Every other state is left
untouched (draft/refining get comment-only reviews; decision and later states
are human-owned). Report what the command printed.

### Step 6: Publish the review

Write the final comment body to a unique temp file (never a fixed path —
concurrent reviews must not clobber each other):

```bash
BODY_FILE=$(mktemp /tmp/vapa-review-XXXXXXXX)
```

First round (or materially changed conclusions):

```bash
${CLAUDE_SKILL_DIR}/scripts/vapa-review.sh post --issue <ref> --body-file "$BODY_FILE" --repo <owner/repo>
```

Unchanged conclusions on re-run:

```bash
${CLAUDE_SKILL_DIR}/scripts/vapa-review.sh update --comment-id <id> --body-file "$BODY_FILE" --repo <owner/repo>
```

Then clean up:

```bash
rm -f "$BODY_FILE"
```

### Step 7: Report

Summarize for the user: the checklist verdicts, the five-question highlights,
the overall advisory conclusion, what label action (if any) was taken, and
whether a new comment was posted or an existing one updated.

## Output handling

- On success, report the advisory conclusion and the review comment location.
- On failure, show the script output and explain the likely cause (missing `gh`
  auth, bad issue reference, no repo detected).
- The skill never edits the issue body and never sets decision labels
  (`approved` / `rejected` / `deferred` / `done`). If the user asks for those,
  explain that they are human committee actions and stop.

## References

- Review comment template: `${CLAUDE_SKILL_DIR}/references/review-comment.md`
- Backend: `${CLAUDE_SKILL_DIR}/scripts/vapa-review.sh`
- Review criteria source: `docs/framework.md` Layer 2.3 (quality checklist) and
  Layer 3.3 (review five questions)
