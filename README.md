<div align="center">
  <img src="icon.svg" width="112" alt="僵尸来了也要种田图标">

# 僵尸来了也要种田

**白天种田、采集与建造，夜晚守住农舍，在末日里活过下一轮尸潮。**

一款使用 Godot 4 制作的俯视角像素风末日种田生存 RPG。

[![Godot](https://img.shields.io/badge/Godot-4.7-478CBF?logo=godot-engine&logoColor=white)](https://godotengine.org/)
[![项目检查](https://github.com/fanfanhappy/zombie-farm-survival/actions/workflows/project-checks.yml/badge.svg)](https://github.com/fanfanhappy/zombie-farm-survival/actions/workflows/project-checks.yml)
![阶段](https://img.shields.io/badge/阶段-Prototype%200.1-E8A94B)
![语言](https://img.shields.io/badge/界面-简体中文-69A84F)

[玩法概览](#玩法概览) · [运行项目](#运行项目) · [操作方式](#操作方式) · [手动修改](#手动修改) · [项目结构](#项目结构)
</div>

---

## 游戏简介

《僵尸来了也要种田》围绕“**经营准备 → 夜间防守 → 尸潮检验 → 继续成长**”展开。玩家需要在白天开垦土地、收集资源、制作工具并布置防线；入夜后利用武器、栅栏、尖刺和陷阱抵挡僵尸，保护作为最终防线的农舍。

当前版本是第一阶段可玩原型，重点验证种田、生存、建造、战斗和存档之间的完整循环。项目采用数据驱动和场景化结构，方便后续直接在 Godot 编辑器中更换美术、调整数值及扩充内容。

## 玩法概览

| 模块 | 当前内容 |
|---|---|
| 🌱 种田 | 开垦、播种、浇水、缺水停长、枯萎、成熟收获与种子循环 |
| 🪓 采集 | 树木、矿石、草药，工具效率、进度反馈与序列帧破坏过程 |
| 🔨 建造 | 栅栏、尖刺、捕兽夹、储物箱，鼠标预览、旋转、放置与拆除 |
| 🧟 战斗 | 普通感染者、快速感染者、连续攻击、掉落与角色成长 |
| 🌙 生存 | 昼夜、天气、饥饿、口渴、体力、睡眠与夜间威胁 |
| 🏠 防守 | 农舍耐久、设施维修、三级强化、七日尸潮与波次奖励 |
| 🎒 物品 | 24 格背包、9 格快捷栏、拖放、堆叠、消耗品与储物箱 |
| 💾 流程 | 中文主菜单、新游戏完整重置、继续游戏、暂停与 v21 存档 |

<details>
<summary><strong>展开查看完整功能列表</strong></summary>

- 鼠标点击或长按完成采集、耕作、浇水、收获和连续战斗。
- 武器与工具制作后进入背包，由玩家自行装备或拖入快捷栏。
- 防御设施支持预览、旋转、碰撞校验、维修、升级、拆除与回收。
- 僵尸以农舍为最终目标，并会攻击途中阻挡它们的防御设施。
- 数据驱动的三波尸潮、第一周目标、奖励、天气和升级内容。
- 可放置的木制储物箱支持双向存取和独立存档。
- 基础养鸡模块支持活动、每日产蛋、鼠标收取和状态保存。
- 玩家、母鸡、感染者、资源点、设施与农舍均使用独立可编辑场景。
- 角色四方向待机、行走、砍树、锄地和浇水动画。
- 默认全屏运行，960×540 逻辑分辨率自适应缩放，并支持 F11 切换。
- 地形、耕地、光标和放置系统统一使用 32 像素逻辑网格。
- 作物信息实时显示生长进度、浇水状态与缺水容忍天数，跨日后汇总生长结果。
- 收获返还种子并获得经验；背包装不下的产物自动掉落在角色脚边，不会消失。

</details>

## 运行项目

### 环境要求

- [Godot Engine 4.7](https://godotengine.org/download/)
- Git（仅克隆和参与开发时需要）

### 本地启动

```bash
git clone https://github.com/fanfanhappy/zombie-farm-survival.git
cd zombie-farm-survival
```

在 Godot 项目管理器中导入根目录下的 `project.godot`，然后运行项目即可。启动场景为 `scenes/ui/main_menu.tscn`。

> 当前稳定节点：`prototype-0.1-final`

## 操作方式

| 操作 | 功能 |
|---|---|
| `WASD` / 方向键 | 移动 |
| `Shift` | 冲刺并持续消耗体力 |
| 鼠标左键 / 长按 | 使用工具、耕作、攻击；放置时确认 |
| 鼠标右键 / `Esc` | 取消放置或关闭当前界面 |
| `E` | 使用工作台、床铺、储物箱和取水泵 |
| `1`—`9` | 选择对应快捷栏槽位 |
| `B` | 打开或关闭背包 |
| `R` | 使用绷带；放置模式下旋转建筑 |
| `F` | 食用炖菜 |
| `X` / `U` | 使用维修锤拆除 / 升级附近防御设施 |
| `K` / `L` | 快速保存 / 读取 |
| `F11` | 切换全屏与窗口模式 |
| `T` | 调试：时间前进两小时 |

## 手动修改

项目尽量将内容放在 `.tscn`、`.tres`、`SpriteFrames` 和 `TileSet` 中，避免把可调整内容写死在代码里。你可以在 Godot 检查器中直接修改：

- 玩家属性、游戏初始规则、世界边界和农田操作消耗；
- 物品图标、堆叠数量、工具参数、配方和作物成长数据；
- 玩家、敌人、动物、资源点、设施及掉落物的外观与碰撞；
- UI 主题、背包样式、网格光标颜色、音量和动画资源；
- 地形自动拼接规则、图集区域和初始地图场景。

第一次修改前，建议阅读 **[手动编辑指南](docs/manual_editing_guide.md)**。其中标明了每类内容的准确文件位置、推荐修改方式和修改后的检查步骤。

## 项目结构

```text
zombie-farm-survival/
├── assets/       # 原始美术、UI、音频与第三方素材
├── data/         # 结构化基础数据
├── docs/         # 架构、命名、资源制作与手动编辑文档
├── resources/    # 可视化数据、数据库、动画、主题与 TileSet
├── scenes/       # 游戏、角色、世界和 UI 场景
├── scripts/      # 核心流程、角色逻辑与独立玩法系统
├── tests/        # 资源完整性与架构回归检查
└── tools/        # 项目辅助工具
```

| 入口 | 位置 |
|---|---|
| 主菜单 | `scenes/ui/main_menu.tscn` |
| 游戏世界 | `scenes/game/game_world.tscn` |
| 游戏流程 | `scripts/core/game_controller.gd` |
| 物品数据库 | `resources/items/item_database.tres` |
| 作物数据库 | `resources/crops/crop_database.tres` |
| 配方数据库 | `resources/recipes/recipe_database.tres` |

更多说明：

- [项目结构规范](docs/project_structure.md)
- [文件命名规范](docs/naming_conventions.md)
- [可视化资源制作规范](docs/visual_authoring_guidelines.md)
- [各模块重构审计](docs/module_refactor_audit.md)

## 开发状态

- **当前阶段：** Prototype 0.1 第一阶段完成
- **主要方向：** 继续补充正式美术、地图内容、更多作物、敌人、音频和长期成长系统
- **质量检查：** 每次推送自动执行 Godot 资源导入、资源数据库检查及新游戏重置回归测试

项目仍处于开发阶段，玩法、数值和美术会持续迭代。

---

<div align="center">
  <strong>哪怕僵尸来了，今天的地也得种。</strong>
</div>
