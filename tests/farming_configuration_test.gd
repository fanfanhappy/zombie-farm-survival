extends SceneTree


func _init() -> void:
	var database := load("res://resources/crops/crop_database.tres") as CropDatabase
	assert(database != null)
	assert(database.get_configuration_issues().is_empty())
	assert(database.build_catalog().size() == database.crops.size())

	var invalid_crop := CropDefinition.new()
	invalid_crop.display_name = "测试错误作物"
	var invalid_issues := invalid_crop.get_configuration_issues()
	assert(invalid_issues.size() >= 4)

	var invalid_database := CropDatabase.new()
	invalid_database.crops = [database.crops[0], database.crops[0], null]
	var database_issues := invalid_database.get_configuration_issues()
	assert(database_issues.any(func(issue: String) -> bool: return "重复" in issue))
	assert(database_issues.any(func(issue: String) -> bool: return "为空" in issue))

	print("FARMING_CONFIGURATION_OK")
	quit()
