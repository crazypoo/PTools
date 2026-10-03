#!/usr/bin/env bash

set -euo pipefail

# English: Keep runtime snapshots pending until a human reviews the diff.
# Español: Mantiene las instantáneas del runtime como pending hasta la revisión humana.
# 中文：Runtime 快照必须先进入 pending，人工审核后才能更新正式目录。

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
catalog="$repo_root/PooToolsSource/Font/Resources/FontCatalog/FontCatalog.json"
pending="$repo_root/PooToolsSource/Font/Resources/FontCatalog/FontCatalog.pending.json"
collector="$repo_root/Scripts/Font/collect-fonts.sh"

usage() {
  cat >&2 <<'MESSAGE'
Usage:
  update-font-catalog.sh --from-json CANDIDATE.json
  update-font-catalog.sh --simulator booted|UDID
  update-font-catalog.sh --all-runtimes

Runtime snapshots are never written directly to FontCatalog.json.
MESSAGE
}

run_diff() {
  local candidate="$1"
  python3 "$repo_root/Scripts/Font/diff-font-catalog.py" \
    --current "$catalog" \
    --candidate "$candidate" \
    --output "$pending"
}

case "${1:-}" in
  --from-json)
    candidate="${2:-}"
    [[ -n "$candidate" && -f "$candidate" ]] || {
      printf 'FAIL [FONT_PENDING] candidate JSON is missing\n' >&2
      exit 1
    }
    run_diff "$candidate"
    ;;
  --simulator)
    simulator="${2:-booted}"
    tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/ptools-font-catalog.XXXXXX")"
    trap 'rm -rf "$tmp_dir"' EXIT
    candidate="$tmp_dir/runtime-fonts.json"
    bash "$collector" --simulator "$simulator" --output "$candidate"
    run_diff "$candidate"
    printf 'PASS [FONT_PENDING] pending=%s\n' "$pending"
    ;;
  --all-runtimes)
    command -v xcrun >/dev/null 2>&1 || {
      printf 'FAIL [FONT_PENDING] xcrun is required for --all-runtimes\n' >&2
      exit 1
    }
    tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/ptools-font-runtimes.XXXXXX")"
    trap 'rm -rf "$tmp_dir"' EXIT
    snapshot_dir="$tmp_dir/Snapshots"
    mkdir -p "$snapshot_dir"

    simulators=()
    while IFS= read -r simulator; do
      [[ -n "$simulator" ]] && simulators+=("$simulator")
    done < <(xcrun simctl list devices booted -j | python3 -c '
import json
import sys

payload = json.load(sys.stdin)
for devices in payload.get("devices", {}).values():
    for device in devices:
        if device.get("state") == "Booted":
            print(device["udid"])
')
    [[ "${#simulators[@]}" -gt 0 ]] || {
      printf 'FAIL [FONT_PENDING] no booted simulators for --all-runtimes\n' >&2
      exit 1
    }

    for simulator in "${simulators[@]}"; do
      runtime_file="$snapshot_dir/$simulator.json"
      bash "$collector" --simulator "$simulator" --output "$runtime_file"
    done

    merged="$tmp_dir/merged-runtime-fonts.json"
    python3 - "$snapshot_dir" "$merged" <<'PY'
import json
import sys
from pathlib import Path

snapshot_dir = Path(sys.argv[1])
output = Path(sys.argv[2])
fonts = {}
runtimes = []
generated_at = None
for path in sorted(snapshot_dir.glob("*.json")):
    payload = json.loads(path.read_text(encoding="utf-8"))
    runtimes.append(payload.get("runtime"))
    generated_at = payload.get("generatedAt", generated_at)
    for item in payload.get("fonts", []):
        name = item.get("postScriptName")
        if name:
            fonts[name] = item

output.write_text(json.dumps({
    "runtime": ",".join(str(value) for value in runtimes if value),
    "generatedAt": generated_at,
    "fonts": [fonts[name] for name in sorted(fonts)],
}, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
PY
    run_diff "$merged"
    printf 'PASS [FONT_PENDING] pending=%s snapshots=%s\n' "$pending" "$snapshot_dir"
    ;;
  --help|-h)
    usage
    exit 0
    ;;
  *)
    usage
    exit 2
    ;;
esac
