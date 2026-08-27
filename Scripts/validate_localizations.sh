#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

resource_root="$repo_root/PooToolsSource/Resource"
reference_file="$resource_root/en.lproj/Localizable.strings"
temporary_root="$(mktemp -d "${TMPDIR:-/tmp}/ptools-localizations.XXXXXX")"
trap 'rm -rf "$temporary_root"' EXIT

resource_files=("$resource_root"/*.lproj/Localizable.strings)
if [[ ! -f "$reference_file" || ! -f "${resource_files[0]}" ]]; then
    printf 'FAIL: 未找到完整的 Localizable.strings 资源\n' >&2
    exit 1
fi

extract_entries() {
    perl -ne '
        if (/^\s*"((?:\\.|[^"\\])*)"\s*=\s*"((?:\\.|[^"\\])*)"\s*;/) {
            print "$1\t$2\n";
        }
    ' "$1"
}

extract_keys() {
    extract_entries "$1" | cut -f1 | LC_ALL=C sort -u
}

extract_signatures() {
    perl -ne '
        if (/^\s*"((?:\\.|[^"\\])*)"\s*=\s*"((?:\\.|[^"\\])*)"\s*;/) {
            my ($key, $value) = ($1, $2);
            my @tokens = ($value =~ /%(?:[0-9]+\$)?[-+0-9.#*]*[hlLzjtq]*[\@aAeEfFgGdiouxXcCsSp]/g);
            print "$key\t", join(",", @tokens), "\n";
        }
    ' "$1" | LC_ALL=C sort -t $'\t' -k1,1
}

check_key_shape() {
    awk '
        /^[[:space:]]*"/ {
            line = $0
            sub(/^[[:space:]]*"/, "", line)
            if (match(line, /"[[:space:]]*=[[:space:]]*/)) {
                key = substr(line, 1, RSTART - 1)
                if (key ~ /^[[:space:]]/ || key ~ /[[:space:]]$/) {
                    print FNR ": 键名包含首尾空白: [" key "]"
                    invalid = 1
                }
                count[key] += 1
            }
        }
        END {
            for (key in count) {
                if (count[key] > 1) {
                    print "重复键: [" key "] (" count[key] " 次)"
                    invalid = 1
                }
            }
            exit invalid ? 1 : 0
        }
    ' "$1"
}

failed=0

reference_keys="$temporary_root/reference.keys"
extract_keys "$reference_file" > "$reference_keys"

for file in "${resource_files[@]}"; do
    locale="$(basename "$(dirname "$file")" .lproj)"

    if plutil -lint "$file" >/dev/null 2>&1; then
        printf 'PASS: %s 资源语法\n' "$locale"
    else
        printf 'FAIL: %s 资源语法\n' "$locale" >&2
        failed=1
    fi

    if key_issues="$(check_key_shape "$file")"; then
        :
    else
        printf 'FAIL: %s 键名检查\n%s\n' "$locale" "$key_issues" >&2
        failed=1
    fi

    locale_keys="$temporary_root/$locale.keys"
    extract_keys "$file" > "$locale_keys"
    if [[ "$locale" == "en" ]]; then
        continue
    fi

    if key_diff="$(diff -u "$reference_keys" "$locale_keys")"; then
        printf 'PASS: %s 与英文资源键集合一致\n' "$locale"
    else
        printf 'FAIL: %s 与英文资源键集合不一致\n%s\n' "$locale" "$key_diff" >&2
        failed=1
    fi
done

reference_signatures="$temporary_root/reference.signatures"
extract_signatures "$reference_file" > "$reference_signatures"
for file in "${resource_files[@]}"; do
    locale="$(basename "$(dirname "$file")" .lproj)"
    [[ "$locale" == "en" ]] && continue

    locale_signatures="$temporary_root/$locale.signatures"
    extract_signatures "$file" > "$locale_signatures"
    if signature_diff="$(diff -u "$reference_signatures" "$locale_signatures")"; then
        printf 'PASS: %s 格式占位符一致\n' "$locale"
    else
        printf 'FAIL: %s 格式占位符不一致\n%s\n' "$locale" "$signature_diff" >&2
        failed=1
    fi
done

used_keys="$temporary_root/used.keys"
{
    while IFS= read -r swift_file; do
        perl -ne '
            while (/("((?:\\.|[^"\\])*)"\s*\.\s*(?:localized|localizedFormat|localizedPlural))\b/g) {
                my $key = $2;
                $key =~ s/\\(["\\])/$1/g;
                print "$key\n";
            }
        ' "$swift_file"
    done < <(rg -l --glob '*.swift' --glob '!Pods/**' --glob '!.build/**' \
        '\.[[:space:]]*(localized|localizedFormat|localizedPlural)\b' \
        PooToolsSource PooTools 2>/dev/null || true)
} | LC_ALL=C sort -u > "$used_keys"

missing_keys="$(comm -23 "$used_keys" "$reference_keys")"
if [[ -n "$missing_keys" ]]; then
    printf 'FAIL: 代码引用了英文资源中不存在的本地化键:\n%s\n' "$missing_keys" >&2
    failed=1
else
    printf 'PASS: 代码中的字面量本地化键均已登记\n'
fi

zh_hans_entries="$temporary_root/zh-Hans.entries"
zh_hant_entries="$temporary_root/zh-Hant.entries"
extract_entries "$resource_root/zh-Hans.lproj/Localizable.strings" | LC_ALL=C sort > "$zh_hans_entries"
extract_entries "$resource_root/zh-Hant.lproj/Localizable.strings" | LC_ALL=C sort > "$zh_hant_entries"
identical_count="$(comm -12 "$zh_hans_entries" "$zh_hant_entries" | wc -l | tr -d ' ')"
total_count="$(wc -l < "$zh_hans_entries" | tr -d ' ')"
printf 'WARN: zh-Hant 与 zh-Hans 有 %s/%s 条翻译值相同；本轮只报告，不自动改译\n' "$identical_count" "$total_count"

if (( failed != 0 )); then
    exit 1
fi

printf 'PASS: 本地化资源质量检查完成\n'
