#!/usr/bin/env ruby

# English: Hash only source and governance inputs, never generated current reports.
# Español: Hashea solo las entradas de código y gobernanza, nunca los informes generados.
# 中文：只对源码和治理输入生成摘要，绝不把生成的 current 报告纳入摘要。

require "digest"

repo_root = File.expand_path("../..", __dir__)

patterns = [
  "PooToolsSource/**/*",
  "Package.swift",
  "PooTools.podspec",
  "VERSION",
  "Scripts/**/*"
]

excluded_prefixes = [
  "Scripts/.build/",
  "Scripts/tmp/"
]

paths = patterns.flat_map do |pattern|
  Dir.glob(File.join(repo_root, pattern))
end.select do |path|
  File.file?(path)
end.map do |path|
  path.delete_prefix("#{repo_root}/")
end.uniq.sort.reject do |relative|
  relative.start_with?("report/") || excluded_prefixes.any? { |prefix| relative.start_with?(prefix) }
end

digest = Digest::SHA256.new
paths.each do |relative|
  digest.update(relative)
  digest.update("\0")
  digest.update(File.binread(File.join(repo_root, relative)))
  digest.update("\0")
end

puts digest.hexdigest
