#!/bin/bash
# vapa-review: backend helpers for reviewing VAPA proposal issues.
# Usage:
#   vapa-review.sh context      --issue 15 [--repo owner/repo]
#   vapa-review.sh find-comment --issue 15 [--repo owner/repo]
#   vapa-review.sh post         --issue 15 --body-file review.md [--repo owner/repo]
#   vapa-review.sh update       --comment-id 123 --body-file review.md [--repo owner/repo]
#   vapa-review.sh start        --issue 15 [--repo owner/repo]
#
# The review comment posted by the skill always carries the hidden marker
# "<!-- vapa-review -->" so re-runs can recognize their own previous review.

set -euo pipefail

# ── Constants ───────────────────────────────────────────────────

REVIEW_MARKER='<!-- vapa-review -->'

# ── Defaults ────────────────────────────────────────────────────

COMMAND=""
ISSUE=""
COMMENT_ID=""
BODY_FILE=""
REPO="${VAPA_REPO:-}"

# ── Helper functions ────────────────────────────────────────────

usage() {
  cat <<'EOF'
vapa-review.sh review backend

  context      --issue <n|url>          print full issue JSON (body + comments + labels)
  find-comment --issue <n|url>          print the ID of the latest vapa-review comment, or nothing
  post         --issue <n|url> --body-file <path>   post a new review comment
  update       --comment-id <id> --body-file <path> patch an existing review comment
  start        --issue <n|url>          label sync: ready-for-review -> in-review

Common flags:
  --repo <owner/repo>  target repository (default: detected from git origin or VAPA_REPO)
  --help               show this message
EOF
}

detect_repo() {
  if git rev-parse --git-dir >/dev/null 2>&1; then
    local remote_url
    remote_url=$(git remote get-url origin 2>/dev/null || true)
    if [[ -n "$remote_url" && "$remote_url" =~ github\.com[/:]([^/]+)/([^/]+)(\.git)?$ ]]; then
      echo "${BASH_REMATCH[1]}/${BASH_REMATCH[2]%.git}"
    fi
  fi
}

require_repo() {
  if [[ -z "$REPO" ]]; then
    REPO=$(detect_repo) || true
  fi
  if [[ -z "$REPO" ]]; then
    echo "❌ Could not detect repo. Set --repo or VAPA_REPO=owner/repo." >&2
    exit 1
  fi
}

# Accepts a plain issue number or a full GitHub issue URL; prints the number.
parse_issue_ref() {
  local ref="$1"
  if [[ "$ref" =~ /issues/([0-9]+) ]]; then
    echo "${BASH_REMATCH[1]}"
  elif [[ "$ref" =~ ^[0-9]+$ ]]; then
    echo "$ref"
  else
    echo "❌ Cannot parse issue reference: $ref (expected a number or an issue URL)" >&2
    return 1
  fi
}

require_body_file() {
  if [[ -z "$BODY_FILE" || ! -f "$BODY_FILE" ]]; then
    echo "❌ Body file not found: ${BODY_FILE:-<none>}" >&2
    exit 1
  fi
}

# ── Review logic ────────────────────────────────────────────────

# Full context in one call: the review must be based on the complete issue,
# not just the title.
fetch_context() {
  local repo="$1" issue="$2"
  gh issue view "$issue" --repo "$repo" \
    --json number,title,state,url,author,labels,body,comments
}

# Print the ID of the most recent comment carrying the review marker.
find_review_comment() {
  local repo="$1" issue="$2"
  gh api "repos/$repo/issues/$issue/comments" --paginate 2>/dev/null \
    | python3 -c '
import json, sys
marker = sys.argv[1]
comments = json.load(sys.stdin)
hits = [c["id"] for c in comments if marker in (c.get("body") or "")]
print(hits[-1] if hits else "")
' "$REVIEW_MARKER"
}

# Decide the label action for review start. Pure function: pass the issue's
# label names as arguments. Prints an action token:
#   transition                     -> swap ready-for-review for in-review
#   noop:already-in-review         -> review already running
#   noop:proposer-not-ready        -> draft/refining: comment only
#   noop:decision-or-later-state   -> approved/rejected/etc: never touch
decide_label_action() {
  local labels=" $* "
  if [[ "$labels" == *" status: ready-for-review "* ]]; then
    echo "transition"
  elif [[ "$labels" == *" status: in-review "* ]]; then
    echo "noop:already-in-review"
  elif [[ "$labels" == *" status: draft "* || "$labels" == *" status: refining "* ]]; then
    echo "noop:proposer-not-ready"
  else
    echo "noop:decision-or-later-state"
  fi
}

# ── Actions ─────────────────────────────────────────────────────

do_context() {
  require_repo
  local issue
  issue=$(parse_issue_ref "$ISSUE")
  fetch_context "$REPO" "$issue"
}

do_find_comment() {
  require_repo
  local issue
  issue=$(parse_issue_ref "$ISSUE")
  find_review_comment "$REPO" "$issue"
}

do_post() {
  require_repo
  require_body_file
  local issue
  issue=$(parse_issue_ref "$ISSUE")
  gh issue comment "$issue" --repo "$REPO" --body-file "$BODY_FILE" >/dev/null
  echo "✅ Review comment posted to $REPO#$issue"
}

do_update() {
  require_repo
  require_body_file
  if [[ -z "$COMMENT_ID" ]]; then
    echo "❌ update requires --comment-id" >&2
    exit 1
  fi
  local payload
  payload=$(python3 -c 'import json,sys; print(json.dumps({"body": open(sys.argv[1]).read()}))' "$BODY_FILE")
  echo "$payload" | gh api "repos/$REPO/issues/comments/$COMMENT_ID" \
    --method PATCH --input - >/dev/null
  echo "✅ Review comment $COMMENT_ID updated"
}

do_start() {
  require_repo
  local issue labels action
  issue=$(parse_issue_ref "$ISSUE")
  labels=$(gh issue view "$issue" --repo "$REPO" --json labels --jq '.[].name' 2>/dev/null || true)
  # shellcheck disable=SC2086
  action=$(decide_label_action $labels)

  case "$action" in
    transition)
      gh issue edit "$issue" --repo "$REPO" \
        --remove-label "status: ready-for-review" \
        --add-label "status: in-review" >/dev/null
      echo "🏷️  $REPO#$issue: status: ready-for-review → status: in-review"
      ;;
    noop:already-in-review)
      echo "ℹ️  $REPO#$issue already has status: in-review — no label change"
      ;;
    noop:proposer-not-ready)
      echo "ℹ️  $REPO#$issue is still draft/refining — review comment only, no label change"
      ;;
    *)
      echo "ℹ️  $REPO#$issue is in a decision or later state — labels are human-owned, no change"
      ;;
  esac
}

# ── CLI parsing ─────────────────────────────────────────────────

parse_args() {
  if [[ $# -eq 0 ]]; then
    usage >&2
    exit 1
  fi

  case "$1" in
    context|find-comment|post|update|start)
      COMMAND="$1"
      shift
      ;;
    --help)
      usage
      exit 0
      ;;
    *)
      echo "❌ Unknown command: $1" >&2
      usage >&2
      exit 1
      ;;
  esac

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --issue)
        if [[ -z "${2:-}" ]]; then
          echo "❌ --issue requires a value" >&2
          exit 1
        fi
        ISSUE="$2"
        shift 2
        ;;
      --comment-id)
        if [[ -z "${2:-}" ]]; then
          echo "❌ --comment-id requires a value" >&2
          exit 1
        fi
        COMMENT_ID="$2"
        shift 2
        ;;
      --body-file)
        if [[ -z "${2:-}" ]]; then
          echo "❌ --body-file requires a value" >&2
          exit 1
        fi
        BODY_FILE="$2"
        shift 2
        ;;
      --repo)
        if [[ -z "${2:-}" ]]; then
          echo "❌ --repo requires a value" >&2
          exit 1
        fi
        REPO="$2"
        shift 2
        ;;
      --help)
        usage
        exit 0
        ;;
      *)
        echo "❌ Unknown option: $1" >&2
        usage >&2
        exit 1
        ;;
    esac
  done

  if [[ "$COMMAND" != "update" && -z "$ISSUE" ]]; then
    echo "❌ $COMMAND requires --issue" >&2
    exit 1
  fi
}

main() {
  parse_args "$@"
  case "$COMMAND" in
    context)      do_context ;;
    find-comment) do_find_comment ;;
    post)         do_post ;;
    update)       do_update ;;
    start)        do_start ;;
  esac
}

# Only run main when executed directly, not when sourced by tests.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
