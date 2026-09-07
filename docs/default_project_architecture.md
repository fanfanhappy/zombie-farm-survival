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
