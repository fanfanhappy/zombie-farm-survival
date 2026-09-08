class_name RecipeEffectDefinition
extends Resource

@export var equip_weapon_id: StringName
@export_range(0.0, 10000.0, 1.0) var attack_damage := 0.0


func to_dictionary() -> Dictionary:
	var result: Dictionary = {}
	if not equip_weapon_id.is_empty(): result["equip_weapon"] = String(equip_weapon_id)
	if attack_damage > 0.0: result["attack_damage"] = attack_damage
	return result
