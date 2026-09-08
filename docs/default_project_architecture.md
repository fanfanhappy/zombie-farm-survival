# Godot 项目默认架构

本项目及后续同类项目统一采用“会话、世界、实体、相机、屏幕特效、界面”分层结构。可在编辑器中完成的地图、碰撞、动画、图集切片和界面布局，不写死在控制器脚本中。

```text
Main
├─ GameSession
├─ GameWorld
│  ├─ TerrainLayers
│  ├─ LogicLayers
│  ├─ DynamicYSortGroup
│  ├─ RoofLayer
│  └─ TransitionZones
├─ CameraRig
├─ ScreenEffects
└─ UI
```

## 强制规则

1. `DynamicYSortGroup` 开启 Y-Sort；需要互相遮挡的角色、动物、敌人、建筑、作物和资源节点放在该组下。
2. 地面、水面、道路和逻辑检测层不参与 Y-Sort，并使用明确的显示层级。
3. 屋顶层使用固定高 `z_index`。
4. 可采集资源使用独立场景并注册到 `TileSetScenesCollectionSource`，地图设计者可在 TileMap 调色板中直接绘制。
5. 纯地图素材使用 TileSet Atlas；角色和动作使用 SpriteFrames；UI 图集使用 AtlasTexture。
6. 库存、制作和任务属于当前游戏会话，不设为 Autoload。
7. Autoload 只用于跨场景服务，例如存档、显示设置、音频、事件总线和游戏流程。
8. UI 子模块使用独立 `.tscn`，统一放在 UI CanvasLayer 下；脚本只更新数据和响应操作。
9. 世界状态与美术资源分离，替换图片、动画、TileSet 或 UI 场景不应破坏存档。
10. 每个迁移阶段必须通过无界面启动和功能回归测试后单独提交。

## 当前可视化编辑入口

- 玩家整体：`scenes/actors/player/player.tscn`
- 初始农田：`scenes/world/farming/initial_farm_plots.tscn`
- 初始动物：`scenes/world/animals/initial_animals.tscn`
- 初始建筑：`scenes/world/buildings/initial_buildings.tscn`
- 初始设施：`scenes/world/facilities/initial_facilities.tscn`
- 地图瓦片：`resources/tilesets/`
- 资源绘制层：`scenes/world/environment/world_resource_layer.tscn`
- 水体碰撞：`resources/tilesets/terrain_water_tileset.tres`（随水瓦片自动同步）
- 地图边界碰撞：`scenes/world/environment/world_boundaries.tscn`
- 常驻 HUD：`scenes/ui/game_hud.tscn`
- 弹窗菜单：`scenes/ui/game_menus.tscn`
- 背包与快捷栏：`scenes/ui/inventory_ui.tscn`

运行时只动态创建确实会变化的对象，例如敌人、掉落物、玩家放置物和配方按钮。初始地图、碰撞、建筑、设施、农田、动物、动画和 UI 均应优先在编辑器中调整。

资源物件必须分为两套：`StaticDecorations` 只显示并可选带固定碰撞，不注册交互和掉落；`HarvestableResources` 才包含耐久、工具判定、进度、掉落和重生。两类物件分别使用 `static_decorations` 与 `harvestable_resources` 分组，不能混用场景。

对应的绘制资源分别为 `resources/tilesets/static_decoration_scenes.tres` 和 `resources/tilesets/harvestable_resource_scenes.tres`。

## Git 安全回退

已经推送到 GitHub 的改动使用 `git revert <提交编号>` 生成反向提交，再推送到远端。这样不会改写历史，适合逐阶段撤销。迁移期间禁止用强制推送覆盖远端历史。
