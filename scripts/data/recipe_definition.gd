class_name RecipeDefinition
extends Resource

@export var recipe_id: StringName
@export var display_name := "新配方"
@export_enum("workbench", "kitchen") var station := "workbench"
@export var ingredients: Dictionary = {}
@export var results: Dictionary = {}
@export var effect: Dictionary = {}


func to_dictionary() -> Dictionary:
	return {
		"id": String(recipe_id), "name": display_name, "station": station,
		"ingredients": ingredients.duplicate(true), "results": results.duplicate(true),
		"effect": effect.duplicate(true),
	}
