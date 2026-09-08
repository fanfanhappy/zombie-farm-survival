class_name ItemAmount
extends Resource

@export var item_id: StringName
@export_range(1, 9999, 1) var amount := 1


static func list_to_dictionary(entries: Array[ItemAmount]) -> Dictionary:
	var result: Dictionary = {}
	for entry in entries:
		if entry != null and not entry.item_id.is_empty() and entry.amount > 0:
			result[String(entry.item_id)] = entry.amount
	return result
