# TEST_REPORT — VEP-0004: vapa-review skill

## Commands run

| Command | Result | Evidence |
|---------|--------|----------|
| `bash tests/test-vapa-review.sh` | ✅ PASS (all assertions) | `evidence/test-vapa-review.txt` |
| `bash tests/test-vapa-proposal.sh` (regression) | ✅ PASS | `evidence/test-vapa-proposal.txt` |
| `bash -n skills/vapa-review/scripts/vapa-review.sh` | ✅ PASS | — (exit 0) |
| `skills/vapa-review/scripts/vapa-review.sh --help` | ✅ PASS | `evidence/help-output.txt` |
| Layout / frontmatter inspection | ✅ PASS | `evidence/layout-check.txt` |
| Template coverage + boundary grep | ✅ PASS | `evidence/template-coverage.txt` |

## Manual verification performed

- SKILL.md frontmatter matches the vapa-proposal convention (`name`,
  `description`, `disable-model-invocation`, `allowed-tools`).
- Review comment template read end-to-end: marker on line 1, all 5 review
  questions, all 6 checklist rows, advisory-only conclusion wording (🟢/🟡/🔴
  recommendation, explicitly "不是准入决策").
- README and framework.md diffs reviewed: single new row each, no other content
  altered.

## Acceptance criteria coverage

| AC | Status | Evidence |
|----|--------|----------|
| AC1 installable; takes number or URL | ✅ (layout + unit tests) | Standard skill layout under `skills/vapa-review/` (the `npx skills add` surface); `parse_issue_ref` tests cover number and URL. Actual `npx skills add` run requires the branch to be merged — see gaps. |
| AC2 full body + comments via gh | ✅ | Unit test pins the exact `gh issue view --json number,title,state,url,author,labels,body,comments` call |
| AC3 comment covers Q1–Q5 + checklist with citations | ✅ | `evidence/template-coverage.txt` (Q1–Q5 present, 6 checklist rows); template mandates quoted evidence per verdict |
| AC4 auto-post + label sync + idempotency | ✅ (unit) / ⚠️ (live gap) | Marker-detection tests (found/not-found/latest-of-several); label matrix tests incl. near-miss substring safety. Live posting not exercised — see gaps. |
| AC5 no body edits, no decision labels | ✅ | Label matrix: all decision/later states → `noop:decision-or-later-state`; backend grep shows label-only `issue edit` and comment-only `--body-file` usage |
| AC6 README + framework.md rows | ✅ | Commit d7d0595 diff |

## Regression check

Existing suite `tests/test-vapa-proposal.sh` passes unmodified. No existing
files changed except additive doc rows in README.md / docs/framework.md.

## Known gaps / tests not run

1. **Live end-to-end run** (`/vapa-review` against a real issue) not executed:
   it would post a real comment and flip a real label. Recommended as the human
   validator's first step — e.g. run against a `status: draft` test issue to
   observe the comment-only path safely.
2. **`npx skills add insentek/VAPA@vapa-review` install** not run: requires the
   skill to be on the default branch (post-merge). Layout conformance to the
   existing four skills is the pre-merge proxy.
3. `--paginate` path of `find-comment` exercised only via mock; real pagination
   behavior depends on `gh api` and is unchanged from standard usage.
