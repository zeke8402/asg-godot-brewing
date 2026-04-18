extends Node2D

var _flock: Node3D
var _main: Node3D

func setup(flock: Node3D, main: Node3D) -> void:
	_flock = flock
	_main = main

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var camera := get_viewport().get_camera_3d()
	if not camera or not _flock:
		return

	var nearest_sugar: Node3D = null
	var nearest_dist := INF

	for node in _main.get_children():
		if node.is_in_group("food"):
			var dist := _flock.global_position.distance_to(node.global_position)
			if dist < nearest_dist:
				nearest_dist = dist
				nearest_sugar = node

	if nearest_sugar == null:
		return

	var viewport_size := get_viewport().get_visible_rect().size
	var center := viewport_size / 2.0
	var sugar_screen_pos := camera.unproject_position(nearest_sugar.global_position)

	var margin := 50.0
	var on_screen := (
		sugar_screen_pos.x > margin and sugar_screen_pos.x < viewport_size.x - margin and
		sugar_screen_pos.y > margin and sugar_screen_pos.y < viewport_size.y - margin
	)

	if on_screen:
		return

	var direction := (sugar_screen_pos - center).normalized()
	var angle := direction.angle()
	var arrow_pos := center + direction * 80.0

	draw_set_transform(arrow_pos, angle, Vector2.ONE)
	draw_colored_polygon(PackedVector2Array([
		Vector2(20, 0),
		Vector2(-10, -10),
		Vector2(-10, 10),
	]), Color(1.0, 0.8, 0.2, 0.8))
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
