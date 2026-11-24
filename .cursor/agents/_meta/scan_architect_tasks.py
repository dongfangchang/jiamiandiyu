#!/usr/bin/env python3
"""Scan .cursor/agents/*/tasks.md for runnable architect-issued items."""
from __future__ import annotations

import re
import sys
from pathlib import Path

AGENTS = Path(__file__).resolve().parents[1]  # .cursor/agents


def parse_tasks(path: Path) -> list[dict]:
    text = path.read_text(encoding="utf-8")
    role = path.parent.name
    # Split on ### headings
    parts = re.split(r"(?m)^###\s+", text)
    header = parts[0]
    architect_zone = "架构师下发" in header or "架构师下发" in text[:800]
    items = []
    for part in parts[1:]:
        lines = part.strip().splitlines()
        if not lines:
            continue
        title = lines[0].strip()
        body = "\n".join(lines[1:])
        status_m = re.search(r"(?m)^-\s*status:\s*(\w+)", body)
        status = status_m.group(1) if status_m else ""
        source_m = re.search(r"(?m)^-\s*来源:\s*(.+)$", body)
        source = source_m.group(1).strip() if source_m else ""
        block_m = re.search(r"(?m)^-\s*阻塞:\s*(.+)$", body)
        blocked = None
        if block_m:
            blocked = block_m.group(1).strip()
            # "无" / "无（已齐）" / "无。" all mean unblocked
            if blocked in ("无", "无。", "-", "—", "") or re.match(r"^无[（(]", blocked):
                blocked = None
        # Only field lines (avoid banner prose that mentions the phrase)
        owner_main = bool(re.search(r"(?m)^-\s+.*\bowner:\s*主会话", body))
        # architect-issued: in banner zone file OR source keywords OR ID prefixes
        id_m = re.match(r"^([A-Za-z0-9_-]+)", title)
        tid = id_m.group(1) if id_m else title
        arch_src = bool(
            re.search(
                r"ADR-0032|ADR-0034|EXPERIENCE_ARCHITECTURE|ROADMAP\s*X|架构师|ART_BRIEF_DESK_WORLD|DESK_WORLD_STATIONS",
                source,
            )
        )
        arch_id = bool(
            re.match(
                r"^(ART-DW|ART-DQ|UI-X|UI-P0|UI-07|CO-X|CO-DQ|LB-X|GD-X|AR-\d|PM-0[56]|P0-|X1-|X2-|X3-|DW-)",
                tid,
            )
        )
        issued = arch_id or arch_src
        items.append(
            {
                "role": role,
                "id": tid,
                "title": title,
                "status": status,
                "blocked": blocked,
                "owner_main": owner_main,
                "issued": bool(issued),
                "path": str(path),
            }
        )
    return items


def main() -> int:
    rows = []
    for path in sorted(AGENTS.glob("*/tasks.md")):
        if path.parent.name.startswith("_"):
            continue
        rows.extend(parse_tasks(path))

    runnable = [
        r
        for r in rows
        if r["issued"]
        and r["status"] in ("todo", "doing")
        and not r["owner_main"]
        and r["blocked"] is None
    ]
    blocked = [
        r
        for r in rows
        if r["issued"] and r["status"] in ("todo", "doing", "blocked") and (r["blocked"] or r["status"] == "blocked")
    ]

    print("=== RUNNABLE (architect-issued, not owner:主会话) ===")
    if not runnable:
        print("(none)")
    for r in runnable:
        print(f"{r['role']}\t{r['status']}\t{r['id']}\t{r['title'][:80]}")

    print("=== BLOCKED (sample) ===")
    for r in blocked[:12]:
        why = r["blocked"] or r["status"]
        print(f"{r['role']}\t{r['id']}\t{why[:60]}")

    print(f"=== COUNTS runnable={len(runnable)} blocked_shown={min(12, len(blocked))} ===")
    return 0


if __name__ == "__main__":
    sys.exit(main())
