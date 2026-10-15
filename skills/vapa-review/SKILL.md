---
name: vapa-review
description: Review a VAPA proposal issue in full (body + all comments) against the framework's five review questions and quality checklist, and present the structured review to the user. Read-only — never posts comments, never changes labels, never edits the issue.
---

# /vapa-review

Review a VAPA proposal issue end-to-end and present the review **to the user,
in the conversation**. The skill reads the **complete** issue — body and every
comment — and assesses it against the framework's review five questions
(Layer 3.3) and the proposal quality checklist (Layer 2.3).

The skill is strictly **read-only**:

- It never posts comments to the issue.
- It never adds, removes, or changes labels.
- It never edits the issue body.

The review is advice for the human reading it. If the user wants the review
published as an issue comment, they can copy it themselves — that is a human
publishing decision, not something this skill automates. Approve / reject /
defer decisions always belong to the human review committee.

## Usage

```
/vapa-review 15
/vapa-review https://github.com/insentek/VAPA/issues/15
```

## Requirements

- `gh` CLI installed and authenticated with **read** access to the target repo.
- Run from inside a git repo, or set `VAPA_REPO=owner/repo`.

## Execution

### Resolve installed paths and invocation

Resolve the absolute directory containing this installed `SKILL.md` as `SKILL_DIR`. Resolve the target repository root as `PROJECT_DIR` (use `git rev-parse --show-toplevel` when available, otherwise the working directory supplied by the user). These are task-local values, not predefined host environment variables. Before running a command, assign `SKILL_DIR` to the actual installed directory and quote all paths. Scripts resolve their own bundled resources from their file location.

In Codex, invoke explicitly with `$vapa-review`; `agents/openai.yaml` preserves explicit invocation. In Claude Code, use `/vapa-review` or an explicit request. Use the host's available shell, file, and user-input tools; no named Claude tool or environment variable is required. Host permissions still apply. Do not initiate this workflow from unrelated work; require the user's request for it.

### Step 1: Detect repository and issue

Run:

```bash
git remote get-url origin
```

For a full GitHub issue URL, take `owner/repo` from the URL. A conflicting explicit repository or `VAPA_REPO` must fail visibly. For a plain number, parse `owner/repo` from the current repository. If detection fails, ask the user to run from a git repo with
a GitHub origin remote, or set `VAPA_REPO=owner/repo`.

Parse the issue reference from the user's argument — a plain number or a full
issue URL both work (the backend normalizes either form).

### Step 2: Fetch the full context

```bash
bash "${SKILL_DIR}/scripts/vapa-review.sh" context --issue <ref> --repo <owner/repo>
```

This returns the issue's number, title, state, author, labels, **body, and all
comments** in one call. Read every field. The review must be based on the
complete context — never review from the title alone. Unanswered substantive
questions in the comments are themselves a checklist finding.

### Step 3: Assess the proposal

Evaluate the issue against the template at
`${SKILL_DIR}/references/review-comment.md`:

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

### Sub-issues and defect issues

- When the reviewed issue is a sub-issue of a decomposed parent (linked via the
  tracker's parent-child relationship), findings belong to the parent's
  decomposition plan: recommend escalating to the parent issue rather than
  having the sub-issue change direction on its own.
- Defect issues (lightweight template: symptom / expected behavior /
  reproduction steps / source) are reviewed with focus on reproducibility and
  a verifiable acceptance criterion — "symptom eliminated without regression".

### Step 4: Present the review to the user

Output the complete filled-in review directly in the conversation, preceded by
a one-line header:

```
🔍 VAPA 评审结果 — <owner/repo>#<number>（status: <current>）
```

Do not post it anywhere. After the review, add one closing line summarizing the
overall conclusion and the single most important gap (if any).

If the user then asks to publish the review as an issue comment, remind them
this skill is read-only by design; they may paste it manually, or ask to change
the skill's scope through a proposal update.

## Output handling

- On success, the review appears in the conversation; nothing is written to
  GitHub.
- On failure, show the script output and explain the likely cause (missing `gh`
  auth, bad issue reference, no repo detected).

## References

- Review output template: `${SKILL_DIR}/references/review-comment.md`
- Backend: `bash "${SKILL_DIR}/scripts/vapa-review.sh"` (read-only; the only
  command is `context`)
- Review criteria source: `docs/framework.md` Layer 2.3 (quality checklist) and
  Layer 3.3 (review five questions)
