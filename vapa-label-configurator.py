#!/usr/bin/env python3
"""
VAPA Label Configurator
=======================
Automatically configure GitHub Issue labels for a repository
based on the VAPA Framework specification.

Usage:
    python vapa_labels.py --token <PAT> --owner <owner> --repo <repo>
    python vapa_labels.py --token <PAT> --owner <owner> --repo <repo> --dry-run
    python vapa_labels.py --token <PAT> --owner <owner> --repo <repo> --clean

Requirements:
    pip install requests
"""

import argparse
import sys
import time
from typing import Optional
import requests


# ─────────────────────────────────────────────
# VAPA Label Definitions
# ─────────────────────────────────────────────

VAPA_LABELS: list[dict] = [

    # ── type: 提案类型 ──────────────────────────────────────────
    {
        "name": "type: vision-amendment",
        "color": "6f42c1",
        "description": "对 VISION.md 的修正提案（最高门槛）",
    },
    {
        "name": "type: feature",
        "color": "0075ca",
        "description": "新能力提案",
    },
    {
        "name": "type: problem",
        "color": "e4e669",
        "description": "纯问题陈述，不含解法",
    },
    {
        "name": "type: improvement",
        "color": "a2eeef",
        "description": "对现有能力的改善",
    },
    {
        "name": "type: experiment",
        "color": "d93f0b",
        "description": "假设验证型提案",
    },
    {
        "name": "type: technical-debt",
        "color": "e99695",
        "description": "技术债清理",
    },
    {
        "name": "type: research",
        "color": "f9d0c4",
        "description": "需要调研后才能形成提案",
    },

    # ── status: 提案状态 ────────────────────────────────────────
    {
        "name": "status: draft",
        "color": "ededed",
        "description": "草稿，欢迎讨论",
    },
    {
        "name": "status: refining",
        "color": "fbca04",
        "description": "讨论中，正在完善",
    },
    {
        "name": "status: ready-for-review",
        "color": "0e8a16",
        "description": "提案人认为已完整，等待评审",
    },
    {
        "name": "status: in-review",
        "color": "006b75",
        "description": "正式评审进行中",
    },
    {
        "name": "status: approved",
        "color": "0075ca",
        "description": "评审通过，进入 Roadmap",
    },
    {
        "name": "status: in-progress",
        "color": "e4e669",
        "description": "Agent 正在执行实现",
    },
    {
        "name": "status: in-validation",
        "color": "d93f0b",
        "description": "实现完成，等待验收",
    },
    {
        "name": "status: done",
        "color": "0e8a16",
        "description": "验收通过，已关闭",
    },
    {
        "name": "status: deferred",
        "color": "c5def5",
        "description": "延期，保留价值，等待时机",
    },
    {
        "name": "status: rejected",
        "color": "b60205",
        "description": "已拒绝，见评论中的拒绝理由",
    },

    # ── align: 战略对齐 ─────────────────────────────────────────
    {
        "name": "align: core",
        "color": "0075ca",
        "description": "直接支撑当前战略重心",
    },
    {
        "name": "align: adjacent",
        "color": "a2eeef",
        "description": "相邻领域，有间接价值",
    },
    {
        "name": "align: exploratory",
        "color": "f9d0c4",
        "description": "探索性，超出当前战略重心",
    },
    {
        "name": "align: off-track",
        "color": "b60205",
        "description": "偏离当前方向，需专项讨论",
    },

    # ── size: 规模估计 ──────────────────────────────────────────
    {
        "name": "size: S",
        "color": "0e8a16",
        "description": "Agent 可在 1 天内独立完成",
    },
    {
        "name": "size: M",
        "color": "fbca04",
        "description": "Agent 需 2–5 天，需人工拆解辅助",
    },
    {
        "name": "size: L",
        "color": "e4e669",
        "description": "必须拆分为多个子提案后执行",
    },
    {
        "name": "size: XL",
        "color": "b60205",
        "description": "战略级，需专项讨论后再拆解",
    },

    # ── contrib: 贡献角色 ───────────────────────────────────────
    {
        "name": "contrib: proposer",
        "color": "bfd4f2",
        "description": "提案发起者",
    },
    {
        "name": "contrib: shaper",
        "color": "d4c5f9",
        "description": "实质性完善贡献者",
    },
    {
        "name": "contrib: reviewer",
        "color": "c5def5",
        "description": "正式评审参与者",
    },
    {
        "name": "contrib: validator",
        "color": "bfe5bf",
        "description": "验收执行者",
    },
    {
        "name": "contrib: sponsor",
        "color": "fef2c0",
        "description": "提案战略背书人",
    },
]


# ─────────────────────────────────────────────
# GitHub API Client
# ─────────────────────────────────────────────

class GitHubLabelClient:
    """
    Minimal GitHub REST API client for label management.
    Reference: https://docs.github.com/en/rest/issues/labels
    """

    API_BASE = "https://api.github.com"
    API_VERSION = "2022-11-28"

    def __init__(self, token: str, owner: str, repo: str) -> None:
        self.owner = owner
        self.repo = repo
        self.session = requests.Session()
        self.session.headers.update({
            "Authorization": f"Bearer {token}",
            "Accept": "application/vnd.github+json",
            "X-GitHub-Api-Version": self.API_VERSION,
        })

    @property
    def _labels_url(self) -> str:
        return f"{self.API_BASE}/repos/{self.owner}/{self.repo}/labels"

    def _handle_rate_limit(self, response: requests.Response) -> None:
        """Back off when approaching GitHub rate limits."""
        remaining = int(response.headers.get("X-RateLimit-Remaining", 999))
        if remaining < 10:
            reset_at = int(response.headers.get("X-RateLimit-Reset", 0))
            wait = max(reset_at - int(time.time()), 0) + 2
            print(f"  ⚠  Rate limit low ({remaining} remaining). "
                  f"Waiting {wait}s ...")
            time.sleep(wait)

    def validate_connection(self) -> bool:
        """Verify token and repository accessibility."""
        url = f"{self.API_BASE}/repos/{self.owner}/{self.repo}"
        resp = self.session.get(url)

        if resp.status_code == 200:
            data = resp.json()
            print(f"  ✓  Repository: {data['full_name']}")
            print(f"     Visibility: {data.get('visibility', 'unknown')}")
            print(f"     Default branch: {data.get('default_branch', 'unknown')}")
            return True

        if resp.status_code == 401:
            print("  ✗  Authentication failed. Check your PAT.")
        elif resp.status_code == 403:
            print("  ✗  Access forbidden. Insufficient token permissions.")
        elif resp.status_code == 404:
            print(f"  ✗  Repository '{self.owner}/{self.repo}' not found.")
        else:
            print(f"  ✗  Unexpected error {resp.status_code}: {resp.text}")

        return False

    def list_labels(self) -> list[dict]:
        """Fetch all existing labels (handles pagination)."""
        labels, page = [], 1

        while True:
            resp = self.session.get(
                self._labels_url,
                params={"per_page": 100, "page": page},
            )
            resp.raise_for_status()
            self._handle_rate_limit(resp)

            batch = resp.json()
            if not batch:
                break

            labels.extend(batch)
            page += 1

        return labels

    def create_label(self, name: str, color: str,
                     description: str) -> Optional[dict]:
        """Create a new label. Returns created label or None on failure."""
        resp = self.session.post(
            self._labels_url,
            json={"name": name, "color": color, "description": description},
        )
        self._handle_rate_limit(resp)

        if resp.status_code == 201:
            return resp.json()
        if resp.status_code == 422:
            # Already exists — treat as non-fatal
            return None

        resp.raise_for_status()
        return None

    def update_label(self, current_name: str, name: str,
                     color: str, description: str) -> Optional[dict]:
        """Update an existing label by its current name."""
        url = f"{self._labels_url}/{requests.utils.quote(current_name)}"
        resp = self.session.patch(
            url,
            json={"new_name": name, "color": color, "description": description},
        )
        self._handle_rate_limit(resp)

        if resp.status_code == 200:
            return resp.json()

        resp.raise_for_status()
        return None

    def delete_label(self, name: str) -> bool:
        """Delete a label by name. Returns True on success."""
        url = f"{self._labels_url}/{requests.utils.quote(name)}"
        resp = self.session.delete(url)
        self._handle_rate_limit(resp)
        return resp.status_code == 204


# ─────────────────────────────────────────────
# Core Logic
# ─────────────────────────────────────────────

class VAPAConfigurator:

    def __init__(self, client: GitHubLabelClient, dry_run: bool = False) -> None:
        self.client = client
        self.dry_run = dry_run
        self._prefix = "[DRY RUN] " if dry_run else ""

        # Counters for final summary
        self._created = 0
        self._updated = 0
        self._skipped = 0
        self._deleted = 0
        self._failed  = 0

    # ── Public entry points ────────────────────────────────────

    def apply(self) -> None:
        """
        Apply VAPA labels to the repository.

        Strategy:
          1. Fetch existing labels.
          2. For each VAPA label:
             - If name matches exactly → update color/description if changed.
             - If name is new → create.
          3. Report any non-VAPA labels found (no auto-delete by default).
        """
        print(f"\n{'─'*54}")
        print(f"  Applying VAPA labels to "
              f"{self.client.owner}/{self.client.repo}")
        if self.dry_run:
            print("  MODE: Dry Run — no changes will be made")
        print(f"{'─'*54}\n")

        existing = {lb["name"]: lb for lb in self.client.list_labels()}
        vapa_names = {lb["name"] for lb in VAPA_LABELS}

        # Apply VAPA labels
        for label in VAPA_LABELS:
            self._apply_single(label, existing)

        # Report orphan labels (non-VAPA)
        orphans = [n for n in existing if n not in vapa_names]
        if orphans:
            print(f"\n  ℹ  Non-VAPA labels found ({len(orphans)}):")
            for name in orphans:
                print(f"     · {name}")
            print("     Run with --clean to remove them.")

        self._print_summary()

    def clean(self) -> None:
        """
        Remove all existing labels and re-apply VAPA labels from scratch.
        Use with caution: this will remove labels currently attached to Issues.
        """
        print(f"\n{'─'*54}")
        print(f"  ⚠  CLEAN MODE — all existing labels will be deleted")
        print(f"     Repository: {self.client.owner}/{self.client.repo}")
        if self.dry_run:
            print("  MODE: Dry Run — no changes will be made")
        print(f"{'─'*54}\n")

        if not self.dry_run:
            confirm = input(
                "  This cannot be undone. Type 'yes' to continue: "
            ).strip().lower()
            if confirm != "yes":
                print("  Aborted.")
                sys.exit(0)

        # Delete all existing
        print("\n  Deleting existing labels...")
        for lb in self.client.list_labels():
            self._delete_single(lb["name"])

        # Re-create VAPA labels
        print("\n  Creating VAPA labels...")
        for label in VAPA_LABELS:
            self._create_single(label)

        self._print_summary()

    # ── Private helpers ────────────────────────────────────────

    def _apply_single(self, label: dict, existing: dict[str, dict]) -> None:
        name  = label["name"]
        color = label["color"]
        desc  = label["description"]

        if name in existing:
            current = existing[name]
            needs_update = (
                current["color"].lstrip("#").lower() != color.lower()
                or current.get("description", "") != desc
            )
            if needs_update:
                print(f"  {self._prefix}↻  Updating : {name}")
                if not self.dry_run:
                    result = self.client.update_label(name, name, color, desc)
                    if result:
                        self._updated += 1
                    else:
                        print(f"       ✗  Failed to update: {name}")
                        self._failed += 1
                else:
                    self._updated += 1
            else:
                print(f"  ✓  Unchanged: {name}")
                self._skipped += 1
        else:
            self._create_single(label)

    def _create_single(self, label: dict) -> None:
        name  = label["name"]
        color = label["color"]
        desc  = label["description"]

        print(f"  {self._prefix}+  Creating : {name}")
        if not self.dry_run:
            result = self.client.create_label(name, color, desc)
            if result:
                self._created += 1
            else:
                print(f"       ✗  Failed to create: {name}")
                self._failed += 1
        else:
            self._created += 1

    def _delete_single(self, name: str) -> None:
        print(f"  {self._prefix}-  Deleting : {name}")
        if not self.dry_run:
            success = self.client.delete_label(name)
            if success:
                self._deleted += 1
            else:
                print(f"       ✗  Failed to delete: {name}")
                self._failed += 1
        else:
            self._deleted += 1

    def _print_summary(self) -> None:
        print(f"\n{'─'*54}")
        print("  Summary")
        print(f"{'─'*54}")
        if self._created:
            print(f"  + Created  : {self._created}")
        if self._updated:
            print(f"  ↻ Updated  : {self._updated}")
        if self._skipped:
            print(f"  ✓ Unchanged: {self._skipped}")
        if self._deleted:
            print(f"  - Deleted  : {self._deleted}")
        if self._failed:
            print(f"  ✗ Failed   : {self._failed}")
        print(f"{'─'*54}\n")


# ─────────────────────────────────────────────
# CLI
# ─────────────────────────────────────────────

def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="vapa_labels",
        description=(
            "VAPA Label Configurator — "
            "automatically set up GitHub Issue labels for the VAPA Framework."
        ),
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
examples:
  # Preview changes without modifying anything
  python vapa_labels.py --token ghp_xxx --owner myorg --repo myrepo --dry-run

  # Apply VAPA labels (create / update, keep existing non-VAPA labels)
  python vapa_labels.py --token ghp_xxx --owner myorg --repo myrepo

  # Delete ALL existing labels and apply VAPA labels from scratch
  python vapa_labels.py --token ghp_xxx --owner myorg --repo myrepo --clean
        """,
    )

    parser.add_argument(
        "--token", "-t",
        required=True,
        metavar="PAT",
        help="GitHub Personal Access Token (requires repo scope)",
    )
    parser.add_argument(
        "--owner", "-o",
        required=True,
        metavar="OWNER",
        help="Repository owner (user or organization name)",
    )
    parser.add_argument(
        "--repo", "-r",
        required=True,
        metavar="REPO",
        help="Repository name (without .git extension)",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Preview what would change without making any API calls",
    )
    parser.add_argument(
        "--clean",
        action="store_true",
        help=(
            "Delete ALL existing labels before applying VAPA labels. "
            "⚠ Labels attached to Issues will also be removed."
        ),
    )
    parser.add_argument(
        "--list-labels",
        action="store_true",
        help="Print the full VAPA label definitions and exit",
    )

    return parser


def print_label_definitions() -> None:
    """Pretty-print the VAPA label spec to stdout."""
    groups = {}
    for lb in VAPA_LABELS:
        prefix = lb["name"].split(":")[0].strip()
        groups.setdefault(prefix, []).append(lb)

    print("\n  VAPA Label Definitions\n")
    for group, labels in groups.items():
        print(f"  ── {group}: ({'─'*40})")
        for lb in labels:
            print(f"     #{lb['color']}  {lb['name']}")
            print(f"              {lb['description']}")
        print()


def main() -> None:
    parser = build_parser()
    args = parser.parse_args()

    # ── --list-labels shortcut ─────────────────────────────────
    if args.list_labels:
        print_label_definitions()
        sys.exit(0)

    # ── Validate connection ────────────────────────────────────
    client = GitHubLabelClient(
        token=args.token,
        owner=args.owner,
        repo=args.repo,
    )

    print(f"\n  Connecting to GitHub API...")
    if not client.validate_connection():
        sys.exit(1)

    # ── Run configurator ───────────────────────────────────────
    configurator = VAPAConfigurator(client, dry_run=args.dry_run)

    if args.clean:
        configurator.clean()
    else:
        configurator.apply()


if __name__ == "__main__":
    main()
