class_name WeatherDatabase
extends Resource

@export var weather_types: Array[WeatherDefinition] = []

func build_catalog() -> Dictionary:
	var result: Dictionary = {}
	for weather in weather_types:
		if weather != null and not weather.weather_id.is_empty(): result[String(weather.weather_id)] = weather.to_dictionary()
	return result
