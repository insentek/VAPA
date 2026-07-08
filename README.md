# VAPA Skills

Vision-driven, async, proposal-based, Agent-executed collaboration for teams working with AI coding agents.

VAPA is a lightweight operating model and skill set for moving team work from vague requests to reviewed proposals, traceable Agent execution, independent audit, and human validation.

## Why VAPA

AI coding agents make implementation cheaper. That changes the scarce resource in a team: the bottleneck is no longer only execution capacity, but judgment.

VAPA is built around a simple premise:

```text
AI agents execute.
Humans decide what is worth executing.
The collaboration record should make that judgment visible.
```

Instead of turning every idea into an immediate coding task, VAPA creates a proposal workflow with explicit gates:

```text
Vision -> Proposal -> Review -> Roadmap -> Execution -> Audit -> Validation -> Contribution Record
```

The full framework specification lives in [docs/framework.md](docs/framework.md).

## Included Skills

| Skill | Purpose |
|---|---|
| `vapa-init` | Initialize VAPA labels, issue templates, and repository configuration for a GitHub project. |
| `vapa-proposal` | Turn an idea into a structured VAPA proposal and submit it as a GitHub Issue. |
| `vapa-exec` | Execute an approved proposal through a traceable project-local Agent workspace. |
| `vapa-audit` | Independently audit Agent implementation, tests, scope, traceability, and PR readiness. |

## Installation

Install all VAPA skills from this repository:

```bash
npx skills add insentek/VAPA
```

Install a single skill:

```bash
npx skills add insentek/VAPA@vapa-init
npx skills add insentek/VAPA@vapa-proposal
npx skills add insentek/VAPA@vapa-exec
npx skills add insentek/VAPA@vapa-audit
```

## Quick Start

1. Install the skills.
2. Open a GitHub-backed project repository in your agent environment.
3. Ask the agent to run `vapa-init` to configure labels and issue templates.
4. Create or fill `VISION.md` so proposals have a strategic reference point.
5. Use `vapa-proposal` to create proposals.
6. After review and approval, use `vapa-exec` to implement approved work.
7. Use `vapa-audit` before PR submission or human validation.

Typical flow:

```text
vapa-init
  -> vapa-proposal
  -> human / team review
  -> vapa-exec
  -> vapa-audit
  -> PR / validation
```

## Repository Layout

```text
.
├── skills/                     # Publishable skills for npx skills add
│   ├── vapa-init/
│   ├── vapa-proposal/
│   ├── vapa-exec/
│   └── vapa-audit/
├── docs/
│   └── framework.md            # Full VAPA framework specification
├── .github/ISSUE_TEMPLATE/     # VAPA issue templates used by this repo
├── tests/                      # Lightweight validation scripts
└── README.md                   # Project overview and installation guide
```

The `skills/` directory is the canonical distribution surface. Each skill is self-contained and follows the standard skill layout:

```text
skill-name/
├── SKILL.md
├── scripts/       # Optional deterministic helpers
└── references/    # Optional templates and reference material
```

## Execution Trace Workspace

VAPA execution creates a project-local workspace for each implemented issue:

```text
.vapa/vapa-exec-<issue-id>/workspace/
  issue.json
  comments/
  images/
  issue-brief.md
  source-map.md
  readiness-report.md
  VAPA_EXEC_PLAN.md
  VAPA_EXEC_LOG.md
  TEST_REPORT.md
  VAPA_AUDIT.md
  PR_DRAFT.md
```

This directory is designed to be committed when it contains no secrets or private data. It gives teams a durable record of how an agent understood, planned, implemented, tested, and audited a change.

## Requirements

- GitHub repository with Issues enabled.
- `gh` CLI installed and authenticated for repository setup and proposal submission.
- Python 3 for bundled setup scripts.
- Organization-level GitHub Issue Types and Issue Fields may require admin configuration, depending on your GitHub plan and permissions.

## Current Status

VAPA is currently `v0.1-draft`. The framework and skills are intentionally open for iteration. The most important design goal is not automation for its own sake, but preserving human judgment while making Agent execution traceable and reviewable.

## Contributing

Contributions are welcome, especially in these areas:

- improving the proposal and audit protocols
- adding `vapa-review` for structured review committee workflows
- hardening GitHub Projects / Roadmap initialization
- adding tests for skill scripts and generated issue templates
- documenting real-world VAPA adoption patterns

Before changing a skill, keep `SKILL.md` focused on the workflow and place detailed templates or reusable material in `references/` or `scripts/`.

## License

CC BY-SA 4.0. See the repository license file when published.
