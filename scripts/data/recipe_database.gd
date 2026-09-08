class_name RecipeDatabase
extends Resource

@export var recipes: Array[RecipeDefinition] = []


func build_catalog() -> Dictionary:
	var catalog: Dictionary = {}
	for recipe in recipes:
		if recipe == null or recipe.recipe_id.is_empty():
			continue
		catalog[String(recipe.recipe_id)] = recipe.to_dictionary()
	return catalog
