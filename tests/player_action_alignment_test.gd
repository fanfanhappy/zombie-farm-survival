extends SceneTree


func _init() -> void:
	var player := preload("res://scenes/actors/player/player.tscn").instantiate() as Player
	var animation := player.get_node("PlayerAnimation") as AnimatedSprite2D
	var frames := animation.sprite_frames
	for action_name in [
		&"axe_down", &"axe_left", &"axe_right", &"axe_up",
		&"hoe_down", &"hoe_left", &"hoe_right", &"hoe_up",
		&"water_down", &"water_left", &"water_right", &"water_up",
	]:
		assert(frames.has_animation(action_name))
		assert(frames.get_frame_count(action_name) == 2)
		for frame_index in frames.get_frame_count(action_name):
			var texture := frames.get_frame_texture(action_name, frame_index) as AtlasTexture
			assert(texture != null)
			assert(texture.region.size == Vector2(48, 48))
	assert((player.get_node("ToolActionPoints/Up") as Marker2D).position == Vector2(0, -32))
	assert((player.get_node("ToolActionPoints/Down") as Marker2D).position == Vector2(0, 32))
	assert((player.get_node("ToolActionPoints/Left") as Marker2D).position == Vector2(-32, 0))
	assert((player.get_node("ToolActionPoints/Right") as Marker2D).position == Vector2(32, 0))
	player.free()
	print("PLAYER_ACTION_ALIGNMENT_OK")
	quit()
