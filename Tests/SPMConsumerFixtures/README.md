# SwiftPM consumer fixtures

This directory records the product/import matrix generated from the package manifest.
It intentionally does not claim a build: isolated product builds require an iOS Xcode host.

Use `Scripts/CI/build_spm_consumer_matrix.sh --require-build` with `SPM_CONSUMER_FIXTURE_PROJECT` and `SPM_CONSUMER_SCHEME` configured to record real Debug/Release evidence.

这个目录只保存由 manifest 生成的 product/import 矩阵；`not_run` 不是通过。
