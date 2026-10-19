# PTools 5.67.4 导航标题布局指南

## 中文

5.67.4 将系统导航容器与 `PTNavBar` 的自定义标题布局统一到同一套内部解析器。现有调用方式不需要修改：

```swift
setCustomTitleView(titleView, fillSpace: true)
```

`fillSpace: true` 会让标题使用左右按钮之间的可用区域；`false` 会按标题自身测量结果居中。`PTNavBar` 继续支持 `.auto`、`.fixed(width)` 和 `.fill`。安全区域、分屏、旋转、按钮尺寸和伪导航栏宿主高度变化会自动重新计算。

标题视图仍由调用方持有和配置，布局使用项目现有的 SnapKit `.snp` 入口；不需要把业务代码迁移到 PTLayout。不要在标题视图内部额外添加与 `PTNavBar.titleContainer` 相冲突的外部约束。

## English

In 5.67.4 the system navigation container and `PTNavBar` share one value-based title geometry and size resolver. Existing calls remain source-compatible:

```swift
setCustomTitleView(titleView, fillSpace: true)
```

`fillSpace: true` uses the space between the physical left and right item groups; `false` centers the measured title. `PTNavBar` still supports `.auto`, `.fixed(width)`, and `.fill`. Safe areas, split panes, rotation, button sizes, and fake-navigation host height changes trigger an idempotent recalculation.

The caller still owns and configures the title view. Layout uses the existing SnapKit `.snp` boundary; migrating business code to PTLayout is not required. Avoid adding competing external constraints to `PTNavBar.titleContainer`.

## Español

En 5.67.4 el contenedor de navegación del sistema y `PTNavBar` comparten un resolvedor de geometría y tamaño basado en valores. Las llamadas existentes siguen siendo compatibles:

```swift
setCustomTitleView(titleView, fillSpace: true)
```

`fillSpace: true` utiliza el espacio entre los grupos físicos de botones izquierdo y derecho; `false` centra el título medido. `PTNavBar` conserva `.auto`, `.fixed(width)` y `.fill`. Los cambios de área segura, panel dividido, rotación, tamaño de botones y altura del host falso provocan un recálculo idempotente.

La vista de título sigue siendo propiedad del llamador. El layout utiliza la frontera SnapKit `.snp` existente; no es necesario migrar el código de negocio a PTLayout. Evita añadir restricciones externas que compitan con `PTNavBar.titleContainer`.
