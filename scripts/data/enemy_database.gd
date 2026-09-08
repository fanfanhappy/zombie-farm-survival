class_name EnemyDatabase
extends Resource

@export var enemies: Array[EnemyDefinition] = []


func get_definition(enemy_id: StringName) -> EnemyDefinition:
	for enemy in enemies:
		if enemy != null and enemy.enemy_id == enemy_id:
			return enemy
	return null


func has_definition(enemy_id: StringName) -> bool:
	return get_definition(enemy_id) != null
