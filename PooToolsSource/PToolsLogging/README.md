# PToolsLogging

<!-- English: This target contains the 5.20.x logging contract, OSLog backend and opt-in file destination. -->
<!-- Español: Este target contiene el contrato de logging 5.20.x, el backend OSLog y el destino de archivos opcional. -->
<!-- 中文：此 target 在 5.20.x 包含日志契约、OSLog 后端和可选文件日志目标。 -->

`PToolsLogging` provides synchronous lazy logging, OSLog output, privacy redaction
and an opt-in file destination. It intentionally does not import UIKit or
CocoaLumberjack. File I/O is performed by one bounded stream consumer and an
actor-owned writer; UI and Debug consumers remain outside this module.
