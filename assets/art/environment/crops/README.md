# crops 目录说明

## 职责

作物各生长阶段的原始图集。

## 当前内容

- `crop_growth_atlas.png`：作物生长阶段图集，尺寸 80×240，按 16×16 像素切格。
  每行从左到右为 Stage0～Stage4。根据素材作者的作物列表，图集从上到下的业务映射为：
  - 玉米（corn）：`y=0`
  - 胡萝卜（carrot）：`y=16`
  - 花椰菜（cauliflower）：`y=32`
  - 番茄（tomato）：`y=48`
  - 茄子（eggplant）：`y=64`
  - 蓝色郁金香（blue_tulip）：`y=80`
  - 生菜（lettuce）：`y=96`
  - 小麦（wheat）：`y=112`
  - 欧洲萝卜（parsnip）：`y=128`
  - 红花（red_flower）：`y=144`
  - 甜菜（beet）：`y=160`
  - 星果（blue_star_fruit）：`y=176`
  - 黄瓜（cucumber）：`y=192`
- 项目旧版本的 `potato`、`medicinal_herb` ID 会保留作存档兼容别名；新场景与新种子按上述真实行顺序配置。
- `scenes/world/farming/crops/` 中的作物场景通过 `Sprite2D.region_rect` 选择图集帧；阶段切换由 `CropVisual` 控制，素材本身不写入脚本。阶段节点支持 `Stage0`、`Stage1`……的可变数量，四帧、五帧或更多帧均可。
- `CropVisual` 默认启用“贴地对齐”：会根据每个阶段实际框选高度自动调整 Sprite2D 的垂直位置，避免小尺寸帧悬空。需要手动微调时，在场景根节点关闭 `Auto Align To Ground`，再分别调整 Stage 节点的 Position。

> `assets/art/characters/enemies/Farming Plants.png` 与本图集内容完全相同，属于重复副本，已移除。以后新增帧请直接替换本图集，或在对应作物场景中调整 `region_rect`。

## 维护规则

- 只放原始素材；不要手改 import 文件。像素图保持最近邻过滤，组合图集先确认单元尺寸和 Terrain/动画排列。
- 文件使用英文蛇形命名；同类文件保持统一前缀，避免含糊名称。
- 删除或移动文件前，用全项目引用搜索确认场景、资源与脚本没有依赖。
