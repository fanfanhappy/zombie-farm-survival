# tilesets 目录说明

## 职责

地形、农田、资源点与装饰使用的 TileSet 资源。

## 当前内容

- `farm_tilled_terrain.tres`：Godot 可视化资源；双击后在检查器维护具体字段和引用。
- `harvestable_resource_scenes.tres`：Godot 可视化资源；双击后在检查器维护具体字段和引用。
- `static_decoration_scenes.tres`：Godot 可视化资源；双击后在检查器维护具体字段和引用。
- `terrain_grass_tileset.tres`：Godot 可视化资源；双击后在检查器维护具体字段和引用。
- `terrain_path_tileset.tres`：Godot 可视化资源；双击后在检查器维护具体字段和引用。
- `terrain_water_tileset.tres`：Godot 可视化资源；双击后在检查器维护具体字段和引用。

## 维护规则

- 优先通过 Godot 检查器修改 tres；更换被引用资源时保持 ID 和路径稳定，并运行资源完整性测试。
- 文件使用英文蛇形命名；同类文件保持统一前缀，避免含糊名称。
- 删除或移动文件前，用全项目引用搜索确认场景、资源与脚本没有依赖。

