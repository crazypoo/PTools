# PTLayout 5.67.1 console bridge evidence

- Install point: `PTBaseViewController.viewDidLoad` calls `PTLayoutConsoleBridge.install()` before base constraints.
- Sink path: aggregate PTools forwards PTL diagnostics to `PTNSLogConsole`; standalone consumers use the fallback sink.
- Static evidence SHA: `80126150505961e259cce5e08ada67962265c063`.
- First missing-superview PTL001 log and duplicate suppression: `blocked_external_host` until the host fixture runs.

中文：源码调用链已固定；第一条真实 PTL001 日志仍需宿主运行验证。
Español: La cadena de instalación está fijada; el primer PTL001 real requiere ejecutar el host.
