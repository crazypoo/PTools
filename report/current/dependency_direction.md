<!--
Current report metadata.
AUTO-GENERATED FILE.
Repository: crazypoo/PTools
Branch: master
Source revision: b6875bfcbb5b503f145e05d8bcc101c196cc316e
Source version: 5.60.0
Source inputs digest: eb66b030720b0fd30eb573eff88c7601464f448a455eafda9e1630c8be0309e3
Generator version: 1
Generator: Scripts/validate_dependency_direction.sh
Generated at: 2026-10-03T05:18:13Z
-->

# Dependency Direction Gate

- Status: `pass_with_legacy_allowlist`
- Internal edges: `203`
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
