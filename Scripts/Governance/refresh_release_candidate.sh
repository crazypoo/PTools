#!/usr/bin/env bash
set -euo pipefail

# Regenerate only the canonical generated assets, never rewrite source or weaken gates.
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$root"

python3 Scripts/Docs/audit_docs.py --write-all
bash Scripts/Governance/generate_all_current_reports.sh --write

# Check mode must be repeatable; no stale reports or missing module docs allowed.
python3 Scripts/Docs/audit_docs.py --check
bash Scripts/Governance/generate_all_current_reports.sh --check
bash Scripts/Governance/validate_current_reports.sh
bash Scripts/validate_docs.sh
printf 'PASS [PTOOLS_GOVERNANCE_REFRESH] generated assets are self-consistent\\n'
