<!--
AUTO-GENERATED FILE.
DO NOT EDIT MANUALLY.

Generator: Scripts/validate_dependency_direction.sh
Source revision: 80126150505961e259cce5e08ada67962265c063
Generated at: 2026-10-18T05:02:37Z
-->

# Dependency Direction Gate

- Status: `pass_with_legacy_allowlist`
- Internal edges: `301`
- Temporary allowlisted edges: `0`
- Unallowlisted violations: `0`

## Rules

- ptools -> local target is forbidden except approved local layers, including PToolsConstraintLayout
- PT*Permission -> non-ptools target is forbidden except PToolsPermissionCore
- MediaViewer/PhotoPicker -> PooToolsNetWork is forbidden after its temporary allowlist expires
- Navigation/Router -> PhotoPicker is forbidden

## Temporary legacy edges

- None

## Violations

- None

## Gate policy

The allowlist is intentionally short-lived. New exceptions must include a concrete migration reason and must not hide a new dependency cycle.
