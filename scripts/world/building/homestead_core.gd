class_name HomesteadCore
extends StaticBody2D

signal health_changed(current: float, maximum: float)
signal destroyed

@export var max_health := 300.0
var health := 300.0
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var health_bar: ProgressBar = $HealthBar


func setup(collision_size: Vector2) -> void:
	health = max_health
	add_to_group("homestead_core")
	var rectangle := collision_shape.shape as RectangleShape2D
	rectangle.size = collision_size
	health_changed.emit(health, max_health)
	_update_health_bar()


func take_damage(amount: float) -> void:
	if health <= 0.0: return
	health = maxf(health - amount, 0.0)
	health_changed.emit(health, max_health)
	_update_health_bar()
	if health <= 0.0: destroyed.emit()


func repair(amount: float) -> void:
	health = minf(health + amount, max_health)
	health_changed.emit(health, max_health)
	_update_health_bar()


func restore_full() -> void:
	health = max_health
	health_changed.emit(health, max_health)
	_update_health_bar()


func _update_health_bar() -> void:
	if not is_instance_valid(health_bar):
		return
	health_bar.max_value = max_health
	health_bar.value = health
	health_bar.visible = health < max_health
	health_bar.modulate = Color.WHITE if health / max_health > 0.35 else Color("#d5534d")
