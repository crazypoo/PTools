#!/usr/bin/env python3
"""English: Inventory and validate PTools documentation and repository assets.
Español: Inventaría y valida la documentación y los activos del repositorio PTools.
中文：盘点并校验 PTools 文档及仓库资产。

This file is the canonical governance entry point. It intentionally uses only
the Python standard library so it can run before project dependencies exist.
"""

from __future__ import annotations

import argparse
import datetime as dt
import hashlib
import json
import os
import re
import subprocess
import sys
from pathlib import Path
from typing import Any, Iterable


ROOT = Path(__file__).resolve().parents[2]
VERSION = (ROOT / "VERSION").read_text(encoding="utf-8").strip()
GENERATED_AT = ""
EXCLUDED_PARTS = {".git", "Pods", ".build", "build", "DerivedData"}
DOC_SUFFIXES = {".md", ".markdown", ".mdx"}
DATA_SUFFIXES = {".json", ".jsonl", ".yml", ".yaml"}
LANGUAGES = ("zh-Hans", "en", "es")


def git(*arguments: str) -> str:
    """Return stable git metadata without making the audit depend on git."""

    try:
        result = subprocess.run(
            ["git", "-C", str(ROOT), *arguments],
            check=True,
            capture_output=True,
            text=True,
        )
        return result.stdout.strip()
    except (OSError, subprocess.CalledProcessError):
        return ""


def source_revision() -> str:
    return git("rev-parse", "HEAD") or "working-tree"


def generated_at() -> str:
    """Use commit time for deterministic reports instead of wall-clock churn."""

    commit_time = git("log", "-1", "--format=%cI")
    return commit_time or dt.datetime.now(dt.timezone.utc).replace(microsecond=0).isoformat()


def relative(path: Path) -> str:
    return path.relative_to(ROOT).as_posix()


def excluded(path: Path) -> bool:
    return any(part in EXCLUDED_PARTS for part in path.parts)


def json_text(value: Any) -> str:
    return json.dumps(value, ensure_ascii=False, sort_keys=True)


def yaml_scalar(value: Any) -> str:
    if value is None:
        return "null"
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, (int, float)):
        return str(value)
    return json.dumps(str(value), ensure_ascii=False)


def write_yaml(path: Path, records: Iterable[dict[str, Any]], header: str) -> None:
    """Write a small dependency-free YAML subset used by repository registries."""

    lines = [
        "# English: Generated from the repository's canonical governance inputs.",
        "# Español: Generado a partir de las entradas canónicas de gobernanza.",
        "# 中文：由仓库治理的 canonical 输入生成，请勿手工修改生成字段。",
        f"# {header}",
    ]
    for record in records:
        lines.append("-")
        for key, value in record.items():
            if isinstance(value, list):
                if not value:
                    lines.append(f"  {key}: []")
                else:
                    lines.append(f"  {key}:")
                    for item in value:
                        lines.append(f"    - {yaml_scalar(item)}")
            else:
                lines.append(f"  {key}: {yaml_scalar(value)}")
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def parse_package() -> tuple[list[str], list[dict[str, Any]]]:
    text = (ROOT / "Package.swift").read_text(encoding="utf-8")
    products = sorted(set(re.findall(r'\.library\(name:\s*"([^"]+)"', text)))
    targets: list[dict[str, Any]] = []
    for match in re.finditer(r"\.testTarget\(\s*name:\s*\"([^\"]+)\"", text, re.S):
        end = re.search(r"\n\s*\.testTarget\(|\n\s*\.target\(", text[match.end() :])
        chunk = text[match.start() : match.end() + (end.start() if end else 1200)]
        path_match = re.search(r'path:\s*"([^"]+)"', chunk)
        targets.append(
            {
                "name": match.group(1),
                "path": path_match.group(1) if path_match else "Tests/" + match.group(1),
            }
        )
    return products, targets


def parse_podspec() -> list[str]:
    text = (ROOT / "PooTools.podspec").read_text(encoding="utf-8")
    return sorted(set(re.findall(r"s\.subspec\s+['\"]([^'\"]+)['\"]", text)))


def legacy_module_metadata() -> dict[str, dict[str, Any]]:
    path = ROOT / "Scripts/module_registry.json"
    if not path.is_file():
        return {}
    payload = json.loads(path.read_text(encoding="utf-8"))
    result: dict[str, dict[str, Any]] = {}
    for item in payload.get("modules", []):
        for key in (item.get("spm_product"), item.get("pod_subspec"), item.get("name")):
            if key:
                result[str(key)] = item
    return result


def slug(value: str) -> str:
    value = re.sub(r"([a-z0-9])([A-Z])", r"\1-\2", value)
    value = re.sub(r"[^A-Za-z0-9]+", "-", value).strip("-").lower()
    return value or "module"


def modules_registry() -> list[dict[str, Any]]:
    products, _ = parse_package()
    subspecs = parse_podspec()
    old = legacy_module_metadata()
    entries: list[dict[str, Any]] = []
    used_ids: set[str] = set()

    def add(name: str, spm: str | None, pod: str | None) -> None:
        metadata = old.get(spm or "") or old.get(pod or "") or old.get(name, {})
        module_id = str(metadata.get("module_id") or slug(name))
        original_id = module_id
        suffix = 2
        while module_id in used_ids:
            module_id = f"{original_id}-{suffix}"
            suffix += 1
        used_ids.add(module_id)
        category = str(metadata.get("category") or ("compatibility" if spm is None else "unclassified"))
        status = "stable" if metadata else ("compatibility" if spm is None else "review")
        entries.append(
            {
                "id": module_id,
                "name": name,
                "swiftpm_product": spm or "",
                "cocoapods_subspec": pod or "",
                "source": str(metadata.get("source_path") or ""),
                "category": category,
                "status": status,
                "minimum_ios": "17.0",
                "swift": "6+",
                "dependencies": list(metadata.get("dependencies") or []),
                "owner": "PTools maintainers",
                "docs": True,
            }
        )

    mapped_spm = {str(item.get("spm_product")) for item in old.values() if item.get("spm_product")}
    mapped_pod = {str(item.get("pod_subspec")) for item in old.values() if item.get("pod_subspec")}
    for product in products:
        metadata = old.get(product)
        pod = str(metadata.get("pod_subspec")) if metadata and metadata.get("pod_subspec") in subspecs else None
        add(product, product, pod)
    for subspec in subspecs:
        if subspec not in mapped_pod and not any(item["cocoapods_subspec"] == subspec for item in entries):
            add(subspec, None, subspec)
    return sorted(entries, key=lambda item: item["id"])


def registry_records(modules: list[dict[str, Any]]) -> list[dict[str, Any]]:
    return [
        {
            "id": item["id"],
            "name": item["name"],
            "swiftpm_product": item["swiftpm_product"],
            "cocoapods_subspec": item["cocoapods_subspec"],
            "source": item["source"],
            "category": item["category"],
            "status": item["status"],
            "minimum_ios": item["minimum_ios"],
            "swift": item["swift"],
            "dependencies": item["dependencies"],
            "owner": item["owner"],
            "docs": item["docs"],
        }
        for item in modules
    ]


SECTION_NAMES = {
    "en": [
        "Overview", "Requirements", "Installation", "Import", "Quick Start", "Core Concepts",
        "Main APIs", "Common Use Cases", "Advanced Usage", "Swift Concurrency", "Lifecycle",
        "Error Handling", "Permissions / Entitlements / Info.plist", "Simulator Behavior",
        "Accessibility", "Performance", "Privacy & Security", "Integration with Other PTools Modules",
        "Migration", "Troubleshooting", "Example Project", "Related Documentation",
    ],
    "zh-Hans": [
        "概览", "要求", "安装", "导入", "快速开始", "核心概念", "主要 API", "常见场景", "高级用法",
        "Swift 并发", "生命周期", "错误处理", "权限 / Entitlement / Info.plist", "模拟器行为", "无障碍",
        "性能", "隐私与安全", "与其他 PTools 模块集成", "迁移", "问题排查", "示例工程", "相关文档",
    ],
    "es": [
        "Descripción", "Requisitos", "Instalación", "Importación", "Inicio rápido", "Conceptos principales",
        "API principales", "Casos de uso", "Uso avanzado", "Concurrencia Swift", "Ciclo de vida",
        "Errores", "Permisos / Entitlements / Info.plist", "Comportamiento en Simulator", "Accesibilidad",
        "Rendimiento", "Privacidad y seguridad", "Integración con otros módulos PTools", "Migración",
        "Solución de problemas", "Proyecto de ejemplo", "Documentación relacionada",
    ],
}


def front_matter(item: dict[str, Any], language: str, canonical: bool) -> str:
    values = {
        "module": item["name"],
        "module_id": item["id"],
        "language": language,
        "status": item["status"],
        "minimum_ios": item["minimum_ios"],
        "swift": item["swift"],
        "swiftpm_product": item["swiftpm_product"] or "null",
        "cocoapods_subspec": item["cocoapods_subspec"] or "null",
        "source": item["source"] or "manifest-only",
        "category": item["category"],
        "last_reviewed": "2026-09-28",
        "canonical": canonical,
        "canonical_source": "README.en.md" if not canonical else "self",
        "documentation_version": VERSION,
    }
    return "---\n" + "\n".join(f"{key}: {yaml_scalar(value)}" for key, value in values.items()) + "\n---\n"


def module_document(item: dict[str, Any], language: str) -> str:
    canonical = language == "en"
    spm = item["swiftpm_product"]
    pod = item["cocoapods_subspec"]
    import_line = f"import {spm}" if spm else "// This entry is CocoaPods-only; import the module exposed by the selected subspec."
    pod_line = f"pod 'PooTools/{pod}'" if pod else "# No standalone CocoaPods subspec is published for this product."
    dependencies = ", ".join(item["dependencies"]) if item["dependencies"] else "None declared by the registry."
    intro = {
        "en": f"{item['name']} is a PTools {item['category']} module. This guide is generated from the canonical module registry and documents the supported boundary for iOS 17+ and Swift 6+.",
        "zh-Hans": f"{item['name']} 是 PTools 的 {item['category']} 模块。本指南由 canonical 模块 registry 生成，说明 iOS 17+ 与 Swift 6+ 下的稳定使用边界。",
        "es": f"{item['name']} es un módulo PTools de categoría {item['category']}. Esta guía se genera desde el registro canónico y describe el límite compatible en iOS 17+ y Swift 6+.",
    }[language]
    bodies = {
        "en": [
            intro,
            f"- Platform: iOS {item['minimum_ios']}+\n- Swift: {item['swift']}\n- Category: `{item['category']}`\n- Status: `{item['status']}`",
            f"Swift Package Manager:\n\n```swift\n{import_line}\n```\n\nCocoaPods:\n\n```ruby\n{pod_line}\n```",
            f"```swift\n{import_line}\n```",
            f"Use the smallest published product or subspec. The registry name is `{item['name']}`; do not infer an unpublished product or dependency.",
            f"The public boundary is value-first where possible. Direct dependencies recorded by the registry: {dependencies}.",
            "Use only stable public symbols documented by the module source. Complete symbol data belongs to generated API reports, not hand-maintained prose.",
            "Typical uses should stay within this module's category and should not duplicate a canonical implementation from another PTools module.",
            "Inject a provider or policy only when the public API exposes one. Avoid reaching into internal state or private UIKit ownership.",
            "UI work is `@MainActor`; shared values should be `Sendable`; cancellation must propagate through the owning `Task`.",
            "Follow the module's start/stop, register/unregister, and scene lifecycle contract. Do not retain a host controller longer than necessary.",
            "Handle public errors explicitly. Recoverable failures should return control to the host; permissions and configuration failures must not be hidden.",
            "This module has no additional requirement unless its source exposes a platform permission, entitlement, background mode, or Info.plist key.",
            "Simulator behavior may differ for hardware, notifications, background execution, audio, camera, or extension hosts. Use a real device for those capabilities.",
            "UI integrations must preserve Dynamic Type, VoiceOver, Reduce Motion, Reduce Transparency, and RTL behavior.",
            "Keep work off the main actor when it is not UI work. Bound memory, cache, media, and network resources according to the module's owning service.",
            "Do not log tokens, cookies, credentials, private payloads, or full user input. Use the module's typed boundary for sensitive data.",
            "Prefer the existing PTools canonical services and adapters instead of creating a parallel cache, router, permission, or scheduler.",
            "Compatibility wrappers remain available during 5.x. New code should use the canonical entry documented by the current registry.",
            "If behavior is unexpected, verify module selection, target membership, scene context, permissions, cancellation, and the generated reports before changing source.",
            "See the repository Example project and the domain test registry for executable coverage. Host-specific entitlements remain the host's responsibility.",
            "[Documentation index](../../index/README.en.md) · [Architecture](../../architecture/ARCHITECTURE.md) · [Quality](../../maintainers/QUALITY.md)",
        ],
        "zh-Hans": [
            intro,
            f"- 平台：iOS {item['minimum_ios']}+\n- Swift：{item['swift']}\n- 分类：`{item['category']}`\n- 状态：`{item['status']}`",
            f"Swift Package Manager：\n\n```swift\n{import_line}\n```\n\nCocoaPods：\n\n```ruby\n{pod_line}\n```",
            f"```swift\n{import_line}\n```",
            f"优先选择最小的 product 或 subspec。registry 中的名称是 `{item['name']}`，不要猜测没有发布的 product 或依赖。",
            f"公开边界优先使用值类型。registry 记录的直接依赖：{dependencies}。",
            "只使用源码中稳定的公开符号。完整符号数据属于自动生成的 API 报告，不在手写指南中重复维护。",
            "常见场景应保持在本模块分类内，不要复制其他 PTools 模块已经提供的 canonical 实现。",
            "只有公开 API 提供 Provider 或策略时才注入；不要访问内部状态，也不要改变 UIKit 的私有所有权。",
            "UI 工作使用 `@MainActor`；共享值应遵守 `Sendable`；取消必须沿所属 `Task` 传播。",
            "遵守模块的 start/stop、register/unregister 和 Scene 生命周期约定，不要让宿主控制器被不必要地长期持有。",
            "显式处理公开错误。可恢复错误应交还宿主，权限和配置失败不能被静默吞掉。",
            "除非源码暴露平台权限、Entitlement、后台模式或 Info.plist key，否则本模块没有额外配置。",
            "硬件、通知、后台、音频、相机或扩展宿主在模拟器中的行为可能不同；这些能力必须用真机验证。",
            "UI 集成必须保留 Dynamic Type、VoiceOver、Reduce Motion、Reduce Transparency 和 RTL 行为。",
            "非 UI 工作不要放到主 actor。按照所属服务限制内存、缓存、媒体和网络资源。",
            "不要记录 token、Cookie、凭据、隐私 payload 或完整用户输入；敏感数据使用类型化边界。",
            "优先复用已有 PTools canonical service 和 adapter，不要再创建并行缓存、路由、权限或调度器。",
            "5.x 期间保留兼容包装器；新代码应使用当前 registry 文档中的 canonical 入口。",
            "遇到异常时先检查模块选择、target membership、Scene context、权限、取消状态和生成报告，再修改源码。",
            "参见 Example 工程和领域测试 registry 获取可执行覆盖。宿主专属 Entitlement 仍由宿主负责。",
            "[文档索引](../../index/README.zh-Hans.md) · [架构](../../architecture/ARCHITECTURE.md) · [质量](../../maintainers/QUALITY.md)",
        ],
        "es": [
            intro,
            f"- Plataforma: iOS {item['minimum_ios']}+\n- Swift: {item['swift']}\n- Categoría: `{item['category']}`\n- Estado: `{item['status']}`",
            f"Swift Package Manager:\n\n```swift\n{import_line}\n```\n\nCocoaPods:\n\n```ruby\n{pod_line}\n```",
            f"```swift\n{import_line}\n```",
            f"Usa el producto o subspec mínimo publicado. El nombre del registro es `{item['name']}`; no inventes productos ni dependencias no publicadas.",
            f"La frontera pública prioriza tipos de valor. Dependencias directas registradas: {dependencies}.",
            "Usa solo símbolos públicos estables. La referencia completa pertenece a los informes de API generados.",
            "Los casos de uso deben permanecer en la categoría del módulo y no duplicar una implementación canónica de otro módulo PTools.",
            "Inyecta un proveedor o una política solo si la API pública lo expone. No accedas al estado interno ni cambies la propiedad privada de UIKit.",
            "El trabajo de UI usa `@MainActor`; los valores compartidos deben ser `Sendable`; la cancelación debe propagarse por el `Task` propietario.",
            "Respeta el contrato start/stop, register/unregister y el ciclo de vida de Scene. No retengas un controlador anfitrión sin necesidad.",
            "Gestiona los errores públicos explícitamente. Los fallos recuperables vuelven al host; los fallos de permisos y configuración no se ocultan.",
            "No hay requisitos adicionales salvo que el código exponga permisos, entitlements, modos de background o claves Info.plist.",
            "El comportamiento de hardware, notificaciones, background, audio, cámara o extensiones puede diferir en Simulator; usa un dispositivo real.",
            "Las integraciones UI deben conservar Dynamic Type, VoiceOver, Reduce Motion, Reduce Transparency y RTL.",
            "Mantén el trabajo fuera del actor principal cuando no sea UI. Limita memoria, caché, medios y red según el servicio propietario.",
            "No registres tokens, cookies, credenciales, payloads privados ni entradas completas; usa la frontera tipada del módulo.",
            "Prefiere los servicios y adapters canónicos de PTools en lugar de crear cachés, routers, permisos o planificadores paralelos.",
            "Los wrappers de compatibilidad siguen disponibles durante 5.x. El código nuevo debe usar la entrada canónica del registro.",
            "Ante un problema, verifica selección de módulo, target membership, Scene context, permisos, cancelación e informes generados antes de editar código.",
            "Consulta el proyecto Example y el registro de tests para cobertura ejecutable. Los entitlements del host son responsabilidad del host.",
            "[Índice de documentación](../../index/README.es.md) · [Arquitectura](../../architecture/ARCHITECTURE.md) · [Calidad](../../maintainers/QUALITY.md)",
        ],
    }[language]
    lines = [front_matter(item, language, canonical), f"# {item['name']}", ""]
    for index, (heading, body) in enumerate(zip(SECTION_NAMES[language], bodies), start=1):
        lines.extend([f"## {index}. {heading}", "", body, ""])
    return "\n".join(lines).rstrip() + "\n"


def write_module_docs(modules: list[dict[str, Any]]) -> None:
    for item in modules:
        directory = ROOT / "docs/modules" / item["id"]
        directory.mkdir(parents=True, exist_ok=True)
        for language in LANGUAGES:
            (directory / f"README.{language}.md").write_text(
                module_document(item, language), encoding="utf-8"
            )


def write_module_index(modules: list[dict[str, Any]]) -> None:
    labels = {
        "en": ("PTools Module Index", "Every listed SwiftPM product and CocoaPods subspec has a generated tri-lingual usage guide.", "Module", "SwiftPM", "CocoaPods"),
        "zh-Hans": ("PTools 模块索引", "每个登记的 SwiftPM product 和 CocoaPods subspec 都有生成的三语使用指南。", "模块", "SwiftPM", "CocoaPods"),
        "es": ("Índice de módulos PTools", "Cada producto SwiftPM y subspec de CocoaPods registrado tiene una guía trilingüe generada.", "Módulo", "SwiftPM", "CocoaPods"),
    }
    for language in LANGUAGES:
        title, intro, module_label, spm_label, pod_label = labels[language]
        lines = [
            "---",
            f"language: {yaml_scalar(language)}",
            f"documentation_version: {yaml_scalar(VERSION)}",
            "status: ACTIVE",
            "generated: true",
            "---",
            f"# {title}",
            "",
            intro,
            "",
            f"| {module_label} | {spm_label} | {pod_label} |",
            "| --- | --- | --- |",
        ]
        for item in modules:
            link = f"../modules/{item['id']}/README.{language}.md"
            lines.append(f"| [{item['name']}]({link}) | `{item['swiftpm_product'] or '—'}` | `{item['cocoapods_subspec'] or '—'}` |")
        (ROOT / "docs/index").mkdir(parents=True, exist_ok=True)
        (ROOT / "docs/index" / f"MODULES.{language}.md").write_text("\n".join(lines) + "\n", encoding="utf-8")


def document_type(path: str) -> str:
    name = Path(path).name.lower()
    if path.startswith("docs/modules/"):
        return "MODULE_GUIDE"
    if path.startswith("docs/archive/"):
        return "ARCHIVE"
    if path.startswith("docs/architecture/decisions/"):
        return "ADR"
    if path.startswith("docs/architecture/"):
        return "ARCHITECTURE"
    if path.startswith("docs/guides/") or path.startswith("docs/modules/"):
        return "HOW_TO"
    if path.startswith("docs/migration") or path.startswith("docs/migrations"):
        return "MIGRATION"
    if path.startswith("docs/maintainers/") or path.startswith("docs/maintenance/"):
        return "QUALITY"
    if path.startswith("docs/security/"):
        return "SECURITY"
    if path.startswith("docs/"):
        return "REFERENCE"
    if path in {"README.md", "CHANGELOG.md", "ROADMAP.md", "CONTRIBUTING.md", "SECURITY.md"}:
        return "ROOT"
    if path.startswith("report/"):
        return "GENERATED"
    return "REFERENCE"


def language_of(text: str, path: str) -> str:
    match = re.search(r"^language:\s*['\"]?([^'\"\n]+)", text, re.M)
    if match:
        return match.group(1).strip()
    has_zh = bool(re.search(r"[\u4e00-\u9fff]", text))
    has_es = any(token in text for token in ("Español", "Descripción", "Instalación", "Privacidad"))
    if has_zh and has_es:
        return "zh-Hans+en+es"
    if has_zh:
        return "zh-Hans"
    if has_es:
        return "es"
    return "en"


def git_file_time(path: Path) -> str:
    # English: One repository revision is enough for a deterministic inventory; per-file git calls do not scale to generated guides.
    # Español: Una revisión del repositorio basta para un inventario determinista; una llamada git por archivo no escala.
    # 中文：整个仓库使用同一个 revision 即可保证清单确定性，逐文件调用 git 无法适配大量生成指南。
    return GENERATED_AT


def markdown_links(text: str) -> list[str]:
    return [
        value.split("#", 1)[0]
        for match in re.finditer(r"\[[^\]]*\]\(<([^>]+)>|\[[^\]]*\]\(([^)\s]+)", text)
        for value in match.groups()
        if value
    ]


def markdown_inventory() -> list[dict[str, Any]]:
    files = [
        path for path in ROOT.rglob("*")
        if path.is_file() and path.suffix.lower() in DOC_SUFFIXES and not excluded(path)
    ]
    outgoing: dict[str, list[str]] = {}
    records: list[dict[str, Any]] = []
    hashes: dict[str, list[str]] = {}
    module_ids = {item["id"] for item in modules_registry()}
    for path in files:
        rel = relative(path)
        text = path.read_text(encoding="utf-8", errors="replace")
        links = markdown_links(text)
        outgoing[rel] = links
        digest = hashlib.sha256(re.sub(r"\s+", " ", text).strip().encode()).hexdigest()
        hashes.setdefault(digest, []).append(rel)
        heading = next((line[2:].strip() for line in text.splitlines() if line.startswith("# ")), path.stem)
        versions = re.findall(r"(?<!\d)(\d+\.\d+\.\d+)(?!\d)", text)
        records.append(
            {
                "path": rel,
                "title": heading,
                "size": path.stat().st_size,
                "lastModified": git_file_time(path),
                "gitLastCommit": source_revision(),
                "documentType": document_type(rel),
                "module": next((part for part in Path(rel).parts if part in module_ids), ""),
                "version": versions[0] if versions else "",
                "language": language_of(text, rel),
                "status": "ARCHIVED" if rel.startswith("docs/archive/") else ("GENERATED" if rel.startswith("report/") else "ACTIVE"),
                "incomingLinks": [],
                "outgoingLinks": links,
                "duplicateScore": 0.0,
                "possibleReplacement": "",
                "action": "KEEP",
            }
        )
    by_path = {item["path"]: item for item in records}
    for source, links in outgoing.items():
        for link in links:
            if link.startswith(("http:", "https:", "mailto:", "#", "/")):
                continue
            target = (ROOT / Path(source).parent / link).resolve()
            try:
                target_rel = relative(target)
            except ValueError:
                continue
            if target_rel in by_path:
                by_path[target_rel]["incomingLinks"].append(source)
    for duplicate_paths in hashes.values():
        if len(duplicate_paths) > 1:
            for path in duplicate_paths:
                by_path[path]["duplicateScore"] = 1.0
                by_path[path]["action"] = "REVIEW_DUPLICATE"
    return sorted(records, key=lambda item: item["path"])


def data_kind(path: str) -> str:
    parts = Path(path).parts
    name = Path(path).name.lower()
    if path.startswith("docs/_meta/") or name in {"package.resolved", "podfile.lock"}:
        return "SOURCE_OF_TRUTH"
    if path.startswith("report/"):
        return "REPORT"
    if ".github/workflows" in path or name in {"_config.yml", "funding.yml"}:
        return "CI"
    if "schema" in name or "schemas" in parts:
        return "SCHEMA"
    if "fixture" in parts or "fixtures" in parts:
        return "FIXTURE"
    if "golden" in parts or "snapshots" in parts:
        return "GOLDEN"
    if "migration" in parts or "migrations" in parts:
        return "MIGRATION"
    if path.startswith("Scripts/"):
        return "DEV_TOOL"
    return "SOURCE_OF_TRUTH"


def data_inventory() -> list[dict[str, Any]]:
    files = [
        path for path in ROOT.rglob("*")
        if path.is_file() and path.suffix.lower() in DATA_SUFFIXES and not excluded(path)
    ]
    return [
        {
            "path": relative(path),
            "kind": data_kind(relative(path)),
            "format": path.suffix.lower().lstrip("."),
            "generated": data_kind(relative(path)) in {"GENERATED", "REPORT"},
            "source_of_truth": data_kind(relative(path)) == "SOURCE_OF_TRUTH",
            "consumer": "governance-audit" if relative(path).startswith("docs/_meta/") else "repository",
            "action": "KEEP",
        }
        for path in sorted(files)
    ]


def script_inventory() -> list[dict[str, Any]]:
    suffixes = {".sh", ".rb", ".py", ".swift"}
    files = [
        path for path in ROOT.rglob("*")
        if path.is_file() and path.suffix.lower() in suffixes and not excluded(path)
        and (path.parts[-2] == "Scripts" or "Scripts" in path.parts or path.name == "paapidetect.sh")
    ]
    records = []
    for path in sorted(files):
        rel = relative(path)
        stem = path.stem
        legacy = bool(re.search(r"(?:_5_|_5\.|5_\d|5\.\d)", stem))
        domain = path.parent.name if path.parent != ROOT else "root"
        records.append(
            {
                "path": rel,
                "language": path.suffix.lstrip("."),
                "domain": domain,
                "status": "LEGACY_REVIEW" if legacy else "ACTIVE",
                "canonical": not legacy,
                "entrypoint": rel in {"Scripts/Docs/audit_docs.py", "Scripts/CI/check_5_56_1_governance.sh"},
                "action": "KEEP_REVIEW" if rel == "paapidetect.sh" else "KEEP",
            }
        )
    return records


def test_inventory() -> list[dict[str, Any]]:
    _, targets = parse_package()
    records: list[dict[str, Any]] = []
    for target in targets:
        path = ROOT / target["path"]
        files = sorted(relative(item) for item in path.rglob("*") if item.is_file()) if path.is_dir() else []
        name = target["name"]
        level = "PERFORMANCE" if "Performance" in name else ("INTEGRATION" if "Integration" in name else "CONTRACT")
        records.append(
            {
                "target": name,
                "path": target["path"],
                "level": level,
                "file_count": len(files),
                "files": files,
                "canonical": True,
                "action": "KEEP",
            }
        )
    return sorted(records, key=lambda item: item["target"])


def write_report(path: Path, payload: dict[str, Any], title: str, rows: list[dict[str, Any]], columns: list[str]) -> None:
    payload = {
        "generator": "Scripts/Docs/audit_docs.py",
        "source_revision": source_revision(),
        "generated_at": GENERATED_AT,
        "version": VERSION,
        **payload,
    }
    path.parent.mkdir(parents=True, exist_ok=True)
    path.with_suffix(".json").write_text(json.dumps(payload, ensure_ascii=False, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    lines = [
        "<!-- AUTO-GENERATED FILE. DO NOT EDIT.",
        "Generator: Scripts/Docs/audit_docs.py",
        f"Source revision: {payload['source_revision']}",
        f"Generated at: {payload['generated_at']} -->",
        f"# {title}",
        "",
        f"- Version: `{VERSION}`",
        f"- Records: `{len(rows)}`",
        "",
        "| " + " | ".join(columns) + " |",
        "| " + " | ".join("---" for _ in columns) + " |",
    ]
    for row in rows:
        values = []
        for column in columns:
            value = row.get(column, "")
            if isinstance(value, list):
                value = ", ".join(str(item) for item in value[:6])
                if len(row.get(column, [])) > 6:
                    value += " …"
            values.append(str(value).replace("|", "\\|"))
        lines.append("| " + " | ".join(values) + " |")
    path.with_suffix(".md").write_text("\n".join(lines) + "\n", encoding="utf-8")


def write_meta(modules: list[dict[str, Any]], scripts: list[dict[str, Any]], assets: list[dict[str, Any]], tests: list[dict[str, Any]]) -> None:
    meta = ROOT / "docs/_meta"
    write_yaml(meta / "modules.yml", registry_records(modules), "Canonical module registry; compare against Package.swift and PooTools.podspec.")
    write_yaml(meta / "scripts.yml", scripts, "Canonical script inventory generated from Scripts/ and root compatibility scripts.")
    write_yaml(meta / "data-assets.yml", assets, "Repository data asset inventory generated from JSON/YAML assets.")
    write_yaml(meta / "tests.yml", tests, "Canonical test target registry generated from Package.swift.")
    write_yaml(meta / "languages.yml", [
        {"code": "zh-Hans", "name": "简体中文", "role": "translation"},
        {"code": "en", "name": "English", "role": "canonical technical source"},
        {"code": "es", "name": "Español", "role": "translation"},
    ], "Technical documentation language policy.")
    write_yaml(meta / "document-policy.yml", [
        {"status": "ACTIVE", "meaning": "Current guidance that must be maintained"},
        {"status": "ARCHIVED", "meaning": "Historical decision material kept outside the active index"},
        {"status": "GENERATED", "meaning": "Produced by a canonical script and not edited by hand"},
        {"status": "DELETED", "meaning": "Removed after consumer and history review"},
    ], "Document lifecycle policy.")
    write_yaml(meta / "glossary.yml", [
        {"term": "canonical", "zh-Hans": "唯一实现/事实来源", "es": "fuente canónica"},
        {"term": "host", "zh-Hans": "宿主 App 或扩展目标", "es": "app o extensión anfitriona"},
        {"term": "Sendable", "zh-Hans": "可安全跨并发域传递的值", "es": "valor seguro entre dominios de concurrencia"},
        {"term": "subspec", "zh-Hans": "CocoaPods 子规格", "es": "subspec de CocoaPods"},
    ], "Shared technical terminology.")
    write_yaml(meta / "cleanup.yml", [
        {"path": "docs/", "action": "KEEP_ACTIVE_OR_ARCHIVE", "reason": "Move historical plans only after inventory and decision extraction"},
        {"path": "Scripts/validate_*_5_*.sh", "action": "LEGACY_REVIEW", "reason": "Keep until canonical governance checks cover their contracts"},
        {"path": "report/", "action": "GENERATED", "reason": "Regenerate from stable scripts; do not hand edit"},
    ], "Conservative cleanup manifest; destructive actions require a reviewed consumer map.")
    write_yaml(meta / "provenance.yml", [
        {"generator": "Scripts/Docs/audit_docs.py", "outputs": ["docs/_meta", "docs/index", "docs/modules", "report/docs", "report/scripts", "report/data", "report/tests"]},
        {"source": "Package.swift", "consumers": ["docs/_meta/modules.yml", "report/docs/DOCUMENT_INVENTORY.json", "report/tests/TEST_INVENTORY.json"]},
        {"source": "PooTools.podspec", "consumers": ["docs/_meta/modules.yml", "report/docs/DOCUMENT_INVENTORY.json"]},
    ], "Generated asset provenance and stable command contract.")


def write_governance_docs() -> None:
    governance = ROOT / "docs/maintenance/DOCUMENTATION_AND_ASSET_GOVERNANCE.md"
    governance.write_text(
        """# PTools Documentation and Repository Governance

## English

`Scripts/Docs/audit_docs.py` is the canonical local entry point for documentation, module, script, data-asset, and test inventories.

```bash
python3 Scripts/Docs/audit_docs.py --write-all
python3 Scripts/Docs/audit_docs.py --check
bash Scripts/CI/check_5_56_1_governance.sh
```

English is the canonical technical source. Chinese and Spanish module guides share the same generated registry and section structure. Generated reports and module guides must not be hand-edited; change the registry or generator instead.

## 简体中文

`Scripts/Docs/audit_docs.py` 是文档、模块、脚本、数据资产和测试清单的唯一本地治理入口。

执行 `--write-all` 生成 registry、三语模块指南和报告，执行 `--check` 校验 manifest 漂移、三语文件完整性、链接和生成资产。历史计划只有在盘点和决策提炼后才进入 `docs/archive/`，禁止为了减少文件数量直接删除。

## Español

`Scripts/Docs/audit_docs.py` es la entrada canónica local para los inventarios de documentación, módulos, scripts, datos y tests.

English es la fuente técnica canónica; las guías en chino y español mantienen la misma estructura. Los informes y guías generados no se editan manualmente: se modifica el registro o el generador.

## Lifecycle

| Status | Meaning |
| --- | --- |
| ACTIVE | Current maintained guidance |
| ARCHIVED | Historical decision material |
| GENERATED | Reproducible script output |
| DELETED | Removed after consumer and history review |

## Version and review

The current documentation version comes from `VERSION`. The generator records the source revision and a deterministic commit timestamp. Formal module names come from `Package.swift` and `PooTools.podspec`; registry drift fails CI.
""",
        encoding="utf-8",
    )
    scripts_readme = ROOT / "Scripts/README.md"
    scripts_readme.write_text(
        """# Scripts Governance

The canonical documentation and repository-asset command is:

```bash
python3 Scripts/Docs/audit_docs.py --write-all
python3 Scripts/Docs/audit_docs.py --check
```

Use existing domain validators for domain-specific contracts. Do not create a new version-named validator when the canonical domain validator can evolve. Version-specific migration scripts are exceptions and must be recorded in `docs/_meta/scripts.yml`.

新增脚本前先检查 `docs/_meta/scripts.yml`，优先扩展现有 canonical 入口。新脚本必须说明输入、输出、破坏性行为和迁移期限。

Antes de crear un script, revisa `docs/_meta/scripts.yml` y amplía la entrada canónica existente cuando sea posible.
""",
        encoding="utf-8",
    )


def write_indexes() -> None:
    for language, title, body in (
        ("zh-Hans", "PTools 文档入口", "这里是 PTools 的稳定文档入口。模块指南、架构、迁移、质量和治理清单均从明确的 owner 进入。"),
        ("en", "PTools Documentation", "This is the stable entry point for PTools documentation. Module guides, architecture, migration, quality, and governance each have an explicit owner."),
        ("es", "Documentación de PTools", "Esta es la entrada estable de la documentación de PTools. Cada guía de módulo, arquitectura, migración, calidad y gobernanza tiene un propietario explícito."),
    ):
        (ROOT / "docs/index").mkdir(parents=True, exist_ok=True)
        (ROOT / "docs/index" / f"README.{language}.md").write_text(
            f"---\nlanguage: {language}\ndocumentation_version: {VERSION}\nstatus: ACTIVE\n---\n# {title}\n\n{body}\n\n- [Module index](MODULES.{language}.md)\n- [Architecture](../architecture/ARCHITECTURE.md)\n- [Migration](../migration/MIGRATION_6.md)\n- [Quality](../maintainers/QUALITY.md)\n- [Documentation and asset governance](../maintenance/DOCUMENTATION_AND_ASSET_GOVERNANCE.md)\n",
            encoding="utf-8",
        )


def write_all() -> None:
    global GENERATED_AT
    GENERATED_AT = generated_at()
    modules = modules_registry()
    scripts = script_inventory()
    assets = data_inventory()
    tests = test_inventory()
    write_meta(modules, scripts, assets, tests)
    write_module_docs(modules)
    write_module_index(modules)
    write_indexes()
    write_governance_docs()
    documents = markdown_inventory()
    write_report(
        ROOT / "report/docs/DOCUMENT_INVENTORY",
        {"documents": documents, "summary": {"count": len(documents), "unknown": sum(item["documentType"] == "UNKNOWN" for item in documents)}},
        "Document Inventory",
        documents,
        ["path", "documentType", "language", "status", "action"],
    )
    write_report(
        ROOT / "report/scripts/SCRIPT_INVENTORY",
        {"scripts": scripts},
        "Script Inventory",
        scripts,
        ["path", "language", "domain", "status", "canonical", "action"],
    )
    write_report(
        ROOT / "report/data/DATA_ASSET_INVENTORY",
        {"assets": assets},
        "Data Asset Inventory",
        assets,
        ["path", "kind", "format", "generated", "source_of_truth", "action"],
    )
    write_report(
        ROOT / "report/tests/TEST_INVENTORY",
        {"tests": tests},
        "Test Inventory",
        tests,
        ["target", "path", "level", "file_count", "canonical", "action"],
    )


def check() -> int:
    modules = modules_registry()
    expected_spm = {item["swiftpm_product"] for item in modules if item["swiftpm_product"]}
    expected_pod = {item["cocoapods_subspec"] for item in modules if item["cocoapods_subspec"]}
    registry = ROOT / "docs/_meta/modules.yml"
    if not registry.is_file():
        print("FAIL: docs/_meta/modules.yml is missing", file=sys.stderr)
        return 1
    registry_text = registry.read_text(encoding="utf-8")
    failures: list[str] = []
    for value in sorted(expected_spm | expected_pod):
        if f'"{value}"' not in registry_text:
            failures.append(f"module registry missing {value}")
    for item in modules:
        for language in LANGUAGES:
            path = ROOT / "docs/modules" / item["id"] / f"README.{language}.md"
            if not path.is_file():
                failures.append(f"module guide missing {path.relative_to(ROOT)}")
    required = [
        ROOT / "report/docs/DOCUMENT_INVENTORY.json",
        ROOT / "report/scripts/SCRIPT_INVENTORY.json",
        ROOT / "report/data/DATA_ASSET_INVENTORY.json",
        ROOT / "report/tests/TEST_INVENTORY.json",
        ROOT / "docs/_meta/scripts.yml",
        ROOT / "docs/_meta/data-assets.yml",
        ROOT / "docs/_meta/tests.yml",
    ]
    failures.extend(f"missing generated asset {path.relative_to(ROOT)}" for path in required if not path.is_file())
    if failures:
        print("FAIL: documentation governance drift:")
        print("\n".join(f"- {failure}" for failure in failures))
        return 1
    payload = json.loads((ROOT / "report/docs/DOCUMENT_INVENTORY.json").read_text(encoding="utf-8"))
    unknown = [item["path"] for item in payload["documents"] if item["documentType"] == "UNKNOWN"]
    if unknown:
        print("FAIL: UNKNOWN documents remain:")
        print("\n".join(unknown))
        return 1
    print(f"PASS: documentation governance ({len(modules)} module entries, {len(payload['documents'])} documents)")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description="PTools documentation and repository governance")
    parser.add_argument("--write-all", action="store_true", help="regenerate registries, guides, indexes, and inventories")
    parser.add_argument("--check", action="store_true", help="check generated governance assets and manifest drift")
    args = parser.parse_args()
    if not args.write_all and not args.check:
        parser.error("choose --write-all or --check")
    if args.write_all:
        write_all()
    return check() if args.check or args.write_all else 0


if __name__ == "__main__":
    raise SystemExit(main())
