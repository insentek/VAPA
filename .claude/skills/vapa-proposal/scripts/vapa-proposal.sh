#!/bin/bash
# vapa-proposal: Create or list VAPA proposals
# Usage:
#   vapa-proposal <subject>         # Create a new Feature proposal (default)
#   vapa-proposal <subject> [type]  # Create a proposal with a specific issue type
#   vapa-proposal                   # List pending proposals

set -euo pipefail

SUBJECT="${1:-}"
ISSUE_TYPE="${2:-Feature}"
REPO="${VAPA_REPO:-}"
API_VERSION="2026-03-10"

if [[ -z "$REPO" ]]; then
  # Try to detect from git remote
  if git rev-parse --git-dir > /dev/null 2>&1; then
    REMOTE_URL=$(git remote get-url origin 2>/dev/null || true)
    if [[ -n "$REMOTE_URL" ]]; then
      # Extract owner/repo from URL
      if [[ "$REMOTE_URL" =~ github\.com[/:]([^/]+)/([^/.]+) ]]; then
        REPO="${BASH_REMATCH[1]}/${BASH_REMATCH[2]}"
      fi
    fi
  fi
fi

if [[ -z "$REPO" ]]; then
  echo "❌ Could not detect repo. Set VAPA_REPO=owner/repo or run from a git repo."
  exit 1
fi

OWNER="${REPO%%/*}"
REPO_NAME="${REPO##*/}"

# Determine the next VEP number by scanning all issue titles for ^VEP-(\d+).
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

# ── List mode ───────────────────────────────────────────────────
if [[ -z "$SUBJECT" ]]; then
  echo "📋 Pending proposals in $REPO:"
  echo ""

  # Fetch issues with pending status labels
  gh issue list --repo "$REPO" \
    --label "status: draft" \
    --json number,title,labels,url \
    --jq '.[] | "  📝 #\(.number) \(.title)"' 2>/dev/null || true

  gh issue list --repo "$REPO" \
    --label "status: refining" \
    --json number,title,labels,url \
    --jq '.[] | "  🔧 #\(.number) \(.title)"' 2>/dev/null || true

  gh issue list --repo "$REPO" \
    --label "status: ready-for-review" \
    --json number,title,labels,url \
    --jq '.[] | "  ✅ #\(.number) \(.title)"' 2>/dev/null || true

  exit 0
fi

# ── Create mode ─────────────────────────────────────────────────

NEXT_VEP=$(get_next_vep_number "$REPO")

# Strip an existing "VEP-XXXX " prefix from the subject so we don't double-prefix.
CLEAN_SUBJECT=$(python3 -c 'import sys, re; print(re.sub(r"^VEP-\d+\s+", "", sys.argv[1]))' "$SUBJECT")
TITLE="VEP-$NEXT_VEP $CLEAN_SUBJECT"

echo "🚀 Creating VAPA proposal: $TITLE"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"

# Map issue type to the bundled template, if any.
TEMPLATE_NAME="feature-proposal.md"
case "$ISSUE_TYPE" in
  "Problem") TEMPLATE_NAME="problem-statement.md" ;;
  "Vision Amendment") TEMPLATE_NAME="vision-amendment.md" ;;
  "Experiment") TEMPLATE_NAME="experiment.md" ;;
  *) TEMPLATE_NAME="feature-proposal.md" ;;
esac

TEMPLATE="$SKILL_DIR/references/$TEMPLATE_NAME"
if [[ -f "$TEMPLATE" ]]; then
  BODY=$(cat "$TEMPLATE")
  # Replace placeholder title
  BODY="${BODY/\[提案标题：动词 + 对象 + 价值\]/$SUBJECT}"
else
  BODY="$SUBJECT"
fi

# Create issue via REST API so the native type is set even on older gh CLI versions
PAYLOAD=$(python3 - "$TITLE" "$BODY" "$ISSUE_TYPE" <<'PY'
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

ISSUE_RESPONSE=$(echo "$PAYLOAD" | gh api "repos/$REPO/issues" \
  --method POST \
  --input - \
  --jq '{number: .number, url: .html_url}' 2>/dev/null || true)

if [[ -z "$ISSUE_RESPONSE" ]]; then
  echo "❌ Failed to create proposal"
  exit 1
fi

ISSUE_NUMBER=$(echo "$ISSUE_RESPONSE" | python3 -c 'import json,sys; print(json.load(sys.stdin)["number"])')
ISSUE_URL=$(echo "$ISSUE_RESPONSE" | python3 -c 'import json,sys; print(json.load(sys.stdin)["url"])')

if [[ -z "$ISSUE_NUMBER" || -z "$ISSUE_URL" ]]; then
  echo "❌ Failed to parse created issue response"
  exit 1
fi

echo "✅ Created VEP-$NEXT_VEP: $ISSUE_URL"
