# data 目录说明

## 职责

可视化 Resource 的 Definition 与 Database 类型声明。

## 当前文件

- `crop_database.gd`：GDScript 逻辑；具体职责与文件名对应，公共接口需保持向后兼容。
- `crop_definition.gd`：GDScript 逻辑；具体职责与文件名对应，公共接口需保持向后兼容。
- `defense_upgrade_database.gd`：GDScript 逻辑；具体职责与文件名对应，公共接口需保持向后兼容。
- `defense_upgrade_definition.gd`：GDScript 逻辑；具体职责与文件名对应，公共接口需保持向后兼容。
- `horde_definition.gd`：GDScript 逻辑；具体职责与文件名对应，公共接口需保持向后兼容。
- `item_database.gd`：GDScript 逻辑；具体职责与文件名对应，公共接口需保持向后兼容。
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

