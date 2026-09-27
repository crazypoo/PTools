# 设备目录维护

JSON 是唯一人工维护源，位置为 `PooToolsSource/PToolsDevice/Resources/DeviceCatalog/`，按 iPhone、iPad、iPod、Apple TV、Apple Watch、Mac、HomePod 和 Apple Vision 分文件保存。

## 修改流程

```text
编辑 JSON
  ↓
python3 Scripts/Device/validate_device_catalog.py
  ↓
python3 Scripts/Device/generate_device_catalog.py
  ↓
python3 Scripts/Device/diff_device_catalog.py
  ↓
git diff / Xcode 构建
```

生成文件位于 `PooToolsSource/PToolsDevice/Generated/`，带有 `AUTO-GENERATED` 标记，不要手工修改。model id 发布后必须稳定；同一硬件 identifier 只能映射一个 model。

## 新设备候选

使用 `update_device_catalog.py --identifier <identifier>` 只生成 `DeviceCatalog.pending.json` 待审报告，不会覆写正式目录。审核时必须确认 Apple 公开资料、family、platform、marketingName 和 releaseYear。

## 未知标识符

`check_unknown_identifiers.py` 用于发布前核对已知标识符。运行时未知设备仍必须安全回退，不得猜测营销名称、SoC、传感器或权限能力。
