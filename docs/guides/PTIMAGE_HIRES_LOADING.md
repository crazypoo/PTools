# PTools 高分辨率图片加载指南

## 目标

PTools 5.64.6 将图片加载的“布局点尺寸”和“解码像素尺寸”明确分开：调用方提供 UIKit 点尺寸，Core 根据实际窗口屏幕比例转换为像素后交给 PhotoKit、ImageIO、Kingfisher 或视频缩略图服务。

PTools 5.64.6 separa el tamaño de diseño en puntos del tamaño de decodificación en píxeles. La escala se obtiene del `UIWindowScene` activo cuando la vista ya está instalada en una ventana.

PTools 5.64.6 separates UIKit layout points from decode pixels. The Core loader resolves the active window screen scale at the UI boundary and keeps the 4096-pixel safety budget for large assets.

## 推荐调用

```swift
imageView.loadImage(contentData: source,
                   emptyImage: UIImage(named: "image-placeholder"))
```

`UIImageView` 和 `UIButton` 会立即清理旧图并设置 `emptyImage`。如果首次调用时控件尚未完成布局，Core 会等待一次主线程布局机会，再使用实际图片区域请求目标尺寸；Cell 复用时旧任务仍可通过 `cancelImageLoad()` 取消。

`UIImageView` y `UIButton` muestran el placeholder antes de la carga. Las solicitudes antiguas siguen protegidas por UUID/generation para que una celda reutilizada no reciba una imagen obsoleta.

## 尺寸规则

- `targetSize` 是点尺寸，不要手动乘 `UIScreen.main.scale`。
- PhotoKit 的 `requestImage`、ImageIO 降采样和视频封面边界会接收像素尺寸。
- Kingfisher 使用点尺寸处理器并附加实际 `scaleFactor`，同时保留原图缓存以避免较大后续请求复用较小变体。
- 未安装到窗口时使用安全回退比例；业务不应在 Core 层写死设备比例。
- 默认最大像素尺寸仍为 `4096`，用于限制大图/GIF 的峰值内存。

## 来源兼容

`PTImageSource.image/data/asset/color/url/named/videoURL/avAsset` 和旧的 `Any` 入口继续可用。视频 URL 默认获取第 10 帧；GIF、iCloud、取消、进度回调和旧 completion 行为不变。

`PTRichText` 的远程图片仍应通过 `PTLoadImageFunction.makeTextAttachmentCoordinator()` 或现有媒体 loader 进入同一条 Core 管线，下载期间使用占位图。

## 验收清单

- 普通 `UIImageView`、`UIButton`、PhotoKit 资源、GIF、远程图片和视频首帧均按窗口比例加载。
- 首次 bounds 为零时不直接解码整张原图。
- 快速复用不会发生旧请求回写。
- `emptyImage` 在每次新请求开始前可见。
- Debug / Release Simulator 构建和真实设备视觉验收分别记录，不以静态解析代替运行时验证。
