#!/usr/bin/env ruby

require "json"
require "set"

old_path, new_path, *options = ARGV
unless old_path && new_path
  warn "Usage: compare_public_api.rb OLD.json NEW.json [--allow-removals]"
  exit 2
end

# English: Allow only removals explicitly reviewed for a release migration.
# Español: Permite solo las eliminaciones revisadas explícitamente para una migración de release.
# 中文：只允许发布迁移中明确审阅并登记的删除项。
allowlist_path = options.filter_map do |option|
  option.delete_prefix("--allow-removals-file=") if option.start_with?("--allow-removals-file=")
end.first

def entries(path)
  JSON.parse(File.read(path)).fetch("declarations", []).map do |entry|
    declaration = entry.fetch("declaration").to_s.gsub(/\s+/, " ")
    kind = entry["kind"].to_s
    signature = if kind == "class" && declaration.match?(/\bclass\s+func\b/)
                  declaration[/\bclass\s+func\s+([A-Za-z_][A-Za-z0-9_]*)/, 1] || declaration
                elsif %w[var let].include?(kind)
                  declaration[/\b(?:var|let)\s+([A-Za-z_][A-Za-z0-9_]*)/, 1] || declaration
                elsif %w[class struct enum protocol actor].include?(kind)
                  declaration[/\b#{kind}\s+([A-Za-z_][A-Za-z0-9_]*)/, 1] || declaration
                else
                  declaration.sub(/[\{;].*$/, "").strip
                end
    # English: Default argument expressions are implementation policy, not part of a Swift function signature.
    # Español: Las expresiones de argumentos predeterminados son política de implementación, no parte de la firma Swift.
    # 中文：默认参数表达式属于实现策略，不属于 Swift 方法签名，因此不参与 API 身份比较。
    if %w[func init].include?(kind)
      normalized = +signature
      parameter_depth = 0
      square_depth = 0
      brace_depth = 0
      string_delimiter = nil
      escaping = false
      removing_default = false
      rebuilt = +""
      normalized.each_char do |character|
        if string_delimiter
          rebuilt << character unless removing_default
          if escaping
            escaping = false
          elsif character == "\\"
            escaping = true
          elsif character == string_delimiter
            string_delimiter = nil
          end
          next
        end

        if removing_default
          case character
          when '"', "'"
            string_delimiter = character
          when '('
            parameter_depth += 1
          when ')'
            if parameter_depth == 1 && square_depth.zero? && brace_depth.zero?
              removing_default = false
              rebuilt << character
            else
              parameter_depth -= 1 if parameter_depth.positive?
            end
          when '['
            square_depth += 1
          when ']'
            square_depth -= 1 if square_depth.positive?
          when '{'
            brace_depth += 1
          when '}'
            brace_depth -= 1 if brace_depth.positive?
          when ','
            if parameter_depth == 1 && square_depth.zero? && brace_depth.zero?
              removing_default = false
              rebuilt << character
            end
          end
          next
        end

        case character
        when '('
          parameter_depth += 1
        when ')'
          parameter_depth -= 1 if parameter_depth.positive?
        when '['
          square_depth += 1
        when ']'
          square_depth -= 1 if square_depth.positive?
        when '{'
          brace_depth += 1
        when '}'
          brace_depth -= 1 if brace_depth.positive?
        when '"', "'"
          string_delimiter = character
        when '='
          if parameter_depth == 1 && square_depth.zero? && brace_depth.zero?
            rebuilt.rstrip!
            removing_default = true
            next
          end
        end
        rebuilt << character
      end
      signature = rebuilt.gsub(/\s+/, " ").strip
    end
    # English: A public symbol keeps its API identity when its implementation moves to another source file.
    # Español: Un símbolo público conserva su identidad de API aunque su implementación cambie de archivo fuente.
    # 中文：公开符号移动到其他源码文件时，API 身份仍由访问级别、类型和签名决定。
    [entry["access"], entry["kind"], signature].join("|")
  end.to_set
end

old_entries = entries(old_path)
new_entries = entries(new_path)

# English: Older reports stored multiline function declarations as a prefix; match that historical form without hiding real removals.
# Español: Los informes antiguos guardaban las declaraciones multilínea como prefijos; acepta ese formato histórico sin ocultar eliminaciones reales.
# 中文：旧报告会把多行函数声明保存为前缀；兼容该历史格式，但不掩盖真实删除。
def declaration_parts(entry)
  access, kind, signature = entry.split("|", 3)
  [access, kind, signature]
end

new_by_group = Hash.new { |hash, key| hash[key] = [] }
new_entries.each do |entry|
  access, kind, = declaration_parts(entry)
  new_by_group[[access, kind]] << entry
end

def covered_by_current?(entry, current_entries, current_by_group)
  return true if current_entries.include?(entry)

  access, kind, signature = declaration_parts(entry)
  return false unless %w[func init subscript].include?(kind) && (signature.end_with?(",") || signature.end_with?("("))

  current_by_group[[access, kind]].any? do |candidate|
    candidate_signature = declaration_parts(candidate)[2]
    candidate_signature.start_with?(signature)
  end
end

old_by_group = Hash.new { |hash, key| hash[key] = [] }
old_entries.each do |entry|
  access, kind, = declaration_parts(entry)
  old_by_group[[access, kind]] << entry
end

removed = old_entries.reject { |entry| covered_by_current?(entry, new_entries, new_by_group) }.sort
added = new_entries.reject { |entry| covered_by_current?(entry, old_entries, old_by_group) }.sort

puts "Public API comparison"
puts "  old=#{old_entries.length}"
puts "  new=#{new_entries.length}"
puts "  added=#{added.length}"
puts "  removed=#{removed.length}"

unless added.empty?
  puts "Added declarations:"
  added.each { |entry| puts "+ #{entry}" }
end

unless removed.empty?
  warn "Removed declarations:"
  removed.each { |entry| warn "- #{entry}" }
end

if allowlist_path
  allowlisted = File.readlines(allowlist_path, chomp: true)
    .reject { |line| line.match?(/^\s*(#|$)/) }
    .to_set
  removed_set = removed.to_set
  unexpected = removed_set - allowlisted
  stale = allowlisted - removed_set
  unless unexpected.empty? && stale.empty?
    warn "Allowlisted API removals do not match the current diff"
    warn "Unexpected removals: #{unexpected.sort.inspect}" unless unexpected.empty?
    warn "Stale allowlist entries: #{stale.sort.inspect}" unless stale.empty?
    exit 1
  end
  puts "Allowlisted removals: #{removed.length}"
end

exit 1 if !removed.empty? && !options.include?("--allow-removals") && !allowlist_path
