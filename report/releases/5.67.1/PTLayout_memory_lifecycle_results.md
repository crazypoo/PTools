# PTLayout 5.67.1 memory and lifecycle review

- Source review: diagnostics use weak view keys and a bounded repeated-issue order.
- Source review: group activation is flattened and activated as one UIKit batch.
- Source review: repeated cell/Scene/device runtime proof is **blocked_external_host**.
- Required runtime cases: handle release, repeated remove/remake, cell reuse 100/1000 times, detach/reparent, multiple scenes, and deinit.

中文：静态实现已核对，内存图、真机生命周期和多 Scene 结果不能由源码审计代替。
Español: La revisión estática está hecha; el ciclo de vida real y la memoria requieren un host externo.
