class_name PlayerAnimationController
extends AnimatedSprite2D


func play_tool_action(action_type: String, facing_direction: Vector2) -> float:
	var animation_name := "%s_%s" % [action_type, get_direction_name(facing_direction)]
	if sprite_frames == null or not sprite_frames.has_animation(animation_name):
		push_warning("未配置工具动画：%s" % animation_name)
		return 0.0
	var duration := float(sprite_frames.get_frame_count(animation_name)) / maxf(sprite_frames.get_animation_speed(animation_name), 0.01)
	play(animation_name)
	return duration


func update_locomotion(direction: Vector2, facing_direction: Vector2, action_locked: bool) -> void:
	if action_locked:
		return
	var animation_name := "%s_%s" % ["idle" if direction == Vector2.ZERO else "walk", get_direction_name(facing_direction)]
	if animation != animation_name:
		play(animation_name)


func update_damage_tint(hurt: bool) -> void:
	modulate = Color("#ffb3ad") if hurt else Color.WHITE


func get_direction_name(facing_direction: Vector2) -> String:
	if absf(facing_direction.x) > absf(facing_direction.y):
		return "right" if facing_direction.x > 0.0 else "left"
	return "down" if facing_direction.y > 0.0 else "up"
