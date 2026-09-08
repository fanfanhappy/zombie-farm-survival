class_name DefenseUpgradeDatabase
extends Resource

@export var definitions: Array[DefenseUpgradeDefinition] = []

func build_catalog() -> Dictionary:
	var result: Dictionary = {}
	for definition in definitions:
		if definition != null and not definition.defense_type.is_empty():
			result[String(definition.defense_type)] = {"name": definition.display_name, "levels": definition.get_level_dictionary()}
	return result
