class_name HordeSystem
extends Node

signal zombie_spawn_requested(fast: bool)
signal horde_started(total_waves: int)
signal wave_started(wave_number: int, total_waves: int)
signal horde_completed
signal state_changed

const DEFAULT_HORDE_DEFINITION := preload("res://resources/hordes/first_horde.tres")

@export var horde_definition: HordeDefinition = DEFAULT_HORDE_DEFINITION
var waves: Array = []
var active := false
var current_wave_index := -1
var alive_zombies := 0
var pending_spawns := 0
var time_until_next_wave := 0.0
var reward: Dictionary = {}


func _ready() -> void:
	_load_horde_data()


func _process(delta: float) -> void:
	if not active or pending_spawns > 0 or alive_zombies > 0:
		return
	if current_wave_index >= waves.size() - 1:
		_finish_horde()
		return
	time_until_next_wave -= delta
	if time_until_next_wave <= 0.0:
		_start_next_wave()
	state_changed.emit()


func start_horde() -> void:
	if active or waves.is_empty(): return
	active = true
	current_wave_index = -1
	alive_zombies = 0
	pending_spawns = 0
	time_until_next_wave = 1.5
	horde_started.emit(waves.size())
	state_changed.emit()


func cancel_horde() -> void:
	active = false
	current_wave_index = -1
	alive_zombies = 0
	pending_spawns = 0
	time_until_next_wave = 0.0
	state_changed.emit()


func notify_zombie_defeated() -> void:
	if not active: return
	alive_zombies = maxi(alive_zombies - 1, 0)
	state_changed.emit()


func get_status_text() -> String:
	if not active: return ""
	if current_wave_index < 0:
		return "尸潮即将开始……"
	if pending_spawns > 0:
		return "尸潮　第%d/%d波　正在来袭" % [current_wave_index + 1, waves.size()]
	if alive_zombies > 0:
		return "尸潮　第%d/%d波　剩余 %d" % [current_wave_index + 1, waves.size(), alive_zombies]
	return "下一波还有 %.1f 秒" % maxf(time_until_next_wave, 0.0)


func _start_next_wave() -> void:
	current_wave_index += 1
	var wave: Dictionary = waves[current_wave_index]
	var normal_count := int(wave.get("normal", 0))
	var fast_count := int(wave.get("fast", 0))
	var spawn_order: Array[bool] = []
	for index in normal_count: spawn_order.append(false)
	for index in fast_count: spawn_order.append(true)
	spawn_order.shuffle()
	pending_spawns = spawn_order.size()
	alive_zombies += spawn_order.size()
	var interval := float(wave.get("spawn_interval", 0.35))
	for index in spawn_order.size():
		get_tree().create_timer(index * interval).timeout.connect(_emit_spawn.bind(spawn_order[index]))
	wave_started.emit(current_wave_index + 1, waves.size())
	state_changed.emit()


func _emit_spawn(fast: bool) -> void:
	if not active: return
	pending_spawns = maxi(pending_spawns - 1, 0)
	zombie_spawn_requested.emit(fast)
	if pending_spawns == 0:
		var wave: Dictionary = waves[current_wave_index]
		time_until_next_wave = float(wave.get("next_wave_delay", 6.0))
	state_changed.emit()


func _finish_horde() -> void:
	active = false
	horde_completed.emit()
	state_changed.emit()


func _load_horde_data() -> void:
	waves.clear()
	reward.clear()
	if horde_definition == null:
		push_error("HordeSystem 未配置尸潮资源")
		return
	waves = horde_definition.waves.duplicate(true)
	reward = horde_definition.reward.duplicate(true)
