# vapa-proposal Redesign: AI-Assisted Proposal Drafting

## Status

Approved design — pending implementation plan.

## Context

The current `/vapa-proposal` skill is a thin wrapper around a shell script. It detects the repository, assigns the next `VEP-XXXX` number, loads a bundled Markdown template, replaces the title placeholder, and creates a GitHub Issue. It does **not** interpret the user's intent, fill in proposal sections, or ask for clarification. As a result, newly created issues contain mostly empty scaffold text.

Additionally, the bundled `feature-proposal.md` template in `.claude/skills/vapa-proposal/references/` is out of sync with the copy in `.claude/skills/vapa-init/references/` (it still uses the old `labels: "type: feature, status: draft"` frontmatter).

## Goal

Redesign `/vapa-proposal` so that when a user invokes it with a one-line idea, the AI:

1. Gathers relevant repository context.
2. Infers the appropriate VAPA Issue Type.
3. Asks clarifying questions when critical information is missing.
4. Generates a complete draft proposal using the matching template.
5. Shows a preview and only creates the GitHub Issue after explicit user confirmation.

## Design

### 1. Overall Flow

```
User: /vapa-proposal "让VAPA变得可被一键安装，推广VAPA的理念和SKILLS"
  │
  ▼
[Skill] Detect repo, read VISION.md, README.md, recent issues
  │
  ▼
[Skill] Infer Issue Type (or use explicit type argument)
  │
  ▼
[Skill] Identify missing required fields per type
  │
  ▼
[Skill] Ask clarifying questions one at a time (optional skip)
  │
  ▼
[Skill] Generate full proposal body from template
  │
  ▼
[Skill] Preview title + body in terminal
  │
  ▼
User chooses: ① Submit ② Edit section ③ Cancel
  │
  ▼
[Script] vapa-proposal.sh --subject "..." --body-file /tmp/vep-body.md --type Feature
  │
  ▼
GitHub Issue created with VEP-XXXX title and status:draft label
```

### 2. Issue Type Inference

The AI infers the type from the user's subject plus repository context. Fallback rules:

| Trigger words / context | Inferred type |
|---|---|
| 愿景, VISION, 战略重心, 修正, amend | `Vision Amendment` |
| Describes a pain/observation without a clear solution | `Problem` |
| 实验, 验证, poc, spike, prototype | `Experiment` |
| 重构, 技术债, 性能, cleanup | `Technical Debt` or `Improvement` |
| 调研, 研究, research | `Research` |
| Default | `Feature` |

If confidence is low (e.g., could be either `Problem` or `Feature`), the AI presents the top two options and asks the user to pick. The user can always override by passing a second argument: `/vapa-proposal "..." "Experiment"`.

### 3. Clarification Rules

The AI checks required fields per type. If a field is missing or too vague, it asks one focused question at a time. The user may answer, skip, or ask the AI to draft a placeholder.

| Type | Required fields to check |
|---|---|
| `Feature` / `Improvement` | target user, problem, core idea, "this is not", acceptance criteria, estimated `Size` |
| `Problem` | affected users, observable evidence, impact if not solved |
| `Vision Amendment` | current VISION.md text, proposed text, rationale, risks of not changing |
| `Experiment` | hypothesis, validation method, success metric, scope |
| `Research` | question, expected output, why it matters now |

### 4. Draft Generation

The AI uses the bundled template that matches the inferred type:

| Inferred type | Template used |
|---|---|
| `Feature` | `feature-proposal.md` |
| `Improvement` | `feature-proposal.md` |
| `Technical Debt` | `feature-proposal.md` |
| `Research` | `feature-proposal.md` (adapted; a dedicated `research.md` template is out of scope for this redesign) |
| `Problem` | `problem-statement.md` |
| `Vision Amendment` | `vision-amendment.md` |
| `Experiment` | `experiment.md` |

It fills each section with content derived from:

- The user's original sentence.
- Answers to clarifying questions.
- `VISION.md` (for alignment statements).
- Recent issues (to avoid duplication and reference related work).
- `README.md` (for project context).

Any section that remains unknown after clarification is left as a bracketed placeholder like `[待补充：具体受影响的角色]`.

For types that share `feature-proposal.md`, the AI adjusts the language accordingly (e.g., an `Improvement` focuses on a change to an existing capability, while `Technical Debt` focuses on the cost of inaction).

The AI prints a terminal preview:

```markdown
📝 提案预览

类型：Feature
标题：VEP-0001 让VAPA变得可被一键安装，推广VAPA的理念和SKILLS

---

（完整 Markdown 正文）
```

The preview is followed by:

> 请选择：① 提交 ② 编辑某节 ③ 取消

- **Submit**: the AI invokes the script to create the issue.
- **Edit**: the AI asks which section to rewrite, regenerates it, and shows the updated preview.
- **Cancel**: no issue is created.

The `VEP-XXXX` number shown in the preview is a best-effort preview. The script re-computes the next number at submission time to avoid race conditions.

### 6. Script CLI Changes

`vapa-proposal.sh` becomes a submission-only tool with the following interface:

```bash
# Create a proposal
vapa-proposal.sh \
  --subject "让VAPA变得可被一键安装，推广VAPA的理念和SKILLS" \
  --body-file /tmp/vep-body.md \
  --type Feature

# Peek the next VEP number (for previews)
vapa-proposal.sh --next-number

# List pending proposals
vapa-proposal.sh --list
```

Rules:

- `--subject` is required for creation.
- `--body-file` is required for creation.
- `--type` defaults to `Feature` if omitted.
- The script computes the next `VEP-XXXX` number and constructs the final title.
- If the subject already starts with `VEP-\d+\s+`, that prefix is stripped before renumbering.
- The script adds `status: draft` and sets the native issue type via the GitHub REST API.

### 7. Template Synchronization

The four templates exist in two locations:

- `.claude/skills/vapa-proposal/references/`
- `.claude/skills/vapa-init/references/`

They must remain identical. The implementation will:

1. Update both copies to the canonical frontmatter:
   ```yaml
   ---
   name: "🚀 Feature Proposal"
   about: "提出一个新能力或改善提案"
   labels: "status: draft"
   type: "Feature"
   ---
   ```
2. Add a top comment in each template:
   ```markdown
   <!-- NOTE: Keep in sync with the copy in ../vapa-init/references/ or ../vapa-proposal/references/ -->
   ```

Long-term, a sync check can be added to CI or a shared symlink, but that is out of scope for this redesign.

### 8. Error Handling

| Scenario | Behavior |
|---|---|
| `gh` not authenticated or no repo permission | Fail immediately with a clear error message. |
| Cannot read `VISION.md` | Continue and insert `[未找到 VISION.md，请手动补充对齐声明]` in the alignment section. |
| Type inference ambiguous | Present top two options and ask the user to choose. |
| User cancels at any question or preview | Stop gracefully; no issue is created. |
| `--body-file` missing or empty | Script exits with an error. |

### 9. Out of Scope

- Automatic assignment of contributor fields (`Shaper`, `Reviewed By`, `Validator`, `Sponsor`). These remain manually set after issue creation.
- Automatic roadmap prioritization or project board assignment.
- Multi-language proposal generation (Chinese only for now).

## Success Criteria

- A one-line `/vapa-proposal` invocation produces an Issue whose body has meaningful content in every major section, not just placeholders.
- The inferred Issue Type matches what a human would choose in at least 90% of clear-cut cases.
- The user sees a preview and confirms before any Issue is created.
- `vapa-proposal/references/` and `vapa-init/references/` templates are identical and use the new metadata model.

## Files to Modify

- `.claude/skills/vapa-proposal/SKILL.md`
- `.claude/skills/vapa-proposal/scripts/vapa-proposal.sh`
- `.claude/skills/vapa-proposal/references/*.md`
- `.claude/skills/vapa-init/references/*.md`
- `README.md` (update `/vapa-proposal` description and examples)
