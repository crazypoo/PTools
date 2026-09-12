# PTools 5.10.x Debug Swizzle Registry

## 注册规则

`PTSwizzleRegistry` 以目标类型、原方法、替换方法和 class/instance 标记作为唯一键，并记录 owner。重复 start 只会命中同一个键，不能再次交换实现。

每个 Debug hook 使用明确 owner：

| Owner | Hook |
| --- | --- |
| `debug.window` | Debug window 生命周期 |
| `debug.view-border` | View border |
| `debug.network` | URLSession 配置 |
| `debug.lifecycle` | UIViewController 生命周期 |
| `debug.inspector` | Inspector view hook |
| `debug.mock-location` | CLLocationManager |
| `debug.console-border` | 控制台边框显示 |
| `core.context-menu` | Core 通用 context menu 能力 |
| `core.window-subview` | Core 通用 window subview 能力 |

## 停止语义

- `PTDebugManager` 和各 Collector 的 start/stop 是幂等的。
- 可安全撤销的状态（任务、callback、notification、console sink）在 stop 或 Scene disconnect 时释放。
- Objective-C runtime swizzle 和 signal handler 没有安全通用的 undo；这些 hook 保留 registry owner，并在代码中说明不可逆原因。
- 新增 hook 必须先登记 owner，不得直接调用裸 swizzle。

## 验证

静态 owner 扫描和完整 Debug Xcode 构建已通过。重复 start、多个 Scene 同时打开、Scene disconnect 后重连、Debug disabled 高频路径仍需真实宿主回归。
