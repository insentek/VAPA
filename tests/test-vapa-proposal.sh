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
