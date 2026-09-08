class_name PlayerDefinition
extends Resource

@export_group("移动")
@export_range(1.0, 1000.0, 1.0) var move_speed := 180.0
@export_range(1.0, 5.0, 0.05) var sprint_speed_multiplier := 1.5

@export_group("初始状态")
@export_range(1.0, 1000.0, 1.0) var max_health := 100.0
@export_range(1.0, 1000.0, 1.0) var max_stamina := 100.0
@export_range(1.0, 1000.0, 1.0) var max_hunger := 100.0
@export_range(1.0, 1000.0, 1.0) var max_thirst := 100.0

@export_group("体力")
@export_range(0.0, 500.0, 0.5) var stamina_regeneration_per_second := 22.0
@export_range(0.0, 500.0, 0.5) var sprint_stamina_per_second := 18.0
@export_range(0.0, 500.0, 0.5) var attack_stamina_cost := 12.0

@export_group("战斗")
@export_range(0.05, 10.0, 0.01) var attack_cooldown := 0.38
@export var starting_weapon_id: StringName = &"wooden_club"
@export var starting_weapon_name := "木棒"
@export_range(0.0, 10000.0, 1.0) var starting_attack_damage := 25.0

@export_group("升级")
@export_range(1, 10000, 1) var first_level_experience := 40
@export_range(0, 10000, 1) var experience_growth_per_level := 25
@export_range(0.0, 1000.0, 1.0) var health_gain_per_level := 10.0
@export_range(0.0, 1000.0, 1.0) var stamina_gain_per_level := 5.0
@export_range(0.0, 1.0, 0.01) var damage_gain_per_level := 0.05
