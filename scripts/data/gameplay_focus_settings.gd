class_name GameplayFocusSettings
extends Resource

@export_category("当前开发阶段")
@export var farming_focus_enabled := true

@export_category("种田专注模式初始物品")
@export var farming_starting_items: Array[ItemAmount] = []


func get_farming_starting_items() -> Dictionary:
	return ItemAmount.list_to_dictionary(farming_starting_items)
