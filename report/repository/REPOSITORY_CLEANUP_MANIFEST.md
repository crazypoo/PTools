<!-- AUTO-GENERATED FILE. DO NOT EDIT.
Generator: Scripts/Governance/audit_repository.py
Source revision: f903ce58e855a57a32a4c867b67b22a6cb02359f -->
# Repository Cleanup Manifest

- Version: `5.56.2`
- Records: `10`

| area | old | canonical | action | consumers |
| --- | --- | --- | --- | --- |
| Docs | historical plan files | docs/archive/ or Git history | KEEP | No current plan files remain in the active tree |
| Scripts | Scripts/report_public_api_5_9.rb | Scripts/report_public_api.rb | MERGED_AND_REPOINTED | validate_59_contracts.sh; validate_quality_scans.sh; API baseline documentation |
| Scripts | Scripts/report_*_5_9.rb | Scripts/report_*.rb | MERGED_AND_REPOINTED | quality and lifecycle validators |
| Scripts | paapidetect.sh + paapi.txt | Scripts/Privacy/validate_privacy_accessed_api.sh + paapi.txt | MOVED_AND_REPOINTED | none; router entry added |
| Scripts | Scripts/report_public_api_5_8.rb; Scripts/generate_58_reports.sh | Git history and Scripts/ptools.py reports regenerate-5.8 | DELETED_AFTER_CONSUMER_SCAN | none |
| Scripts | Scripts/CI/check_5_36_1_finalization.sh | Git history | DELETED_AFTER_CONSUMER_SCAN | none; generated index only |
| Data | PooTools/Images.xcassets/Contents.json, PooToolsSource/Resource/ElementLibrary.xcassets/Originals/Contents.json, PooToolsSource/Resource/ElementLibrary.xcassets/Templates/Contents.json, PooToolsSource/Resource/ElementLibrary.xcassets/Templates/UIView/Contents.json, PooToolsSource/Resource/OSSKitImages.xcassets/Contents.json, PooToolsSource/Resource/Symbols.xcassets/Contents.json, PooToolsSource/Resource/Symbols.xcassets/Generic/Contents.json, PooToolsSource/Resource/Symbols.xcassets/Layer Actions/Contents.json, PooToolsSource/Resource/Symbols.xcassets/Panel/Contents.json | same source pending owner review | DUPLICATE_REVIEW | not automatically deleted |
| Data | PooTools/Images.xcassets/Day/Contents.json, PooTools/Images.xcassets/TagImage/Contents.json | same source pending owner review | DUPLICATE_REVIEW | not automatically deleted |
| Data | PooToolsSource/Resource/OSSKitImages.xcassets/nb-NO.imageset/Contents.json, PooToolsSource/Resource/OSSKitImages.xcassets/no-NO.imageset/Contents.json | same source pending owner review | DUPLICATE_REVIEW | not automatically deleted |
| Data | PooToolsSource/Resource/OSSKitImages.xcassets/zh-CH.imageset/Contents.json, PooToolsSource/Resource/OSSKitImages.xcassets/zh-CN.imageset/Contents.json | same source pending owner review | DUPLICATE_REVIEW | not automatically deleted |
