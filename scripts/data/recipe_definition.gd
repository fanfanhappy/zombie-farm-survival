class_name RecipeDefinition
extends Resource

@export var recipe_id: StringName
@export var display_name := "新配方"
@export_enum("workbench", "kitchen") var station := "workbench"
@export var ingredients: Array[ItemAmount] = []
@export var results: Array[ItemAmount] = []
@export var effect: RecipeEffectDefinition


func to_dictionary() -> Dictionary:
	return {
		"id": String(recipe_id), "name": display_name, "station": station,
		"ingredients": ItemAmount.list_to_dictionary(ingredients),
		"results": ItemAmount.list_to_dictionary(results),
		"effect": effect.to_dictionary() if effect != null else {},
	}
