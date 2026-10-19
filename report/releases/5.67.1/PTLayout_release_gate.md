# PTLayout 5.67.1 release gate

```json
{
  "version": "5.67.1",
  "generated_at": "2026-10-18T19:18:18.089060+00:00",
  "source_revision": "7bab5e185402dbeba7a04e17641a3ee1ad078c70",
  "inventory_rows": 1405,
  "failure_fixtures": 56,
  "standalone_runtime": "xcodebuild iOS Simulator passed: F01-F56, 56/56",
  "runtime_evidence": "report/layout/runtime_parity_5.67.1.json + report/layout/runtime_parity_5.67.1.csv; xcresult cleaned after validation",
  "visual_regression": "not_run",
  "consumer_validation": "blocked_missing_report_spm_onepass",
  "iphone26_validation": "partial: report/layout/iphone26_validation_5.67.1.json; build/install/launch/relaunch/screenshot passed; PTLayout Demo flow pending",
  "release_decision": "blocked_visual_consumer_device_validation"
}
```

中文：静态审计不替代 Xcode Simulator、CocoaPods Consumer 和真机视觉验证。
Español: La auditoría estática no sustituye Xcode Simulator, CocoaPods Consumer ni la validación visual en dispositivo.
