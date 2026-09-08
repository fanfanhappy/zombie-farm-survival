class_name WeatherDefinition
extends Resource

@export var weather_id: StringName
@export var display_name := "新天气"
@export_range(0, 1000, 1) var weight := 1
@export_range(0.1, 5.0, 0.05) var thirst_multiplier := 1.0
@export var waters_crops := false

func to_dictionary() -> Dictionary:
	return {"name": display_name, "weight": weight, "thirst_multiplier": thirst_multiplier, "waters_crops": waters_crops}
