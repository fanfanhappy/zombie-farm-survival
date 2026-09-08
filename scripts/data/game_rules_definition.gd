class_name GameRulesDefinition
extends Resource

@export_group("时间")
@export_range(10.0, 3600.0, 1.0) var day_length_seconds := 90.0
@export_range(0, 23, 1) var day_start_hour := 7
@export_range(0, 23, 1) var night_threat_hour := 18

@export_group("出生与初始物品")
@export var player_home := Vector2(640, 460)
@export var starting_items: Array[ItemAmount] = []

@export_group("生活规则")
@export_range(1, 99, 1) var watering_can_capacity := 5
@export_range(0, 23, 1) var earliest_sleep_hour := 18
@export_range(0.0, 100.0, 1.0) var sleep_hunger_cost := 18.0
@export_range(0.0, 100.0, 1.0) var sleep_thirst_cost := 15.0
@export_range(0.0, 1000.0, 1.0) var sleep_heal := 15.0


func get_starting_items() -> Dictionary:
	return ItemAmount.list_to_dictionary(starting_items)


func get_day_start_progress() -> float:
	return float(day_start_hour) / 24.0
