# PTAcknowledgements

`PTAcknowledgementsCore` es el producto offline basado solo en Foundation. `PToolsAcknowledgements` es la UI UIKit opcional para lista y detalle.

## Datos headless

```swift
import PToolsAcknowledgementsCore

let manifest = try PTAcknowledgementsProvider.load()
let matches = manifest.search("alamofire")
let summary = manifest.statistics()
let json = try manifest.export(.json)
```

Core no importa UIKit, SnapKit ni el agregado completo `ptools`. Sirve para pantallas propias, extensiones, CLI y pruebas. El manifest se genera durante la compilación y no usa red en runtime.

## UI UIKit integrada

```swift
import PToolsAcknowledgements

navigationController?.pushViewController(
    PTAcknowledgementsViewController(),
    animated: true
)
```

Cuando está disponible el target UIKit de PTools, las pantallas de lista y detalle heredan explícitamente de `PTBaseViewController` y reutilizan su navegación, ciclo de vida y barra de estado. Solo un build independiente sin ese target usa `UIViewController` como fallback.

## Generación durante la compilación

```sh
bash Scripts/pt_acknowledgements_build.sh
bash Scripts/validate_acknowledgements.sh .build/acknowledgements/PTAcknowledgements.json
```

Copia `PTAcknowledgements.json` al bundle correcto de la App. Release y CI usan validación estricta; el texto de licencia ausente, un manifest inválido o un conflicto nunca se presentan silenciosamente como una lista vacía.
