#!/usr/bin/env python3
"""Check README package links and local documentation targets without network."""
from pathlib import Path
import re
from urllib.parse import unquote, urlsplit

ROOT = Path(__file__).resolve().parents[1]
errors = []
readmes = [ROOT / "README.md", ROOT / "README.en.md"]
documents = readmes + [
    ROOT / "docs/skill-design-review.md",
    ROOT / "docs/exec-parent-child-model.md",
    ROOT / "skills/vapa-exec/SKILL.md",
    ROOT / "skills/vapa-audit/SKILL.md",
] + list((ROOT / "skills/vapa-exec/references").glob("*.md"))

for document in documents:
    content = document.read_text()
    links = re.findall(r"\[[^\]]+\]\(([^)]+)\)", content)
    links += re.findall(r'(?:href|src)="([^"]+)"', content)
    for link in links:
        ref = urlsplit(link)
        if ref.scheme or ref.netloc or not ref.path:
            continue
        if not (document.parent / unquote(ref.path)).is_file():
            errors.append(f"{document.name}: missing local target {link}")
    if document in readmes:
        for skill in (ROOT / "skills").glob("*/SKILL.md"):
            if skill.relative_to(ROOT).as_posix() not in links:
                errors.append(f"{document.name}: no link to {skill.parent.name}")

if errors:
    raise SystemExit("\n".join(errors))
print("README Skill coverage and local documentation links passed")
