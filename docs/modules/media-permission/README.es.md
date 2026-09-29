---
module: "MediaPermission"
module_id: "media-permission"
language: "es"
status: "compatibility"
minimum_ios: "17.0"
swift: "6+"
swiftpm_product: "null"
cocoapods_subspec: "MediaPermission"
source: "manifest-only"
category: "compatibility"
last_reviewed: "2026-09-28"
canonical: false
canonical_source: "README.en.md"
product_version_source: "repository:VERSION"
document_schema_version: 1
---

# MediaPermission

## 1. Descripción

MediaPermission es un módulo PTools de categoría compatibility. Esta guía se genera desde el registro canónico y describe el límite compatible en iOS 17+ y Swift 6+.

## 2. Requisitos

- Plataforma: iOS 17.0+
- Swift: 6+
- Categoría: `compatibility`
- Estado: `compatibility`

## 3. Instalación

Swift Package Manager:

```swift
// This entry is CocoaPods-only; import the module exposed by the selected subspec.
```

CocoaPods:

```ruby
pod 'PooTools/MediaPermission'
```

## 4. Importación

```swift
// This entry is CocoaPods-only; import the module exposed by the selected subspec.
```

## 5. Inicio rápido

Usa el producto o subspec mínimo publicado. El nombre del registro es `MediaPermission`; no inventes productos ni dependencias no publicadas.

## 6. Conceptos principales

La frontera pública prioriza tipos de valor. Dependencias directas registradas: None declared by the registry..

## 7. API principales

Usa solo símbolos públicos estables. La referencia completa pertenece a los informes de API generados.

## 8. Casos de uso

Los casos de uso deben permanecer en la categoría del módulo y no duplicar una implementación canónica de otro módulo PTools.

## 9. Uso avanzado

Inyecta un proveedor o una política solo si la API pública lo expone. No accedas al estado interno ni cambies la propiedad privada de UIKit.

## 10. Concurrencia Swift

El trabajo de UI usa `@MainActor`; los valores compartidos deben ser `Sendable`; la cancelación debe propagarse por el `Task` propietario.

## 11. Ciclo de vida

Respeta el contrato start/stop, register/unregister y el ciclo de vida de Scene. No retengas un controlador anfitrión sin necesidad.

## 12. Errores

Gestiona los errores públicos explícitamente. Los fallos recuperables vuelven al host; los fallos de permisos y configuración no se ocultan.

## 13. Permisos / Entitlements / Info.plist

No hay requisitos adicionales salvo que el código exponga permisos, entitlements, modos de background o claves Info.plist.

## 14. Comportamiento en Simulator

El comportamiento de hardware, notificaciones, background, audio, cámara o extensiones puede diferir en Simulator; usa un dispositivo real.

## 15. Accesibilidad

Las integraciones UI deben conservar Dynamic Type, VoiceOver, Reduce Motion, Reduce Transparency y RTL.

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
