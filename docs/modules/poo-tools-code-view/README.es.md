---
module: "PooToolsCodeView"
module_id: "poo-tools-code-view"
language: "es"
status: "stable"
minimum_ios: "17.0"
swift: "6+"
swiftpm_product: "PooToolsCodeView"
cocoapods_subspec: "CodeView"
source: "PooToolsSource/CodeView"
category: "ui-leaf"
last_reviewed: "2026-10-20"
canonical: false
canonical_source: "README.en.md"
product_version_source: "repository:VERSION"
document_schema_version: 1
---

# PooToolsCodeView

## 1. Descripción

PooToolsCodeView es el nombre de SwiftPM para el módulo estable de interfaz UI-leaf de PTools. Esta guía se genera desde el registro canónico y describe el límite compatible en iOS 17+ y Swift 6+.

## 2. Requisitos

- Plataforma: iOS 17.0+
- Swift: 6+
- Categoría: `ui-leaf`
- Estado: `stable`
- Límite de plataforma: esta vista UIKit se ofrece para iOS; el módulo no expone un target UIKit para watchOS o macOS y no declara compatibilidad con visionOS.

## 3. Instalación

Swift Package Manager:

```swift
import PooToolsCodeView
```

CocoaPods:

```ruby
pod 'PooTools/CodeView'
```

## 4. Importación

```swift
import PooToolsCodeView
```

## 5. Inicio rápido

Usa `PooToolsCodeView` con SwiftPM o `PooTools/CodeView` con CocoaPods. El módulo admite generación local, texto externo e imagen externa suministrados por el host.

## 6. Conceptos principales

El módulo solo depende de la frontera Core de PTools. No descarga ni decodifica medios remotos; el host realiza el trabajo de red y entrega el texto o la imagen.

## 7. API principales

Usa `PTCodeView(numberOfCodes:numberOfLines:changeTimes:)` para generar localmente; `changeTimes` es el intervalo automático en segundos y `0` lo desactiva. Usa `setCode(_:)` para texto externo, `setCodeImage(_:)` para una imagen y `requestRefresh()` para actualizar de forma programática. Las actualizaciones externas llegan por `onRefreshRequested`; las locales por `codeBlock`.

```swift
let codeView = PTCodeView(numberOfCodes: 4, numberOfLines: 3, changeTimes: 0)
codeView.setCode("SERVER-001")
codeView.onRefreshRequested = { view, reason in
    view.setCode("SERVER-002")
}
```

## 8. Casos de uso

Los casos de uso deben permanecer en la categoría del módulo y no duplicar una implementación canónica de otro módulo PTools.

## 9. Uso avanzado

Inyecta un proveedor o una política solo si la API pública lo expone. No accedas al estado interno ni cambies la propiedad privada de UIKit.

## 10. Concurrencia Swift

El trabajo de UI usa `@MainActor`. `PTCodeRefreshReason` es `Sendable` y los callbacks externos permanecen en el actor de la vista. La actualización automática se cancela al salir de la ventana o al entrar en background.

## 11. Ciclo de vida

Respeta el contrato start/stop, register/unregister y el ciclo de vida de Scene. No retengas un controlador anfitrión sin necesidad.

## 12. Errores

Gestiona los errores públicos explícitamente. Los fallos recuperables vuelven al host; los fallos de permisos y configuración no se ocultan.

## 13. Permisos / Entitlements / Info.plist

No hay requisitos adicionales salvo que el código exponga permisos, entitlements, modos de background o claves Info.plist.

## 14. Comportamiento en Simulator

El comportamiento de hardware, notificaciones, background, audio, cámara o extensiones puede diferir en Simulator; usa un dispositivo real.

## 15. Accesibilidad

La vista expone una acción de VoiceOver llamada “刷新验证码” y mantiene la imagen sin interacción. Si el código no debe anunciarse, el host debe proporcionar una etiqueta accesible adecuada.

## 16. Rendimiento

Mantén el trabajo fuera del actor principal cuando no sea UI. Limita memoria, caché, medios y red según el servicio propietario.

## 17. Privacidad y seguridad

No registres tokens, cookies, credenciales, payloads privados ni entradas completas; usa la frontera tipada del módulo.

## 18. Integración con otros módulos PTools

Prefiere los servicios y adapters canónicos de PTools en lugar de crear cachés, routers, permisos o planificadores paralelos.

## 19. Migración

Los wrappers de compatibilidad siguen disponibles durante 5.x. El código nuevo debe usar la entrada canónica del registro.

## 20. Solución de problemas

Ante un problema, verifica selección de módulo, target membership, Scene context, permisos, cancelación e informes generados antes de editar código.

## 21. Proyecto de ejemplo

Consulta el proyecto Example y el registro de tests para cobertura ejecutable. Los entitlements del host son responsabilidad del host.

## 22. Documentación relacionada

[Índice de documentación](../../index/README.es.md) · [Arquitectura](../../architecture/ARCHITECTURE.md) · [Calidad](../../maintainers/QUALITY.md)
