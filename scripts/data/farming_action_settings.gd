class_name FarmingActionSettings
extends Resource

@export_group("体力消耗")
@export_range(0.0, 100.0, 0.5) var till_cost := 6.0
@export_range(0.0, 100.0, 0.5) var plant_cost := 2.0
@export_range(0.0, 100.0, 0.5) var water_cost := 3.0
@export_range(0.0, 100.0, 0.5) var harvest_cost := 4.0
@export_range(0.0, 100.0, 0.5) var clear_withered_cost := 4.0

@export_group("经验奖励")
@export_range(0, 1000, 1) var till_experience := 2
@export_range(0, 1000, 1) var plant_experience := 2
@export_range(0, 1000, 1) var water_experience := 1
