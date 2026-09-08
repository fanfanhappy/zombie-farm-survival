# 数据目录

后续物品、配方、作物、武器、敌人和尸潮波次数据统一存放于此。每种数据应使用独立的 Godot Resource 类型，不把大批数值散落在界面或场景脚本中。

当前数据入口：

- 物品配置已迁移到 `resources/items/definitions/`，本目录只保留配方等纯表格数据
- `recipes/basic_recipes.json`：工作台与料理台基础配方
- `hordes/first_horde.json`：第一次尸潮的波次、间隔与奖励
- 作物配置已迁移到 `resources/crops/definitions/`，生长与收获内容可在检查器修改
- `objectives/first_week_objectives.json`：第一周目标、条件与奖励
