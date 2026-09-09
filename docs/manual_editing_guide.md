# Godot 手动调整入口

这份清单用于判断“应该改场景、资源还是脚本”。美术、布局、数值和关卡摆放优先在 Godot 检查器中完成；脚本只维护规则和状态转换。

## 全局数值

- `resources/settings/game_rules.tres`：一天长度、出生点、初始背包、睡眠条件、浇水壶容量。
- `resources/settings/player_definition.tres`：移动、生命、体力、饥饿、口渴、攻击和升级成长。
- `resources/settings/world_settings.tres`：世界范围、玩家/建造边距、农田和建造交互距离。
- `resources/settings/farming_action_settings.tres`：开垦、播种、浇水、收获和清理枯萎作物的体力消耗，以及前三项操作的经验奖励。

## 美术与动画

- 玩家动作：`resources/animations/player_sprite_frames.tres`。
- 树木和石头破坏过程：`resources/animations/tree_harvest_sprite_frames.tres`、`stone_harvest_sprite_frames.tres`。
- 敌人外观：在 `resources/enemies/definitions/` 的敌人资源中替换 `visual_scene`；场景根节点使用 `Node2D`，可选提供名为 `Head` 的节点用于受击变色。
- 物品图标：打开 `resources/items/definitions/` 中对应物品，在 `icon` 的 AtlasTexture 中调整图集和区域。
- 作物阶段：`scenes/world/farming/crops/` 下的作物外观场景。
- 作物规则：`resources/crops/definitions/` 下每种作物的 `growth_days`、`dry_tolerance_days`、`harvest_experience` 和 `harvest`。缺水日只累计、不生长；达到容忍天数后枯萎，需要用锄头清理。

## 地图与交互对象

- 地面、水、道路、农田自动拼接：`resources/tilesets/`。
- 静态装饰和可采集资源必须分别放入 `static_decoration_scenes.tres` 与 `harvestable_resource_scenes.tres`。
- 初始建筑、设施和动物在 `scenes/world/` 对应的 `initial_*.tscn` 中摆放；`initial_farm_plots.tscn` 只是空容器，农田由玩家开垦时动态创建。
- 想调整可耕范围时，在 `game_world.tscn` 的 `GroundLayer`、`WaterLayer`、`PathLayer` 和 `FenceLayer` 中直接绘制；不需要修改代码。农田外观在 `farm_tilled_terrain.tres` 的 Terrain Set 中调整。
- 农田存档按32像素世界网格坐标识别；动物存档按场景中的 `persistence_id` 识别。不要让两个对象使用同一ID；也不要手工叠放两个农田格。
- 每份作物收获建议至少返还1颗对应种子，确保玩家能够持续种植；背包溢出的收获会生成地面物品。
- 扩大地图时先修改 `world_settings.tres`，再同步调整主相机限制与主场景边界碰撞。

## 背包、配方与数值内容

- 物品：`resources/items/definitions/`，新增后拖入 `item_database.tres`。
- 配方：`resources/recipes/definitions/`，材料和产物使用 `ItemAmount` 子资源，不再手写 Dictionary。
- 作物、任务、尸潮、升级、敌人掉落均使用检查器中的强类型子资源列表。
- 背包视觉：`resources/themes/inventory_visual_style.tres`。
- 全局UI主题：`resources/themes/survival_ui_theme.tres`。
- 制作列表单行布局：`scenes/ui/components/crafting_recipe_entry.tscn`。
- 世界鼠标格高亮：`scenes/world/environment/world_grid_cursor.tscn`。

## 音频

- 总线在 `default_bus_layout.tres`，包含 Master、Music、Ambience、SFX、UI。
- 常驻音乐与环境播放器在 `scenes/core/audio_manager.tscn`。
- 将来接入素材时，把循环音乐交给 `play_music`，短音效交给 `play_sfx`；设置界面的音量会自动保存。

## 修改后检查

1. 保存所有打开的场景和资源。
2. 确认 Godot 输出面板没有红色错误。
3. 运行 `tests/resource_database_test.gd`、`tests/architecture_phase2_test.gd` 和 `tests/farming_loop_test.gd`。
4. 每个独立改动使用中文提交并推送。GitHub 会自动再次运行全部检查。

不要直接编辑 `.godot/`；它是可删除的导入缓存。不要通过修改节点数组顺序来表达存档身份，应使用网格坐标或 `persistence_id`。
