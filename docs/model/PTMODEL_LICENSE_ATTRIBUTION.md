# PTModel License and Attribution Boundary

`PToolsModelCore` 的实现为 PTools 自有 Foundation-only 代码，不复制 SmartCodable、
SmartCodableMacro 或 KakaJSON 的内部实现。

第三方兼容 Adapter 若在后续版本加入，必须继续放在独立产品中，并保留对应上游许可证、
版本、来源和行为 fixture；Core 不得通过隐藏 import 重新引入这些依赖。
