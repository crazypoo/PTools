#!/usr/bin/env bash

set -euo pipefail

# English: Enforce the dependency direction rules from the pre-6.0 roadmap.
# Español: Aplica las reglas de dirección de dependencias de la hoja de ruta pre-6.0.
# 中文：执行 6.0 之前路线图定义的依赖方向规则。

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ruby "$repo_root/Scripts/report_spm_dependency_graph.rb" >/dev/null

ruby - "$repo_root" <<'RUBY'
require "json"

repo_root = File.expand_path(ARGV.fetch(0))
graph_path = File.join(repo_root, "report/spm_dependency_graph.json")
report_json_path = File.join(repo_root, "report/dependency_direction_5_8.json")
report_markdown_path = File.join(repo_root, "report/dependency_direction_5_8.md")
allowlist_path = File.join(repo_root, "Scripts/dependency_direction_allowlist.txt")
graph = JSON.parse(File.read(graph_path))

allowlist = {}
File.readlines(allowlist_path, chomp: true).each do |line|
  next if line.strip.empty? || line.lstrip.start_with?("#")
  source, destination, reason = line.split("|", 3)
  next if source.to_s.empty? || destination.to_s.empty? || reason.to_s.empty?
  allowlist[[source, destination]] = reason
end

# English: Test targets validate the package but are not shipped dependency edges.
# Español: Los targets de prueba validan el paquete, pero no son dependencias publicadas.
# 中文：测试 target 只用于验证包，不属于发布依赖边。
edges = graph.fetch("targets", []).reject { |target| target["type"] == "test" }.flat_map do |target|
  target.fetch("internal_dependencies", []).map do |dependency|
    {
      "source" => target.fetch("name"),
      "destination" => dependency.fetch("name")
    }
  end
end.sort_by { |edge| [edge["source"], edge["destination"]] }

violations = []
allowed_legacy_edges = []

edges.each do |edge|
  source = edge["source"]
  destination = edge["destination"]
  forbidden = false
  rule = nil

  if source == "ptools" && !%w[PToolsCore PToolsUIFoundation PToolsPermissionCore].include?(destination)
    forbidden = true
    rule = "Core target may depend only on PToolsCore, PToolsUIFoundation, and PToolsPermissionCore local layers"
  elsif source.match?(/^PT.*Permission$/) && !%w[ptools PToolsPermissionCore].include?(destination)
    forbidden = true
    rule = "Permission target may depend only on ptools or PToolsPermissionCore"
  elsif %w[PooToolsMediaViewer PooToolsPhotoPicker].include?(source) && destination == "PooToolsNetWork"
    forbidden = true
    rule = "Media target must not depend on the concrete Network implementation"
  elsif source.match?(/Navigation|Router/) && destination == "PooToolsPhotoPicker"
    forbidden = true
    rule = "Navigation must not depend on PhotoPicker"
  end

  next unless forbidden
  exception_reason = allowlist[[source, destination]]
  if exception_reason
    allowed_legacy_edges << edge.merge("rule" => rule, "reason" => exception_reason)
  else
    violations << edge.merge("rule" => rule)
  end
end

result = {
  "schema_version" => 1,
  "status" => violations.empty? ? "pass_with_legacy_allowlist" : "fail",
  "rules" => [
    "ptools -> local target is forbidden except PToolsCore, PToolsUIFoundation, and PToolsPermissionCore",
    "PT*Permission -> non-ptools target is forbidden except PToolsPermissionCore",
    "MediaViewer/PhotoPicker -> PooToolsNetWork is forbidden after its temporary allowlist expires",
    "Navigation/Router -> PhotoPicker is forbidden"
  ],
  "edges" => edges,
  "allowed_legacy_edges" => allowed_legacy_edges,
  "violations" => violations
}
File.write(report_json_path, JSON.pretty_generate(result) + "\n")

markdown = []
markdown << "# Dependency Direction Gate"
markdown << ""
markdown << "- Status: `#{result["status"]}`"
markdown << "- Internal edges: `#{edges.length}`"
markdown << "- Temporary allowlisted edges: `#{allowed_legacy_edges.length}`"
markdown << "- Unallowlisted violations: `#{violations.length}`"
markdown << ""
markdown << "## Rules"
markdown << ""
result["rules"].each { |rule| markdown << "- #{rule}" }
markdown << ""
markdown << "## Temporary legacy edges"
markdown << ""
allowed_legacy_edges.each do |edge|
  markdown << "- `#{edge["source"]}` → `#{edge["destination"]}`: #{edge["reason"]}"
end
markdown << "- None" if allowed_legacy_edges.empty?
markdown << ""
markdown << "## Violations"
markdown << ""
violations.each { |edge| markdown << "- `#{edge["source"]}` → `#{edge["destination"]}`: #{edge["rule"]}" }
markdown << "- None" if violations.empty?
markdown << ""
markdown << "## Gate policy"
markdown << ""
markdown << "The allowlist is intentionally short-lived. New exceptions must include a concrete migration reason and must not hide a new dependency cycle."
File.write(report_markdown_path, markdown.join("\n") + "\n")

puts "Dependency direction: #{result["status"]}; edges=#{edges.length}; allowlisted=#{allowed_legacy_edges.length}; violations=#{violations.length}"
exit 1 unless violations.empty?
RUBY
