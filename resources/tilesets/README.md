# tilesets 目录说明

## 职责

地形、农田、资源点与装饰使用的 TileSet 资源。

## 当前内容

- `farm_tilled_terrain.tres`：开垦土地的自动拼接资源；当前只启用详细图集左上角的一套完整 `4×4` Terrain 模板，避免与同图中的其他模板混用。运行时会根据动态农田坐标调用 Terrain Set 拼接，因此只需在这里可视化修正位图区域和地形连接规则。
- `harvestable_resource_scenes.tres`：Godot 可视化资源；双击后在检查器维护具体字段和引用。
- `static_decoration_scenes.tres`：Godot 可视化资源；双击后在检查器维护具体字段和引用。
- `terrain_grass_tileset.tres`：Godot 可视化资源；双击后在检查器维护具体字段和引用。
- `terrain_hills_tileset.tres`：山丘与高地可视化切片资源，在 `HillLayer` 中绘制；不再保留无内容的同名 `.tscn`。
- `terrain_path_tileset.tres`：Godot 可视化资源；双击后在检查器维护具体字段和引用。
- `terrain_water_tileset.tres`：水体动画瓦片及其碰撞；绘制或擦除水瓦片时，物理碰撞会同步生成或移除。

## 维护规则

- 优先通过 Godot 检查器修改 tres；更换被引用资源时保持 ID 和路径稳定，并运行资源完整性测试。
- 文件使用英文蛇形命名；同类文件保持统一前缀，避免含糊名称。
- 删除或移动文件前，用全项目引用搜索确认场景、资源与脚本没有依赖。
- 瓦片地形的连接规则、动画与碰撞都应保存在 TileSet 中；禁止再用独立场景手工复刻同一片区域的碰撞。
- 当前水图是四帧循环的“水面底图”，岸边形状由 `terrain_grass_tileset.tres` 的 Terrain Set 自动拼接后覆盖在水面上；两层共同组成完整池塘。
