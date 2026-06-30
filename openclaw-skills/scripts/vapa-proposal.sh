#!/bin/bash
# vapa-proposal: Create or list VAPA proposals
# Usage:
#   vapa-proposal <subject>     # Create new proposal
#   vapa-proposal                 # List pending proposals

set -euo pipefail

SUBJECT="${1:-}"
REPO="${VAPA_REPO:-}"

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
echo "🚀 Creating VAPA proposal: $SUBJECT"

# Use feature-proposal template
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
TEMPLATE="$SKILL_DIR/assets/feature-proposal.md"

if [[ -f "$TEMPLATE" ]]; then
  BODY=$(cat "$TEMPLATE")
  # Replace placeholder title
  BODY="${BODY/\[提案标题：动词 + 对象 + 价值\]/$SUBJECT}"
else
  BODY="$SUBJECT"
fi

# Create issue
ISSUE_URL=$(gh issue create --repo "$REPO" \
  --title "$SUBJECT" \
  --body "$BODY" \
  --label "type: feature,status: draft" \
  2>/dev/null || true)

if [[ -n "$ISSUE_URL" ]]; then
  echo "✅ Created: $ISSUE_URL"
else
  echo "❌ Failed to create proposal"
  exit 1
fi
