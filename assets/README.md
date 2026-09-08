# 素材目录

所有美术和音频素材按 `docs/project_structure.md` 与 `docs/naming_conventions.md` 管理。

导入第三方素材前必须确认商业使用范围，并保留授权文件与来源链接。正式素材和临时占位素材不得使用相同名称。

## 目录分工

- `art/characters`：角色、动物和工具动作精灵表。
- `art/environment`：地形、建筑、农田、设施与资源点。
- `art/ui`：HUD、图标和背包界面图集。
- `art/third_party`：供应商原包，只归档，不在内部重命名或删除。
- `audio/music` 与 `audio/sfx`：长循环音乐和短音效分开管理。

## 导入流程

1. 先判断图片是单图、规则图集、动画精灵表还是 Terrain 自动拼接瓦片。
2. 原图放入对应分类，Godot 生成的 `.import` 不手工修改。
3. TileSet、AtlasTexture、SpriteFrames 等加工结果放入 `resources/`。
4. 在 `scenes/` 中引用加工资源，不在脚本中硬编码裁切区域。
