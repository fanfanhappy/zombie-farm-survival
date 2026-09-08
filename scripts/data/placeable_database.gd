class_name PlaceableDatabase
extends Resource

@export var definitions: Array[PlaceableDefinition] = []


func build_catalog() -> Dictionary:
	var catalog: Dictionary = {}
	for definition in definitions:
		if definition == null or definition.placement_type.is_empty() or definition.scene == null:
			continue
		catalog[String(definition.placement_type)] = definition.to_dictionary()
	return catalog
