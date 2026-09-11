# crops 目录说明

## 职责

作物各生长阶段的原始图集。

## 当前内容

- `crop_growth_atlas.png`：作物生长阶段图集，尺寸 80×240，按 16×16 像素切格。
  每行从左到右为 Stage0～Stage4，具体作物行由对应的 `*_crop_visual.tscn` 场景配置：
  - 胡萝卜：`y=16`
  - 土豆：`y=48`
  - 草药：`y=176`
- `scenes/world/farming/crops/` 中的作物场景通过 `Sprite2D.region_rect` 选择图集帧；阶段切换由 `CropVisual` 控制，素材本身不写入脚本。

> `assets/art/characters/enemies/Farming Plants.png` 与本图集内容完全相同，属于重复副本，已移除。以后新增帧请直接替换本图集，或在对应作物场景中调整 `region_rect`。

## 维护规则

- 只放原始素材；不要手改 import 文件。像素图保持最近邻过滤，组合图集先确认单元尺寸和 Terrain/动画排列。
- 文件使用英文蛇形命名；同类文件保持统一前缀，避免含糊名称。
- 删除或移动文件前，用全项目引用搜索确认场景、资源与脚本没有依赖。
