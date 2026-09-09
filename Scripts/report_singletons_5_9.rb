#!/usr/bin/env ruby

require "json"
require "fileutils"

repo_root = File.expand_path("..", __dir__)
source_root = File.join(repo_root, "PooToolsSource")
report_dir = File.join(repo_root, "report")
FileUtils.mkdir_p(report_dir)

entries = []
shared_calls = 0

def singleton_classification(path, declaration)
  text = "#{path} #{declaration}"

  if text.match?(/Alert|NavigationBar|LocalConsole|ResizeController|ColorPick|ViewRuler|BasePicker|DarkModeSchedule|StatusBarManager|Rotation|LaunchVisualizer|LaunchProfiler|ThemeProvider|TabBar|PTAppBaseConfig|LaunchAdMonitor|MediaLibConfig|ImageEditorConfig|Camera.*Config|HudConfig|BannerScheduler/)
    return ["D", "Shared mutable UI or scene state", "按 Scene 或控制器实例保存；保留兼容入口"]
  end

  if text.match?(/Cache|cache|Cover|AudioService|ImageCache|NetworkCache/)
    return ["B", "Thread-safe shared cache or resource", "保留共享入口，但必须有容量、过期和清理策略"]
  end

  if text.match?(/PTUtils|PTAdapterConfig|PTApplicationDirectories|PTFileBrowser|PTProtocol/)
    return ["A", "Stateless convenience or immutable utility", "优先保留；有可变状态时迁移为实例配置"]
  end

  ["C", "Shared mutable service", "提供可实例化入口，shared/share 仅作为默认兼容入口"]
end

Dir.glob(File.join(source_root, "**", "*.swift")).sort.each do |file|
  relative = file.delete_prefix("#{repo_root}/")
  File.foreach(file).with_index do |line, index|
    shared_calls += line.scan(/\.(?:shared|share)\b/).length
    next unless line.match?(/\bstatic\s+(?:let|var)\s+(?:shared|share)\b/)
    category, scope, action = singleton_classification(relative, line.strip)
    entries << {
      "path" => relative,
      "line" => index + 1,
      "declaration" => line.strip,
      "name" => line.match(/\bstatic\s+(?:let|var)\s+(shared|share)\b/)[1],
      "category" => category,
      "scope" => scope,
      "action" => action
    }
  end
end

payload = {
  "schema_version" => 2,
  "shared_call_count" => shared_calls,
  "declarations" => entries
}
File.write(File.join(report_dir, "singletons_5_9.json"), JSON.pretty_generate(payload) + "\n")

markdown = []
markdown << "# PTools 5.9.x 单例范围盘点"
markdown << ""
markdown << "本报告用于后续 DI 迁移；它不会自动改变现有单例生命周期。"
markdown << ""
markdown << "- .shared / .share 调用文本计数：**#{shared_calls}**"
markdown << "- 单例声明计数：**#{entries.length}**"
markdown << ""
markdown << "| 位置 | 名称 | 分类 | 声明 | 迁移建议 |"
markdown << "| --- | --- | --- | --- | --- |"
entries.each do |entry|
  declaration = entry["declaration"].gsub("|", "\\|")
  scope = entry["scope"].gsub("|", "\\|")
  action = entry["action"].gsub("|", "\\|")
  markdown << "| #{entry["path"]}:#{entry["line"]} | #{entry["name"]} | #{entry["category"]} #{scope} | #{declaration} | #{action} |"
end
File.write(File.join(report_dir, "singletons_5_9.md"), markdown.join("\n") + "\n")
puts "Singleton 5.9 report: declarations=#{entries.length}, shared_calls=#{shared_calls}"
