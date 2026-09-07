class_name HomesteadCore
extends StaticBody2D

const HOUSE_VISUAL_SCENE := preload("res://scenes/world/buildings/wooden_house_visual.tscn")

signal health_changed(current: float, maximum: float)
signal destroyed

@export var max_health := 300.0
var health := 300.0


func _ready() -> void:
	var visual := HOUSE_VISUAL_SCENE.instantiate()
	visual.name = "WoodenHouseVisual"
	add_child(visual)


func setup(collision_size: Vector2) -> void:
	collision_layer = 1
	collision_mask = 0
	health = max_health
	add_to_group("homestead_core")
	var collision := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = collision_size
	collision.shape = rectangle
	add_child(collision)
	health_changed.emit(health, max_health)
	queue_redraw()


func take_damage(amount: float) -> void:
	if health <= 0.0: return
	health = maxf(health - amount, 0.0)
	health_changed.emit(health, max_health)
	queue_redraw()
	if health <= 0.0: destroyed.emit()


func repair(amount: float) -> void:
	health = minf(health + amount, max_health)
	health_changed.emit(health, max_health)
	queue_redraw()


func restore_full() -> void:
	health = max_health
	health_changed.emit(health, max_health)
	queue_redraw()


func _draw() -> void:
	if health >= max_health: return
	var ratio := clampf(health / max_health, 0.0, 1.0)
	draw_rect(Rect2(-90, -135, 180, 10), Color("#321f20"))
	draw_rect(Rect2(-90, -135, 180 * ratio, 10), Color("#65b65c") if ratio > 0.35 else Color("#d5534d"))
