class_name CraftingSystem
extends Node

const RECIPES_PATH := "res://data/recipes/basic_recipes.json"

var recipes: Dictionary = {}


func _ready() -> void:
	_load_recipes()


func get_recipes_for_station(station_type: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for recipe_id in recipes:
		var recipe: Dictionary = recipes[recipe_id]
		if recipe.get("station", "") == station_type:
			var entry := recipe.duplicate(true)
			entry["id"] = recipe_id
			result.append(entry)
	return result


func craft(recipe_id: String, game: Node) -> bool:
	if not recipes.has(recipe_id):
		game.show_message("找不到这个配方")
		return false
	var recipe: Dictionary = recipes[recipe_id]
	var ingredients: Dictionary = recipe.get("ingredients", {})
	var results: Dictionary = recipe.get("results", {})
	for item_id in ingredients:
		if game.get_resource_amount(item_id) < int(ingredients[item_id]):
			game.show_message("材料不足：%s" % game.format_cost(ingredients))
			return false
	for item_id in results:
		if not game.can_add_resource(item_id, int(results[item_id])):
			game.show_message("背包没有空间，或该物品已达到堆叠上限")
			return false
	for item_id in ingredients:
		game.spend_resource(item_id, int(ingredients[item_id]))
	for item_id in results:
		game.add_resource(item_id, int(results[item_id]), false)
	game.apply_recipe_effect(recipe.get("effect", {}))
	game.show_message("制作完成：%s" % recipe.get("name", recipe_id))
	return true


func format_recipe(recipe: Dictionary, game: Node) -> String:
	return "%s　[%s]" % [recipe.get("name", "未知配方"), game.format_cost(recipe.get("ingredients", {}))]


func _load_recipes() -> void:
	if not FileAccess.file_exists(RECIPES_PATH):
		push_error("配方文件不存在：%s" % RECIPES_PATH)
		return
	var file := FileAccess.open(RECIPES_PATH, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		recipes = parsed
	else:
		push_error("配方文件格式无效：%s" % RECIPES_PATH)
