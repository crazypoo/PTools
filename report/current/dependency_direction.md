<!--
AUTO-GENERATED FILE.
DO NOT EDIT MANUALLY.

Generator: Scripts/validate_dependency_direction.sh
Source revision: 9e7888628a473d8c424ab2bd6259d8a1dc8a6b9e
Generated at: 2026-09-30T15:19:08Z
-->

# Dependency Direction Gate

- Status: `pass_with_legacy_allowlist`
- Internal edges: `196`
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
