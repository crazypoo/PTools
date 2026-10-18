# PTLayout 5.67.1 migration checklist

<!-- English: Migrate one ownership boundary at a time; do not mechanically replace every layout call. -->
<!-- Español: Migra un límite de propiedad cada vez; no reemplaces todas las llamadas mecánicamente. -->
<!-- 中文：按所有权边界逐步迁移，不要机械替换全部布局调用。 -->

## Before changing a file

- [ ] Record `.snp`, `NSLayoutConstraint.activate`, manual constraint constructors, and anchor constraints in `report/layout/Full_Layout_Inventory.csv`.
- [ ] Confirm the file is a PTools-owned Auto Layout consumer, not a CollectionView layout algorithm, drawing path, frame animation, or third-party compatibility boundary.
- [ ] Add the appropriate consumer dependency (`PToolsConstraintLayout`) without making the standalone target depend on the umbrella target.

## Translation table

| Legacy | PTLayout |
| --- | --- |
| `view.snp.makeConstraints` | `view.ptLayout.makeConstraints` |
| `view.snp.updateConstraints` | `view.ptLayout.updateConstraints` |
| `view.snp.remakeConstraints` | `view.ptLayout.remakeConstraints` |
| `view.snp.prepareConstraints` | `view.ptLayout.prepareConstraints` |
| `view.snp.removeConstraints` | `view.ptLayout.removeConstraints` |
| `Constraint` | `PTLayoutConstraint` |
| `ConstraintGroup` | `PTLayoutConstraintGroup` |

`updateConstraints` intentionally does not upsert an unknown signature. Use `upsertConstraints` only when the caller explicitly wants that behavior.

## Required checks per migrated file

- [ ] The view is added to its intended hierarchy before positional constraints are made.
- [ ] Width/height-only constants remain legal for standalone views.
- [ ] Safe-area, keyboard, layout-margin, readable-content, scroll-view, and RTL guides use the actual UIKit guide.
- [ ] `remake` failure leaves the old PTLayout group active.
- [ ] Foreign SnapKit/storyboard constraints are not removed by PTLayout.
- [ ] New comments use English, Spanish, and Chinese.
- [ ] Run the file's Swift parse/type-check and the iOS Simulator Debug/Release Xcode build.

## Explicit exemptions

The following remain outside PTLayout ownership and need a row in the inventory with a reason and regression path:

- `PooToolsLayout` / CollectionViewPagingLayout and collection layout algorithms.
- `layoutSubviews` geometry, drawing, shadow paths, transforms, camera/player frame calculations.
- UIStackView's arranged-subview internals.
- Third-party and legacy `.snp` compatibility code.

## Release evidence

Run:

```text
python3 Scripts/CI/audit_layout_567.py
python3 Scripts/CI/validate_layout_negative_fixtures_567.py
bash Scripts/CI/run_ptlayout_differential_tests.sh
bash Scripts/CI/validate_ptlayout_5_67_release.sh
```

The static scripts do not replace Xcode Simulator, CocoaPods consumer, accessibility, visual, or physical-device validation.
