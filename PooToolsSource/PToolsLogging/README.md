# PToolsLogging

<!-- English: This target contains the 5.21.x logging contract, memory diagnostics and opt-in file destination. -->
<!-- Español: Este target contiene el contrato de logging 5.21.x, el diagnóstico en memoria y el destino de archivos opcional. -->
<!-- 中文：此 target 在 5.21.x 包含日志契约、内存诊断和可选文件日志目标。 -->

`PToolsLogging` provides synchronous lazy logging, OSLog output, privacy redaction,
a bounded memory destination and an opt-in file destination. It intentionally does
not import UIKit or CocoaLumberjack. File and memory work use bounded consumers;
LocalConsole and Instruments subscribe to immutable snapshots without owning the
logging pipeline.
