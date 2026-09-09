class_name WorldTargetingService
extends RefCounted


func find_mouse_target(game: Node, mouse_world_position: Vector2) -> Node2D:
	var nearest: Node2D
	var nearest_cursor_distance := 28.0
	for node in game.get_tree().get_nodes_in_group("mouse_action_targets"):
		var target := node as Node2D
		var cursor_distance := mouse_world_position.distance_to(target.global_position)
		var selection_radius := FarmPlot.CELL_SIZE * 0.5 if target is FarmPlot else nearest_cursor_distance
		if cursor_distance <= selection_radius and cursor_distance < nearest_cursor_distance:
			nearest = target
			nearest_cursor_distance = cursor_distance
	for node in game.get_tree().get_nodes_in_group("zombies"):
		var zombie := node as Zombie
		var cursor_distance := mouse_world_position.distance_to(zombie.global_position)
		if cursor_distance < nearest_cursor_distance:
			nearest = zombie
			nearest_cursor_distance = cursor_distance
	return nearest


func find_nearest_interactable(game: Node) -> Node:
	var nearest: Node
	var nearest_distance := 58.0
	for node in game.get_tree().get_nodes_in_group("interactables"):
		var distance: float = game.player.global_position.distance_to(node.global_position)
		if distance < nearest_distance:
			var prompt: String = node.get_interaction_prompt() if node.has_method("get_interaction_prompt") else ""
			if not prompt.is_empty():
				nearest = node
				nearest_distance = distance
	return nearest


func find_nearest_defense(game: Node) -> DefenseStructure:
	var nearest: DefenseStructure
	var nearest_distance := 58.0
	for node in game.get_tree().get_nodes_in_group("defenses"):
		var structure := node as DefenseStructure
		var distance: float = game.player.global_position.distance_to(structure.global_position)
		if distance < nearest_distance:
			nearest = structure
			nearest_distance = distance
	return nearest
