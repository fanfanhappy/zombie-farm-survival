class_name HordeWaveDefinition
extends Resource

@export var enemies: Array[EnemySpawnEntry] = []
@export_range(0.05, 30.0, 0.05) var spawn_interval := 0.35
@export_range(0.0, 120.0, 0.5) var next_wave_delay := 6.0


func to_dictionary() -> Dictionary:
	var enemy_counts: Dictionary = {}
	for entry in enemies:
		if entry != null and not entry.enemy_id.is_empty(): enemy_counts[String(entry.enemy_id)] = entry.amount
	return {"enemies": enemy_counts, "spawn_interval": spawn_interval, "next_wave_delay": next_wave_delay}
