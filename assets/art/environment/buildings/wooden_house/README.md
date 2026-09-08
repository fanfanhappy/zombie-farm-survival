# wooden house 目录说明

## 职责

木屋门、墙和屋顶图集，对应独立建筑 TileSet。

## 当前内容

- `building_wooden_house_doors.png`：原始像素图或参考图；实际裁切与动画配置位于对应资源或场景。
- `building_wooden_house_roof_tileset.png`：原始像素图或参考图；实际裁切与动画配置位于对应资源或场景。
- `building_wooden_house_wall_tileset.png`：原始像素图或参考图；实际裁切与动画配置位于对应资源或场景。

## 维护规则

- 只放原始素材；不要手改 import 文件。像素图保持最近邻过滤，组合图集先确认单元尺寸和 Terrain/动画排列。
- 文件使用英文蛇形命名；同类文件保持统一前缀，避免含糊名称。
- 删除或移动文件前，用全项目引用搜索确认场景、资源与脚本没有依赖。

