#!/usr/bin/env python3

"""Compare a reviewed catalog with an iOS runtime snapshot.

English: Runtime differences are evidence for review, never automatic deletion.
Español: Las diferencias del runtime son evidencia para revisión, nunca eliminación automática.
中文：Runtime 差异只作为审核证据，绝不自动删除正式目录。
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path


def by_postscript(payload: dict[str, object]) -> dict[str, dict[str, object]]:
    return {
        str(item["postScriptName"]): item
        for item in payload.get("fonts", [])
        if isinstance(item, dict) and item.get("postScriptName")
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--current", type=Path, required=True)
    parser.add_argument("--candidate", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()

    current = json.loads(args.current.read_text(encoding="utf-8"))
    candidate = json.loads(args.candidate.read_text(encoding="utf-8"))
    current_fonts = by_postscript(current)
    candidate_fonts = by_postscript(candidate)
    added_names = sorted(set(candidate_fonts) - set(current_fonts))
    removed_names = sorted(set(current_fonts) - set(candidate_fonts))
    shared_names = set(current_fonts) & set(candidate_fonts)
    family_changed = sorted(
        name
        for name in shared_names
        if candidate_fonts[name].get("familyName") != current_fonts[name].get("familyName")
    )

    # English: Same-family name changes are review candidates, not confirmed renames.
    # Español: Los cambios de nombre dentro de la misma familia son candidatos de revisión, no renombrados confirmados.
    # 中文：同一字体族中的名称变化只能标记为候选，不能直接确认重命名。
    alias_candidates = []
    current_by_family = {}
    candidate_by_family = {}
    for name, item in current_fonts.items():
        current_by_family.setdefault(item.get("familyName"), []).append(name)
    for name, item in candidate_fonts.items():
        candidate_by_family.setdefault(item.get("familyName"), []).append(name)
    for family in sorted(set(current_by_family) & set(candidate_by_family)):
        old_names = sorted(set(current_by_family[family]) - set(candidate_by_family[family]))
        new_names = sorted(set(candidate_by_family[family]) - set(current_by_family[family]))
        if old_names and new_names:
            alias_candidates.append({"familyName": family, "removed": old_names, "added": new_names})

    result = {
        "schemaVersion": 1,
        "runtime": candidate.get("runtime"),
        "generatedAt": candidate.get("generatedAt"),
        "added": [candidate_fonts[name] for name in added_names],
        "removed": removed_names,
        "familyChanged": family_changed,
        "postScriptNameChanged": [],
        "aliasCandidates": alias_candidates,
        "needsReview": added_names + removed_names + family_changed + alias_candidates,
    }
    args.output.write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(
        "PASS [FONT_DIFF] "
        f"added={len(added_names)} removed={len(removed_names)} "
        f"familyChanged={len(family_changed)} aliasCandidates={len(alias_candidates)}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
