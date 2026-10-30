<!--
Current report metadata.
AUTO-GENERATED FILE.
Repository: crazypoo/PTools
Branch: feature/pr56-pr60-rc-ci-security-20261030
Source revision: 1fb15b13c3f41fcaabd7a2ad5f537deb0a599df1
Source version: 5.69.0
Source inputs digest: d55d40519638e28785124558612fcb09551665299151a4effe0a7b983163cfcb
Generator version: 1
Generator: Scripts/validate_dependency_direction.sh
Generated at: 2026-10-30T04:32:51Z
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
