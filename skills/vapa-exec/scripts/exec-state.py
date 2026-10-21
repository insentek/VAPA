#!/usr/bin/env python3
"""Read-only validation and dependency-ready selection for VAPA execution records."""
import argparse
from datetime import datetime
import json
from pathlib import Path
import sys

PHASES = {"readiness-check", "context-ready", "plan-ready", "implementing",
          "implemented", "testing", "tested", "audited"}
ACTIVITIES = {"idle", "running", "waiting", "blocked", "unknown"}
VERDICTS = {"READY_TO_INTEGRATE", "READY_FOR_PR", "NEEDS_REVISION",
            "BLOCKED_FOR_HUMAN_DECISION"}
EVENTS = {"run.started", "run.resumed", "phase.changed", "activity.changed",
          "heartbeat", "test.started", "test.finished", "audit.recorded",
          "integration.recorded", "tracker.synced", "checkpoint", "run.finished"}
REQUIRED = {"schema_version", "issue", "run_id", "mode", "size", "domain",
            "phase", "branch", "revision_count", "defect_fix_rounds", "updated_at",
            "last_event_seq", "activity", "audit", "evidence", "tracker"}
OPTIONAL = {"issue_url", "parent", "risk", "sub_issues", "integration_phase"}
NODE_KEYS = {"workspace", "depends_on", "conflicts_with", "resources", "phase",
             "audit", "integrated", "integration_commit"}
EVENT_KEYS = {"schema_version", "seq", "event_id", "at", "run_id", "issue", "actor",
              "type", "phase", "activity", "source_commit", "evidence_ref", "outcome"}


def require(condition, message):
    if not condition:
        raise ValueError(message)


def fields(value, required, optional=frozenset()):
    require(isinstance(value, dict), "expected an object")
    require(required <= value.keys(), "missing fields: " + str(sorted(required - value.keys())))
    require(not value.keys() - required - optional,
            "unknown fields: " + str(sorted(value.keys() - required - optional)))


def text(value, nullable=False):
    require((nullable and value is None) or (isinstance(value, str) and bool(value.strip())),
            "expected a nonempty string" + (" or null" if nullable else ""))


def integer(value, minimum=0):
    require(type(value) is int and value >= minimum, "expected an integer >= " + str(minimum))


def timestamp(value, nullable=False):
    if nullable and value is None:
        return
    text(value)
    require("T" in value and datetime.fromisoformat(value.replace("Z", "+00:00")).tzinfo is not None,
            "expected an RFC3339 timestamp with timezone")


def strings(value):
    require(isinstance(value, list), "expected an array")
    for item in value:
        text(item)
    require(len(value) == len(set(value)), "duplicate array entries")


def verdict(value):
    require(value is None or value in VERDICTS, "invalid audit verdict")


def graph(nodes):
    for issue, node in nodes.items():
        text(issue)
        fields(node, NODE_KEYS, {"worktree"})
        text(node["workspace"])
        text(node.get("worktree"), nullable=True)
        for key in ("depends_on", "conflicts_with", "resources"):
            strings(node[key])
        for key in ("depends_on", "conflicts_with"):
            require(set(node[key]) <= nodes.keys() and issue not in node[key],
                    "unknown or self-referencing " + key + " for " + issue)
        require(node["phase"] in PHASES, "invalid child phase")
        verdict(node["audit"])
        require(type(node["integrated"]) is bool, "integrated must be boolean")
        text(node["integration_commit"], nullable=True)
        if node["integrated"]:
            require(node["audit"] == "READY_TO_INTEGRATE" and node["integration_commit"],
                    "integration requires child audit and commit: " + issue)
    done, visiting = set(), set()

    def visit(issue):
        require(issue not in visiting, "dependency cycle at " + issue)
        if issue in done:
            return
        visiting.add(issue)
        for dependency in nodes[issue]["depends_on"]:
            visit(dependency)
        visiting.remove(issue)
        done.add(issue)

    for issue in nodes:
        visit(issue)


def validate_state(state):
    fields(state, REQUIRED, OPTIONAL)
    require(type(state["schema_version"]) is int and state["schema_version"] == 1,
            "unsupported schema_version; migrate legacy records explicitly")
    for key in ("issue", "run_id"):
        text(state[key])
    for key in ("branch", "parent", "issue_url"):
        text(state.get(key), nullable=True)
    require(state["mode"] in {"inline", "decomposed"}, "invalid mode")
    require(state["size"] in {"S", "M", "L", "XL"}, "invalid size")
    require(state["domain"] in {"frontend", "backend", "mixed", "docs"}, "invalid domain")
    require(state["phase"] in PHASES, "invalid phase")
    if "risk" in state:
        require(state["risk"] in {"normal", "high"}, "invalid risk")
    for key in ("revision_count", "defect_fix_rounds", "last_event_seq"):
        integer(state[key])
    timestamp(state["updated_at"])
    activity = state["activity"]
    fields(activity, {"state", "actor", "heartbeat_at", "waiting_for"})
    require(activity["state"] in ACTIVITIES, "invalid activity state")
    text(activity["actor"], nullable=True)
    timestamp(activity["heartbeat_at"], nullable=True)
    strings(activity["waiting_for"])
    if activity["state"] == "blocked":
        require(activity["waiting_for"], "blocked activity requires a reason or evidence reference")
    verdict(state["audit"])
    fields(state["evidence"], {"plan", "tests", "audit", "tested_commit"})
    for value in state["evidence"].values():
        text(value, nullable=True)
    if state["phase"] == "audited":
        require(state["audit"] and state["evidence"]["audit"] and state["evidence"]["tested_commit"],
                "audited requires verdict, report and tested commit")
    if state["audit"] == "READY_TO_INTEGRATE":
        require(state.get("parent"), "READY_TO_INTEGRATE belongs to a child")
    if state.get("parent"):
        require(state["audit"] != "READY_FOR_PR", "a child verdict cannot authorize a parent PR")
    tracker = state["tracker"]
    fields(tracker, {"desired_status", "observed_statuses", "observed_at", "sync"})
    text(tracker["desired_status"], nullable=True)
    require(tracker["desired_status"] is None or tracker["desired_status"].startswith("status: "),
            "desired_status must be a status label")
    strings(tracker["observed_statuses"])
    require(all(label.startswith("status: ") for label in tracker["observed_statuses"]),
            "observed_statuses contains a non-status label")
    timestamp(tracker["observed_at"], nullable=True)
    require(tracker["sync"] in {"pending", "synced", "failed", "unavailable"}, "invalid tracker sync")
    if tracker["sync"] == "synced":
        require(tracker["observed_at"] and tracker["desired_status"] and
                tracker["observed_statuses"] == [tracker["desired_status"]],
                "synced requires a fresh read-back of exactly one desired status")
    if state["mode"] == "decomposed":
        require(not state.get("parent"), "recursive decomposition is not supported")
        require(isinstance(state.get("sub_issues"), dict) and state["sub_issues"], "missing children")
        require(state.get("integration_phase") in {"pending", "integrating", "tested"},
                "invalid integration phase")
        graph(state["sub_issues"])
    else:
        require(not {"sub_issues", "integration_phase"} & state.keys(), "inline state contains parent fields")


def load(workspace):
    state = json.loads((workspace / "state.json").read_text())
    validate_state(state)
    event_ids, last = set(), None
    for seq, line in enumerate((workspace / "events.jsonl").read_text().splitlines(), 1):
        event = json.loads(line)
        fields(event, EVENT_KEYS)
        require(type(event["schema_version"]) is int and event["schema_version"] == 1, "invalid event version")
        require(type(event["seq"]) is int and event["seq"] == seq, "event sequence gap or duplicate")
        for key in ("event_id", "run_id", "issue", "actor"):
            text(event[key])
        require(event["event_id"] not in event_ids, "duplicate event_id")
        event_ids.add(event["event_id"])
        require(event["issue"] == state["issue"], "event issue mismatch")
        timestamp(event["at"])
        require(event["type"] in EVENTS and event["phase"] in PHASES and
                event["activity"] in ACTIVITIES, "invalid event type or state")
        require(event["outcome"] is None or event["outcome"] in {"passed", "failed", "unknown", "cancelled"},
                "invalid event outcome")
        for key in ("source_commit", "evidence_ref"):
            text(event[key], nullable=True)
        if event["outcome"] == "passed":
            require(event["evidence_ref"], "passed event requires actual evidence")
        last = event
    require(state["last_event_seq"] == len(event_ids), "snapshot/event cursor mismatch; reconcile before dispatch")
    if last:
        require((last["run_id"], last["phase"], last["activity"]) ==
                (state["run_id"], state["phase"], state["activity"]["state"]),
                "snapshot differs from last event; reconcile before dispatch")
    return state


def ready(workspace, state, capacity):
    require(state["mode"] == "decomposed", "ready requires a decomposed parent")
    nodes = state["sub_issues"]
    # Workspace paths are project-relative; an active worktree can supply fresher child records.
    project = workspace.parents[2]
    children = {}
    for issue, node in nodes.items():
        base = Path(node["worktree"]) if node.get("worktree") else project
        child = load((base / node["workspace"]).resolve())
        require(child["issue"] == issue and child.get("parent") == state["issue"], "child identity mismatch")
        children[issue] = child
    in_flight = {issue for issue, child in children.items()
                 if child["activity"]["state"] in {"running", "waiting", "unknown"}}

    def conflicts(a, b):
        return (b in nodes[a]["conflicts_with"] or a in nodes[b]["conflicts_with"] or
                bool(set(nodes[a]["resources"]) & set(nodes[b]["resources"])))

    eligible, waiting = [], {}
    for issue in sorted(nodes):
        node, child = nodes[issue], children[issue]
        if node["integrated"]:
            continue
        reasons = []
        if child["activity"]["state"] != "idle":
            reasons.append("activity:" + child["activity"]["state"])
        if child["phase"] in {"tested", "audited"}:
            reasons.append("awaiting-audit-or-integration")
        for dep in node["depends_on"]:
            if not (nodes[dep]["integrated"] and children[dep]["audit"] == "READY_TO_INTEGRATE"):
                reasons.append("dependency:" + dep)
        reasons += ["conflict:" + active for active in sorted(in_flight) if active != issue and conflicts(issue, active)]
        if reasons:
            waiting[issue] = reasons
        else:
            eligible.append(issue)
    start = []
    for issue in eligible:
        if len(start) >= max(0, capacity - len(in_flight)):
            break
        if not any(conflicts(issue, selected) for selected in start):
            start.append(issue)
    return {"eligible": eligible, "start": start, "in_flight": sorted(in_flight), "waiting": waiting,
            "capacity": capacity, "scope": "read-only candidates; coordinator must verify integration commits and worktree bases"}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=("check", "ready"))
    parser.add_argument("workspace", type=Path)
    parser.add_argument("--capacity", type=int, default=1, help="total available worker slots, excluding coordinator")
    args = parser.parse_args()
    try:
        require(args.capacity > 0, "capacity must be positive")
        workspace = args.workspace.resolve()
        state = load(workspace)
        result = ready(workspace, state, args.capacity) if args.command == "ready" else {"issue": state["issue"]}
        print(json.dumps({"status": "PASS", **result}, sort_keys=True))
        return 0
    except (ValueError, OSError, KeyError, TypeError) as error:
        print(json.dumps({"status": "FAIL", "error": str(error)}))
        return 1


if __name__ == "__main__":
    sys.exit(main())
