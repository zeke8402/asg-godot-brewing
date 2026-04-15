extends Node3D

var anchor: Node3D = null
var velocity := Vector3.ZERO

const FLOCK_RADIUS = 2.0
const RADIUS_STRENGTH = 8.0
const SEPARATION_RADIUS = 1.2
const SEPARATION_STRENGTH = 6.0
const DAMPING = 0.85
const VISUAL_RANGE = 20
const PROTECTED_RANGE = 5
const CENTERING_FACTOR = 5
const MATCHING_FACTOR = 1
const AVOIDANCE_FACTOR = 1000
const MIN_SPEED = -0.1
const MAX_SPEED = 0.1

func _ready() -> void:
	_build_mesh()
	_set_initial_position()

func _build_mesh() -> void:
	var body = AnimatableBody3D.new()
	var mesh_instance := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.3
	sphere.height = 0.6
	mesh_instance.mesh = sphere

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.9, 0.95, 0.6)
	mesh_instance.material_override = mat

	body.add_child(mesh_instance)
	add_child(body)

func _set_initial_position() -> void:
	var index: int = anchor.cells.find(self)
	var total: int = anchor.cells.size()
	var angle: float = (float(index) / float(total)) * TAU
	global_position = Vector3(
		anchor.global_position.x + cos(angle) * FLOCK_RADIUS,
		anchor.global_position.y,
		anchor.global_position.z + sin(angle) * FLOCK_RADIUS
	)

func update(delta: float) -> void:
	var pos_avg = anchor.position
	var vel_avg = anchor.velocity
	var close_dv = (anchor.position - position) * CENTERING_FACTOR * 10
	var neighboring_cells = 1
	
	for cell in anchor.cells:
		var distance_to_cell: Vector3 = position - cell.position
		
		if distance_to_cell.length() < VISUAL_RANGE:
			if distance_to_cell.length_squared() < PROTECTED_RANGE ** 2:
				close_dv += distance_to_cell + Vector3(0.5, anchor.global_position.y, 0.5)
			else:
				pos_avg += cell.position
				vel_avg += cell.velocity
				neighboring_cells += 1
				
		pos_avg = pos_avg / neighboring_cells
		vel_avg = vel_avg / neighboring_cells
			
		velocity += (pos_avg - position) * CENTERING_FACTOR + (vel_avg - velocity) * MATCHING_FACTOR
			
		velocity += close_dv * AVOIDANCE_FACTOR
		
		velocity = velocity.clampf(MIN_SPEED, MAX_SPEED) * delta
		
		position += velocity
		
