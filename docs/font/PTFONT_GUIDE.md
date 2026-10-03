# PTFont 5.60

<!-- English: The reviewed JSON catalog is the only maintained font list. -->
<!-- Español: El catálogo JSON revisado es la única lista de fuentes mantenida. -->
<!-- 中文：已审核的 JSON 目录是唯一维护的字体清单。 -->

## Use the generated catalog

```swift
let font = PTFont.avenirNextBold
let titleFont = await MainActor.run {
    font.uiFont(size: 18)
}

let byName = PTFontCatalog.font(named: "AvenirNext-Bold")
let familyFonts = PTFontCatalog.fonts(family: "Avenir Next")
```

`PTFont` stores only immutable metadata (`postScriptName`, `familyName`, and the PTools support baseline). `UIFont`, `CTFont`, and `UIFontDescriptor` are created on `MainActor` and never enter the catalog value type.

## Catalog and runtime are different sources

- `PTFontCatalog` is the reviewed, generated, type-safe catalog. It does not scan the device, read disk, or use the network.
- `PTFontRuntime.installedFonts` lazily discovers the fonts actually installed in the current iOS runtime. The result is cached on `MainActor` and can be refreshed explicitly.

```swift
let runtimeFonts = await MainActor.run {
    PTFontRuntime.installedFonts
}
let snapshot = await MainActor.run {
    PTFontRuntime.snapshot(runtime: "iOS Simulator")
}
```

Runtime absence is not proof that Apple removed a font. It must first enter the pending review report.

## Updating the catalog

1. Run `Scripts/Font/collect-fonts.sh` from a booted iOS Simulator host and save `PTFontRuntime.snapshotJSON(runtime:)` output.
2. Run `Scripts/Font/update-font-catalog.sh --from-json <snapshot.json>`.
3. Review `PooToolsSource/Font/Resources/FontCatalog/FontCatalog.pending.json`.
4. Confirm additions, removals, family changes, and alias candidates against every supported runtime.
5. Update the reviewed `FontCatalog.json`, then run `python3 Scripts/Font/generate-font-catalog.py --generate`.
6. Run `python3 Scripts/Font/validate-font-catalog.py` and `bash Scripts/Font/verify-generated-fonts.sh`.

The formal catalog is never overwritten by the collector or the pending step. Generated Swift files are not hand-edited.

## FontName migration

5.x source compatibility remains available:

```swift
let oldName = FontName.PingFangSCRegular
```

New code should use:

```swift
let name = PTFont.pingFangSCRegular.postScriptName
```

`FontName` and `fontNames()` are generated compatibility forwards and are deprecated until the 6.0 removal window. The old `osVersion` helper no longer pretends to enforce runtime availability.

## Inspector and Simulator

`FontReference` consumes `PTFontRuntime.installedFonts`; it does not maintain a second font discovery list. This keeps the Inspector useful for fonts added by a future iOS runtime while the generated catalog remains stable for source compatibility.
