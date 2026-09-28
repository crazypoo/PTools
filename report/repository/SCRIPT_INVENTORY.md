<!-- AUTO-GENERATED FILE. DO NOT EDIT.
Generator: Scripts/Governance/audit_repository.py
Source revision: f903ce58e855a57a32a4c867b67b22a6cb02359f -->
# Script Inventory

- Version: `5.56.2`
- Records: `101`

| path | language | category | status | action | consumers |
| --- | --- | --- | --- | --- | --- |
| Package.swift | swift | PTools | ACTIVE | KEEP | .swiftpm/xcode/package.xcworkspace/xcuserdata/jax.xcuserdatad/UserInterfaceState.xcuserstate, CHANGELOG.md, Scripts/CI/check_devicekit_removed.sh, Scripts/CI/check_instructions_architecture.sh, Scripts/CI/check_instructions_removed.sh, Scripts/CI/check_jx_paging_removed.sh, Scripts/CI/check_notification_banner_removed.sh, Scripts/CI/check_p0_platform_modules.sh … |
| Scripts/CI/build_cocoapods_device.sh | sh | CI | ACTIVE | KEEP | docs/_meta/scripts.yml, docs/audits/SIMULATOR_BUILD_BASELINE.md |
| Scripts/CI/build_cocoapods_simulator.sh | sh | CI | ACTIVE | KEEP | docs/_meta/scripts.yml, docs/audits/SIMULATOR_BUILD_BASELINE.md |
| Scripts/CI/check_5_56_1_governance.sh | sh | CI | LEGACY_REVIEW | KEEP | .github/workflows/ptools-governance.yml, Scripts/Docs/audit_docs.py, docs/_meta/scripts.yml, docs/guides/PTOOLS_5_56_2_CLOSURE.md, docs/maintainers/TEST_GOVERNANCE.md, docs/maintenance/DOCUMENTATION_AND_ASSET_GOVERNANCE.md |
| Scripts/CI/check_devicekit_removed.sh | sh | CI | ACTIVE | KEEP | Scripts/validate_build_entries.sh, docs/_meta/scripts.yml, docs/audits/DEVICEKIT_USAGE_AUDIT.md |
| Scripts/CI/check_example_source_ownership.rb | rb | CI | ACTIVE | KEEP | Scripts/validate_build_entries.sh, docs/_meta/scripts.yml, docs/audits/SIMULATOR_BUILD_BASELINE.md |
| Scripts/CI/check_instructions_architecture.sh | sh | CI | ACTIVE | KEEP | docs/_meta/scripts.yml, docs/audits/INSTRUCTIONS_USAGE_AUDIT.md |
| Scripts/CI/check_instructions_removed.sh | sh | CI | ACTIVE | KEEP | docs/_meta/scripts.yml, docs/audits/INSTRUCTIONS_USAGE_AUDIT.md |
| Scripts/CI/check_jx_paging_removed.sh | sh | CI | ACTIVE | KEEP | Scripts/validate_quality_scans.sh, docs/_meta/scripts.yml, docs/audits/JX_PAGING_SEGMENTED_USAGE_AUDIT.md |
| Scripts/CI/check_notification_banner_removed.sh | sh | CI | ACTIVE | KEEP | docs/_meta/scripts.yml |
| Scripts/CI/check_overlay_architecture.sh | sh | CI | ACTIVE | KEEP | Scripts/validate_quality_scans.sh, docs/_meta/scripts.yml |
| Scripts/CI/check_p0_platform_modules.sh | sh | CI | ACTIVE | KEEP | Scripts/validate_quality_scans.sh, Scripts/validate_release.sh, docs/_meta/scripts.yml, docs/architecture/PTOOLS_PLATFORM_INFRASTRUCTURE.md |
| Scripts/CI/check_p1_advanced_modules.sh | sh | CI | ACTIVE | KEEP | Scripts/validate_build_entries.sh, Scripts/validate_quality_scans.sh, Scripts/validate_release.sh, docs/_meta/scripts.yml |
| Scripts/CI/check_p2_modern_modules.sh | sh | CI | ACTIVE | KEEP | Scripts/CI/quality_gate.sh, Scripts/validate_519_package_tests_docs.sh, Scripts/validate_build_entries.sh, Scripts/validate_quality_scans.sh, Scripts/validate_release.sh, docs/_meta/scripts.yml, docs/guides/PTOOLS_P2_MODERN_EXTENSIONS.md |
| Scripts/CI/check_popovers_removed.sh | sh | CI | ACTIVE | KEEP | Scripts/validate_quality_scans.sh, docs/_meta/scripts.yml |
| Scripts/CI/quality_gate.sh | sh | CI | ACTIVE | KEEP | .github/workflows/quality.yml, Scripts/CI/quality_gates.yml, Scripts/ptools.py, Scripts/registry.yml, docs/_meta/scripts.yml |
| Scripts/CI/version_facts.rb | rb | CI | ACTIVE | KEEP | Scripts/validate_api_baseline.sh, Scripts/validate_document_versions.sh, Scripts/validate_release.sh, docs/_meta/scripts.yml |
| Scripts/Device/check_unknown_identifiers.py | py | Device | ACTIVE | KEEP | docs/_meta/scripts.yml |
| Scripts/Device/diff_device_catalog.py | py | Device | ACTIVE | KEEP | .github/workflows/device-catalog-watch.yml, docs/_meta/scripts.yml, docs/maintenance/DEVICE_CATALOG_MAINTENANCE.md |
| Scripts/Device/generate_device_catalog.py | py | Device | ACTIVE | KEEP | PooToolsSource/PToolsDevice/Generated/PTAppleTVCatalog.generated.swift, PooToolsSource/PToolsDevice/Generated/PTAppleVisionCatalog.generated.swift, PooToolsSource/PToolsDevice/Generated/PTAppleWatchCatalog.generated.swift, PooToolsSource/PToolsDevice/Generated/PTDeviceIdentifierIndex.generated.swift, PooToolsSource/PToolsDevice/Generated/PTHomePodCatalog.generated.swift, PooToolsSource/PToolsDevice/Generated/PTMacCatalog.generated.swift, PooToolsSource/PToolsDevice/Generated/PTiPadCatalog.generated.swift, PooToolsSource/PToolsDevice/Generated/PTiPhoneCatalog.generated.swift … |
| Scripts/Device/update_device_catalog.py | py | Device | ACTIVE | KEEP | docs/_meta/scripts.yml |
| Scripts/Device/validate_device_catalog.py | py | Device | ACTIVE | KEEP | .github/workflows/device-catalog-watch.yml, Scripts/registry.yml, docs/_meta/scripts.yml, docs/maintenance/DEVICE_CATALOG_MAINTENANCE.md |
| Scripts/Docs/apply_cleanup.py | py | Docs | ACTIVE | KEEP | Scripts/ptools.py, Scripts/registry.yml, docs/_meta/scripts.yml |
| Scripts/Docs/audit_docs.py | py | Docs | ACTIVE | KEEP | .github/workflows/ptools-governance.yml, CHANGELOG.md, Data/registry.yml, ROADMAP.md, Scripts/CI/check_5_56_1_governance.sh, Scripts/CI/quality_gate.sh, Scripts/CI/quality_gates.yml, Scripts/Governance/audit_repository.py … |
| Scripts/Governance/audit_data_assets.py | py | Governance | ACTIVE | KEEP | docs/_meta/scripts.yml |
| Scripts/Governance/audit_repository.py | py | Governance | ACTIVE | KEEP | Scripts/Docs/audit_docs.py, Scripts/ptools.py, Scripts/registry.yml, docs/_meta/cleanup.yml, docs/_meta/scripts.yml |
| Scripts/Governance/audit_scripts.py | py | Governance | ACTIVE | KEEP | docs/_meta/scripts.yml |
| Scripts/Governance/audit_tests.py | py | Governance | ACTIVE | KEEP | Scripts/ptools.py, docs/_meta/scripts.yml |
| Scripts/Governance/find_duplicates.py | py | Governance | ACTIVE | KEEP | Scripts/ptools.py, Scripts/registry.yml, docs/_meta/scripts.yml |
| Scripts/Migration/cleanup_example_source_membership.rb | rb | Migration | ACTIVE | KEEP | docs/_meta/scripts.yml |
| Scripts/Privacy/validate_privacy_accessed_api.sh | sh | Privacy | ACTIVE | KEEP | Scripts/Governance/audit_repository.py, Scripts/ptools.py, Scripts/registry.yml, docs/_meta/scripts.yml |
| Scripts/Symbols/symbol-diff.sh | sh | Symbols | ACTIVE | KEEP | docs/_meta/scripts.yml, docs/architecture/PTOOLS_SYMBOL_GUIDELINES.md, docs/reports/SYMBOL_CATALOG_DIFF.md |
| Scripts/Symbols/update-symbols.sh | sh | Symbols | ACTIVE | KEEP | docs/_meta/scripts.yml, docs/architecture/PTOOLS_SYMBOL_GUIDELINES.md |
| Scripts/Symbols/verify-generated-symbols.sh | sh | Symbols | ACTIVE | KEEP | Scripts/validate_symbols_5_24.sh, docs/_meta/scripts.yml, docs/architecture/PTOOLS_SYMBOL_GUIDELINES.md, docs/audits/SAFESFSYMBOLS_USAGE_AUDIT.md |
| Scripts/compare_public_api.rb | rb | Scripts | ACTIVE | KEEP | Scripts/validate_api_baseline.sh, api-baseline/README.md, docs/_meta/scripts.yml |
| Scripts/generate_dependency_matrix.rb | rb | Scripts | ACTIVE | KEEP | docs/_meta/scripts.yml, docs/architecture/DEPENDENCY_MATRIX.md |
| Scripts/generate_package_matrix.rb | rb | Scripts | ACTIVE | KEEP | docs/_meta/scripts.yml, docs/architecture/PACKAGE_MATRIX.md |
| Scripts/ptools.py | py | Scripts | ACTIVE | KEEP | Scripts/Docs/audit_docs.py, Scripts/Governance/audit_repository.py, Scripts/registry.yml, docs/_meta/scripts.yml, docs/maintainers/TEST_GOVERNANCE.md, docs/maintenance/DOCUMENTATION_AND_ASSET_GOVERNANCE.md |
| Scripts/quality.sh | sh | Scripts | ACTIVE | KEEP | Scripts/Governance/audit_repository.py, docs/_meta/scripts.yml, docs/maintainers/QUALITY.md, docs/maintainers/RELEASE.md |
| Scripts/report_accessibility.rb | rb | Scripts | ACTIVE | KEEP | Scripts/Governance/audit_repository.py, Scripts/validate_59_contracts.sh, Scripts/validate_quality_scans.sh, docs/_meta/scripts.yml |
| Scripts/report_cache_inventory.rb | rb | Scripts | ACTIVE | KEEP | Scripts/Governance/audit_repository.py, Scripts/validate_59_contracts.sh, Scripts/validate_p2_performance_closure.sh, Scripts/validate_quality_scans.sh, docs/_meta/scripts.yml |
| Scripts/report_cocoapods_subspec_graph.rb | rb | Scripts | ACTIVE | KEEP | Scripts/ptools.py, Scripts/validate_58_contracts.sh, Scripts/validate_module_parity.sh, docs/_meta/scripts.yml |
| Scripts/report_concurrency.rb | rb | Scripts | ACTIVE | KEEP | Scripts/Governance/audit_repository.py, Scripts/validate_59_contracts.sh, Scripts/validate_quality_scans.sh, docs/_meta/scripts.yml |
| Scripts/report_current_summaries.rb | rb | Scripts | ACTIVE | KEEP | Scripts/validate_quality_scans.sh, docs/_meta/scripts.yml |
| Scripts/report_duplicate_entries.sh | sh | Scripts | ACTIVE | KEEP | Scripts/validate_quality_scans.sh, Scripts/validate_release.sh, docs/_meta/scripts.yml |
| Scripts/report_mainactor_heavy_work.rb | rb | Scripts | ACTIVE | KEEP | Scripts/validate_p2_performance_closure.sh, docs/_meta/scripts.yml |
| Scripts/report_public_api.rb | rb | Scripts | ACTIVE | KEEP | Scripts/Governance/audit_repository.py, Scripts/validate_59_contracts.sh, Scripts/validate_quality_scans.sh, api-baseline/5.18.2/public_api.json, api-baseline/5.35.0/public_api.json, api-baseline/README.md, docs/_meta/scripts.yml |
| Scripts/report_sendable_exceptions.rb | rb | Scripts | ACTIVE | KEEP | Scripts/ptools.py, Scripts/validate_58_contracts.sh, Scripts/validate_quality_scans.sh, docs/_meta/scripts.yml |
| Scripts/report_singletons.rb | rb | Scripts | ACTIVE | KEEP | Scripts/Governance/audit_repository.py, Scripts/validate_59_contracts.sh, Scripts/validate_lifecycle_5_9.sh, Scripts/validate_quality_scans.sh, docs/_meta/scripts.yml |
| Scripts/report_spm_dependency_graph.rb | rb | Scripts | ACTIVE | KEEP | Scripts/ptools.py, Scripts/validate_58_contracts.sh, Scripts/validate_dependency_direction.sh, Scripts/validate_module_parity.sh, docs/_meta/scripts.yml |
| Scripts/validate_514_network_security.sh | sh | Scripts | ACTIVE | KEEP | docs/_meta/scripts.yml |
| Scripts/validate_515_media.sh | sh | Scripts | ACTIVE | KEEP | Scripts/validate_quality_scans.sh, Scripts/validate_release.sh, docs/_meta/scripts.yml |
| Scripts/validate_516_permission.sh | sh | Scripts | ACTIVE | KEEP | Scripts/validate_quality_scans.sh, Scripts/validate_release.sh, docs/_meta/scripts.yml |
| Scripts/validate_517_ui.sh | sh | Scripts | ACTIVE | KEEP | ROADMAP.md, Scripts/validate_quality_scans.sh, Scripts/validate_release.sh, docs/_meta/scripts.yml, docs/guides/MODULES.md, docs/maintainers/QUALITY.md, docs/ui/UI_COMPONENTS_5_17.md |
| Scripts/validate_519_package_tests_docs.sh | sh | Scripts | ACTIVE | KEEP | Scripts/generate_package_matrix.rb, Scripts/validate_quality_scans.sh, Scripts/validate_release.sh, docs/_meta/scripts.yml, docs/architecture/PACKAGE_MATRIX.md, docs/maintainers/QUALITY.md, docs/maintainers/RELEASE.md |
| Scripts/validate_58_contracts.sh | sh | Scripts | ACTIVE | KEEP | docs/_meta/scripts.yml |
| Scripts/validate_592_quality.sh | sh | Scripts | ACTIVE | KEEP | Scripts/validate_59_contracts.sh, docs/_meta/scripts.yml |
| Scripts/validate_59_contracts.sh | sh | Scripts | ACTIVE | KEEP | docs/_meta/scripts.yml |
| Scripts/validate_api_baseline.sh | sh | Scripts | ACTIVE | KEEP | Scripts/validate_519_package_tests_docs.sh, api-baseline/README.md, docs/_meta/scripts.yml |
| Scripts/validate_attributedstring_absorption_5_25.sh | sh | Scripts | LEGACY_REVIEW | KEEP | Scripts/validate_quality_scans.sh, docs/_meta/scripts.yml |
| Scripts/validate_branch_dependencies.sh | sh | Scripts | ACTIVE | KEEP | Scripts/validate_59_contracts.sh, docs/_meta/scripts.yml |
| Scripts/validate_build_entries.sh | sh | Scripts | ACTIVE | KEEP | ROADMAP.md, Scripts/CI/quality_gate.sh, Scripts/validate_59_contracts.sh, docs/_meta/scripts.yml, docs/maintainers/MODULE_CHECKLIST.md, docs/maintainers/QUALITY.md, docs/maintainers/RELEASE.md |
| Scripts/validate_concurrency_5_19.sh | sh | Scripts | LEGACY_REVIEW | KEEP | Scripts/validate_quality_scans.sh, docs/_meta/scripts.yml, docs/architecture/CONCURRENCY.md |
| Scripts/validate_core_boundary_5_12.sh | sh | Scripts | LEGACY_REVIEW | KEEP | Scripts/validate_build_entries.sh, Scripts/validate_quality_scans.sh, docs/_meta/scripts.yml |
| Scripts/validate_core_source_contract.sh | sh | Scripts | ACTIVE | KEEP | Scripts/validate_build_entries.sh, docs/_meta/scripts.yml, docs/maintainers/RELEASE.md |
| Scripts/validate_debug_foundation_5_10.sh | sh | Scripts | LEGACY_REVIEW | KEEP | Scripts/validate_quality_scans.sh, docs/_meta/scripts.yml |
| Scripts/validate_debug_instruments_5_18.sh | sh | Scripts | LEGACY_REVIEW | KEEP | ROADMAP.md, Scripts/validate_quality_scans.sh, Scripts/validate_release.sh, docs/_meta/scripts.yml, docs/maintainers/QUALITY.md |
| Scripts/validate_dependencies_5_9_6.sh | sh | Scripts | LEGACY_REVIEW | KEEP | Scripts/validate_59_contracts.sh, docs/_meta/scripts.yml |
| Scripts/validate_dependency_direction.sh | sh | Scripts | ACTIVE | KEEP | Scripts/validate_58_contracts.sh, Scripts/validate_quality_scans.sh, docs/_meta/scripts.yml |
| Scripts/validate_deprecated_inventory.sh | sh | Scripts | ACTIVE | KEEP | Scripts/validate_519_package_tests_docs.sh, Scripts/validate_59_contracts.sh, Scripts/validate_migration_5_9_7.sh, Scripts/validate_quality_scans.sh, docs/_meta/scripts.yml |
| Scripts/validate_docs.sh | sh | Scripts | ACTIVE | KEEP | ROADMAP.md, Scripts/CI/quality_gate.sh, Scripts/validate_migration_5_9_7.sh, Scripts/validate_release.sh, docs/_meta/scripts.yml, docs/maintainers/QUALITY.md, docs/maintainers/RELEASE.md |
| Scripts/validate_document_versions.sh | sh | Scripts | ACTIVE | KEEP | ROADMAP.md, Scripts/CI/quality_gate.sh, Scripts/CI/quality_gates.yml, Scripts/validate_migration_5_9_7.sh, Scripts/validate_release.sh, docs/_meta/scripts.yml, docs/maintainers/QUALITY.md, docs/maintainers/RELEASE.md |
| Scripts/validate_file_size_gate.sh | sh | Scripts | ACTIVE | KEEP | Scripts/ptools.py, Scripts/validate_58_contracts.sh, Scripts/validate_p2_performance_closure.sh, Scripts/validate_quality_scans.sh, docs/_meta/scripts.yml |
| Scripts/validate_gcdwebserver_removal_5_28.sh | sh | Scripts | LEGACY_REVIEW | KEEP | Scripts/validate_quality_scans.sh, docs/_meta/scripts.yml, docs/audits/GCDWEBSERVER_USAGE_AUDIT.md |
| Scripts/validate_instruments_5_11.sh | sh | Scripts | LEGACY_REVIEW | KEEP | Scripts/validate_quality_scans.sh, docs/_meta/scripts.yml |
| Scripts/validate_lifecycle_5_9.sh | sh | Scripts | LEGACY_REVIEW | KEEP | Scripts/validate_59_contracts.sh, docs/_meta/scripts.yml |
| Scripts/validate_localizations.sh | sh | Scripts | ACTIVE | KEEP | Scripts/validate_quality_scans.sh, docs/_meta/scripts.yml |
| Scripts/validate_logging_5_21.sh | sh | Scripts | LEGACY_REVIEW | KEEP | Scripts/validate_quality_scans.sh, Scripts/validate_release.sh, docs/_meta/scripts.yml |
| Scripts/validate_logging_5_22.sh | sh | Scripts | LEGACY_REVIEW | KEEP | Scripts/validate_quality_scans.sh, Scripts/validate_release.sh, docs/_meta/scripts.yml, docs/audits/COCOALUMBERJACK_USAGE_AUDIT.md, docs/dependencies/DEPENDENCY_POLICY.md, docs/guides/MIGRATION_5_22_LOGGING.md |
| Scripts/validate_logging_foundation_5_20.sh | sh | Scripts | LEGACY_REVIEW | KEEP | Scripts/validate_build_entries.sh, Scripts/validate_quality_scans.sh, Scripts/validate_release.sh, docs/_meta/scripts.yml |
| Scripts/validate_migration_5_9_7.sh | sh | Scripts | LEGACY_REVIEW | KEEP | Scripts/validate_59_contracts.sh, docs/_meta/scripts.yml |
| Scripts/validate_module_parity.sh | sh | Scripts | ACTIVE | KEEP | Scripts/CI/quality_gate.sh, Scripts/validate_519_package_tests_docs.sh, Scripts/validate_58_contracts.sh, Scripts/validate_quality_scans.sh, docs/_meta/scripts.yml, docs/architecture/PTOOLS_PLATFORM_INFRASTRUCTURE.md |
| Scripts/validate_naming_debt.sh | sh | Scripts | ACTIVE | KEEP | Scripts/validate_519_package_tests_docs.sh, docs/_meta/scripts.yml |
| Scripts/validate_network_security.sh | sh | Scripts | ACTIVE | KEEP | Scripts/validate_quality_scans.sh, Scripts/validate_release.sh, docs/_meta/scripts.yml |
| Scripts/validate_p1_architecture_closure.sh | sh | Scripts | ACTIVE | KEEP | Scripts/validate_quality_scans.sh, docs/_meta/scripts.yml |
| Scripts/validate_p1_dependency_supply_chain.sh | sh | Scripts | ACTIVE | KEEP | Scripts/validate_p1_architecture_closure.sh, docs/_meta/scripts.yml |
| Scripts/validate_p1_performance_registry.sh | sh | Scripts | ACTIVE | KEEP | Scripts/validate_p1_architecture_closure.sh, Scripts/validate_p2_performance_closure.sh, docs/_meta/scripts.yml |
| Scripts/validate_p1_public_api_intent.sh | sh | Scripts | ACTIVE | KEEP | Scripts/validate_p1_architecture_closure.sh, docs/_meta/scripts.yml |
| Scripts/validate_p1_standalone_modules.sh | sh | Scripts | ACTIVE | KEEP | Scripts/validate_p1_architecture_closure.sh, docs/_meta/scripts.yml |
| Scripts/validate_p2_performance_closure.sh | sh | Scripts | ACTIVE | KEEP | Scripts/validate_quality_scans.sh, docs/_meta/scripts.yml |
| Scripts/validate_permission_source_contract.sh | sh | Scripts | ACTIVE | KEEP | Scripts/validate_58_contracts.sh, Scripts/validate_build_entries.sh, Scripts/validate_quality_scans.sh, docs/_meta/scripts.yml |
| Scripts/validate_quality_scans.sh | sh | Scripts | ACTIVE | KEEP | ROADMAP.md, Scripts/CI/quality_gate.sh, Scripts/CI/quality_gates.yml, Scripts/validate_59_contracts.sh, docs/_meta/scripts.yml, docs/architecture/CONCURRENCY.md, docs/dependencies/DEPENDENCY_POLICY.md, docs/maintainers/MODULE_CHECKLIST.md … |
| Scripts/validate_release.sh | sh | Scripts | ACTIVE | KEEP | .github/workflows/release-validation.yml, Scripts/CI/quality_gate.sh, Scripts/CI/quality_gates.yml, Scripts/ptools.py, Scripts/registry.yml, docs/_meta/scripts.yml, docs/maintainers/RELEASE.md |
| Scripts/validate_search_5_18_1.sh | sh | Scripts | LEGACY_REVIEW | KEEP | Scripts/validate_quality_scans.sh, docs/_meta/scripts.yml |
| Scripts/validate_socketrocket_removal_5_27.sh | sh | Scripts | LEGACY_REVIEW | KEEP | Scripts/validate_quality_scans.sh, Scripts/validate_release.sh, docs/_meta/scripts.yml |
| Scripts/validate_swiftdate_removal_5_26.sh | sh | Scripts | LEGACY_REVIEW | KEEP | Scripts/validate_quality_scans.sh, docs/_meta/scripts.yml |
| Scripts/validate_swifterswift_removal.sh | sh | Scripts | ACTIVE | KEEP | Scripts/validate_quality_scans.sh, Scripts/validate_release.sh, docs/_meta/scripts.yml, docs/dependencies/DEPENDENCY_POLICY.md |
| Scripts/validate_symbols_5_24.sh | sh | Scripts | LEGACY_REVIEW | KEEP | Scripts/validate_quality_scans.sh, Scripts/validate_release.sh, docs/_meta/scripts.yml, docs/audits/SAFESFSYMBOLS_USAGE_AUDIT.md |
| Scripts/validate_test_matrix.sh | sh | Scripts | ACTIVE | KEEP | Scripts/validate_519_package_tests_docs.sh, docs/_meta/scripts.yml, docs/maintainers/TEST_MATRIX.md |
| Scripts/validate_ui_5_13_contract.sh | sh | Scripts | LEGACY_REVIEW | KEEP | Scripts/validate_quality_scans.sh, docs/_meta/scripts.yml |
| Scripts/validate_xcode_source_warnings.sh | sh | Scripts | ACTIVE | KEEP | Scripts/CI/quality_gate.sh, Scripts/CI/quality_gates.yml, docs/_meta/scripts.yml |
