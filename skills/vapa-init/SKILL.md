---
name: vapa-init
description: Inspect VAPA organization metadata and initialize repository status labels and issue templates, with an optional organization-wide contributor-field setup. Preview changes and confirm update or reset before applying them.
---

# /vapa-init

Initialize the VAPA (Vision-driven · Async · Proposal-based · Agent-executed) workflow on the current GitHub repository.

## What it does

1. Detects the target repository from `git remote get-url origin`.
2. Checks the remote repo for VAPA configuration across three layers:
   - **Issue types** (organization-level): Feature, Problem, Vision Amendment, Experiment, Improvement, Technical Debt, Research
   - **Issue fields** (organization-level): Align, Size, Shaper, Reviewed By, Validator, Sponsor. The contributor-role fields (`Shaper`, `Reviewed By`, `Validator`, `Sponsor`) are single-select fields whose options are the organization's members.
   - **Labels** (repository-level): only the `status:*` taxonomy
   - **Issue templates** (repository-level): feature-proposal, problem-statement, vision-amendment, experiment
3. Asks you to choose the action:
   - **Initialize / Update**: create missing labels/templates and update existing ones to match the VAPA spec.
   - **Reset**: delete all existing VAPA labels/templates and recreate them from scratch (useful for testing/debugging).
   - **Cancel**: do nothing.
4. Executes the chosen action.
5. Optionally guides you to create or update `VISION.md` in the project root.

## Usage

```
/vapa-init
/vapa-init --init-fields
```

No arguments needed. The skill detects the target repository from `git remote get-url origin`.

## Requirements

- Run inside a git repo with a GitHub `origin` remote.
- `gh` CLI installed and authenticated with permission to modify the target repo.
- The organization must already have the required issue types and the `Align` / `Size` fields. `--init-fields` can create or update the four contributor-role fields with organization-admin permission.
- Python 3 and `requests` (used by the bundled label configurator).

## Execution

### Resolve installed paths and invocation

Resolve the absolute directory containing this installed `SKILL.md` as `SKILL_DIR`. Resolve the target repository root as `PROJECT_DIR` (use `git rev-parse --show-toplevel` when available, otherwise the working directory supplied by the user). These are task-local values, not predefined host environment variables. Before running a command, assign `SKILL_DIR` to the actual installed directory and quote all paths. Scripts resolve their own bundled resources from their file location.

In Codex, invoke explicitly with `$vapa-init`; `agents/openai.yaml` preserves explicit invocation. In Claude Code, use `/vapa-init` or an explicit request. Use the host's available shell, file, and user-input tools; no named Claude tool or environment variable is required. Host permissions still apply. Do not initiate this workflow from unrelated work; require the user's request for it.

### Step 1: Detect repo and pre-flight check

1. Detect the current repo:

   ```bash
   git remote get-url origin
   ```

2. Parse `owner/repo` from the remote URL.
3. Run a pre-flight check:

   ```bash
   bash "${SKILL_DIR}/scripts/vapa-init.sh" --check <owner/repo>
   ```

4. Show the result and ask the user what to do:
   - If nothing exists: "No VAPA configuration found on `owner/repo`. Initialize?"
   - If partially or fully present: "Found X/Y VAPA labels, A/4 templates, B/7 issue types, and C/6 issue fields. Choose: ① Update (create missing, update existing) ② Reset (delete and recreate) ③ Cancel"
   - If contributor issue fields are missing or not populated with org members: also offer to run `--init-fields` to create/update them from the organization member list. Explain that these are organization-wide changes. A conflicting field type stops execution and requires a separate migration plan.
   - Explain that initialization writes labels remotely and commits the four templates directly to the repository's default branch through the GitHub Contents API. Include the target repository and files in the preview.

5. Execute the chosen action:
   - Update / Initialize: `bash "${SKILL_DIR}/scripts/vapa-init.sh" <owner/repo>`
   - Reset: `bash "${SKILL_DIR}/scripts/vapa-init.sh" --reset <owner/repo>`
   - Initialize org fields: `bash "${SKILL_DIR}/scripts/vapa-init.sh" --init-fields <owner/repo>`
   - Cancel: stop and confirm cancellation.

### Step 2: VISION.md guidance

After labels and templates are initialized successfully:

1. Check whether `${PROJECT_DIR}/VISION.md` exists.
2. If it does **not** exist, ask the user: "是否现在创建 VISION.md？这是 VAPA 流程的北极星文档，所有提案都需要与之对齐。"
   - If the user agrees, proceed to step 3.
   - If the user declines, confirm that VISION.md can be created later.
3. If it **already exists**, read it and determine whether it contains meaningful content (i.e. sections have been filled with real text rather than only template placeholders).
   - **If it has meaningful content**: do **not** offer to edit it. Explain that according to the VAPA framework, `VISION.md` is protected and can only be changed through a Vision Amendment proposal. Guide the user to use the `vision-amendment.md` issue template (`/vapa-proposal` can create one with the `Vision Amendment` issue type if needed).
   - **If it is empty or only contains template placeholders**: ask the user: "VISION.md 尚未填写实质内容。是否现在填写？"
     - If the user agrees, proceed to step 3.
     - If the user declines, confirm that VISION.md can be filled later.

### Step 3: Collect VISION.md content

Guide the user through the five sections defined in the VAPA specification. Ask one question per section to keep it step-by-step:

1. **我们在解决谁的什么问题**
   - Ask: "请描述：具体人群、具体场景、具体痛点，以及为什么现在解决它？"
2. **我们明确不做什么**
   - Ask: "请列出 1-3 个明确的排除项及原因，防止提案范围蔓延。"
3. **当前阶段战略重心**
   - Ask: "请列出本季度的 2-4 个战略重心，格式：重心 | 描述 | 权重。"
4. **12个月后成功看起来是什么样子**
   - Ask: "请列出 2-3 个可观测的成功状态。"
5. **当前开放问题**
   - Ask: "请列出 1-3 个团队尚未想清楚、最欢迎提案探索的开放问题。"

### Step 4: Write VISION.md

Use the collected answers to write a `VISION.md` file that follows the structure in `${SKILL_DIR}/references/VISION.md.template`.

Place the file at `${PROJECT_DIR}/VISION.md`.

Include the current date in the footer:

```markdown
---
_最后更新：YYYY-MM-DD　｜　下次评审：YYYY-MM-DD_
_修改历史见：[VISION-CHANGELOG.md](./VISION-CHANGELOG.md)_
```

After writing, show the user the file path and a brief summary of what was written.

## Output handling

- On success, confirm the repo has been initialized/updated/reset and summarize what changed.
- On failure, show the script output and explain the likely cause (e.g., `gh` not authenticated, missing repo permission, network error).
- On cancellation, confirm that no changes were made.

## VAPA configuration model

| Dimension | Level | Mechanism | Managed by `/vapa-init` |
|---|---|---|---|
| Type | Organization | Issue types | Check only |
| Align / Size | Organization | Issue fields | Check only |
| Contributor roles | Organization | Issue fields (`Shaper`, `Reviewed By`, `Validator`, `Sponsor`) — single-select populated from org members | Check / `--init-fields` |
| Status | Repository | Labels | Create / update |
| Templates | Repository | `.github/ISSUE_TEMPLATE/` | Create / update |

## References

- Issue templates are bundled in `${SKILL_DIR}/references/`.
- VISION.md template is at `${SKILL_DIR}/references/VISION.md.template`.

## Safety notes

- Non-VAPA labels and templates are never modified or deleted, even in reset mode.
- Reset mode only deletes labels whose names match the current or legacy VAPA taxonomy and the four bundled issue templates.
- Issue types and `Align` / `Size` are check-only. `--init-fields` creates or updates the four contributor-role fields organization-wide; it never deletes a field to change its type.
- VISION.md is only created when it does not exist or only contains template placeholders.
- Once VISION.md has meaningful content, it is treated as immutable by `/vapa-init`. Changes must go through the Vision Amendment process using the `vision-amendment.md` issue template.
