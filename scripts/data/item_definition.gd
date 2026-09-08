class_name ItemDefinition
extends Resource

@export_group("基础信息")
@export var item_id: StringName
@export var display_name := "新物品"
@export_multiline var description := ""
@export_enum("weapon", "tool", "placeable", "material", "ingredient", "seed", "consumable") var category := "material"
@export var icon: Texture2D

@export_group("背包设置")
@export_range(1, 999, 1) var stack_limit := 99
@export var usable := false
@export var sort_order := 999

@export_group("玩法参数")
@export var tool_type: StringName
@export var placement_type: StringName
@export var crop_id: StringName
@export var attack_damage := 0.0
@export var consumable_effect: ConsumableEffectDefinition


func to_dictionary() -> Dictionary:
	return {
		"id": String(item_id), "name": display_name, "description": description,
		"category": category, "icon": icon, "stack_limit": stack_limit,
		"usable": usable, "sort_order": sort_order, "tool_type": String(tool_type),
		"placement_type": String(placement_type), "crop_id": String(crop_id),
		"attack_damage": attack_damage,
	}
