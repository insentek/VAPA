#!/usr/bin/env python3
"""Exercise execution records and scheduling decisions with isolated workspaces."""
import importlib.util
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

SCRIPT = Path(__file__).resolve().parents[1] / "skills/vapa-exec/scripts/exec-state.py"
spec = importlib.util.spec_from_file_location("exec_state", SCRIPT)
runtime = importlib.util.module_from_spec(spec)
spec.loader.exec_module(runtime)
AT = "2026-01-01T12:00:00Z"


def state(issue="42", parent=None):
    value = {
        "schema_version": 1, "issue": issue, "run_id": "attempt-1", "mode": "inline",
        "size": "S", "domain": "backend", "phase": "plan-ready", "branch": "vapa/42-test",
        "revision_count": 0, "defect_fix_rounds": 0, "updated_at": AT, "last_event_seq": 1,
        "activity": {"state": "idle", "actor": "worker", "heartbeat_at": None, "waiting_for": []},
        "audit": None, "evidence": {"plan": "VAPA_EXEC_PLAN.md", "tests": None, "audit": None, "tested_commit": None},
        "tracker": {"desired_status": "status: in-progress", "observed_statuses": ["status: in-progress"],
                    "observed_at": AT, "sync": "synced"},
    }
    if parent is not None:
        value["parent"] = parent
    return value


def write(workspace, snapshot):
    workspace.mkdir(parents=True, exist_ok=True)
    event = {"schema_version": 1, "seq": 1, "event_id": "event-1", "at": AT,
             "run_id": snapshot["run_id"], "issue": snapshot["issue"], "actor": "worker",
             "type": "checkpoint", "phase": snapshot["phase"], "activity": snapshot["activity"]["state"],
             "source_commit": snapshot["evidence"]["tested_commit"], "evidence_ref": "VAPA_EXEC_LOG.md", "outcome": None}
    (workspace / "state.json").write_text(json.dumps(snapshot))
    (workspace / "events.jsonl").write_text(json.dumps(event) + "\n")


class ExecutionTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.project = Path(self.temp.name)
        self.workspace = self.project / ".vapa/vapa-exec-42/workspace"

    def parent(self, ids=("43", "44", "45"), integrated=("44",)):
        parent = state()
        parent.update(mode="decomposed", integration_phase="integrating", sub_issues={})
        for issue in ids:
            child = state(issue, "42")
            merged = issue in integrated
            if merged:
                child.update(phase="audited", audit="READY_TO_INTEGRATE")
                child["evidence"].update(audit="VAPA_AUDIT.md", tested_commit="tested-" + issue)
            path = ".vapa/vapa-exec-" + issue + "/workspace"
            write(self.project / path, child)
            parent["sub_issues"][issue] = {
                "workspace": path, "depends_on": [], "conflicts_with": [], "resources": [],
                "phase": child["phase"], "audit": child["audit"], "integrated": merged,
                "integration_commit": "merge-" + issue if merged else None,
            }
        return parent

    def child(self, issue, **changes):
        path = self.project / (".vapa/vapa-exec-" + issue + "/workspace")
        child = json.loads((path / "state.json").read_text())
        child.update(changes)
        write(path, child)
        return child

    def select(self, parent, capacity=2):
        write(self.workspace, parent)
        return runtime.ready(self.workspace, runtime.load(self.workspace), capacity)

    def test_successor_starts_without_waiting_for_unrelated_running_peer(self):
        parent = self.parent()
        parent["sub_issues"]["45"]["depends_on"] = ["44"]
        self.child("43", activity={"state": "running", "actor": "slow-peer", "heartbeat_at": AT, "waiting_for": []})
        result = self.select(parent)
        self.assertEqual(result["start"], ["45"])
        self.assertEqual(result["in_flight"], ["43"])

    def test_all_direct_dependencies_must_be_integrated(self):
        parent = self.parent()
        parent["sub_issues"]["45"]["depends_on"] = ["43", "44"]
        result = self.select(parent)
        self.assertNotIn("45", result["eligible"])
        self.assertIn("dependency:43", result["waiting"]["45"])

    def test_asymmetric_conflict_is_enforced(self):
        parent = self.parent()
        parent["sub_issues"]["43"]["conflicts_with"] = ["45"]
        self.assertEqual(self.select(parent)["start"], ["43"])
        self.child("43", activity={"state": "running", "actor": "worker", "heartbeat_at": AT, "waiting_for": []})
        self.assertIn("conflict:43", self.select(parent)["waiting"]["45"])

    def test_resource_claims_and_capacity_apply_to_selected_candidates(self):
        parent = self.parent()
        for issue in ("43", "45"):
            parent["sub_issues"][issue]["resources"] = ["database:exclusive"]
        self.assertEqual(self.select(parent)["start"], ["43"])
        parent["sub_issues"]["45"]["resources"] = []
        self.assertEqual(self.select(parent, capacity=1)["start"], ["43"])
        self.assertEqual(self.select(parent, capacity=2)["start"], ["43", "45"])

    def test_unknown_worker_keeps_slot_and_does_not_restart(self):
        parent = self.parent()
        self.child("43", activity={"state": "unknown", "actor": "lost-worker", "heartbeat_at": None, "waiting_for": []})
        result = self.select(parent, capacity=1)
        self.assertEqual(result["start"], [])
        self.assertNotIn("43", result["eligible"])

    def test_revised_child_audit_overrides_stale_parent_summary(self):
        parent = self.parent()
        parent["sub_issues"]["45"]["depends_on"] = ["44"]
        self.child("44", audit="NEEDS_REVISION")
        result = self.select(parent)
        self.assertIn("dependency:44", result["waiting"]["45"])

    def test_missing_integration_receipt_is_rejected(self):
        parent = self.parent()
        parent["sub_issues"]["44"]["integration_commit"] = None
        with self.assertRaisesRegex(ValueError, "integration requires"):
            self.select(parent)

    def test_graph_rejects_unknown_dependencies_and_cycles(self):
        parent = self.parent()
        parent["sub_issues"]["43"]["depends_on"] = ["absent"]
        with self.assertRaisesRegex(ValueError, "unknown or self"):
            self.select(parent)
        parent["sub_issues"]["43"]["depends_on"] = ["45"]
        parent["sub_issues"]["45"]["depends_on"] = ["43"]
        with self.assertRaisesRegex(ValueError, "cycle"):
            self.select(parent)

    def test_active_worktree_supplies_fresh_child_state(self):
        parent = self.parent()
        active = self.project / "active-checkout"
        parent["sub_issues"]["43"]["worktree"] = str(active)
        child = state("43", "42")
        child["activity"]["state"] = "running"
        write(active / parent["sub_issues"]["43"]["workspace"], child)
        self.assertIn("43", self.select(parent)["in_flight"])

    def test_fixed_fields_and_tracker_duplicate_states(self):
        for mutate in (
            lambda s: s.update(arbitrary_progress_note="do not grow the schema"),
            lambda s: s["tracker"]["observed_statuses"].append("status: approved"),
            lambda s: s.update(schema_version=True),
            lambda s: s["activity"].update(state="blocked"),
        ):
            value = state()
            mutate(value)
            write(self.workspace, value)
            with self.assertRaises(ValueError):
                runtime.load(self.workspace)

    def test_event_cursor_duplicate_and_torn_tail_fail_closed(self):
        for change in ("cursor", "duplicate", "torn", "last-state"):
            value = state()
            write(self.workspace, value)
            stream = self.workspace / "events.jsonl"
            event = json.loads(stream.read_text())
            if change == "cursor":
                value["last_event_seq"] = 2
                (self.workspace / "state.json").write_text(json.dumps(value))
            elif change == "duplicate":
                stream.write_text(stream.read_text() * 2)
            elif change == "torn":
                stream.write_text(stream.read_text() + '{"seq":2')
            else:
                event["phase"] = "testing"
                stream.write_text(json.dumps(event) + "\n")
            with self.assertRaises(ValueError):
                runtime.load(self.workspace)

    def test_cli_is_read_only_and_missing_child_never_becomes_ready(self):
        parent = self.parent()
        write(self.workspace, parent)
        before = {p: p.read_bytes() for p in self.project.rglob("*") if p.is_file()}
        result = subprocess.run([sys.executable, str(SCRIPT), "ready", str(self.workspace), "--capacity", "2"],
                                capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(json.loads(result.stdout)["start"], ["43", "45"])
        self.assertEqual(before, {p: p.read_bytes() for p in self.project.rglob("*") if p.is_file()})
        (self.project / parent["sub_issues"]["43"]["workspace"] / "events.jsonl").unlink()
        result = subprocess.run([sys.executable, str(SCRIPT), "ready", str(self.workspace)], capture_output=True, text=True)
        self.assertEqual(result.returncode, 1)
        self.assertEqual(json.loads(result.stdout)["status"], "FAIL")

    def test_resume_retains_prior_run_sequence_and_rejects_duplicate_identity(self):
        value = state()
        write(self.workspace, value)
        stream = self.workspace / "events.jsonl"
        first = stream.read_text()
        event = json.loads(first)
        event.update(seq=2, event_id="resumed-2", run_id="attempt-2", type="run.resumed")
        stream.write_text(first + json.dumps(event) + "\n")
        value.update(run_id="attempt-2", last_event_seq=2)
        (self.workspace / "state.json").write_text(json.dumps(value))
        self.assertEqual(runtime.load(self.workspace)["run_id"], "attempt-2")
        event["event_id"] = "event-1"
        stream.write_text(first + json.dumps(event) + "\n")
        with self.assertRaisesRegex(ValueError, "duplicate event_id"):
            runtime.load(self.workspace)

    def test_child_audit_is_not_parent_pr_readiness(self):
        value = state("43", "42")
        value["audit"] = "READY_FOR_PR"
        write(self.workspace, value)
        with self.assertRaisesRegex(ValueError, "child verdict"):
            runtime.load(self.workspace)


if __name__ == "__main__":
    unittest.main()
