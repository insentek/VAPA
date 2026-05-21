#!/bin/bash
# vapa-init: Initialize VAPA labels and issue templates on a GitHub repo
# Usage: vapa-init <owner/repo>

set -euo pipefail

REPO="${1:-}"
if [[ -z "$REPO" ]]; then
  echo "Usage: vapa-init <owner/repo>"
  exit 1
fi

OWNER="${REPO%%/*}"
REPO_NAME="${REPO##*/}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"

# ── 1. Configure labels ─────────────────────────────────────────
echo "🎯 Configuring VAPA labels for $REPO..."
python3 "$SCRIPT_DIR/vapa-labels.py" \
  --token "$(gh auth token)" \
  --owner "$OWNER" \
  --repo "$REPO_NAME"

# ── 2. Create issue templates ───────────────────────────────────
echo "📝 Creating issue templates..."

TEMPLATES=(
  "feature-proposal.md"
  "problem-statement.md"
  "vision-amendment.md"
  "experiment.md"
)

for tmpl in "${TEMPLATES[@]}"; do
  src="$SKILL_DIR/assets/$tmpl"
  if [[ ! -f "$src" ]]; then
    echo "  ⚠️  Missing template: $src"
    continue
  fi

  # Encode content to base64
  content_b64=$(base64 -i "$src" | tr -d '\n')

  # Check if template already exists
  existing=$(gh api "repos/$REPO/contents/.github/ISSUE_TEMPLATE/$tmpl" --jq '.sha' 2>/dev/null || true)

  if [[ -n "$existing" && "$existing" != "null" ]]; then
    echo "  updating: $tmpl"
    gh api "repos/$REPO/contents/.github/ISSUE_TEMPLATE/$tmpl" \
      --method PUT \
      -f message="Update VAPA issue template: $tmpl" \
      -f content="$content_b64" \
      -f sha="$existing" \
      >/dev/null
  else
    echo "  creating: $tmpl"
    gh api "repos/$REPO/contents/.github/ISSUE_TEMPLATE/$tmpl" \
      --method PUT \
      -f message="Add VAPA issue template: $tmpl" \
      -f content="$content_b64" \
      >/dev/null
  fi
done

echo "✅ VAPA initialized on $REPO"
