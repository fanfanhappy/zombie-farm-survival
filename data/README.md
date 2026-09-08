# 数据目录

后续物品、配方、作物、武器、敌人和尸潮波次数据统一存放于此。每种数据应使用独立的 Godot Resource 类型，不把大批数值散落在界面或场景脚本中。

当前数据入口：

- 物品配置已迁移到 `resources/items/definitions/`，本目录只保留配方等纯表格数据
- 配方已迁移到 `resources/recipes/definitions/`，工作台与厨房配方可在检查器修改
- 尸潮配置已迁移到 `resources/hordes/`
- 作物配置已迁移到 `resources/crops/definitions/`，生长与收获内容可在检查器修改
- 天气、任务和防御升级配置已迁移到 `resources/` 对应模块

## 当前定位

策划配置已经全部迁移为 Godot Resource，本目录只作为旧数据迁移记录和未来外部数据交换的预留入口。玩家存档不在这里，运行时写入 `user://`。

如果未来需要导入 CSV、翻译表或外部平衡表，应先在本目录保存源数据，再通过明确的导入流程生成 `resources/` 中的运行资源；游戏运行时不要同时读取两套配置。
