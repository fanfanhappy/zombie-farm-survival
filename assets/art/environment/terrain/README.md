# terrain 目录说明

## 职责

草地、水面、山丘与桥梁等基础地形图集。这里保存原始像素图，具体切片、Terrain Set、动画和碰撞配置位于 `resources/tilesets/`。

## 当前内容

- `terrain_grass_tileset.png`：主草地与岸边自动拼接图集。
- `terrain_grass_dark_tileset.png`：深色草地主体图集，适合高地或区域分层。
- `terrain_grass_layers_tileset.png`：普通草地透明边缘叠加图集。
- `terrain_grass_layers_dark_tileset.png`：深色草地透明边缘叠加图集，已接入主草地 TileSet。
- `terrain_hills_tileset.png`：当前使用的山丘、高地和坡道图集。
- `terrain_grass_hills_dark_tileset.png`：深色山丘备选图集，保留供后续建立独立 Terrain Set。
- `terrain_water_tileset.png`：四帧循环水面底图。
- `terrain_wooden_bridge_tileset.png`：横向和纵向木桥图集，应在独立 `BridgeLayer` 中切片绘制。

## 维护规则

- 只放原始素材；不要在资源类目录存放桥梁等地形结构。像素图保持最近邻过滤，组合图集先确认单元尺寸和 Terrain/动画排列。
- 文件使用英文蛇形命名；同类文件保持统一前缀，避免含糊名称。
- 删除或移动文件前，用全项目引用搜索确认场景、资源与脚本没有依赖。
