# 全局可视化配置

- `world_settings.tres`：世界尺寸、玩家活动边距、建造边距和交互距离。扩大地图时优先修改这里。
- `player_definition.tres`：玩家移动、状态上限、体力、战斗和升级数值。
- `farming_action_settings.tres`：开垦、播种、浇水和收获的体力消耗。
- `game_rules.tres`：昼夜长度、出生点、初始物品、睡眠消耗与浇水壶容量。

这些资源用于替代脚本中的玩法硬编码。修改后运行回归测试，确认旧存档数值仍在合法范围内。
