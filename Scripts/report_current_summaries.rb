#!/usr/bin/env ruby

require "fileutils"
require "json"
require "rubygems"
require "time"

repo_root = File.expand_path("..", __dir__)
current_dir = File.join(repo_root, "report", "current")
FileUtils.mkdir_p(current_dir)

source_revision = `git -C "#{repo_root}" rev-parse HEAD`.strip
generated_at = Time.now.utc.iso8601

def header(generator, source_revision, generated_at)
  [
    "<!--",
    "AUTO-GENERATED FILE.",
    "DO NOT EDIT MANUALLY.",
    "",
    "Generator: #{generator}",
    "Source revision: #{source_revision}",
    "Generated at: #{generated_at}",
    "-->",
    ""
  ]
end

def write_markdown(path, generator, source_revision, generated_at, lines)
  content = header(generator, source_revision, generated_at) + lines
  File.write(path, content.join("\n") + "\n")
end

spm_path = File.join(current_dir, "spm_dependency_graph.json")
pods_path = File.join(current_dir, "cocoapods_subspec_graph.json")
spm = JSON.parse(File.read(spm_path))
pods = JSON.parse(File.read(pods_path))

write_markdown(
  File.join(current_dir, "dependency_graph.md"),
  "Scripts/report_current_summaries.rb",
  source_revision,
  generated_at,
  [
    "# PTools 当前依赖图",
    "",
    "本报告合并当前 SwiftPM target 图和 CocoaPods subspec 图；详细机器数据保留在同目录的 JSON 报告。",
    "",
    "- SwiftPM target 数量：`#{spm.fetch("targets").length}`",
    "- SwiftPM product 数量：`#{spm.fetch("products").length}`",
    "- CocoaPods subspec 数量：`#{pods.fetch("subspec_count")}`",
    "- CocoaPods 默认 subspec：`#{pods.fetch("default_subspec")}`",
    "- 当前 podspec 版本：`#{pods.fetch("version")}`",
    "",
    "## 机器报告",
    "",
    "- [`spm_dependency_graph.json`](spm_dependency_graph.json)",
    "- [`cocoapods_subspec_graph.json`](cocoapods_subspec_graph.json)",
    "- [`module_parity.md`](module_parity.md)",
    "- [`dependency_direction.md`](dependency_direction.md)"
  ]
)

debug_targets = spm.fetch("targets").select do |target|
  target.fetch("name").match?(/Debug|Instrument|Console|Inspector/i)
end
debug_subspecs = pods.fetch("subspecs").select do |subspec|
  subspec.fetch("short_name").match?(/DEBUG|Instrument|Console|Inspector/i)
end

write_markdown(
  File.join(current_dir, "debug_dependency_graph.md"),
  "Scripts/report_current_summaries.rb",
  source_revision,
  generated_at,
  [
    "# PTools 当前 Debug 依赖图",
    "",
    "本报告从当前 manifest 和 podspec 过滤 Debug、Console、Inspector、Instrument 相关节点；它不复用旧 milestone 的静态数字。",
    "",
    "## SwiftPM",
    "",
    "| Target | Path | Internal dependencies |",
    "| --- | --- | --- |",
    *debug_targets.map do |target|
      dependencies = target.fetch("internal_dependencies", []).map { |item| "`#{item.fetch("name")}`" }.join(", ")
      "| `#{target.fetch("name")}` | `#{target["path"] || "—"}` | #{dependencies.empty? ? "—" : dependencies} |"
    end,
    ("| None | — | — |" if debug_targets.empty?),
    "",
    "## CocoaPods",
    "",
    "| Subspec | Local dependencies |",
    "| --- | --- |",
    *debug_subspecs.map do |subspec|
      dependencies = subspec.fetch("local_dependencies", []).map { |name| "`#{name}`" }.join(", ")
      "| `#{subspec.fetch("short_name")}` | #{dependencies.empty? ? "—" : dependencies} |"
    end,
    ("| None | — |" if debug_subspecs.empty?),
    "",
    "Debug 运行时是否创建窗口、采样器、sink 或 observer，仍需通过真实宿主回归确认。"
  ].compact
)

version = File.read(File.join(repo_root, "VERSION")).strip
tags = `git -C "#{repo_root}" tag --list`.lines(chomp: true).filter_map do |tag|
  tag if tag.match?(/\A\d+\.\d+\.\d+\z/)
end
latest_tag = tags.max_by { |tag| Gem::Version.new(tag) }

write_markdown(
  File.join(current_dir, "regression_status.md"),
  "Scripts/report_current_summaries.rb",
  source_revision,
  generated_at,
  [
    "# PTools 当前回归状态",
    "",
    "本报告只记录当前基线和验证边界；静态通过不等于真机或真实宿主通过。",
    "",
    "- 当前 podspec 版本：`#{version}`",
    "- 最新正式 Git tag：`#{latest_tag || "none"}`",
    "- 当前提交：`#{source_revision}`",
    "- 当前状态：`static_and_build_evidence_required`",
    "",
    "## 发布前仍需人工确认",
    "",
    "- [ ] PooTools-Example iOS Simulator Debug / Release",
    "- [ ] CocoaPods Core 与目标 subspec lint",
    "- [ ] 真机多 Scene、权限、媒体和导航回归",
    "- [ ] PTInstruments CPU、内存、FPS、hitch 和长会话基线",
    "- [ ] 至少一个真实宿主项目完成迁移回归",
    "",
    "证据文件应放入 `report/baselines/<version>/`，不覆盖当前报告。"
  ]
)

legacy_symbols = {
  "Network.gobalUrl" => "Network.globalURL",
  "Network.socketGobalUrl" => "Network.socketGlobalURL",
  "GobalNavControl" => "globalNavControl",
  "gobalWebImageLoadOption" => "webImageLoadOptions",
  "heightlightColor" => "highlightColor",
  "netRequsetTime" => "requestTimeout",
  "PTCoreUserDefultsWrapper" => "PTCoreUserDefaultsWrapper"
}
deprecated_rows = []
Dir.glob(File.join(repo_root, "PooToolsSource", "**", "*.swift")).sort.each do |file|
  relative = file.delete_prefix("#{repo_root}/")
  File.foreach(file).with_index do |line, index|
    legacy_symbols.each do |legacy, canonical|
      next unless line.include?(legacy)
      deprecated_rows << [relative, index + 1, legacy, canonical]
    end
    if line.include?("@available") && line.include?("deprecated")
      deprecated_rows << [relative, index + 1, "@available deprecated", "兼容入口，迁移到 MIGRATION_6.md"]
    end
  end
end

write_markdown(
  File.join(current_dir, "deprecated_api.md"),
  "Scripts/report_current_summaries.rb",
  source_revision,
  generated_at,
  [
    "# PTools 当前弃用入口清单",
    "",
    "本报告从当前源码扫描弃用属性和历史拼写；删除前必须通过 `docs/migration/MIGRATION_6.md` 的宿主回归门槛。",
    "",
    "| 位置 | 旧入口 | 推荐入口 |",
    "| --- | --- | --- |",
    *deprecated_rows.map { |path, line, legacy, canonical| "| `#{path}:#{line}` | `#{legacy}` | `#{canonical}` |" },
    ("| None | — | — |" if deprecated_rows.empty?),
    "",
    "扫描数量：`#{deprecated_rows.length}`。该数量用于发现漂移，不代表可以自动删除公开 API。"
  ].compact
)

puts "Current summaries generated in #{current_dir}"
