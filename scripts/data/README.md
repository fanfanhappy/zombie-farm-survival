# data 目录说明

## 职责

可视化 Resource 的 Definition 与 Database 类型声明。

## 当前文件

- `item_amount.gd`：所有配方、奖励、收获和初始背包共用的“物品ID+数量”子资源。
- `game_rules_definition.gd`、`player_definition.gd`、`world_settings.gd`、`farming_action_settings.gd`：集中可调玩法规则。
- `horde_wave_definition.gd`、`enemy_spawn_entry.gd`、`defense_upgrade_level.gd`、`loot_entry.gd`：尸潮、升级和掉落的强类型子资源。
- `inventory_visual_style.gd`：背包与快捷栏视觉资源定义。
- `consumable_effect_definition.gd`、`recipe_effect_definition.gd`：物品和配方效果资源定义。

- `crop_database.gd`：GDScript 逻辑；具体职责与文件名对应，公共接口需保持向后兼容。
- `crop_definition.gd`：GDScript 逻辑；具体职责与文件名对应，公共接口需保持向后兼容。
- `defense_upgrade_database.gd`：GDScript 逻辑；具体职责与文件名对应，公共接口需保持向后兼容。
- `defense_upgrade_definition.gd`：GDScript 逻辑；具体职责与文件名对应，公共接口需保持向后兼容。
- `horde_definition.gd`：GDScript 逻辑；具体职责与文件名对应，公共接口需保持向后兼容。
- `item_database.gd`：GDScript 逻辑；具体职责与文件名对应，公共接口需保持向后兼容。
- `enemy_definition.gd` / `enemy_database.gd`：敌人属性定义与敌人总表查询，运行时控制器只读取这些资源。
- `item_definition.gd`：GDScript 逻辑；具体职责与文件名对应，公共接口需保持向后兼容。
- `objective_database.gd`：GDScript 逻辑；具体职责与文件名对应，公共接口需保持向后兼容。
- `objective_definition.gd`：GDScript 逻辑；具体职责与文件名对应，公共接口需保持向后兼容。
- `placeable_database.gd`：GDScript 逻辑；具体职责与文件名对应，公共接口需保持向后兼容。
- `placeable_definition.gd`：GDScript 逻辑；具体职责与文件名对应，公共接口需保持向后兼容。
- `recipe_database.gd`：GDScript 逻辑；具体职责与文件名对应，公共接口需保持向后兼容。
- `recipe_definition.gd`：GDScript 逻辑；具体职责与文件名对应，公共接口需保持向后兼容。
- `weather_database.gd`：GDScript 逻辑；具体职责与文件名对应，公共接口需保持向后兼容。
- `weather_definition.gd`：GDScript 逻辑；具体职责与文件名对应，公共接口需保持向后兼容。

## 关联与维护

- 一个脚本只负责一个明确职责；跨实体逻辑进入 systems，实体自身逻辑进入 world 或 actors。
- 场景节点使用 PascalCase，文件使用英文蛇形命名，脚本与场景尽量同领域对应。
- 修改公共节点路径、组名、信号或资源 ID 后，必须运行两套回归测试。
- 删除文件前检查动态加载、TileSet 场景集合和存档恢复逻辑。
