#!/bin/bash
# vapa-review: read-only backend for reviewing VAPA proposal issues.
# Usage:
#   vapa-review.sh context --issue 15 [--repo owner/repo]
#   vapa-review.sh context --issue https://github.com/owner/repo/issues/15
#
# The skill is read-only: it fetches the full issue context so the agent can
# produce a review. The review is shown to the user locally — nothing is ever
# posted to the issue and no labels are changed.

set -euo pipefail

# ── Defaults ────────────────────────────────────────────────────

COMMAND=""
ISSUE=""
REPO="${VAPA_REPO:-}"

# ── Helper functions ────────────────────────────────────────────

usage() {
  cat <<'EOF'
vapa-review.sh review backend (read-only)

  context      --issue <n|url>   print full issue JSON (body + comments + labels)

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

# ── Review logic ────────────────────────────────────────────────

# Full context in one call: the review must be based on the complete issue,
# not just the title.
fetch_context() {
  local repo="$1" issue="$2"
  gh issue view "$issue" --repo "$repo" \
    --json number,title,state,url,author,labels,body,comments
}

# ── Actions ─────────────────────────────────────────────────────

do_context() {
  require_repo
  local issue
  issue=$(parse_issue_ref "$ISSUE")
  fetch_context "$REPO" "$issue"
}

# ── CLI parsing ─────────────────────────────────────────────────

parse_args() {
  if [[ $# -eq 0 ]]; then
    usage >&2
    exit 1
  fi

  case "$1" in
    context)
      COMMAND="$1"
      shift
      ;;
    --help)
      usage
      exit 0
      ;;
    *)
      echo "❌ Unknown command: $1 (vapa-review is read-only; only 'context' is available)" >&2
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

  if [[ -z "$ISSUE" ]]; then
    echo "❌ context requires --issue" >&2
    exit 1
  fi
}

main() {
  parse_args "$@"
  case "$COMMAND" in
    context) do_context ;;
  esac
}

# Only run main when executed directly, not when sourced by tests.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
