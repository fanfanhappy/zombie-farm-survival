class_name SnareTrap
extends Area2D

const MAX_CHARGES := 3
var charges := MAX_CHARGES
var triggered_cooldown := 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	monitoring = true
	add_to_group("snare_traps")
	var collision := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 17.0
	collision.shape = circle
	add_child(collision)
	body_entered.connect(_on_body_entered)
	queue_redraw()


func _physics_process(delta: float) -> void:
	triggered_cooldown = maxf(triggered_cooldown - delta, 0.0)


func _on_body_entered(body: Node2D) -> void:
	if triggered_cooldown > 0.0 or charges <= 0 or not body is Zombie: return
	var zombie := body as Zombie
	zombie.take_damage(8.0)
	zombie.apply_slow(0.38, 4.0)
	charges -= 1
	triggered_cooldown = 0.6
	queue_redraw()
	if charges <= 0:
		monitoring = false
		get_tree().create_timer(0.35).timeout.connect(queue_free)


func create_save_data() -> Dictionary:
	return {"x": position.x, "y": position.y, "rotation": rotation, "charges": charges}


func _draw() -> void:
	var metal := Color("#9aa09b") if charges > 0 else Color("#554d48")
	draw_arc(Vector2.ZERO, 15.0, 0.0, TAU, 18, metal, 5.0)
	for angle in range(0, 360, 45):
		var direction := Vector2.from_angle(deg_to_rad(angle))
		draw_line(direction * 9.0, direction * 18.0, metal, 4.0)
	draw_circle(Vector2.ZERO, 5.0, Color("#584334"))
	draw_string(ThemeDB.fallback_font, Vector2(-5, 31), str(charges), HORIZONTAL_ALIGNMENT_CENTER, 12, 11, Color.WHITE)
