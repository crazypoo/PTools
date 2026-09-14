# Dependency Direction Gate

- Status: `pass_with_legacy_allowlist`
- Internal edges: `124`
- Temporary allowlisted edges: `2`
- Unallowlisted violations: `0`

## Rules

- ptools -> local target is forbidden except PToolsCore, PToolsUIFoundation, and PToolsPermissionCore
- PT*Permission -> non-ptools target is forbidden except PToolsPermissionCore
- MediaViewer/PhotoPicker -> PooToolsNetWork is forbidden after its temporary allowlist expires
- Navigation/Router -> PhotoPicker is forbidden

## Temporary legacy edges

- `PooToolsMediaViewer` → `PooToolsNetWork`: Legacy media viewer still uses the callback Network facade; migrate to MediaCore provider in 5.8.7.
- `PooToolsPhotoPicker` → `PooToolsNetWork`: Legacy PhotoPicker upload/cache path still uses Network; migrate to a media provider in 5.8.7.

## Violations

- None

## Gate policy

The allowlist is intentionally short-lived. New exceptions must include a concrete migration reason and must not hide a new dependency cycle.
