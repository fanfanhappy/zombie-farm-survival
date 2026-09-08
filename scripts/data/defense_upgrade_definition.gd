class_name DefenseUpgradeDefinition
extends Resource

@export var defense_type: StringName
@export var display_name := "防御设施"
@export var levels: Array[DefenseUpgradeLevel] = []


func get_level_dictionary() -> Dictionary:
	var result: Dictionary = {}
	for upgrade in levels:
		if upgrade != null: result[str(upgrade.level)] = upgrade.to_dictionary()
	return result
