#!/usr/bin/env python3
"""Check the published package contract, including portable resource paths."""
from pathlib import Path
import re
import yaml

ROOT = Path(__file__).resolve().parents[1]
SUPPORTED = {"name", "description", "license", "metadata", "allowed-tools"}
SCRIPTED = {"vapa-init", "vapa-proposal", "vapa-review"}
EXPLICIT = SCRIPTED | {"vapa-design"}

for folder in sorted((ROOT / "skills").iterdir()):
    if not folder.is_dir():
        continue
    content = (folder / "SKILL.md").read_text()
    front = re.match(r"^---\n(.*?)\n---\n", content, re.S)
    assert front, f"{folder.name}: missing YAML frontmatter"
    meta = yaml.safe_load(front[1])
    assert not set(meta) - SUPPORTED, f"{folder.name}: unsupported frontmatter"
    assert meta["name"] == folder.name
    assert isinstance(meta["description"], str) and meta["description"].strip()
    assert "${CLAUDE_" not in content, f"{folder.name}: host-specific paths"
    assert "AskUserQuestion" not in content, f"{folder.name}: host-specific tool"
    if folder.name in EXPLICIT:
        config = yaml.safe_load((folder / "agents/openai.yaml").read_text())
        assert config["policy"]["allow_implicit_invocation"] is False
        assert f"${folder.name}" in config["interface"]["default_prompt"]
    for resource in re.findall(r"\$\{SKILL_DIR\}/((?:scripts|references)/[\w./-]+)", content):
        assert (folder / resource).exists(), f"{folder.name}: missing {resource}"
    print(f"{folder.name}: portable package contract passed")
