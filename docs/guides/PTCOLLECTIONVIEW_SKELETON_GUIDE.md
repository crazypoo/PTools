# PTCollectionView Skeleton / Skeleton de PTCollectionView / PTCollectionView 骨架

## Overview / Resumen / 概览

`PTCollectionView` 的骨架是独立覆盖层，不会伪造 `PTSection`、`PTRows`，也不会触发业务 Cell 配置回调。骨架、loading、empty 和 content 由同一条 MainActor 状态链仲裁。

The skeleton is an independent overlay. It does not create fake `PTSection`/`PTRows` values or invoke business-cell callbacks. Skeleton, loading, empty, and content are reconciled on one MainActor state path.

El skeleton es una capa independiente. No crea valores falsos `PTSection`/`PTRows` ni ejecuta callbacks de celdas de negocio. Skeleton, loading, empty y content se reconcilian en una única ruta MainActor.

## Basic usage / Uso básico / 基本用法

```swift
let configuration = PTCollectionSkeletonConfiguration(
    layout: PTCollectionSkeletonLayout(itemHeight: 72,
                                       verticalSpacing: 12,
                                       cornerRadius: 10),
    animation: PTCollectionSkeletonAnimation(style: .shimmer),
    transition: .crossDissolve(duration: 0.2),
    content: .card,
    itemCountMode: .fillViewport(extraRows: 1),
    interactionPolicy: .blocksTouches,
    minimumVisibleDuration: 0.25
)

collectionView.showSkeleton(configuration: configuration)

loadContent { result in
    Task { @MainActor in
        switch result {
        case .success(let sections):
            collectionView.showCollectionDetail(collectionData: sections)
        case .failure:
            collectionView.showEmptyLoading(isLoading: false)
        }
        collectionView.hideSkeleton()
    }
}
```

旧入口仍然可用：

```swift
collectionView.showSkeleton(itemCount: 6)
collectionView.hideSkeleton()
```

The legacy entry point remains source-compatible. / El punto de entrada heredado sigue siendo compatible. / 旧入口保持源码兼容。

## Layouts and content / Layouts y contenido / 布局与内容

`PTCollectionSkeletonLayout` 与真实列表布局解耦，支持普通列表、Grid、Tag、Waterfall、Horizontal、HorizontalLayoutSystem 和 Custom。`itemHeight`、`itemWidth`、间距、列数、Insets、圆角和几何 Provider 都可以独立配置。

Available content presets are `.block`, `.text`, `.avatarText`, `.imageText`, `.card`, and `.custom(shapes:)`. Shapes use normalized coordinates by default, so one descriptor adapts to different cell sizes, RTL direction, rotation, and iPhone Duo safe areas.

Los presets disponibles son `.block`, `.text`, `.avatarText`, `.imageText`, `.card` y `.custom(shapes:)`. Las formas usan coordenadas normalizadas por defecto y se adaptan a distintos tamaños, RTL, rotación y safe areas de iPhone Duo.

可用内容模板包括 `.block`、`.text`、`.avatarText`、`.imageText`、`.card` 和 `.custom(shapes:)`。形状默认使用归一化坐标，可适配不同尺寸、RTL、旋转和 iPhone Duo 安全区域。

## Sections and supplementary views / Secciones y vistas auxiliares / Section 与辅助视图

Use `PTSkeletonSectionDescriptor` when sections, headers, or footers have different shapes. These descriptors are presentation-only and never enter the business Diffable snapshot.

使用 `PTSkeletonSectionDescriptor` 可以让不同 Section 拥有独立的形状、Header 和 Footer。它们只描述展示，不会进入业务 Diffable snapshot。

Usa `PTSkeletonSectionDescriptor` cuando cada sección necesite formas, headers o footers distintos. Estos descriptores solo representan la presentación y nunca entran en el snapshot Diffable de negocio.

## Updating and cancellation / Actualización y cancelación / 更新与取消

```swift
collectionView.updateSkeleton(configuration: configuration, animated: true)
collectionView.invalidateSkeletonLayout()
collectionView.hideSkeleton()
```

调用方必须在请求成功、失败或取消时显式 `hideSkeleton()`。显示延迟和最短显示时长会由 generation token 保护，旧请求不会隐藏新一代骨架。

The caller explicitly hides the skeleton on success, failure, or cancellation. Show-delay and minimum-visible timing are protected by generation tokens, so an old request cannot hide a newer skeleton session.

El consumidor oculta explícitamente el skeleton en éxito, error o cancelación. El retraso de presentación y la duración mínima usan tokens de generación para que una solicitud antigua no oculte una sesión nueva.

## Accessibility and animation / Accesibilidad y animación / 无障碍与动画

`PTCollectionSkeletonAnimation` 支持 solid、gradient、pulse、shimmer 和 none。开启 Reduce Motion 时会停止渐变动画；`interactionPolicy` 可选 `blocksTouches`、`allowsScrolling` 或 `passthrough`。骨架覆盖层默认不作为无障碍元素读取，但可以通过 `accessibilityLabel` 提供加载状态。

`PTCollectionSkeletonDiagnosticsSnapshot` 只返回请求状态、显示状态、数量、Section 数量、动画样式和 generation，不泄露业务 Row 数据。

## Validation / Validación / 验证

- UIKit target: iOS 17+ / Swift 6。
- 骨架显示不改变 Diffable snapshot，也不调用业务 Cell 回调。
- Zero bounds、无效尺寸、过大数量和 Reduce Motion 都会安全回退。
- 使用现有 `PToolsUIFoundationTests` 验证默认值、策略、几何配置和形状清理。
- Use the Example route **Collection Skeleton Lab** for visual checks across layouts, Dynamic Type, RTL, dark mode, Reduce Motion, and rotation.

