# resources 目录说明

## 职责

Godot 已加工资源目录。这里保存可由检查器编辑和复用的 Resource，不放原始美术文件。

## 子目录

- `animations`：SpriteFrames 动画。
- `items、crops、recipes`：物品、作物和配方数据库。
- `placements、defense_upgrades`：放置与升级配置。
- `weather、objectives、hordes、enemies`：世界规则、敌人和进度配置。
- `tilesets、themes`：地图瓦片与全局 UI 样式。
- `settings`：玩家、世界、农田和游戏规则的集中可视化配置。

## 维护规则

- 优先通过 Godot 检查器修改 `.tres`，不要在脚本中复制同一份配置。
- 文件使用英文蛇形命名；同类文件保持统一前缀，避免含糊名称。
- 删除或移动文件前，用全项目引用搜索确认场景、资源与脚本没有依赖。
