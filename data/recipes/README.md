# recipes 目录说明

## 职责

旧配方 JSON 目录。配置已迁移到 `resources/recipes/`。

## 维护规则

- 此目录的文件不应被运行时代码直接读取，除非先更新架构文档并明确唯一数据源。
- 迁移后的实际编辑入口请使用上面标出的 resources 目录。
- 参考图片只用于比对图集布局；Terrain 连接规则必须在 Godot TileSet 编辑器中人工确认。

