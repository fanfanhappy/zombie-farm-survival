class_name DefenseUpgradeLevel
extends Resource

@export_range(2, 99, 1) var level := 2
@export var cost: Array[ItemAmount] = []
@export_range(1.0, 100000.0, 1.0) var max_health := 100.0
@export_range(0.0, 10000.0, 1.0) var spike_damage := 0.0


func to_dictionary() -> Dictionary:
	var result := {"cost": ItemAmount.list_to_dictionary(cost), "max_health": max_health}
	if spike_damage > 0.0: result["spike_damage"] = spike_damage
	return result
