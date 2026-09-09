# farming 目录说明

## 职责

动态农田格、状态提示和运行时农田容器。

## 当前文件

- `farm_plot.tscn`：单个32×32逻辑格，包含浇水标记与悬停高亮；颜色和节点位置可视化维护。
- `initial_farm_plots.tscn`：空的运行时农田容器。不要在这里预放固定农田；玩家用锄头点击有效草地后，`FarmingSystem` 会按32像素世界网格创建 `farm_plot.tscn`。

## 可耕区域如何配置

- 可耕基础范围来自 `game_world.tscn/WorldTileMap/GroundLayer`，在编辑器中绘制草地即可扩展。
- `WaterLayer`、`PathLayer`、`FenceLayer` 会自动排除水体、道路和围栏格。
- 建筑、设施、静态装饰、可采集资源和已放置物会通过图层占用或碰撞自动阻止开垦。
- `FarmingTerrainLayer` 只显示已经开垦的格子，并读取 `farm_tilled_terrain.tres` 的 Terrain Set 自动拼接；不要手工绘制农田结果。
- 每个动态农田都写入存档的网格坐标；新游戏会删除全部动态农田并清空农田图层。

## 关联与维护

- 场景只负责节点组合和可调参数；复杂逻辑放到 scripts 对应目录。可复用对象必须是独立场景。
- 场景节点使用 PascalCase，文件使用英文蛇形命名，脚本与场景尽量同领域对应。
- 修改公共节点路径、组名、信号或资源 ID 后，必须运行两套回归测试。
- 删除文件前检查动态加载、TileSet 场景集合和存档恢复逻辑。
