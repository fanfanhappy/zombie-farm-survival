# resources 目录说明

## 职责

可砍伐、采矿或采集的资源实体。

## 当前文件

- `initial_world_resources.tscn`：当前地图的资源摆放容器。种植专注阶段保持为空；以后需要树木、石头和装饰时，在这里重新绘制或放置，不必修改 `game_world.tscn`。
- `initial_world_resources.tscn`：正式地图资源布置入口；`StaticDecorations` 放不可采集装饰，`HarvestableResources` 放可砍伐树木、可破坏石头和可采集草药。两个图层都可在 Godot 中直接绘制、擦除和移动。
- `herb_resource.tscn`：可视化场景；节点结构、外观引用、碰撞和默认参数在编辑器中维护。
- `stone_resource.tscn`：可视化场景；节点结构、外观引用、碰撞和默认参数在编辑器中维护。
- `tree_resource.tscn`：可视化场景；节点结构、外观引用、碰撞和默认参数在编辑器中维护。

## 关联与维护

- 场景只负责节点组合和可调参数；复杂逻辑放到 scripts 对应目录。可复用对象必须是独立场景。
- 场景节点使用 PascalCase，文件使用英文蛇形命名，脚本与场景尽量同领域对应。
- 修改公共节点路径、组名、信号或资源 ID 后，必须运行两套回归测试。
- 删除文件前检查动态加载、TileSet 场景集合和存档恢复逻辑。
