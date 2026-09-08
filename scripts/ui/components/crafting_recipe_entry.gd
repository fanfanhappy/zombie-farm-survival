class_name CraftingRecipeEntry
extends Button

signal craft_requested(recipe_id: String)

var configured_recipe_id := ""


func configure(recipe_id: String, label_text: String) -> void:
	configured_recipe_id = recipe_id
	text = label_text
	pressed.connect(_request_craft)


func _request_craft() -> void:
	craft_requested.emit(configured_recipe_id)
