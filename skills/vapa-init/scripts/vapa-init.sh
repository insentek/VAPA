#!/bin/bash
# vapa-init: Initialize VAPA labels and issue templates on a GitHub repo
# Usage:
#   vapa-init               # detect repo from git remote, upsert config
#   vapa-init owner/repo    # explicit repo, upsert config
#   vapa-init --check       # inspect existing config without changes
#   vapa-init --reset       # delete existing VAPA config and recreate
#   vapa-init --init-fields # create/update org issue fields from org members

set -euo pipefail

RESET=false
CHECK=false
INIT_FIELDS=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --reset)
      RESET=true
      shift
      ;;
    --check)
      CHECK=true
      shift
      ;;
    --init-fields)
      INIT_FIELDS=true
      shift
      ;;
    --)
      shift
      break
      ;;
    -*)
      echo "❌ Unknown option: $1"
      echo "Usage: vapa-init [--check|--reset] [owner/repo]"
      exit 1
      ;;
    *)
      break
      ;;
  esac
done

REPO="${1:-}"

if [[ -z "$REPO" ]]; then
  # Try to detect from git remote
  if git rev-parse --git-dir > /dev/null 2>&1; then
    REMOTE_URL=$(git remote get-url origin 2>/dev/null || true)
    if [[ -n "$REMOTE_URL" ]]; then
      if [[ "$REMOTE_URL" =~ github\.com[/:]([^/]+)/([^/.]+) ]]; then
        REPO="${BASH_REMATCH[1]}/${BASH_REMATCH[2]}"
      fi
    fi
  fi
fi

if [[ -z "$REPO" ]]; then
  echo "❌ Could not detect repo. Run from a git repo, or pass owner/repo explicitly."
  echo "Usage: vapa-init [--check|--reset] [owner/repo]"
  exit 1
fi

OWNER="${REPO%%/*}"
REPO_NAME="${REPO##*/}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"

TEMPLATES=(
  "feature-proposal.md"
  "problem-statement.md"
  "vision-amendment.md"
  "experiment.md"
)

# VAPA metadata dimensions. Issue types and issue fields are organization-level;
# this script checks that they exist but does not create/delete them.
VAPA_TYPES=(
  "Feature"
  "Problem"
  "Vision Amendment"
  "Experiment"
  "Improvement"
  "Technical Debt"
  "Research"
)

VAPA_FIELDS=(
  "Align"
  "Size"
  "Shaper"
  "Reviewed By"
  "Validator"
  "Sponsor"
)

API_VERSION="2026-03-10"

# ── Helpers ─────────────────────────────────────────────────────

urlencode() {
  python3 -c "import urllib.parse, sys; print(urllib.parse.quote(sys.argv[1], safe=''))" "$1"
}

get_vapa_label_names() {
  python3 "$SCRIPT_DIR/vapa-labels.py" --list-names
}

get_legacy_label_names() {
  python3 "$SCRIPT_DIR/vapa-labels.py" --list-legacy
}

get_remote_labels() {
  gh api "repos/$REPO/labels" --paginate --jq '.[].name' 2>/dev/null || true
}

get_remote_template_names() {
  gh api "repos/$REPO/contents/.github/ISSUE_TEMPLATE" --jq '.[].name' 2>/dev/null || true
}

get_org_issue_types() {
  gh api "orgs/$OWNER/issue-types" --jq '.[].name' 2>/dev/null || true
}

get_org_issue_fields() {
  gh api "orgs/$OWNER/issue-fields" \
    --header "X-GitHub-Api-Version: $API_VERSION" \
    --jq '.[].name' 2>/dev/null || true
}

get_org_members() {
  gh api "orgs/$OWNER/members" --paginate --jq '.[].login' 2>/dev/null | sort || true
}

# Build a JSON array of single-select options from a file containing one name per line.
build_options_json() {
  local members_file="$1" color="${2:-gray}"
  python3 - "$members_file" "$color" <<'PY'
import json, sys
with open(sys.argv[1]) as f:
    names = [line.strip() for line in f if line.strip()]
color = sys.argv[2]
print(json.dumps([
    {"name": name, "color": color, "priority": idx}
    for idx, name in enumerate(names, start=1)
]))
PY
}

# Ensure an organization issue field exists as single_select with the given options.
# If it exists with a different data_type, it is deleted and recreated.
ensure_issue_field() {
  local name="$1" description="$2" options_json="$3"

  local fields_json
  fields_json=$(gh api "orgs/$OWNER/issue-fields" \
    --header "X-GitHub-Api-Version: $API_VERSION" 2>/dev/null || true)

  local field_id field_type
  field_id=$(echo "$fields_json" | python3 -c 'import json,sys; name=sys.argv[1]; data=json.load(sys.stdin); f=next((x for x in data if x["name"]==name), None); print(f["id"] if f else "")' "$name" 2>/dev/null || true)
  field_type=$(echo "$fields_json" | python3 -c 'import json,sys; name=sys.argv[1]; data=json.load(sys.stdin); f=next((x for x in data if x["name"]==name), None); print(f["data_type"] if f else "")' "$name" 2>/dev/null || true)

  if [[ -n "$field_id" && "$field_type" != "single_select" ]]; then
    echo "  existing '$name' is $field_type; deleting to recreate as single_select"
    gh api "orgs/$OWNER/issue-fields/$field_id" \
      --method DELETE \
      --header "X-GitHub-Api-Version: $API_VERSION" \
      >/dev/null 2>&1 || true
    field_id=""
  fi

  local payload
  payload=$(python3 - "$name" "$description" "$options_json" <<'PY'
import json, sys
name, desc, options = sys.argv[1], sys.argv[2], json.loads(sys.argv[3])
print(json.dumps({
  "name": name,
  "description": desc,
  "data_type": "single_select",
  "options": options
}))
PY
)

  if [[ -n "$field_id" ]]; then
    echo "  updating options for '$name'"
    if ! echo "$payload" | gh api "orgs/$OWNER/issue-fields/$field_id" \
      --method PATCH \
      --header "X-GitHub-Api-Version: $API_VERSION" \
      --input - \
      >/dev/null 2>&1; then
      echo "  ❌ failed to update '$name'"
    fi
  else
    echo "  creating '$name'"
    if ! echo "$payload" | gh api "orgs/$OWNER/issue-fields" \
      --method POST \
      --header "X-GitHub-Api-Version: $API_VERSION" \
      --input - \
      >/dev/null 2>&1; then
      echo "  ❌ failed to create '$name'"
    fi
  fi
}

init_org_fields() {
  echo "🏢 Initializing VAPA issue fields for organization '$OWNER'..."
  echo ""

  local members
  members=$(get_org_members)
  if [[ -z "$members" ]]; then
    echo "⚠️  Could not fetch organization members. Skipping issue field initialization."
    return 0
  fi

  local members_file
  members_file=$(mktemp)
  echo "$members" > "$members_file"

  local member_options
  member_options=$(build_options_json "$members_file" "gray")

  rm -f "$members_file"

  ensure_issue_field "Shaper" "实质性完善贡献者" "$member_options"
  ensure_issue_field "Reviewed By" "正式评审参与者" "$member_options"
  ensure_issue_field "Validator" "验收执行者" "$member_options"
  ensure_issue_field "Sponsor" "提案战略背书人" "$member_options"

  echo ""
}

# Count how many items from $1 are present in $2 (both newline-separated).
count_present() {
  local expected="$1" actual="$2" found=0
  local item
  while IFS= read -r item; do
    [[ -n "$item" ]] || continue
    if echo "$actual" | grep -qx "$item"; then
      ((found++)) || true
    fi
  done <<< "$expected"
  echo "$found"
}

# Print missing items from $1 against $2.
list_missing() {
  local expected="$1" actual="$2" item
  while IFS= read -r item; do
    [[ -n "$item" ]] || continue
    if ! echo "$actual" | grep -qx "$item"; then
      echo "$item"
    fi
  done <<< "$expected"
}

# ── Check mode ──────────────────────────────────────────────────

if $CHECK; then
  echo "🔍 Checking VAPA configuration on $REPO..."
  echo ""

  vapa_names=$(get_vapa_label_names)
  remote_labels=$(get_remote_labels)

  found_labels=$(count_present "$vapa_names" "$remote_labels")
  total_labels=$(echo "$vapa_names" | grep -c '^' || true)

  echo "Labels: $found_labels/$total_labels VAPA status labels present"
  missing_labels=$(list_missing "$vapa_names" "$remote_labels")
  if [[ -n "$missing_labels" ]]; then
    echo "  Missing: $(echo "$missing_labels" | tr '\n' ' ')"
  fi

  remote_templates=$(get_remote_template_names)

  found_templates=0
  missing_templates=()
  for tmpl in "${TEMPLATES[@]}"; do
    if echo "$remote_templates" | grep -qx "$tmpl"; then
      ((found_templates++)) || true
    else
      missing_templates+=("$tmpl")
    fi
  done

  echo "Templates: $found_templates/${#TEMPLATES[@]} VAPA templates present"
  if [[ ${#missing_templates[@]} -gt 0 ]]; then
    echo "  Missing: ${missing_templates[*]}"
  fi

  org_types=$(get_org_issue_types)
  found_types=$(count_present "$(printf "%s\n" "${VAPA_TYPES[@]}")" "$org_types")
  total_types=${#VAPA_TYPES[@]}
  echo "Issue types: $found_types/$total_types VAPA types present in $OWNER"
  missing_types=$(list_missing "$(printf "%s\n" "${VAPA_TYPES[@]}")" "$org_types")
  if [[ -n "$missing_types" ]]; then
    echo "  Missing: $(echo "$missing_types" | tr '\n' ' ')"
  fi

  org_fields=$(get_org_issue_fields)
  found_fields=$(count_present "$(printf "%s\n" "${VAPA_FIELDS[@]}")" "$org_fields")
  total_fields=${#VAPA_FIELDS[@]}
  echo "Issue fields: $found_fields/$total_fields VAPA fields present in $OWNER"
  missing_fields=$(list_missing "$(printf "%s\n" "${VAPA_FIELDS[@]}")" "$org_fields")
  if [[ -n "$missing_fields" ]]; then
    echo "  Missing: $(echo "$missing_fields" | tr '\n' ' ')"
  fi

  echo ""
  echo "💡 Run without --check to initialize/update, or with --reset to delete and recreate."
  exit 0
fi

# ── Reset mode ──────────────────────────────────────────────────

if $RESET; then
  echo "🔄 Resetting VAPA configuration on $REPO..."
  echo ""

  echo "🗑️  Removing current VAPA labels..."
  vapa_names=$(get_vapa_label_names)
  for name in $vapa_names; do
    encoded=$(urlencode "$name")
    if gh api "repos/$REPO/labels/$encoded" --jq '.name' >/dev/null 2>&1; then
      echo "  deleting label: $name"
      gh api "repos/$REPO/labels/$encoded" --method DELETE >/dev/null
      sleep 0.3
    fi
  done

  echo "🗑️  Removing legacy VAPA labels..."
  legacy_names=$(get_legacy_label_names)
  for name in $legacy_names; do
    encoded=$(urlencode "$name")
    if gh api "repos/$REPO/labels/$encoded" --jq '.name' >/dev/null 2>&1; then
      echo "  deleting legacy label: $name"
      gh api "repos/$REPO/labels/$encoded" --method DELETE >/dev/null
      sleep 0.3
    fi
  done

  echo "🗑️  Removing VAPA issue templates..."
  for tmpl in "${TEMPLATES[@]}"; do
    existing=$(gh api "repos/$REPO/contents/.github/ISSUE_TEMPLATE/$tmpl" --jq '.sha' 2>/dev/null || true)
    if [[ -n "$existing" && "$existing" != "null" ]]; then
      echo "  deleting template: $tmpl"
      gh api "repos/$REPO/contents/.github/ISSUE_TEMPLATE/$tmpl" \
        --method DELETE \
        -f message="Remove VAPA issue template: $tmpl" \
        -f sha="$existing" \
        >/dev/null
      sleep 0.3
    fi
  done

  echo ""
fi

# ── Pre-flight warning for org-level metadata ───────────────────

org_types=$(get_org_issue_types)
missing_types=$(list_missing "$(printf "%s\n" "${VAPA_TYPES[@]}")" "$org_types")
if [[ -n "$missing_types" ]]; then
  echo "⚠️  The following VAPA issue types are missing from organization '$OWNER':"
  echo "$missing_types" | sed 's/^/  - /'
  echo "   Issue types must be created at the organization level by an org admin."
  echo ""
fi

org_fields=$(get_org_issue_fields)
missing_fields=$(list_missing "$(printf "%s\n" "${VAPA_FIELDS[@]}")" "$org_fields")
if [[ -n "$missing_fields" ]]; then
  echo "⚠️  The following VAPA issue fields are missing from organization '$OWNER':"
  echo "$missing_fields" | sed 's/^/  - /'
  echo "   Issue fields must be created at the organization level by an org admin."
  echo ""
fi

# ── Initialize organization-level issue fields ──────────────────

if $INIT_FIELDS; then
  init_org_fields
fi

# ── Configure labels ────────────────────────────────────────────

echo "🎯 Configuring VAPA labels for $REPO..."
python3 "$SCRIPT_DIR/vapa-labels.py" \
  --token "$(gh auth token)" \
  --owner "$OWNER" \
  --repo "$REPO_NAME"

# ── Create issue templates ──────────────────────────────────────

echo "📝 Creating issue templates..."

for tmpl in "${TEMPLATES[@]}"; do
  src="$SKILL_DIR/references/$tmpl"
  if [[ ! -f "$src" ]]; then
    echo "  ⚠️  Missing template: $src"
    continue
  fi

  content_b64=$(base64 -i "$src" | tr -d '\n')
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
