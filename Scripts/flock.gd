extends Node3D

const SPEED = 20
# const CELL_COUNT = 1
const FLOCK_RADIUS = 2.0
const RADIUS_STRENGTH = 100.0
const SEPARATION_RADIUS = 1.2
const SEPARATION_STRENGTH = 6.0
const DAMPING = 0.85
const PROTECTED_RANGE = 5
const CENTERING_FACTOR = 5
const MATCHING_FACTOR = 1
const AVOIDANCE_FACTOR = 25

# parameters for optimizing swarm
var _process_timer: float = 0.0
const PROCESS_INTERVAL: float = 0.016

var _cells: Array[Node3D] = []

# Rule weights
@export var cellMaxVelocity: float = 10
@export var CELL_COUNT: int = 1
@export var cohesionWeight: float = 0.1
@export var separationWeight: float = 3
@export var alignmentWeight: float = 10
@export var foodWeight: float = 20
@export var visualRange: float = 15
@export var foodRange: float = 20
@export var replicateBurstStrength: float = 800.0

@export var bordersWeight: float = 300
@export var predatorWeight: float = 500

var _envDims
var _rallying: bool = false


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
		var cell := preload("res://Scenes/yeast.tscn").instantiate()
		add_child(cell)
		cell.top_level = true
		if CELL_COUNT > 1:
			cell.position = Vector3(
				randf_range(top_left.x, bottom_right.x),
				0.0,
				randf_range(top_left.z, bottom_right.z)
			)
		else:
			cell.position = Vector3(0,0,0)
		_cells.append(cell)
			
func spawn_cell_at(pos: Vector3, burst_dir: Vector3 = Vector3.ZERO) -> void:
	var cell: Node3D = preload("res://Scenes/yeast.tscn").instantiate()
	add_child(cell)
	cell.top_level = true
	cell.position = pos
	cell.burst_timer = 0.3
	cell.velocity = burst_dir * replicateBurstStrength
	_cells.append(cell)
	#if OS.is_debug_build():
		#_add_range_indicator(cell)
		#_add_food_range_indicator(cell)

func remove_cell(cell: Node3D) -> void:
	_cells.erase(cell)
		
func _process(delta: float) -> void:
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input_dir.length() > 1.0:
		input_dir = input_dir.normalized()
	position.x += input_dir.x * SPEED * delta
	position.z += input_dir.y * SPEED * delta

	_process_timer += delta
	if _process_timer >= PROCESS_INTERVAL:
		var scaled_delta := _process_timer
		_process_timer = 0.0
		if Input.is_action_pressed('rally'):
			if not _rallying:
				_rallying = true
				for cell in _cells:
					cell.reset()
			_process_flock(scaled_delta)
		else:
			_rallying = false
			_process_flock_idle(scaled_delta)

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
		cell.velocity.y = 0.0
		cell.velocity *= pow(DAMPING, delta)
		cell.velocity = cell.velocity.limit_length(cellMaxVelocity)

		var body := cell.get_child(0) as CharacterBody3D
		if body:
			body.global_position = cell.global_position
			var collision := body.move_and_collide(cell.velocity * delta)
			if collision:
				cell.velocity = cell.velocity.bounce(collision.get_normal()) * 0.1
			cell.global_position = body.global_position
			cell.global_position.y = 0.0


func _process_flock_idle(delta: float) -> void:
	_detectNeighbors()
	_detectFood()
	_boids_food()
	
	for cell in _cells:
		if not cell.food_targets.is_empty():
			continue
		_boids_cohesion_for(cell)
		_boids_separation_for(cell)
		_boids_alignment_for(cell)
		_boids_borders_for(cell, delta)
		
	_boids_apply(delta)
	

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
				
func _detectFood() -> void:
	var food_items: Array = []
	for node in get_parent().get_children():
		if node.is_in_group("food"):
			food_items.append(node)
	for cell in _cells:
		cell.food_targets.clear()
		for food in food_items:
			var food_radius: float = food.get("radius") if food.get("radius") != null else 0.0
			var dist := cell.global_position.distance_to(food.global_position)
			if dist <= foodRange + food_radius:
				cell.food_targets.append(food)

func _boids_cohesion_for(cell: Node3D) -> void:
	if cell.neighbors.is_empty():
		return

	var average_pos := Vector3.ZERO
	for neighbor in cell.neighbors:
		average_pos += neighbor.global_position
	average_pos /= cell.neighbors.size()

	cell.acceleration += (average_pos - cell.global_position).normalized() * cohesionWeight
		
func _boids_separation_for(cell: Node3D) -> void:
	if cell.neighbors.is_empty():
		return

	var neighbors = cell.neighbors
	var distances = cell.neighborsDistances

	for j in range(neighbors.size()):
		if distances[j] >= PROTECTED_RANGE:
			continue

		var dist_multiplier: float = 1.0 - (distances[j] / float(PROTECTED_RANGE))
		var direction: Vector3 = (cell.global_position - neighbors[j].global_position).normalized()
		cell.acceleration += direction * dist_multiplier * separationWeight
			
func _boids_alignment_for(cell: Node3D) -> void:
	if cell.neighbors.is_empty():
		return

	var average_vel := Vector3.ZERO
	for neighbor in cell.neighbors:
		average_vel += neighbor.velocity
	average_vel /= cell.neighbors.size()

	cell.acceleration += average_vel.normalized() * alignmentWeight


func _boids_borders_for(cell: Node3D, delta: float) -> void:
	var bounds := _get_viewport_world_rect()
	var top_left: Vector3 = bounds[0]
	var bottom_right: Vector3 = bounds[1]
	var mid_point := (top_left + bottom_right) / 2.0

	var pos := cell.global_position
	var out_of_bounds := (
		pos.x < top_left.x or pos.x > bottom_right.x or
		pos.z < top_left.z or pos.z > bottom_right.z
	)

	if out_of_bounds:
		cell.time_out_of_borders += delta
		var dir := (mid_point - pos)
		dir.y = 0.0
		dir = dir.normalized()
		cell.acceleration += dir * cell.time_out_of_borders * bordersWeight
	else:
		cell.time_out_of_borders = 0.0

		
func _boids_apply(delta: float) -> void:
	for cell in _cells:
		if not cell.global_position.is_finite():
			print("corrupt cell position detected, removing: ", cell)
			cell.queue_free()
			_cells.erase(cell)
			continue

		var body := cell.get_child(0) as CharacterBody3D

		if cell.state == cell.State.EATING:
			if body:
				body.global_position = cell.global_position
				var collision := body.move_and_collide(Vector3.ZERO)
				if collision:
					var collider = collision.get_collider()
					if collider and collider.get_parent().is_in_group("enemy"):
						collider.get_parent()._die()
						cell._die()
			continue

		cell.velocity += cell.acceleration * delta
		cell.velocity.y = 0.0
		cell.velocity *= pow(DAMPING, delta)
		cell.velocity = cell.velocity.limit_length(cellMaxVelocity)
		cell.acceleration = Vector3.ZERO

		if body:
			body.global_position = cell.global_position
			var collision := body.move_and_collide(cell.velocity * delta)
			if collision:
				var collider = collision.get_collider()
				if collider and collider.get_parent().is_in_group("food"):
					cell.state = cell.State.EATING
					cell.velocity = Vector3.ZERO
					cell.current_food = collider.get_parent()
					collider.get_parent().increment_eaters()
				elif collider and collider.get_parent().is_in_group("enemy"):
					collider.get_parent()._die()
					cell._die()
				else:
					cell.velocity = cell.velocity.bounce(collision.get_normal()) * 0.1
			cell.global_position = body.global_position
			cell.global_position.y = 0.0

			
			
func _boids_food() -> void:
	for cell in _cells:
		if cell.food_targets.is_empty():
			continue

		var closest_food: Node3D = null
		var closest_dist := foodRange
		for food in cell.food_targets:
			var dist := cell.global_position.distance_to(food.global_position)
			if dist < closest_dist:
				closest_dist = dist
				closest_food = food

		if closest_food == null:
			continue

		var direction := (closest_food.global_position - cell.global_position).normalized()
		direction.y = 0.0
		cell.acceleration = direction * foodWeight
