# vapa-proposal AI-Assisted Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Transform `/vapa-proposal` from a template-stamping script into an AI-assisted proposal designer that infers type, drafts content, asks clarifying questions, previews the result, and submits only after user confirmation.

**Architecture:** The shell script becomes a submission-only backend (`--subject`, `--body-file`, `--type`, `--next-number`, `--list`). The `SKILL.md` orchestrates the AI workflow: context gathering, type inference, clarification, draft generation, preview, and final invocation.

**Tech Stack:** Bash, GitHub CLI (`gh`), Python 3, Markdown.

---

## File Map

| File | Responsibility |
|---|---|
| `.claude/skills/vapa-proposal/scripts/vapa-proposal.sh` | Pure submission backend: parse CLI, compute VEP number, list/create issues. |
| `.claude/skills/vapa-proposal/SKILL.md` | Orchestrates the AI workflow: read context, infer type, ask questions, draft, preview, confirm, submit. |
| `.claude/skills/vapa-proposal/references/*.md` | Canonical templates used by the skill for drafting. |
| `.claude/skills/vapa-init/references/*.md` | Mirror copies used by `/vapa-init` to install repo templates. Must stay identical to the vapa-proposal copies. |
| `README.md` | Public documentation for the `/vapa-proposal` command. |
| `tests/test-vapa-proposal.sh` | Unit-style tests for pure bash functions (CLI parsing, title construction, VEP prefix stripping). |

---

### Task 1: Restructure `vapa-proposal.sh` into functions with a `main` guard

**Files:**
- Modify: `.claude/skills/vapa-proposal/scripts/vapa-proposal.sh`

**Why:** The current script runs top-level code immediately, so it cannot be sourced by tests. We need a function-based structure.

- [ ] **Step 1: Replace the entire script with the skeleton below**

```bash
#!/bin/bash
# vapa-proposal: Submission backend for VAPA proposals.
# Usage:
#   vapa-proposal.sh --subject "..." --body-file path.md --type Feature
#   vapa-proposal.sh --next-number
#   vapa-proposal.sh --list
#   vapa-proposal.sh --repo owner/repo

set -euo pipefail

# ── Defaults ────────────────────────────────────────────────────
SUBJECT=""
BODY_FILE=""
ISSUE_TYPE="Feature"
REPO="${VAPA_REPO:-}"
NEXT_NUMBER=false
LIST_MODE=false

# ── Helper functions ────────────────────────────────────────────

usage() {
  cat <<'EOF'
vapa-proposal.sh submission backend

  --subject <text>     proposal subject (used to build the VEP title)
  --body-file <path>   path to a file containing the issue body
  --type <type>        VAPA issue type (default: Feature)
  --repo <owner/repo>  target repository (default: detected from git origin)
  --next-number        print the next VEP-XXXX number and exit
  --list               list pending proposals and exit
  --help               show this message
EOF
}

detect_repo() {
  if git rev-parse --git-dir >/dev/null 2>&1; then
    local remote_url
    remote_url=$(git remote get-url origin 2>/dev/null || true)
    if [[ -n "$remote_url" && "$remote_url" =~ github\.com[/:]([^/]+)/([^/.]+) ]]; then
      echo "${BASH_REMATCH[1]}/${BASH_REMATCH[2]}"
    fi
  fi
}

get_next_vep_number() {
  local repo="$1"
  local max=0
  local titles
  titles=$(gh issue list --repo "$repo" \
    --state all \
    --search "VEP- in:title" \
    --json title \
    --jq '.[].title' 2>/dev/null || true)

  if [[ -n "$titles" ]]; then
    local num
    num=$(echo "$titles" | python3 -c '
import sys, re
nums = []
for line in sys.stdin:
    m = re.match(r"^VEP-(\d+)", line.strip())
    if m:
        nums.append(int(m.group(1)))
print(max(nums) if nums else 0)
' 2>/dev/null || true)
    [[ -n "$num" ]] && max="$num"
  fi

  printf "%04d" $((max + 1))
}

# ── Action functions ────────────────────────────────────────────

print_next_number() {
  local repo="${1:-}"
  if [[ -z "$repo" ]]; then
    repo=$(detect_repo) || true
  fi
  if [[ -z "$repo" ]]; then
    echo "❌ Could not detect repo. Set --repo or VAPA_REPO=owner/repo." >&2
    exit 1
  fi
  get_next_vep_number "$repo"
}

list_proposals() {
  local repo="${1:-}"
  if [[ -z "$repo" ]]; then
    repo=$(detect_repo) || true
  fi
  if [[ -z "$repo" ]]; then
    echo "❌ Could not detect repo. Set --repo or VAPA_REPO=owner/repo." >&2
    exit 1
  fi

  echo "📋 Pending proposals in $repo:"
  echo ""
  local status
  for status in "status: draft" "status: refining" "status: ready-for-review"; do
    gh issue list --repo "$repo" \
      --label "$status" \
      --json number,title,url \
      --jq '.[] | "  #\(.number) \(.title)"' 2>/dev/null || true
  done
}

create_proposal() {
  local repo="$1" subject="$2" body_file="$3" issue_type="$4"

  if [[ ! -f "$body_file" ]]; then
    echo "❌ Body file not found: $body_file" >&2
    exit 1
  fi

  local next_vep clean_subject title body payload response issue_number issue_url
  next_vep=$(get_next_vep_number "$repo")
  clean_subject=$(python3 -c 'import sys, re; print(re.sub(r"^VEP-\d+\s+", "", sys.argv[1]))' "$subject")
  title="VEP-$next_vep $clean_subject"
  body=$(cat "$body_file")

  payload=$(python3 - "$title" "$body" "$issue_type" <<'PY'
import json, sys
title, body, issue_type = sys.argv[1], sys.argv[2], sys.argv[3]
print(json.dumps({
  "title": title,
  "body": body,
  "labels": ["status: draft"],
  "type": issue_type
}))
PY
)

  response=$(echo "$payload" | gh api "repos/$repo/issues" \
    --method POST \
    --input - \
    --jq '{number: .number, url: .html_url}' 2>/dev/null || true)

  if [[ -z "$response" ]]; then
    echo "❌ Failed to create proposal" >&2
    exit 1
  fi

  issue_number=$(echo "$response" | python3 -c 'import json,sys; print(json.load(sys.stdin)["number"])')
  issue_url=$(echo "$response" | python3 -c 'import json,sys; print(json.load(sys.stdin)["url"])')

  if [[ -z "$issue_number" || -z "$issue_url" ]]; then
    echo "❌ Failed to parse created issue response" >&2
    exit 1
  fi

  echo "✅ Created VEP-$next_vep: $issue_url"
}

# ── CLI parsing ─────────────────────────────────────────────────

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --subject)
        SUBJECT="$2"
        shift 2
        ;;
      --body-file)
        BODY_FILE="$2"
        shift 2
        ;;
      --type)
        ISSUE_TYPE="$2"
        shift 2
        ;;
      --repo)
        REPO="$2"
        shift 2
        ;;
      --next-number)
        NEXT_NUMBER=true
        shift
        ;;
      --list)
        LIST_MODE=true
        shift
        ;;
      --help)
        usage
        exit 0
        ;;
      --)
        shift
        break
        ;;
      -*)
        echo "❌ Unknown option: $1" >&2
        usage >&2
        exit 1
        ;;
      *)
        break
        ;;
    esac
  done
}

main() {
  parse_args "$@"

  if $NEXT_NUMBER; then
    print_next_number "$REPO"
    exit 0
  fi

  if $LIST_MODE; then
    list_proposals "$REPO"
    exit 0
  fi

  if [[ -z "$REPO" ]]; then
    REPO=$(detect_repo) || true
  fi

  if [[ -z "$REPO" ]]; then
    echo "❌ Could not detect repo. Set --repo or VAPA_REPO=owner/repo." >&2
    exit 1
  fi

  if [[ -z "$SUBJECT" || -z "$BODY_FILE" ]]; then
    echo "❌ --subject and --body-file are required to create a proposal." >&2
    usage >&2
    exit 1
  fi

  create_proposal "$REPO" "$SUBJECT" "$BODY_FILE" "$ISSUE_TYPE"
}

# Only run main when executed directly, not when sourced by tests.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
```

- [ ] **Step 2: Run a syntax check**

```bash
bash -n .claude/skills/vapa-proposal/scripts/vapa-proposal.sh
```

Expected: no output (success).

- [ ] **Step 3: Commit**

```bash
git add .claude/skills/vapa-proposal/scripts/vapa-proposal.sh
git commit -m "refactor(vapa-proposal): restructure script into functions with CLI flags

- Add --subject, --body-file, --type, --repo, --next-number, --list.
- Keep VEP numbering and prefix-stripping logic.
- Guard code with main() so the script can be sourced by tests.

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 2: Sync and fix the bundled reference templates

**Files:**
- Modify: `.claude/skills/vapa-proposal/references/feature-proposal.md`
- Modify: `.claude/skills/vapa-proposal/references/problem-statement.md`
- Modify: `.claude/skills/vapa-proposal/references/vision-amendment.md`
- Modify: `.claude/skills/vapa-proposal/references/experiment.md`
- Modify: `.claude/skills/vapa-init/references/feature-proposal.md`
- Modify: `.claude/skills/vapa-init/references/problem-statement.md`
- Modify: `.claude/skills/vapa-init/references/vision-amendment.md`
- Modify: `.claude/skills/vapa-init/references/experiment.md`

**Why:** The vapa-proposal copies are stale and the two directories are out of sync. We need one canonical version in both places.

- [ ] **Step 1: Update `feature-proposal.md` frontmatter in both directories**

The file must start with:

```markdown
---
name: "🚀 Feature Proposal"
about: "提出一个新能力或改善提案"
labels: "status: draft"
type: "Feature"
---

<!-- NOTE: Keep in sync with the copy in the sibling skill's references/ directory. -->
```

Apply this exact change to:
- `.claude/skills/vapa-proposal/references/feature-proposal.md`
- `.claude/skills/vapa-init/references/feature-proposal.md`

- [ ] **Step 2: Add sync comments to the other three templates**

At the top of each file (after the frontmatter), add:

```markdown
<!-- NOTE: Keep in sync with the copy in the sibling skill's references/ directory. -->
```

Apply to all eight files (four in each directory).

- [ ] **Step 3: Verify the two directories are identical**

```bash
diff -r .claude/skills/vapa-proposal/references .claude/skills/vapa-init/references
```

Expected: no output.

- [ ] **Step 4: Commit**

```bash
git add .claude/skills/vapa-proposal/references .claude/skills/vapa-init/references
git commit -m "fix(templates): sync vapa-proposal and vapa-init reference templates

- Update feature-proposal.md frontmatter to native type + status label.
- Add sync comments to prevent future drift.

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 3: Rewrite `vapa-proposal/SKILL.md` to orchestrate the AI workflow

**Files:**
- Modify: `.claude/skills/vapa-proposal/SKILL.md`

**Why:** The skill instructions must now drive context gathering, type inference, clarification, drafting, preview, and confirmation.

- [ ] **Step 1: Replace the entire `SKILL.md` with the following**

```markdown
---
name: vapa-proposal
description: Create a new VAPA proposal with AI-assisted drafting, preview, and confirmation before submitting to GitHub Issues.
disable-model-invocation: true
allowed-tools: Bash(git remote get-url origin) Bash(gh issue list *) Bash(gh issue view *) Read Write AskUserQuestion Bash(${CLAUDE_SKILL_DIR}/scripts/vapa-proposal.sh *)
---

# /vapa-proposal

Create a new VAPA proposal on a GitHub repository. The skill helps you turn a one-line idea into a complete, well-structured proposal, shows a preview, and only creates the Issue after you confirm.

## Modes

- **With a subject**: AI gathers repository context, infers the Issue Type, asks clarifying questions if needed, drafts the full proposal, previews it, and creates the Issue upon confirmation.
- **With a subject and explicit Issue Type**: skip type inference and use the provided type.
- **Without arguments**: list pending proposals (`status: draft`, `status: refining`, `status: ready-for-review`).

## Proposal numbering

Every approved proposal receives a `VEP-XXXX` prefix (4-digit, zero-padded). The shell backend computes the next number from existing issue titles at submission time.

## Usage

```
/vapa-proposal "让VAPA变得可被一键安装，推广VAPA的理念和SKILLS"
/vapa-proposal "调整 Q3 战略重心" "Vision Amendment"
/vapa-proposal
```

## Requirements

- `gh` CLI installed and authenticated with permission to create issues on the target repo.
- Run from inside a git repo, or set `VAPA_REPO=owner/repo`.
- The organization must have the required VAPA issue types and issue fields (`Align`, `Size`, `Shaper`, `Reviewed By`, `Validator`, `Sponsor`).

## Execution

### Step 1: Detect repository

Run:

```bash
git remote get-url origin
```

Parse `owner/repo`. If detection fails, explain that the user should run `/vapa-proposal` from a git repo with a GitHub origin remote, or set `VAPA_REPO=owner/repo`.

### Step 2: Gather context

Read the following files when they exist:

- `${CLAUDE_PROJECT_DIR}/VISION.md`
- `${CLAUDE_PROJECT_DIR}/README.md`

Fetch recent issues for context and duplicate detection:

```bash
gh issue list --repo <owner/repo> --state all --limit 30 --json number,title,labels,body
```

### Step 3: Infer Issue Type

Use the user's subject and the gathered context to choose the most likely VAPA Issue Type:

| Trigger words / context | Type |
|---|---|
| 愿景, VISION, 战略重心, 修正, amend | `Vision Amendment` |
| Describes a pain/observation without a clear solution | `Problem` |
| 实验, 验证, poc, spike, prototype | `Experiment` |
| 重构, 技术债, 性能, cleanup | `Technical Debt` or `Improvement` |
| 调研, 研究, research | `Research` |
| Default | `Feature` |

If confidence is low, present the top two options and ask the user to choose. If the user provided a second argument, use it and skip inference.

### Step 4: Ask clarifying questions

Check required fields per type. If any are missing or vague, ask one focused question at a time. The user may answer, skip, or ask you to draft a placeholder.

| Type | Required fields |
|---|---|
| `Feature` / `Improvement` | target user, problem, core idea, "this is not", acceptance criteria, estimated `Size` |
| `Problem` | affected users, observable evidence, impact if not solved |
| `Vision Amendment` | current VISION.md text, proposed text, rationale, risks of not changing |
| `Experiment` | hypothesis, validation method, success metric, scope |
| `Research` | research question, expected output, why it matters now |

### Step 5: Draft the proposal

Select the bundled template that matches the type:

| Type | Template |
|---|---|
| `Feature`, `Improvement`, `Technical Debt`, `Research` | `${CLAUDE_SKILL_DIR}/references/feature-proposal.md` |
| `Problem` | `${CLAUDE_SKILL_DIR}/references/problem-statement.md` |
| `Vision Amendment` | `${CLAUDE_SKILL_DIR}/references/vision-amendment.md` |
| `Experiment` | `${CLAUDE_SKILL_DIR}/references/experiment.md` |

Read the template, replace the title placeholder with the user's subject, and fill each section using:

- the user's original sentence,
- answers to clarifying questions,
- `VISION.md` for alignment,
- recent issues for related context.

Leave unknown sections as bracketed placeholders like `[待补充：具体受影响的角色]`.

### Step 6: Preview

Show the complete proposal in the terminal:

```markdown
📝 提案预览

类型：<type>
标题：VEP-XXXX <subject>

---

<full body>
```

The `VEP-XXXX` number is a best-effort preview. The actual number is computed at submission time.

Then ask:

> 请选择：① 提交 ② 编辑某节 ③ 取消

- **① 提交**: proceed to Step 7.
- **② 编辑某节**: ask which section, regenerate only that section, and return to the preview.
- **③ 取消**: stop and confirm that no Issue was created.

### Step 7: Submit

Write the final body to a temporary file and invoke the submission backend:

```bash
${CLAUDE_SKILL_DIR}/scripts/vapa-proposal.sh \
  --repo <owner/repo> \
  --subject "<user subject>" \
  --body-file /tmp/vep-body.md \
  --type "<type>"
```

On success, report the created issue URL and VEP number.

## Output handling

- On success, report the assigned `VEP-XXXX` number and the created issue URL.
- On cancellation, confirm that no Issue was created.
- On failure, show the script output and explain the likely cause (e.g., missing `gh` auth, no repo detected, invalid issue type, missing org-level issue fields).

## References

The proposal templates are bundled at `${CLAUDE_SKILL_DIR}/references/`:

- `feature-proposal.md`
- `problem-statement.md`
- `vision-amendment.md`
- `experiment.md`
```

- [ ] **Step 2: Validate YAML frontmatter**

Ensure the file starts with valid YAML delimited by `---`. The `allowed-tools` line is long but must remain a single value under the key.

- [ ] **Step 3: Commit**

```bash
git add .claude/skills/vapa-proposal/SKILL.md
git commit -m "docs(vapa-proposal): rewrite SKILL.md for AI-assisted workflow

- Add context gathering, type inference, and clarification rules.
- Define preview/confirmation flow.
- Update allowed-tools for new backend CLI.

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 4: Update `README.md`

**Files:**
- Modify: `README.md`

**Why:** The public examples and field table should reflect the new behavior.

- [ ] **Step 1: Update the Skills table**

Replace the `/vapa-proposal` row with:

```markdown
| `/vapa-proposal [subject] [type]` | AI 辅助创建提案：推断类型、澄清缺失信息、生成完整正文、预览确认后提交；不带参数时列出待定提案 | `/vapa-proposal "让VAPA变得可被一键安装，推广VAPA的理念和SKILLS"` |
```

- [ ] **Step 2: Update the Issue metadata table in Layer 2.1**

The table currently lists `Proposed By` under Issue Fields. Replace that row with two rows:

```markdown
| **战略对齐 / 规模 / 贡献角色** | 组织 | Issue Fields | `Align`、`Size`、`Shaper`、`Reviewed By`、`Validator`、`Sponsor` |
| **提案人** | Issue | 作者 | 提案 Issue 的创建者即为 Proposer，不单独设置字段 |
```

- [ ] **Step 3: Commit**

```bash
git add README.md
git commit -m "docs(readme): update vapa-proposal description and metadata table

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 5: Add unit-style tests for pure functions

**Files:**
- Create: `tests/test-vapa-proposal.sh`

**Why:** The script now has pure helper logic (title construction, prefix stripping) that can be tested without calling GitHub.

- [ ] **Step 1: Create the `tests` directory and test file**

```bash
mkdir -p tests
```

Create `tests/test-vapa-proposal.sh` with the following content:

```bash
#!/bin/bash
# Unit tests for vapa-proposal helper logic.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source the script under test. main() is guarded, so this only loads functions.
source "$PROJECT_DIR/.claude/skills/vapa-proposal/scripts/vapa-proposal.sh"

# Override gh so get_next_vep_number can be tested without network.
gh() {
  echo "VEP-0001 first"
  echo "VEP-0010 second"
  echo "VEP-0005 third"
}
export -f gh

failures=0

assert_eq() {
  local expected="$1" actual="$2" msg="$3"
  if [[ "$expected" != "$actual" ]]; then
    echo "FAIL: $msg"
    echo "  expected: '$expected'"
    echo "  actual:   '$actual'"
    ((failures++)) || true
  fi
}

# Test VEP number extraction picks the max + 1.
next=$(get_next_vep_number "owner/repo")
assert_eq "0011" "$next" "next VEP number should be max+1 with 4-digit padding"

# Test prefix stripping in title construction via inline python logic.
clean1=$(python3 -c 'import sys, re; print(re.sub(r"^VEP-\d+\s+", "", sys.argv[1]))' "VEP-0003 some idea")
assert_eq "some idea" "$clean1" "clean_subject strips existing VEP prefix"

clean2=$(python3 -c 'import sys, re; print(re.sub(r"^VEP-\d+\s+", "", sys.argv[1]))' "some idea")
assert_eq "some idea" "$clean2" "clean_subject leaves subject unchanged when no prefix"

if [[ $failures -gt 0 ]]; then
  echo "$failures test(s) failed"
  exit 1
fi

echo "All tests passed"
```

- [ ] **Step 2: Make the test executable and run it**

```bash
chmod +x tests/test-vapa-proposal.sh
bash tests/test-vapa-proposal.sh
```

Expected output:

```
All tests passed
```

- [ ] **Step 3: Commit**

```bash
git add tests/test-vapa-proposal.sh
git commit -m "test(vapa-proposal): add unit tests for VEP numbering helpers

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 6: Manual end-to-end verification

**Files:**
- None (uses live repo)

**Why:** The GitHub API path can only be verified against a real repository.

- [ ] **Step 1: Verify `--next-number` works**

```bash
.claude/skills/vapa-proposal/scripts/vapa-proposal.sh --next-number
```

Expected: prints `0002` (because `VEP-0001` already exists from the earlier test issue).

- [ ] **Step 2: Verify `--list` works**

```bash
.claude/skills/vapa-proposal/scripts/vapa-proposal.sh --list
```

Expected: lists issue #11 with `VEP-0001` and no errors.

- [ ] **Step 3: Verify `--subject/--body-file/--type` creates an Issue**

Create a temporary body file:

```bash
cat > /tmp/vep-test-body.md <<'EOF'
## 测试正文

这是一个用于验证 vapa-proposal 后端的测试提案。
EOF
```

Run the backend:

```bash
.claude/skills/vapa-proposal/scripts/vapa-proposal.sh \
  --subject "测试 VEP 后端创建流程" \
  --body-file /tmp/vep-test-body.md \
  --type Feature
```

Expected: output `✅ Created VEP-0002: https://github.com/insentek/VAPA/issues/...`

- [ ] **Step 4: Inspect the created issue**

```bash
gh issue view <number-from-step-3> --repo insentek/VAPA --json title,labels
```

Expected:

```json
{
  "labels": [{"name": "status: draft"}],
  "title": "VEP-0002 测试 VEP 后端创建流程"
}
```

- [ ] **Step 5: Close the test issue**

```bash
gh issue close <number-from-step-3> --repo insentek/VAPA --comment "关闭测试 Issue"
```

- [ ] **Step 6: Commit a verification note**

No code change. Optionally add a note to `docs/superpowers/plans/2026-07-03-vapa-proposal.md` marking verification complete. Not required.

---

## Spec Coverage Check

| Spec Section | Implementing Task |
|---|---|
| AI-assisted overall flow | Task 3 (SKILL.md) |
| Type inference rules | Task 3 (SKILL.md) |
| Clarification rules | Task 3 (SKILL.md) |
| Draft generation / template mapping | Task 3 (SKILL.md) |
| Preview & confirmation | Task 3 (SKILL.md) |
| Script CLI changes | Task 1 |
| Template synchronization | Task 2 |
| Error handling | Task 1 + Task 3 |
| Public README updates | Task 4 |

No gaps identified.

---

## Execution Handoff

Plan complete and saved to `docs/superpowers/plans/2026-07-03-vapa-proposal.md`.

**Two execution options:**

1. **Subagent-Driven (recommended)** — dispatch a fresh subagent per task, review between tasks.
2. **Inline Execution** — execute tasks in this session using `superpowers:executing-plans`.

Which approach do you want?
