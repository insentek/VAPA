# Execution state and events — version 1

Read when initializing or resuming execution, handing ownership to an auditor,
or selecting decomposed work. The standard-library helper
[`exec-state.py`](../scripts/exec-state.py) checks the contract and computes
read-only dispatch candidates. It never spawns agents, edits files or contacts a
tracker. Resolve its path relative to the installed `SKILL.md`.

## Snapshot

`state.json` is the latest observed snapshot. Use exactly the required fields
below; do not add per-step flags, test histories, narrative notes or dynamic
role names. Store those in the existing reports and reference them. Optional
fields are `issue_url`, `parent`, `risk`, and the two decomposed-parent fields
described below. A new structural field requires a schema version change.

```json
{
  "schema_version": 1,
  "issue": "42",
  "run_id": "exec-42-attempt-1",
  "mode": "inline",
  "size": "S",
  "domain": "backend",
  "phase": "plan-ready",
  "branch": "vapa/42-batch-export",
  "revision_count": 0,
  "defect_fix_rounds": 0,
  "updated_at": "2026-01-01T12:00:00Z",
  "last_event_seq": 1,
  "activity": {
    "state": "idle",
    "actor": "coordinator",
    "heartbeat_at": null,
    "waiting_for": []
  },
  "audit": null,
  "evidence": {
    "plan": "VAPA_EXEC_PLAN.md",
    "tests": null,
    "audit": null,
    "tested_commit": null
  },
  "tracker": {
    "desired_status": "status: approved",
    "observed_statuses": ["status: approved"],
    "observed_at": "2026-01-01T12:00:00Z",
    "sync": "synced"
  }
}
```

- Identity: `issue` is the tracker issue ID, not the VEP display number;
  `issue_url`, when provided, must agree with the source repository and ID.
  `run_id` identifies an invocation/resume attempt. Retain prior runs in events.
- `mode`: `inline` or `decomposed`; a child is inline with `parent: "42"`.
  `size`: S/M/L/XL; `domain`: frontend/backend/mixed/docs; optional `risk`:
  normal/high. `branch` can be null until selected.
- `phase`: readiness-check, context-ready, plan-ready, implementing,
  implemented, testing, tested, audited. Revisions may return to an earlier
  phase; record the transition. Do not invent phases for scheduling conditions.
- `activity.state`: idle, running, waiting, blocked, unknown. `actor` and
  `heartbeat_at` may be null when unavailable; `waiting_for` is a list of issue
  IDs, resource names, decision or evidence references. Blocked needs a reason.
  Silence is not proof of a dead worker or a completed task. Show stale
  heartbeat data separately and retain its reservations until reconciled.
- `audit`: null or READY_TO_INTEGRATE / READY_FOR_PR / NEEDS_REVISION /
  BLOCKED_FOR_HUMAN_DECISION. `audited` requires the report and tested commit.
  A changed implementation invalidates its old audit; keep historical evidence.
- `tracker` is a projection, not execution authority. `sync` is pending,
  synced, failed or unavailable. Record all observed `status:` labels so duplicate
  states remain visible. Set synced only after read-back confirms exactly the
  desired status. Observed timestamps do not imply continuous freshness.
- `revision_count`, `defect_fix_rounds` and `last_event_seq` are nonnegative
  integers. Timestamps include a timezone; prefer UTC RFC3339. Reports and Git
  evidence still establish truth; a schema-valid claim is not verification.

### Decomposed parent

Add `integration_phase`: pending / integrating / tested, and `sub_issues` keyed
by child ID. Every summary has this shape:

```json
{
  "workspace": ".vapa/vapa-exec-43/workspace",
  "depends_on": [],
  "conflicts_with": [],
  "resources": [],
  "phase": "readiness-check",
  "audit": null,
  "integrated": false,
  "integration_commit": null
}
```

`workspace` is relative to the project root. Optional `worktree` identifies the
active checkout root when fresher child records live outside the parent checkout.
Each child owns its execution facts; the coordinator alone owns dependency,
conflict/resource assignments and integration receipts. An integrated child needs
READY_TO_INTEGRATE and a real integration commit verified in the parent branch.
Reconcile summaries against child records on resume and before dispatch. Never
let a stale child copy erase a verified parent integration receipt, or let a stale
parent audit summary override a revised child report.

`resources` names exclusive reservations needed for dispatch (for example,
`test:shared-database`). Use them only where simultaneous work actually conflicts.
For a short test-only reservation, coordinate at that checkpoint instead of
locking the entire implementation. Readiness depends on all direct predecessors
being audited and integrated, available worker slots, conflicts and reservations;
topological levels are for display, not execution barriers.

## Append-only events

Create `events.jsonl` alongside the snapshot. Each UTF-8 line is one object with
exactly these fields; each workspace has its own stream and monotonically
increasing `seq`, starting at 1 across all runs:

```json
{"schema_version":1,"seq":1,"event_id":"42-attempt-1-start","at":"2026-01-01T12:00:00Z","run_id":"exec-42-attempt-1","issue":"42","actor":"coordinator","type":"run.started","phase":"plan-ready","activity":"idle","source_commit":null,"evidence_ref":"VAPA_EXEC_PLAN.md","outcome":null}
```

Allowed types: run.started, run.resumed, phase.changed, activity.changed,
heartbeat, test.started, test.finished, audit.recorded, integration.recorded,
tracker.synced, checkpoint, run.finished. `event_id` is unique within the stream.
`phase` and `activity` are the state after the observation; `source_commit` and
`evidence_ref` are strings or null. `outcome` is null, passed, failed, unknown or
cancelled. A timeout/interruption is never passed.

Emit events at actual starts, stops, handoffs, tests, audit/integration and tracker
sync, including failed sync attempts. Heartbeats are optional when the host can
provide them; do not create a background service merely to satisfy this skill.
Do not invent missing history, token/cost figures or elapsed times. Keep logs,
secrets and business payloads out of events; link redacted evidence instead.

### Ownership and recovery

1. Exactly one writer owns a workspace snapshot and stream. Child agents do not
   append parent events. Explicitly hand over ownership for an auditor; its
   updates do not authorize concurrent parent writes.
2. Append and flush the complete event first. Write the matching snapshot to a
   temporary sibling and atomically replace `state.json`. Set `last_event_seq`
   to that event. The final event's run, phase and activity must match the snapshot.
3. On resume, check sequence/IDs and the snapshot cursor before dispatch. A torn
   line or cursor mismatch is a recording fault, not an implementation failure.
   Preserve the original bytes, reconcile current facts with Git/reports/runtime,
   and record an explicit recovery and `run.resumed` event. Do not silently reset
   the stream, synthesize prior successes or consume audit revision budget.
4. For unversioned/older state, archive the original snapshot, map only verified
   facts into version 1 and begin a new observed event stream with `run.resumed`.
   Reference the archive. Legacy narrative fields stay archived, not copied into
   arbitrary new snapshot keys; preserve the existing reports and design inputs.

## Read-only checks

```text
python3 <installed-skill>/scripts/exec-state.py check <workspace>
python3 <installed-skill>/scripts/exec-state.py ready <parent-workspace> --capacity 3
```

`check` validates the current workspace and stream. `ready` also reads actual
child snapshots/streams and validates the whole graph. It returns `eligible`,
`start`, `in_flight` and explicit waiting reasons. `start` respects capacity,
asymmetric conflict declarations and exclusive resources, including conflicts
among candidates. Running, waiting and unknown workers retain slots. Missing or
invalid records fail closed; no result authorizes starting from the wrong base.

Before dispatch, verify dependency commits are present and create/refresh the
worktree from that current parent revision. These checks are local primitives
for a future read-only observer, not a scheduler daemon or automatic label writer.
