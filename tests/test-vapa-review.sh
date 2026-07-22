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

# ── decide_label_action matrix ──────────────────────────────────

assert_eq "transition" \
  "$(decide_label_action "status: ready-for-review")" \
  "ready-for-review triggers transition"

assert_eq "noop:already-in-review" \
  "$(decide_label_action "status: in-review")" \
  "in-review is a no-op"

assert_eq "noop:proposer-not-ready" \
  "$(decide_label_action "status: draft")" \
  "draft is comment-only"

assert_eq "noop:proposer-not-ready" \
  "$(decide_label_action "status: refining")" \
  "refining is comment-only"

for label in "status: approved" "status: rejected" "status: done" \
             "status: in-progress" "status: in-validation" "status: deferred"; do
  assert_eq "noop:decision-or-later-state" \
    "$(decide_label_action "$label")" \
    "$label must never be touched by automation"
done

# Substring safety: a label like "status: ready-for-review-later" must not match.
assert_eq "noop:decision-or-later-state" \
  "$(decide_label_action "status: ready-for-review-later")" \
  "near-miss label name does not trigger transition"

# ── find_review_comment marker detection (mocked gh) ────────────

gh() {
  cat <<'JSON'
[
  {"id": 101, "body": "human comment"},
  {"id": 102, "body": "<!-- vapa-review -->\nfirst review round"},
  {"id": 103, "body": "another human comment"},
  {"id": 104, "body": "second round\n<!-- vapa-review -->"}
]
JSON
}
export -f gh

assert_eq "104" "$(find_review_comment "owner/repo" "15")" \
  "finds the latest comment carrying the marker"

gh() {
  echo '[{"id": 101, "body": "human comment"}]'
}
export -f gh

assert_eq "" "$(find_review_comment "owner/repo" "15")" \
  "no marker -> empty output"

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

# ── body file validation ────────────────────────────────────────

# Run in a subshell: require_body_file exits non-zero on failure, and we want
# the subshell to die, not this test script.
BODY_FILE="/nonexistent/review.md"
if ( require_body_file ) >/dev/null 2>&1; then
  echo "FAIL: missing body file should be rejected"
  ((failures++)) || true
fi

# ── result ──────────────────────────────────────────────────────

if [[ $failures -gt 0 ]]; then
  echo "$failures test(s) failed"
  exit 1
fi

echo "All tests passed"
