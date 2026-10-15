#!/bin/bash
# Exercise the real CLI with a fake gh. No network or repository writes.
set -euo pipefail
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fixture=$(mktemp -d)
trap 'rm -rf "$fixture"' EXIT
cat > "$fixture/gh" <<'STUB'
#!/bin/bash
printf '%s\n' "$*" >> "$VAPA_TEST_CALLS"
case "$*" in
  *'orgs/owner/issue-types'*) printf '%s\n' Feature Problem 'Vision Amendment' Experiment Improvement 'Technical Debt' Research ;;
  *'orgs/owner/members'*) echo alice ;;
  *'--jq .[].name'*) printf '%s\n' Align Size Shaper 'Reviewed By' Validator Sponsor ;;
  *'--method PATCH'*) exit 1 ;;
  *'orgs/owner/issue-fields'*)
    case "$VAPA_TEST_SCENARIO" in
      lookup-failure) exit 1 ;;
      invalid-json) echo 'not json' ;;
      incompatible) echo '[{"id":1,"name":"Shaper","data_type":"text"}]' ;;
      failed-update) echo '[{"id":1,"name":"Shaper","data_type":"single_select"}]' ;;
    esac ;;
  *) echo "Unexpected gh operation: $*" >&2; exit 99 ;;
esac
STUB
chmod +x "$fixture/gh"
export PATH="$fixture:$PATH"
export VAPA_TEST_CALLS="$fixture/calls"
for scenario in incompatible lookup-failure invalid-json failed-update; do
  export VAPA_TEST_SCENARIO="$scenario"
  : > "$VAPA_TEST_CALLS"
  if bash "$PROJECT_DIR/skills/vapa-init/scripts/vapa-init.sh" --init-fields owner/repo > "$fixture/output" 2>&1; then
    echo "FAIL: $scenario must stop initialization"
    exit 1
  fi
  if grep -Eq -- '--method DELETE|--method POST|auth token|repos/owner/repo' "$VAPA_TEST_CALLS"; then
    echo "FAIL: $scenario reached a destructive or unrelated write"
    cat "$VAPA_TEST_CALLS"
    exit 1
  fi
done

# Exercise origin parsing and reset with labels containing spaces. Stop the
# mocked DELETE deliberately, before the script can reach any later operation.
real_python=$(command -v python3)
export VAPA_TEST_REAL_PYTHON="$real_python"
cat > "$fixture/python3" <<'STUB'
#!/bin/bash
if [[ "${2:-}" == "--list-names" ]]; then
  echo 'status: draft'
else
  exec "$VAPA_TEST_REAL_PYTHON" "$@"
fi
STUB
cat > "$fixture/git" <<'STUB'
#!/bin/bash
case "$1" in
  rev-parse) exit 0 ;;
  remote) echo 'git@github.com:owner/project.v2.git' ;;
  *) exit 99 ;;
esac
STUB
cat > "$fixture/gh" <<'STUB'
#!/bin/bash
printf '%s\n' "$*" >> "$VAPA_TEST_CALLS"
case "$*" in
  'api repos/owner/project.v2/labels/status%3A%20draft --jq .name') echo 'status: draft' ;;
  'api repos/owner/project.v2/labels/status%3A%20draft --method DELETE') exit 1 ;;
  *) exit 99 ;;
esac
STUB
chmod +x "$fixture/python3" "$fixture/git" "$fixture/gh"
: > "$VAPA_TEST_CALLS"
if bash "$PROJECT_DIR/skills/vapa-init/scripts/vapa-init.sh" --reset > "$fixture/output" 2>&1; then
  echo "FAIL: the deliberate delete failure should stop reset"
  exit 1
fi
if ! grep -Fxq 'api repos/owner/project.v2/labels/status%3A%20draft --method DELETE' "$VAPA_TEST_CALLS"; then
  echo "FAIL: dotted repository names and labels with spaces must remain intact"
  cat "$VAPA_TEST_CALLS"
  exit 1
fi
echo "All tests passed"
