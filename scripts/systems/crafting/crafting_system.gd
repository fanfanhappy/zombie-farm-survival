class_name CraftingSystem
extends Node

const DEFAULT_RECIPE_DATABASE := preload("res://resources/recipes/recipe_database.tres")

@export var recipe_database: RecipeDatabase = DEFAULT_RECIPE_DATABASE
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
	recipes.clear()
	if recipe_database == null:
		push_error("CraftingSystem 未配置配方数据库")
		return
	recipes = recipe_database.build_catalog()
