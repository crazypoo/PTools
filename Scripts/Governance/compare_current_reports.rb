#!/usr/bin/env ruby

# English: Compare reports after removing only nondeterministic timestamps.
# Español: Compara informes eliminando únicamente marcas de tiempo no deterministas.
# 中文：只移除非确定性时间戳后比较报告内容。

require "fileutils"
require "json"
require "tmpdir"

left, right = ARGV
abort "Usage: compare_current_reports.rb COMMITTED GENERATED" unless left && right

def canonicalize(source, destination)
  FileUtils.rm_rf(destination)
  FileUtils.mkdir_p(destination)
  Dir.glob(File.join(source, "*"), File::FNM_DOTMATCH).each do |path|
    next if [".", ".."].include?(File.basename(path))
    relative = path.delete_prefix("#{source}/")
    output = File.join(destination, relative)
    FileUtils.mkdir_p(File.dirname(output))
    if File.extname(path) == ".json"
      begin
        payload = JSON.parse(File.read(path))
        scrub = lambda do |value|
          case value
          when Hash
            value.each_with_object({}) do |(key, child), result|
              next if %w[generatedAt generated_at].include?(key)
              result[key] = scrub.call(child)
            end
          when Array
            value.map { |child| scrub.call(child) }
          else
            value
          end
        end
        File.write(output, JSON.pretty_generate(scrub.call(payload)) + "\n")
      rescue JSON::ParserError
        FileUtils.cp(path, output)
      end
    else
      content = File.read(path)
      content = content.lines.reject { |line| line.match?(/Generated at: /) }.join
      File.write(output, content)
    end
  end
end

temporary_root = Dir.mktmpdir("ptools-current-compare")
begin
  left_canonical = File.join(temporary_root, "left")
  right_canonical = File.join(temporary_root, "right")
  canonicalize(left, left_canonical)
  canonicalize(right, right_canonical)
  left_files = Dir.glob(File.join(left_canonical, "**", "*")).select { |path| File.file?(path) }
    .map { |path| path.delete_prefix("#{left_canonical}/") }
    .sort
  right_files = Dir.glob(File.join(right_canonical, "**", "*")).select { |path| File.file?(path) }
    .map { |path| path.delete_prefix("#{right_canonical}/") }
    .sort
  same_reports = left_files == right_files && left_files.all? do |relative|
    File.binread(File.join(left_canonical, relative)) == File.binread(File.join(right_canonical, relative))
  end
  unless same_reports
    missing = (left_files - right_files).map { |path| "missing generated report: #{path}" }
    extra = (right_files - left_files).map { |path| "unexpected generated report: #{path}" }
    changed = left_files & right_files
      .reject { |path| File.binread(File.join(left_canonical, path)) == File.binread(File.join(right_canonical, path)) }
      .map { |path| "changed report: #{path}" }
    abort "FAIL [CURRENT_REPORT_DRIFT]\n#{(missing + extra + changed).join("\n")}"
  end
ensure
  FileUtils.rm_rf(temporary_root)
end
