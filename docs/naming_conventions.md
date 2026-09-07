# 文件与资源命名规范

## 总原则

文件名使用简洁、可搜索、有明确含义的英文；中文用于编辑器显示名、注释和文档。

统一使用小写 `snake_case`：

```text
player_controller.gd
zombie_farmer.tscn
crop_potato_stage_02.png
item_wood_icon.png
```

不使用：

```text
新建场景.tscn
脚本1.gd
test2_final_new.gd
IMG_001.png
```

## 文件命名

| 类型 | 格式 | 示例 |
|---|---|---|
| 场景 | `对象_用途.tscn` | `game_world.tscn`、`zombie_basic.tscn` |
| 脚本 | `对象_职责.gd` | `player_controller.gd`、`inventory_system.gd` |
| 数据资源 | `类别_对象.tres` | `crop_potato.tres`、`weapon_wooden_club.tres` |
| 图片 | `类别_对象_状态.png` | `crop_potato_stage_01.png` |
| 音效 | `sfx_对象_动作_编号.wav` | `sfx_zombie_hit_01.wav` |
| 音乐 | `music_场景_情绪.ogg` | `music_homestead_day.ogg` |
| 字体 | `font_名称_字重.ttf` | `font_pixel_regular.ttf` |

## 常用词汇

为避免同一种对象出现多种英文名称，优先使用下列词汇：

| 中文 | 固定英文 |
|---|---|
| 玩家 | `player` |
| 僵尸 | `zombie` |
| 作物 | `crop` |
| 农田格 | `farm_plot` |
| 采集资源 | `harvestable_resource` |
| 静态装饰 | `static_decoration` |
| 防御设施 | `defense_structure` |
| 栅栏 | `fence` |
| 尖刺 | `spike` |
| 物品 | `item` |
| 配方 | `recipe` |
| 尸潮 | `horde` |
| 家园 | `homestead` |

## 版本规则

- 不在正式源文件名后添加 `最新版`、`最终版`、`new` 或日期。
- 代码版本由 Git 管理。
- 策划文档可使用明确版本号，例如 `game_design_v0.2.md`。
- 被替换的资源不留在正式目录中；需要保留时移入专门的归档目录。

## 第三方美术

每一套第三方素材使用独立目录：

```text
assets/art/third_party/作者名_素材包名/
├─ license.txt
├─ source_url.txt
└─ 原始素材文件
```

不要修改后覆盖唯一原文件。派生素材放入项目对应正式分类，并在同目录或资产清单中记录来源。
