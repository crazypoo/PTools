<!--
Current report metadata.
AUTO-GENERATED FILE.
Repository: crazypoo/PTools
Branch: feature/pr51-pr55-debug-performance-rel-candidate-20261030
Source revision: 6928fdb7d49e1a9b1353b68d24225b23a0d67eb2
Source version: 5.69.0
Source inputs digest: c0ec772e7214cf193c1b62fabd35850af82c5fef5524d529dcced405437ce7e0
Generator version: 1
Generator: Scripts/validate_dependency_direction.sh
Generated at: 2026-10-30T04:12:21Z
-->

# Dependency Direction Gate

- Status: `pass_with_legacy_allowlist`
- Internal edges: `291`
- Temporary allowlisted edges: `0`
- Unallowlisted violations: `0`

## Rules

- ptools -> local target is forbidden except approved local layers, including PToolsConstraintLayout and PToolsTransferCore
- PT*Permission -> non-ptools target is forbidden except PToolsPermissionCore
- MediaViewer/PhotoPicker -> PooToolsNetWork is forbidden after its temporary allowlist expires
- Navigation/Router -> PhotoPicker is forbidden

## Temporary legacy edges

- None

## Violations

- None

## Gate policy

The allowlist is intentionally short-lived. New exceptions must include a concrete migration reason and must not hide a new dependency cycle.
