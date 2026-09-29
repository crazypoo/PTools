<!--
AUTO-GENERATED FILE.
DO NOT EDIT MANUALLY.

Generator: Scripts/validate_dependency_direction.sh
Source revision: 4a9dfe8a69da258e4f5c28799816ef2212bd4015
Generated at: 2026-09-29T15:12:14Z
-->

# Dependency Direction Gate

- Status: `pass_with_legacy_allowlist`
- Internal edges: `192`
- Temporary allowlisted edges: `0`
- Unallowlisted violations: `0`

## Rules

- ptools -> local target is forbidden except PToolsCore, PToolsDate, PToolsUIFoundation, PToolsPermissionCore, PToolsLogging, PToolsSymbols, and PToolsDevice
- PT*Permission -> non-ptools target is forbidden except PToolsPermissionCore
- MediaViewer/PhotoPicker -> PooToolsNetWork is forbidden after its temporary allowlist expires
- Navigation/Router -> PhotoPicker is forbidden

## Temporary legacy edges

- None

## Violations

- None

## Gate policy

The allowlist is intentionally short-lived. New exceptions must include a concrete migration reason and must not hide a new dependency cycle.
