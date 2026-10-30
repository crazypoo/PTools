<!--
Current report metadata.
AUTO-GENERATED FILE.
Repository: crazypoo/PTools
Branch: feature/pr46-pr50-inspector-layout-governance-20261030
Source revision: 98086745a5deb64f173282d5cdfa5faaed2e2106
Source version: 5.69.0
Source inputs digest: 8c745967288dcd0493111e7ec716d9f601938762a8f52bae2525c7d3591bb455
Generator version: 1
Generator: Scripts/validate_dependency_direction.sh
Generated at: 2026-10-30T03:49:02Z
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
