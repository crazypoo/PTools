# PTLayout 5.67.1 migration decisions

- source SHA: `80126150505961e259cce5e08ada67962265c063`
- worktree diff SHA-256: `dd049abfcb1dea64bcdf504eb61d8fbbea12c014ee4fde52a433ae77bb333077`
- migrated rows: `881`
- approved compatibility rows: `93`
- unresolved rows: `0`

普通 PTools UIKit 调用点使用 `ptLayout`；PTLayout 原生引擎、公开 SnapKit 兼容边界和 AppKit 路径不被机械替换。
English: Ordinary PTools-owned UIKit constraints use ptLayout; native engine and documented compatibility boundaries remain explicit.
Español: Las restricciones UIKit propias usan ptLayout; el motor nativo y los límites de compatibilidad quedan documentados.
