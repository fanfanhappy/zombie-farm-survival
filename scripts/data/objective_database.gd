class_name ObjectiveDatabase
extends Resource

@export var objectives: Array[ObjectiveDefinition] = []

func build_list() -> Array:
	var result: Array = []
	for objective in objectives:
		if objective != null and not objective.objective_id.is_empty(): result.append(objective.to_dictionary())
	return result
