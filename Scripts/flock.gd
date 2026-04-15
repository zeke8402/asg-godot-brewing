extends Node3D

const SPEED = 25
const CELL_COUNT = 100
const FLOCK_RADIUS = 2.0
const RADIUS_STRENGTH = 8.0
const SEPARATION_RADIUS = 1.2
const SEPARATION_STRENGTH = 6.0
const DAMPING = 0.85
const PROTECTED_RANGE = 5
const CENTERING_FACTOR = 5
const MATCHING_FACTOR = 1
const AVOIDANCE_FACTOR = 1000

var _cells: Array[Node3D] = []

# Rule weights
@export var cellMaxVelocity: float = 1.0
@export var cohesionWeight: float = 0.3
@export var separationWeight: float = 50
@export var alignmentWeight: float = 1
@export var visualRange: float = 2


@export var bordersWeight: float = 300
@export var predatorWeight: float = 500

var _envDims

func _ready() -> void:
	_envDims = get_viewport()
	_build_reticle()
	call_deferred("_spawn_cells")
	
func _build_reticle() -> void:
	var label := Label3D.new()
	label.text = "X"
	label.font_size = 64
	label.modulate = Color(0.0, 1.0, 0.8)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	add_child(label)
	
func _get_viewport_world_rect() -> Array:
	var camera := get_viewport().get_camera_3d()
	var viewport_size := get_viewport().get_visible_rect().size
	
	var corners := [
		Vector2(0, 0),
		Vector2(viewport_size.x, viewport_size.y)
	]
	
	var world_corners := []
	for corner in corners:
		var origin := camera.project_ray_origin(corner)
		var direction := camera.project_ray_normal(corner)
		var t := -origin.y / direction.y
		world_corners.append(origin + direction * t)
	
	return world_corners  # [top_left, bottom_right] in world space


func _spawn_cells() -> void:
	var bounds := _get_viewport_world_rect()
	var top_left: Vector3 = bounds[0]
	var bottom_right: Vector3 = bounds[1]
	
	for i in range(CELL_COUNT):
		var cell := preload("res://Scenes/yeast_cell.tscn").instantiate()
		get_parent().add_child(cell)
		cell.position = Vector3(
			randf_range(top_left.x, bottom_right.x),
			0.0,
			randf_range(top_left.z, bottom_right.z)
		)
		_cells.append(cell)
		
		if OS.is_debug_build():
			_add_range_indicator(cell)
		
func _add_range_indicator(cell: Node3D) -> void:
	var mesh_instance := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = visualRange - 0.1
	torus.outer_radius = visualRange
	mesh_instance.mesh = torus
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1, 0, 0, 0.2)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh_instance.material_override = mat
	cell.add_child(mesh_instance)

func _process(delta: float) -> void:
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input_dir.length() > 1.0:
		input_dir = input_dir.normalized()
	position.x += input_dir.x * SPEED * delta
	position.z += input_dir.y * SPEED * delta
	
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		_process_flock(delta)
	else:
		_process_flock_idle(delta)


func _process_flock(delta: float) -> void:
	for cell in _cells:
		var to_cell: Vector3 = cell.global_position - global_position
		if to_cell.length() < 0.001:
			to_cell = Vector3(1, 0, 0)

		var ideal_position: Vector3 = global_position + to_cell.normalized() * FLOCK_RADIUS
		var radius_force: Vector3 = (ideal_position - cell.global_position) * RADIUS_STRENGTH

		var separation_force := Vector3.ZERO
		for other in _cells:
			if other == cell:
				continue
			var diff: Vector3 = cell.global_position - other.global_position
			var dist: float = diff.length()
			if dist < SEPARATION_RADIUS and dist > 0.001:
				separation_force += diff.normalized() * (SEPARATION_RADIUS - dist) * SEPARATION_STRENGTH

		cell.velocity += (radius_force + separation_force) * delta
		cell.velocity *= DAMPING
		cell.global_position += cell.velocity * delta


func _process_flock_idle(delta: float) -> void:
	_detectNeighbors()
	_cohesion()
	_separation()
	_apply(delta)
		
	
	
func _detectNeighbors():
	for i in range(_cells.size()):
		_cells[i].neighbors.clear()
		_cells[i].neighborsDistances.clear()
	
	for i in range(_cells.size()):		
		for j in range(i+1, _cells.size()):
			var distance = _cells[i].get_position().distance_to(_cells[j].get_position())
			if (distance <= visualRange):
				_cells[i].neighbors.append(_cells[j])
				_cells[j].neighbors.append(_cells[i])
				_cells[i].neighborsDistances.append(distance)
				_cells[j].neighborsDistances.append(distance)
				
func _cohesion() -> void:
	for cell in _cells:
		if cell.neighbors.is_empty():
			continue

		var average_pos := Vector3.ZERO
		for neighbor in cell.neighbors:
			average_pos += neighbor.global_position
		average_pos /= cell.neighbors.size()

		cell.acceleration += (average_pos - cell.global_position).normalized() * cohesionWeight
		
func _separation() -> void:
	for cell in _cells:
		if cell.neighbors.is_empty():
			continue

		var neighbors = cell.neighbors
		var distances = cell.neighborsDistances

		for j in range(neighbors.size()):
			if distances[j] >= PROTECTED_RANGE:
				continue

			var dist_multiplier: float = 1.0 - (distances[j] / float(PROTECTED_RANGE))
			var direction: Vector3 = (cell.global_position - neighbors[j].global_position).normalized()
			cell.acceleration += direction * dist_multiplier * separationWeight


func _apply(delta: float) -> void:
	for cell in _cells:
		cell.velocity += cell.acceleration * delta
		cell.velocity.y = 0.0
		cell.velocity = cell.velocity.limit_length(cellMaxVelocity)
		cell.acceleration = Vector3.ZERO
		cell.global_position += cell.velocity * delta
