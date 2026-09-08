# 作物资源维护说明

- `crop_database.tres` 是作物总表；新增作物后，把新定义拖入 `crops` 数组。
- `definitions/` 中每个 `.tres` 对应一种作物，可修改种子 ID、生长天数、收获内容和外观场景。
- 作物每个阶段的图片与节点位置在 `scenes/world/farming/crops/` 的独立场景中修改。
- 新增作物时复制同类定义和外观场景，不需要修改 `farm_plot.gd`。
