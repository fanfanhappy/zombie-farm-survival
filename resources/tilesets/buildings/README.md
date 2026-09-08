# buildings 目录说明

## 职责

房屋和围墙专用 TileSet，供可视化建筑层绘制。

## 当前内容

- `perimeter_fence_tileset.tres`：Godot 可视化资源；双击后在检查器维护具体字段和引用。
- `wooden_house_doors.tres`：Godot 可视化资源；双击后在检查器维护具体字段和引用。
- `wooden_house_roof.tres`：Godot 可视化资源；双击后在检查器维护具体字段和引用。
- `wooden_house_walls.tres`：Godot 可视化资源；双击后在检查器维护具体字段和引用。

## 维护规则

- 优先通过 Godot 检查器修改 tres；更换被引用资源时保持 ID 和路径稳定，并运行资源完整性测试。
- 文件使用英文蛇形命名；同类文件保持统一前缀，避免含糊名称。
- 删除或移动文件前，用全项目引用搜索确认场景、资源与脚本没有依赖。

