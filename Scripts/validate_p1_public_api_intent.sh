#!/usr/bin/env bash

set -euo pipefail

# English: Validate the reviewed public API intent registry without changing public symbols.
# Español: Valida el registro revisado de intención de API pública sin cambiar símbolos públicos.
# 中文：校验公开 API 意图登记，不修改现有公开符号。
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

ruby - <<'RUBY'
require "json"

registry = JSON.parse(File.read("Scripts/p1_public_api_intent.json"))
allowed = %w[supported compatibility advanced accidental]
entries = registry.fetch("entries")
abort "FAIL: public API intent registry is empty" if entries.empty?
seen = {}
entries.each do |entry|
  %w[symbol path intent owner migration].each do |field|
    value = entry[field]
    abort "FAIL: public API entry is missing #{field}" unless value.is_a?(String) && !value.strip.empty?
  end
  abort "FAIL: unknown public API intent #{entry["intent"]}" unless allowed.include?(entry["intent"])
  abort "FAIL: public API path is missing #{entry["path"]}" unless File.file?(entry["path"])
  key = [entry["symbol"], entry["path"]]
  abort "FAIL: duplicate public API intent #{key.join("|")}" if seen[key]
  seen[key] = true
end

inventory = JSON.parse(File.read("report/current/public_api.json"))
abort "FAIL: generated public API inventory is missing" unless inventory["declarations"].is_a?(Array)
puts "PASS: public API intent registry (reviewed=#{entries.length}, inventory=#{inventory["declarations"].length})"
RUBY
