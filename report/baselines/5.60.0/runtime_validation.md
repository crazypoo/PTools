# PTools 5.60.0 Runtime Validation Status

> English: Simulator compilation is not a substitute for device, host, or Instruments evidence.
>
> Español: La compilación del simulador no sustituye la evidencia del dispositivo, host o Instruments.
>
> 中文：模拟器编译不能替代真机、真实宿主或 Instruments 证据。

## Pending flows

| Flow | Status | Required evidence |
| --- | --- | --- |
| `Network.requestPTModel` root | PENDING_HOST | Real host response and decode result |
| `Network.requestPTModel` `$.data` | PENDING_HOST | Envelope response and path diagnostics |
| Array path / deep path | PENDING_HOST | List and nested path payloads |
| PhotoPicker / MediaViewer | PENDING_DEVICE | iCloud, cancellation, memory and reuse behavior |
| VideoEditor / ImageEditor | PENDING_DEVICE | Export, cancellation, save and memory behavior |
| Multi-Scene navigation and permissions | PENDING_DEVICE | Scene presentation and lifecycle trace |
| PTInstruments | PENDING_INSTRUMENTS | CPU, memory, FPS, hitch, main-thread stall and long session |

The generated `report/current/mainactor_runtime_validation.md` remains the machine-readable release blocker for these flows.
