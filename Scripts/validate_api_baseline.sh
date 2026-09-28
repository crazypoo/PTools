#!/usr/bin/env bash

set -euo pipefail

# English: Compare the current public API against the latest formal release baseline and reviewed migrations.
# Español: Compara la API pública actual con la línea base formal y las migraciones revisadas.
# 中文：将当前公开 API 与最新正式版本基线及已审阅迁移进行比较。

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

version="$(tr -d '[:space:]' < VERSION)"

# English: Ignore malformed or future tags so a development release is compared with a real prior baseline.
# Español: Ignora etiquetas inválidas o futuras para comparar con una línea base anterior real.
# 中文：忽略异常或高于当前版本的标签，避免开发版本被错误的未来标签污染。
latest_tag="$(ruby - "$version" <<'RUBY'
require "rubygems"
require "open3"

version = Gem::Version.new(ARGV.fetch(0))
tags = IO.popen(["git", "tag", "--list"], &:read).lines(chomp: true)
  .select { |tag| tag.match?(%r{\A\d+\.\d+\.\d+\z}) }
  .select { |tag| Gem::Version.new(tag) <= version }
  .select do |tag|
    # English: Ignore tags whose embedded VERSION disagrees with the tag name.
    # Español: Ignora etiquetas cuyo VERSION interno no coincide con el nombre.
    # 中文：忽略标签名与标签内部 VERSION 不一致的异常标签。
    begin
      content, status = Open3.capture2e("git", "show", "#{tag}:VERSION")
      status.success? && content.strip == tag
    rescue SystemCallError
      false
    end
  end
puts(tags.max_by { |tag| Gem::Version.new(tag) } || "")
RUBY
)"
[[ -n "$latest_tag" ]] || { printf 'FAIL: no semantic release tag is available\n' >&2; exit 1; }

baseline_tag="$(ruby - "$repo_root" <<'RUBY'
require "rubygems"

repo_root = ARGV.fetch(0)
current_version = Gem::Version.new(File.read(File.join(repo_root, "VERSION")).strip)
tags = IO.popen(["git", "-C", repo_root, "tag", "--list"], &:read)
  .lines(chomp: true)
  .select { |tag| tag.match?(%r{\A\d+\.\d+\.\d+\z}) }
  .select { |tag| Gem::Version.new(tag) <= current_version }
available = tags.select do |tag|
  File.file?(File.join(repo_root, "api-baseline", tag, "public_api.json"))
end
puts(available.max_by { |tag| Gem::Version.new(tag) } || "")
RUBY
)"
[[ -n "$baseline_tag" ]] || { printf 'FAIL: no API baseline is available\n' >&2; exit 1; }
baseline="api-baseline/$baseline_tag/public_api.json"
if [[ "$baseline_tag" != "$latest_tag" ]]; then
  printf 'INFO: API baseline for latest tag %s is not frozen; using latest available baseline %s\n' "$latest_tag" "$baseline_tag"
fi
[[ -f report/current/public_api.json ]] || { printf 'FAIL: current API report is missing\n' >&2; exit 1; }

comparison="$(mktemp)"
trap 'rm -f "$comparison"' EXIT
removal_allowlist="api-baseline/removals_${version}.txt"
comparison_args=("$baseline" "report/current/public_api.json")
if [[ -f "$removal_allowlist" ]]; then
  comparison_args+=("--allow-removals-file=$removal_allowlist")
fi
if ruby Scripts/compare_public_api.rb "${comparison_args[@]}" >"$comparison" 2>&1; then
  cat "$comparison"
else
  cat "$comparison"
  printf 'FAIL: public API removals or breaking signature changes detected\n' >&2
  exit 1
fi

printf 'PASS: public API baseline compared against %s\n' "$latest_tag"
