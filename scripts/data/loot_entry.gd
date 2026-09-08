class_name LootEntry
extends Resource

@export var item_id: StringName
@export_range(0.0, 1.0, 0.01) var chance := 1.0
@export_range(1, 999, 1) var min_amount := 1
@export_range(1, 999, 1) var max_amount := 1


func roll() -> Dictionary:
	if item_id.is_empty() or randf() >= chance: return {}
	return {"item_id": String(item_id), "amount": randi_range(mini(min_amount, max_amount), maxi(min_amount, max_amount))}
