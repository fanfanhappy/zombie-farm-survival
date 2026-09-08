# definitions 目录说明

## 职责

一物品一资源的定义目录，负责名称、图标、分类、堆叠和玩法参数。

## 当前内容

- `bandage.tres`：Godot 可视化资源；双击后在检查器维护具体字段和引用。
- `carrot_seed.tres`：Godot 可视化资源；双击后在检查器维护具体字段和引用。
- `carrot.tres`：Godot 可视化资源；双击后在检查器维护具体字段和引用。
- `egg.tres`：Godot 可视化资源；双击后在检查器维护具体字段和引用。
- `herb_seed.tres`：Godot 可视化资源；双击后在检查器维护具体字段和引用。
- `herb.tres`：Godot 可视化资源；双击后在检查器维护具体字段和引用。
- `meal.tres`：Godot 可视化资源；双击后在检查器维护具体字段和引用。
- `potato_seed.tres`：Godot 可视化资源；双击后在检查器维护具体字段和引用。
- `potato.tres`：Godot 可视化资源；双击后在检查器维护具体字段和引用。
- `repair_hammer.tres`：Godot 可视化资源；双击后在检查器维护具体字段和引用。
- `scrap.tres`：Godot 可视化资源；双击后在检查器维护具体字段和引用。
- `snare_trap.tres`：Godot 可视化资源；双击后在检查器维护具体字段和引用。
- `stone_axe.tres`：Godot 可视化资源；双击后在检查器维护具体字段和引用。
- `stone_hoe.tres`：Godot 可视化资源；双击后在检查器维护具体字段和引用。
- `stone_pickaxe.tres`：Godot 可视化资源；双击后在检查器维护具体字段和引用。
- `stone.tres`：Godot 可视化资源；双击后在检查器维护具体字段和引用。
- `storage_chest.tres`：Godot 可视化资源；双击后在检查器维护具体字段和引用。
- `watering_can.tres`：Godot 可视化资源；双击后在检查器维护具体字段和引用。
- `wood_fence.tres`：Godot 可视化资源；双击后在检查器维护具体字段和引用。
- `wood_spike.tres`：Godot 可视化资源；双击后在检查器维护具体字段和引用。
- `wood.tres`：Godot 可视化资源；双击后在检查器维护具体字段和引用。
- `wooden_club.tres`：Godot 可视化资源；双击后在检查器维护具体字段和引用。

## 维护规则

- 优先通过 Godot 检查器修改 tres；更换被引用资源时保持 ID 和路径稳定，并运行资源完整性测试。
- 文件使用英文蛇形命名；同类文件保持统一前缀，避免含糊名称。
- 删除或移动文件前，用全项目引用搜索确认场景、资源与脚本没有依赖。

