class_name WeatherSystem
extends Node

signal weather_changed(weather_id: String, weather_data: Dictionary)

const DEFAULT_WEATHER_DATABASE := preload("res://resources/weather/weather_database.tres")
@export var weather_database: WeatherDatabase = DEFAULT_WEATHER_DATABASE
var catalog: Dictionary = {}
var current_weather_id := "clear"


func _ready() -> void:
	if weather_database == null:
		push_error("WeatherSystem 未配置天气数据库")
		return
	catalog = weather_database.build_catalog()


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
