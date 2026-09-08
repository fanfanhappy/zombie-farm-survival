class_name EnemyDefinition
extends Resource

@export_group("基础信息")
@export var enemy_id: StringName
@export var display_name := "感染者"

@export_group("移动与仇恨")
@export_range(1.0, 500.0, 1.0) var move_speed := 62.0
@export_range(1.0, 500.0, 1.0) var aggro_distance := 105.0
@export_range(0.0, 30.0, 0.1) var aggro_duration := 3.0

@export_group("战斗参数")
@export_range(1.0, 10000.0, 1.0) var max_health := 50.0
@export_range(0.0, 1000.0, 1.0) var player_attack_damage := 9.0
@export_range(0.0, 1000.0, 1.0) var homestead_attack_damage := 10.0
@export_range(0.0, 1000.0, 1.0) var defense_attack_damage := 12.0
@export_range(0.05, 10.0, 0.05) var attack_interval := 0.8
@export_range(0, 10000, 1) var experience_reward := 12

@export_group("可视化")
@export var visual_scene: PackedScene
@export var visual_scale := Vector2.ONE
@export var body_tint := Color("#73945c")

@export_group("掉落表")
@export var loot_table: Array[LootEntry] = []


func roll_drop() -> Dictionary:
	for entry in loot_table:
		if entry == null: continue
		var result := entry.roll()
		if not result.is_empty(): return result
	return {}
