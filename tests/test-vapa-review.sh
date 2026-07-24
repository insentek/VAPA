#!/bin/bash
# Unit tests for vapa-review helper logic.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source the script under test. main() is guarded, so this only loads functions.
source "$PROJECT_DIR/skills/vapa-review/scripts/vapa-review.sh"

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

# ── parse_issue_ref ─────────────────────────────────────────────

assert_eq "15" "$(parse_issue_ref "15")" "plain number passes through"
assert_eq "15" "$(parse_issue_ref "https://github.com/insentek/VAPA/issues/15")" "issue URL extracts number"
if parse_issue_ref "not-an-issue" >/dev/null 2>&1; then
  echo "FAIL: unparseable ref should fail"
  ((failures++)) || true
fi

# ── fetch_context requests the full field set (mocked gh) ───────

gh() {
  # Echo back the args so the test can inspect them.
  printf '%s\n' "$*"
}
export -f gh

ctx_args=$(fetch_context "owner/repo" "15")
assert_eq "issue view 15 --repo owner/repo --json number,title,state,url,author,labels,body,comments" \
  "$ctx_args" \
  "context fetches body AND comments AND labels in one call"

# ── read-only guarantee: no write operations anywhere ───────────

script_path="$PROJECT_DIR/skills/vapa-review/scripts/vapa-review.sh"
for forbidden in "issue comment" "issue edit" "method PATCH" "method POST" "method DELETE" "--add-label" "--remove-label"; do
  if grep -q -- "$forbidden" "$script_path"; then
    echo "FAIL: read-only backend must not contain '$forbidden'"
    ((failures++)) || true
  fi
done

# ── unknown commands are rejected ───────────────────────────────

if ( parse_args post --issue 15 ) >/dev/null 2>&1; then
  echo "FAIL: removed 'post' command must be rejected"
  ((failures++)) || true
fi
if ( parse_args start --issue 15 ) >/dev/null 2>&1; then
  echo "FAIL: removed 'start' command must be rejected"
  ((failures++)) || true
fi

# ── result ──────────────────────────────────────────────────────

if [[ $failures -gt 0 ]]; then
  echo "$failures test(s) failed"
  exit 1
fi

echo "All tests passed"
