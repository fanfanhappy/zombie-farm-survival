# 物品资源维护说明

- `item_database.tres` 是物品总表。新增物品后，把新资源拖入它的 `items` 数组。
- `definitions/` 中每个 `.tres` 只描述一件物品，可在 Godot 检查器中修改。
- 新增物品最方便的方法是复制一个同类型 `.tres`，再修改 `item_id`、名称、图标和玩法参数。
- `item_id` 必须唯一且保持英文蛇形命名；存档、配方和快捷栏都通过它关联物品。
- 图标是 `AtlasTexture`。在检查器里展开 `icon`，即可重新选择图集中的 `region`，无需改代码。
- 工具填写 `tool_type`，可放置物填写 `placement_type`，种子填写 `crop_id`；无关字段留空。
- 背包布局在 `scenes/ui/backpack_ui.tscn`，快捷栏布局在 `scenes/ui/hotbar_ui.tscn`。
