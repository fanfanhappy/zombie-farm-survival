class_name WeatherSystem
extends Node

signal weather_changed(weather_id: String, weather_data: Dictionary)

const CATALOG_PATH := "res://data/weather/weather_catalog.json"
var catalog: Dictionary = {}
var current_weather_id := "clear"


func _ready() -> void:
	var file := FileAccess.open(CATALOG_PATH, FileAccess.READ)
	if file == null:
		push_error("天气目录不存在：%s" % CATALOG_PATH)
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary: catalog = parsed


func choose_weather_for_day(day: int) -> void:
	var generator := RandomNumberGenerator.new()
	generator.seed = day * 7919 + 137
	var total_weight := 0
	for data in catalog.values(): total_weight += int(data.get("weight", 0))
	var roll := generator.randi_range(1, maxi(total_weight, 1))
	var accumulated := 0
	for weather_id in catalog:
		accumulated += int(catalog[weather_id].get("weight", 0))
		if roll <= accumulated:
			set_weather(str(weather_id))
			return
	set_weather("clear")


func set_weather(weather_id: String) -> void:
	current_weather_id = weather_id if catalog.has(weather_id) else "clear"
	weather_changed.emit(current_weather_id, get_current_data())


func get_current_data() -> Dictionary:
	return catalog.get(current_weather_id, {"name": "晴朗", "thirst_multiplier": 1.0})


func get_display_name() -> String:
	return str(get_current_data().get("name", current_weather_id))
