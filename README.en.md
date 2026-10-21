# VAPA Skills

VAPA is a set of six collaboration Skills for teams using GitHub and AI coding agents. Turn ideas into proposals, agree on a solution, make execution traceable, and review the result against explicit acceptance criteria.

**People decide what is worth doing. Agents leave evidence of how it was done.**

[简体中文](README.md) · [Framework](docs/framework.md) · [Feedback](https://github.com/insentek/VAPA/issues)

`v0.1-draft` · Early public preview · CC BY-SA 4.0

## Why use VAPA?

An agent can turn a short request into code. Reviewing that work still requires answers: Why this change? Who agreed to its scope? What do the tests prove? Who accepts the result?

VAPA connects those answers. Ideas become GitHub proposals. People decide whether to proceed. Agents implement the agreed scope and save plans, decisions, and test evidence in the repository. An audit checks the delivery against the proposal before human review.

You get clearer task inputs, durable handoffs between sessions, and acceptance evidence that reviewers can inspect.

**VAPA** stands for **Vision-driven · Async · Proposal-based · Agent-executed**.

## Six Skills, one workflow

```text
init → proposal → design → review → HUMAN APPROVAL → exec → audit → HUMAN VALIDATION
```

- **[`vapa-init`](skills/vapa-init/SKILL.md):** inspect configuration, then configure status labels and four Issue templates after confirmation; help establish `VISION.md`.
- **[`vapa-proposal`](skills/vapa-proposal/SKILL.md):** develop an idea into a proposal with scope and acceptance criteria. Preview and confirm before creating a draft Issue. With no subject, list pending proposals.
- **[`vapa-design`](skills/vapa-design/SKILL.md):** discuss data, API, interaction, migration, and other relevant design decisions. Post each confirmed item as an Issue comment and retain its local archive.
- **[`vapa-review`](skills/vapa-review/SKILL.md):** read the Issue and comments, then present an evidence-backed assessment in the conversation. Read-only: no comments, label changes, or approval decisions.
- **[`vapa-exec`](skills/vapa-exec/SKILL.md):** check readiness, implement approved work, and save the plan, execution log, test report, and PR draft. Decompose large tasks first.
- **[`vapa-audit`](skills/vapa-audit/SKILL.md):** inspect the actual diff, tests, and traceability. Prefer a separate agent/session; disclose same-session self-review.

Start with a read-only proposal review if you want to try one part before adopting the full workflow.

## Get started

Run in your project directory:

```bash
npx skills add insentek/VAPA
```

Choose Skills and agents in the installer. To inspect the package or install one Skill:

```bash
npx skills add insentek/VAPA --list
npx skills add insentek/VAPA --skill vapa-review
```

Requires Node.js / npm. The canonical package source is `skills/`. See the [Skills CLI documentation](https://github.com/vercel-labs/skills#readme). Installer support for an agent does not establish end-to-end VAPA runtime compatibility.

Open a project with a GitHub `origin`. Send these requests in **Codex chat**, not your terminal, replacing the placeholder with a real Issue URL:

```text
$vapa-init Inspect this repository. Show the configuration changes before applying them.

$vapa-proposal Draft: let operations staff export device data by date range.
Clarify the users, scope, and acceptance criteria. Show the full preview.

$vapa-design <full GitHub Issue URL>
Discuss the solution with me. Confirm each item before posting an Issue comment.

$vapa-review <full GitHub Issue URL>
```

After the team reviews and approves execution:

```text
$vapa-exec Implement the approved proposal: <full GitHub Issue URL>

$vapa-audit Inspect .vapa/vapa-exec-<issue-number>/workspace/.
Check the actual diff, acceptance criteria, and test evidence.
```

In **Claude Code**, replace `$skill-name` with `/skill-name`, for example `/vapa-review <full GitHub Issue URL>`. If a newly installed Skill is missing, reopen the session and check that the installer selected the current agent and project.

### Requirements and effects

- GitHub Issues and [GitHub CLI](https://cli.github.com/). Sign in with `gh auth login` and check with `gh auth status`. Review needs read access; setup, proposal submission, and design comments need the corresponding write permissions.
- Bash and Python 3 for the scripts; label setup also needs `requests` (`python3 -m pip install requests`).
- For full organization setup, an administrator must provision Issue Types and the `Align` / `Size` fields. `--init-fields` creates or updates four organization-wide contributor fields; a type conflict stops execution.
- An agent able to read the repository and run commands; execution also needs file writes and project test tools. Resolve script paths relative to the installed Skill; no Claude environment variables are required. Init, proposal, design, and review keep Codex's explicit invocation policy in `agents/openai.yaml`. Preview and confirmation before writes remain part of the workflow.

All six Skills pass package validation and a local Codex loader check for discovery and metadata. This does not establish end-to-end acceptance of live GitHub writes.

Initialization updates remote labels and commits four templates directly to the default branch using GitHub's Contents API. The Skill previews the target and changes for confirmation. Try it in a test repository first. A personal repository can use standalone read-only review; the full field workflow targets organization repositories.

## Evidence stays with the work

Design and execution share `.vapa/vapa-exec-<issue-number>/workspace/`. Design adds only `design/`; execution adds versioned `state.json`, append-only `events.jsonl`, source snapshots, the agreed brief, source map, readiness report, codebase survey, plan, execution log, test evidence, and PR draft. Audit adds its report. UI work also requires `ui-spec.md`; decomposed parent tasks require `decomposition.md`. Records can accompany the implementation after redaction. See the [parent/child execution model](docs/exec-parent-child-model.md) (Chinese).

`READY_FOR_PR` means ready for human review. A sub-issue's `READY_TO_INTEGRATE` only allows integration into its parent branch. People accept delivery and approve the final merge.

The [execution state contract](skills/vapa-exec/references/execution-state.md) defines fixed snapshots and append-only events. Its read-only helper validates records and selects dependency-ready candidates; it neither starts agents nor writes GitHub. Decomposition weighs independent delivery benefits against coordination costs, and dispatch uses no whole-wave barriers.

## Current scope

VAPA is an **early public preview (`v0.1-draft`)**. Six installable Skills, proposal templates, helper scripts, and design/execution/audit protocols are included.

People run the review committee, prioritize work, and accept delivery. Automated GitHub Projects setup, a complete automatic lifecycle, and contribution scoring are not provided. The execution protocol requires progress updates at key transitions, subject to actual agent execution. Multi-agent execution depends on the host environment.

`VEP-XXXX` is a display convention: concurrent submissions can collide, and the lookup covers at most 1,000 matching Issues. Use the GitHub Issue number / URL as the canonical identity.

See the [design review](docs/skill-design-review.md) for findings, fixes, and remaining validation.

## Learn more and contribute

Use VAPA if your team already works in GitHub and needs clearer handoffs between people and agents. Start with one small proposal; introduce the framework's Roadmap, Steward rotation, and contribution records as needed. Small edits can remain lightweight.

- [Full framework](docs/framework.md) (Chinese)
- [Parent/child execution model](docs/exec-parent-child-model.md) (Chinese)
- [Report a problem or propose an improvement](https://github.com/insentek/VAPA/issues/new/choose)

Run the bundled checks:

```bash
python3 -m pip install -r tests/requirements.txt
python3 tests/check-skills.py
python3 tests/check-docs.py
bash tests/test-vapa-init.sh
bash tests/test-vapa-proposal.sh
bash tests/test-vapa-review.sh
```

With Codex CLI installed, `node tests/test-codex-loading.cjs` checks the actual loader in an isolated directory without starting a model turn or writing to GitHub.

## License

[CC BY-SA 4.0](LICENSE). Credit the source and share adaptations under the same license.
