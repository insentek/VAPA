# PR_DRAFT — VEP-0004: vapa-review skill

## Suggested PR title

```
[#15] Add vapa-review skill for full-context proposal review with auto-comment
```

## Linked issue

```
Closes #15
```

## Implementation summary

Adds the `vapa-review` skill approved in VEP-0004. Given an issue number or URL,
the skill fetches the issue's full body and all comments via `gh`, assesses the
proposal against the framework's five review questions (Layer 3.3) and quality
checklist (Layer 2.3) with quoted evidence, auto-posts a structured review
comment, and syncs the review-start label (`status: ready-for-review` →
`status: in-review`). Re-runs are idempotent via a hidden `<!-- vapa-review -->`
marker: unchanged conclusions update the existing comment, materially changed
conclusions start a new round. The skill is advisory only — it never edits the
issue body and never touches decision labels.

Components:

- `skills/vapa-review/SKILL.md` — 7-step workflow (detect → fetch → assess →
  idempotency check → label sync → publish → report)
- `skills/vapa-review/scripts/vapa-review.sh` — backend: `context`,
  `find-comment`, `post`, `update`, `start`
- `skills/vapa-review/references/review-comment.md` — structured review template
- `tests/test-vapa-review.sh` — mocked-`gh` unit tests (issue-ref parsing, label
  decision matrix incl. near-miss safety, marker detection, context field set,
  body-file validation)
- README.md + docs/framework.md — skill table rows and quick-start flow

## Acceptance criteria mapping

| 验收标准 | 实现位置 | 状态 |
|---------|---------|------|
| 可通过 npx skills add 安装；接受编号或 URL | 标准 skill 布局 `skills/vapa-review/`；`parse_issue_ref` | ✅（安装需合并后验证） |
| gh 抓取完整正文与全部评论 | `fetch_context` 单次调用含 body+comments+labels | ✅ |
| 评论覆盖评审五问与自检清单并引用具体内容 | `references/review-comment.md` + SKILL.md Step 3 | ✅ |
| 自动发布评论；按阶段更新标签；重复运行不刷屏 | `post`/`update`/`start`/`find-comment` + marker | ✅（live 端到端未跑，见局限） |
| 不修改正文、不设置决策性状态 | 后端无 body/title 编辑；决策标签一律 noop | ✅ |
| README 与 framework.md 同步 | 两个文件各加一行 + README 快速开始流程 | ✅ |

## Test evidence

- `bash tests/test-vapa-review.sh` — all assertions pass (`.vapa/vapa-exec-15/workspace/evidence/test-vapa-review.txt`)
- `bash tests/test-vapa-proposal.sh` — regression pass (`evidence/test-vapa-proposal.txt`)
- `bash -n` syntax check, `--help` output, layout/template/boundary inspections (`evidence/`)

## Known limitations

- Live end-to-end review against a real issue not run (would post a real
  comment); recommended as the validator's first check, ideally on a
  `status: draft` test issue to observe the comment-only path.
- `npx skills add insentek/VAPA@vapa-review` verifiable only after merge.
- Review quality itself (the agent's Q1–Q5 analysis) is prompt-driven, not
  unit-testable; the template constrains structure and evidence requirements.

## VAPA workspace

`.vapa/vapa-exec-15/workspace/` (issue-brief, source-map, readiness-report,
codebase-survey, plan, log, test report, evidence)

Audit verdict: _pending `vapa-audit`_

## Suggested contribution records

| Role | Person | Basis |
|------|--------|-------|
| Proposer | @fre2d0m | VEP-0004 initial draft, clarification answers |
| Shaper | @fre2d0m |澄清决策：自动发布、标签同步、Size M |
| Validator | _TBD_ | human validation after audit |
| Sponsor | _TBD_ | — |
