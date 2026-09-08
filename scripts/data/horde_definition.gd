class_name HordeDefinition
extends Resource

@export var horde_id: StringName
@export var display_name := "新尸潮"
@export_range(1, 365, 1) var trigger_interval_days := 7
@export var waves: Array[Dictionary] = []
@export var reward: Dictionary = {}
