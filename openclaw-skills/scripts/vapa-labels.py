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

    BASE_URL = "https://api.github.com"

    def __init__(self, token: str, owner: str, repo: str, dry_run: bool = False):
        self.token = token
        self.owner = owner
        self.repo = repo
        self.dry_run = dry_run
        self.session = requests.Session()
        self.session.headers.update({
            "Authorization": f"token {token}",
            "Accept": "application/vnd.github.v3+json",
            "User-Agent": "vapa-label-configurator/0.1",
        })

    # ── helpers ───────────────────────────────────────────────

    def _url(self, endpoint: str) -> str:
        return f"{self.BASE_URL}/repos/{self.owner}/{self.repo}/{endpoint}"

    def _get(self, endpoint: str, params: Optional[dict] = None):
        return self.session.get(self._url(endpoint), params=params or {})

    def _post(self, endpoint: str, json_data: dict):
        return self.session.post(self._url(endpoint), json=json_data)

    def _patch(self, endpoint: str, json_data: dict):
        return self.session.patch(self._url(endpoint), json=json_data)

    def _delete(self, endpoint: str):
        return self.session.delete(self._url(endpoint))

    # ── label CRUD ──────────────────────────────────────────────

    def list_labels(self) -> list[dict]:
        """Fetch all existing labels (paginated)."""
        labels: list[dict] = []
        page = 1
        while True:
            resp = self._get("labels", {"per_page": 100, "page": page})
            resp.raise_for_status()
            batch = resp.json()
            if not batch:
                break
            labels.extend(batch)
            page += 1
        return labels

    def create_label(self, label: dict) -> dict:
        """Create a new label."""
        payload = {
            "name": label["name"],
            "color": label["color"],
            "description": label.get("description", ""),
        }
        resp = self._post("labels", payload)
        resp.raise_for_status()
        return resp.json()

    def update_label(self, old_name: str, label: dict) -> dict:
        """Update an existing label (GitHub uses the old name in the URL)."""
        # URL-encode the label name for the path segment
        encoded_name = requests.utils.quote(old_name, safe="")
        payload = {
            "new_name": label["name"],
            "color": label["color"],
            "description": label.get("description", ""),
        }
        resp = self._patch(f"labels/{encoded_name}", payload)
        resp.raise_for_status()
        return resp.json()

    def delete_label(self, name: str) -> None:
        """Delete a label."""
        encoded_name = requests.utils.quote(name, safe="")
        resp = self._delete(f"labels/{encoded_name}")
        resp.raise_for_status()

    # ── high-level operations ───────────────────────────────────

    def clean_all_labels(self) -> None:
        """Remove every existing label from the repo."""
        existing = self.list_labels()
        if not existing:
            print("  (no labels to clean)")
            return
        for lbl in existing:
            name = lbl["name"]
            if self.dry_run:
                print(f"  [DRY-RUN] would delete label: {name}")
            else:
                print(f"  deleting label: {name}")
                self.delete_label(name)
                time.sleep(0.3)  # polite rate-limiting

    def upsert_labels(self, labels: list[dict]) -> None:
        """
        Ensure the repo has exactly the provided labels.
        - If a label exists with the same name but different attrs → update.
        - If a label does not exist → create.
        - Existing labels not in the provided list are left untouched (unless --clean).
        """
        existing = {l["name"]: l for l in self.list_labels()}

        for label in labels:
            name = label["name"]
            existing_lbl = existing.get(name)

            if existing_lbl is None:
                # Try to find by normalized name (GitHub is case-insensitive in some contexts)
                for ename, elbl in existing.items():
                    if ename.lower() == name.lower():
                        existing_lbl = elbl
                        break

            if existing_lbl is None:
                if self.dry_run:
                    print(f"  [DRY-RUN] would create: {name}")
                else:
                    print(f"  creating: {name}")
                    try:
                        self.create_label(label)
                    except requests.HTTPError as exc:
                        if exc.response.status_code == 422:
                            print(f"    ⚠️  422 Unprocessable — label may already exist with different casing: {name}")
                        else:
                            raise
                    time.sleep(0.3)
            else:
                # Compare attributes
                needs_update = (
                    existing_lbl.get("color", "").lstrip("#").lower() != label["color"].lower()
                    or existing_lbl.get("description", "") != label.get("description", "")
                )
                if needs_update:
                    if self.dry_run:
                        print(f"  [DRY-RUN] would update: {name}")
                    else:
                        print(f"  updating: {name}")
                        self.update_label(existing_lbl["name"], label)
                        time.sleep(0.3)
                else:
                    print(f"  unchanged: {name}")


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Configure VAPA labels on a GitHub repository",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument("--token", required=True, help="GitHub personal access token (PAT)")
    parser.add_argument("--owner", required=True, help="Repository owner (user or org)")
    parser.add_argument("--repo", required=True, help="Repository name")
    parser.add_argument("--clean", action="store_true", help="Delete ALL existing labels first (destructive)")
    parser.add_argument("--dry-run", action="store_true", help="Print what would be done without making changes")

    args = parser.parse_args()

    client = GitHubLabelClient(
        token=args.token,
        owner=args.owner,
        repo=args.repo,
        dry_run=args.dry_run,
    )

    print(f"🔗 Target repo: {args.owner}/{args.repo}")
    print(f"🧪 Dry-run: {args.dry_run}")
    print()

    if args.clean:
        print("🧹 Cleaning existing labels...")
        client.clean_all_labels()
        print()

    print(f"📦 Configuring {len(VAPA_LABELS)} VAPA labels...")
    client.upsert_labels(VAPA_LABELS)
    print()
    print("✅ Done.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
