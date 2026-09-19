#!/usr/bin/env ruby

require "json"
require "fileutils"
require "time"

# English: Inventory potentially expensive work near UI-isolated code without pretending static text proves runtime scheduling.
# Español: Inventaría trabajo potencialmente costoso cerca de código aislado en UI sin fingir que el texto prueba el planificador real.
# 中文：盘点 UI 隔离代码附近可能较重的工作，但不把静态文本误认为真实运行时调度证明。

repo_root = File.expand_path("..", __dir__)
report_dir = File.join(repo_root, "report", "current")
FileUtils.mkdir_p(report_dir)

targets = {
  "PooToolsSource/Base/PTVideoCoverCache.swift" => %w[UIImage\(data: jpegData\( FileManager.default],
  "PooToolsSource/Category/PTVideoThumbnailService.swift" => %w[AVAssetImageGenerator loadTracks\( generator.image],
  "PooToolsSource/Core/PTLoadImageFunction.swift" => %w[UIImage\(data: Data\(contentsOf: CGImageSourceCreate],
  "PooToolsSource/NetWork/Network.swift" => %w[JSONDecoder JSONSerialization Data\(contentsOf: FileManager.default],
  "PooToolsSource/NetWork/NetworkSupport.swift" => %w[JSONDecoder JSONEncoder Data\(contentsOf: FileManager.default],
  "PooToolsSource/Base/PTCollectionView.swift" => %w[FileManager.default UIGraphicsImageRenderer UIImage\(data:],
  "PooToolsSource/Base/PTBaseViewController.swift" => %w[UIGraphicsImageRenderer FileManager.default UIImage\(data:]
}

entries = []
targets.each do |relative, patterns|
  path = File.join(repo_root, relative)
  abort "FAIL: heavy-work target is missing #{relative}" unless File.file?(path)

  lines = File.readlines(path)
  lines.each_with_index do |line, index|
    matched = patterns.find { |pattern| line.match?(Regexp.new(pattern)) }
    next unless matched

    window_start = [index - 10, 0].max
    window_end = [index + 10, lines.length - 1].min
    context = lines[window_start..window_end].join
    boundary = if context.include?("Task.detached") || context.include?("actor ")
                 "explicit-background-or-actor-boundary"
               elsif context.include?("PTVideoCoverDiskStore") || context.include?("URLSession")
                 "dedicated-system-or-disk-boundary"
               else
                 "review-required"
               end

    entries << {
      "path" => relative,
      "line" => index + 1,
      "operation" => matched,
      "classification" => boundary,
      "text" => line.strip
    }
  end
end

# English: Keep the two P2 fixes as explicit machine-checkable contracts.
# Español: Mantiene las dos correcciones P2 como contratos comprobables por máquina.
# 中文：将 P2 的两项重活修复保留为可机器校验的契约。
cover_source = File.read(File.join(repo_root, "PooToolsSource/Base/PTVideoCoverCache.swift"))
thumbnail_source = File.read(File.join(repo_root, "PooToolsSource/Category/PTVideoThumbnailService.swift"))
abort "FAIL: video cover cache does not expose detached image decode/encode" unless cover_source.include?("Task.detached") && cover_source.include?("decodeImage") && cover_source.include?("encodeJPEG")
abort "FAIL: video thumbnail generation does not expose its AVFoundation boundary" unless thumbnail_source.include?("PTVideoAssetSendableBox") && thumbnail_source.include?("generateImageOffMainActor")

payload = {
  "schema_version" => 1,
  "generator" => "Scripts/report_mainactor_heavy_work.rb",
  "source_revision" => `git -C "#{repo_root}" rev-parse HEAD`.strip,
  "generated_at" => Time.now.utc.iso8601,
  "entries" => entries,
  "review_required_count" => entries.count { |entry| entry["classification"] == "review-required" },
  "background_or_actor_count" => entries.count { |entry| entry["classification"].include?("boundary") }
}

File.write(File.join(report_dir, "mainactor_heavy_work.json"), JSON.pretty_generate(payload) + "\n")

markdown = []
markdown << "<!--"
markdown << "AUTO-GENERATED FILE."
markdown << "DO NOT EDIT MANUALLY."
markdown << ""
markdown << "Generator: #{payload["generator"]}"
markdown << "Source revision: #{payload["source_revision"]}"
markdown << "Generated at: #{payload["generated_at"]}"
markdown << "-->"
markdown << ""
markdown << "# MainActor 重活盘点"
markdown << ""
markdown << "静态报告只用于定位和复核；运行时调度仍需通过 Xcode/Instruments 和真实宿主验证。"
markdown << ""
markdown << "- 已识别并有边界：#{payload["background_or_actor_count"]}"
markdown << "- 需要人工复核：#{payload["review_required_count"]}"
markdown << ""
markdown << "| 文件 | 行号 | 操作 | 分类 | 代码 |"
markdown << "| --- | ---: | --- | --- | --- |"
entries.each do |entry|
  text = entry["text"].gsub("|", "\\|")
  markdown << "| `#{entry["path"]}` | #{entry["line"]} | `#{entry["operation"]}` | #{entry["classification"]} | `#{text}` |"
end
markdown << "| 无 | 0 | - | - | - |" if entries.empty?
File.write(File.join(report_dir, "mainactor_heavy_work.md"), markdown.join("\n") + "\n")

puts "MainActor heavy-work report: entries=#{entries.length}, review=#{payload["review_required_count"]}"
