# 项目结构

本工程按“资源类型 + 玩法领域”组织。查找文件时应先知道它属于哪一类，再知道它负责哪个玩法。

```text
僵尸来了也要种田/
├─ assets/                         # 游戏原始素材
│  ├─ art/
│  │  ├─ characters/              # 玩家、僵尸、NPC图像与动画
│  │  ├─ environment/             # 地形、建筑、作物与场景物件
│  │  ├─ items/                   # 工具、武器、物品图标
│  │  └─ ui/                      # 界面、光标、按钮与图标
│  └─ audio/
│     ├─ music/                   # 背景音乐
│     └─ sfx/                     # 音效
├─ docs/                           # 策划、结构和开发规范
├─ resources/                      # 可视化数据、动画、TileSet、主题与数据库
│  ├─ items/                       # 物品定义与物品数据库
│  ├─ crops/                       # 作物定义与作物数据库
│  ├─ recipes/                     # 制作配方与配方数据库
│  └─ tilesets/                    # 地形、建筑、农田和场景集合 TileSet
├─ scenes/
│  ├─ actors/                     # 玩家、敌人和NPC场景
│  ├─ game/                       # 主世界与流程入口场景
│  ├─ ui/                         # 独立界面场景
│  └─ world/                      # 农田、建筑、资源点等世界场景
└─ scripts/
   ├─ actors/
   │  ├─ player/                  # 玩家输入、状态和能力
   │  └─ zombies/                 # 僵尸行为与战斗逻辑
   ├─ core/                       # 游戏流程、存档、全局状态
   ├─ systems/                    # 配方、存档、背包、时间等跨领域系统
   │  ├─ crafting/               # 配方读取与制作规则
   │  ├─ inventory/              # 背包、堆叠与容量
   │  └─ save/                   # 存档序列化与读取
   ├─ ui/                         # 独立界面控制脚本
   └─ world/
	  ├─ building/                # 建造和防御设施
	  ├─ farming/                 # 土地、作物和种植
	  └─ resources/               # 采集点与资源刷新
```

## 放置规则

1. 场景放在 `scenes/`，脚本放在 `scripts/`，不可混放。
2. 通用素材按内容放入 `assets/`，不要放在项目根目录。
3. 数值配置和配方放在 `resources/` 对应领域目录，使用 `.tres` 可视化资源维护，不硬编码到界面脚本。
4. 一个文件只承担一个清晰职责；文件变得过大时按系统拆分。
5. 第三方素材包必须放入独立子目录，并保留原始授权文件。
6. 临时资源名称必须带 `placeholder`，避免误当成正式素材。
7. 只供 `game_world.tscn` 使用一次的简单包装节点直接内联；可复用实体和包含成组布局的场景继续独立保存。

## 当前入口

`project.godot` 指向 `scenes/ui/main_menu.tscn`；开始或继续游戏后进入 `scenes/game/game_world.tscn`，主流程由 `scripts/core/game_controller.gd` 控制。
