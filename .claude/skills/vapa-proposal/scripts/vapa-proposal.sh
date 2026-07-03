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
    if [[ -n "$remote_url" && "$remote_url" =~ github\.com[/:]([^/]+)/([^/]+?)(\.git)?$ ]]; then
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
    --limit 1000 \
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
        if [[ -z "${2:-}" ]]; then
          echo "❌ --subject requires a value" >&2
          usage >&2
          exit 1
        fi
        SUBJECT="$2"
        shift 2
        ;;
      --body-file)
        if [[ -z "${2:-}" ]]; then
          echo "❌ --body-file requires a value" >&2
          usage >&2
          exit 1
        fi
        BODY_FILE="$2"
        shift 2
        ;;
      --type)
        if [[ -z "${2:-}" ]]; then
          echo "❌ --type requires a value" >&2
          usage >&2
          exit 1
        fi
        ISSUE_TYPE="$2"
        shift 2
        ;;
      --repo)
        if [[ -z "${2:-}" ]]; then
          echo "❌ --repo requires a value" >&2
          usage >&2
          exit 1
        fi
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
