#!/usr/bin/env bash

set -euo pipefail

# English: Regenerate all 5.8 architecture evidence from the current checkout.
# Español: Regenera toda la evidencia arquitectónica de 5.8 desde el checkout actual.
# 中文：根据当前工作区重新生成全部 5.8 架构证据。

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

ruby Scripts/report_spm_dependency_graph.rb >/dev/null
ruby Scripts/report_cocoapods_subspec_graph.rb >/dev/null
bash Scripts/validate_file_size_gate.sh >/dev/null
ruby Scripts/report_sendable_exceptions.rb >/dev/null
ruby Scripts/report_public_api_5_8.rb >/dev/null

printf 'PASS: 5.8 architecture reports regenerated\n'
