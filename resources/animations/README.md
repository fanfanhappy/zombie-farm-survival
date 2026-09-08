# animations 目录说明

## 职责

角色、动物与可采集物的 SpriteFrames 动画资源。帧区域、顺序、FPS 和循环设置都在这里维护。

## 当前内容

- `chicken_sprite_frames.tres`：Godot 可视化资源；双击后在检查器维护具体字段和引用。
- `player_sprite_frames.tres`：Godot 可视化资源；双击后在检查器维护具体字段和引用。
- `stone_harvest_sprite_frames.tres`：Godot 可视化资源；双击后在检查器维护具体字段和引用。
- `tree_harvest_sprite_frames.tres`：Godot 可视化资源；双击后在检查器维护具体字段和引用。

## 维护规则

- 优先通过 Godot 检查器修改 tres；更换被引用资源时保持 ID 和路径稳定，并运行资源完整性测试。
- 文件使用英文蛇形命名；同类文件保持统一前缀，避免含糊名称。
- 删除或移动文件前，用全项目引用搜索确认场景、资源与脚本没有依赖。

