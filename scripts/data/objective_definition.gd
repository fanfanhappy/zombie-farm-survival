class_name ObjectiveDefinition
extends Resource

@export var objective_id: StringName
@export var title := "新目标"
@export_enum("inventory", "tilled_plots", "planted_plots", "defenses", "kills", "hordes_survived") var condition_type := "inventory"
@export var condition_target: StringName
@export_range(1, 9999, 1) var condition_amount := 1
@export var reward: Dictionary = {}

func to_dictionary() -> Dictionary:
	return {"id": String(objective_id), "title": title, "condition": {"type": condition_type, "target": String(condition_target), "amount": condition_amount}, "reward": reward.duplicate(true)}
