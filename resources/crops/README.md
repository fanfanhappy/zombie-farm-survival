# 作物资源维护说明

- `crop_database.tres` 是作物总表；新增作物后，把新定义拖入 `crops` 数组。
- `definitions/` 中每个 `.tres` 对应一种作物，可修改种子 ID、生长天数、耐旱天数、收获经验、收获内容和外观场景。
- 作物每个阶段的图片与节点位置在 `scenes/world/farming/crops/` 的独立场景中修改。
- 新增作物时复制同类定义和外观场景，不需要修改 `farm_plot.gd`。

## 新增检查

1. 创建物品种子定义并填写唯一 `crop_id`。
2. 复制一种作物定义，设置 `seed_item_id`、`growth_days`、`dry_tolerance_days`、`harvest_experience` 和 `harvest`。
3. 复制一种作物外观场景，按 `Stage0`、`Stage1`……命名阶段节点并重新选择各自的图集区域；阶段数可以自由增减。
4. 将定义加入总数据库，运行 `resource_database_test.gd` 检查物品引用。

## 生长规则

- 每天结束时，已经浇水的作物增加1天生长进度；未浇水的作物停止生长并累计1个缺水日。
- 缺水日达到 `dry_tolerance_days` 后进入枯萎状态，选择锄头点击即可清理并重新播种。
- 雨天会在新一天开始时自动浇灌仍在生长的作物。
- 成熟收获会发放 `harvest` 中的全部物品及 `harvest_experience` 经验。
- 为保证长期循环，每种作物的 `harvest` 应至少配置1颗自己的种子。
- 修改后运行 `tests/farming_loop_test.gd`，确认完整种植闭环未被破坏。
