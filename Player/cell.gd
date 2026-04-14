extends Node3D

var anchor: Node3D = null
var velocity := Vector3.ZERO

const FLOCK_RADIUS = 2.0
const RADIUS_STRENGTH = 8.0
const SEPARATION_RADIUS = 1.2
const SEPARATION_STRENGTH = 6.0
const DAMPING = 0.85

func _ready() -> void:
	_build_mesh()
	_set_initial_position()

func _build_mesh() -> void:
	var mesh_instance := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.3
	sphere.height = 0.6
	mesh_instance.mesh = sphere

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.9, 0.95, 0.6)
	mesh_instance.material_override = mat

	add_child(mesh_instance)

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
	if anchor == null:
		return
		
	var to_cell: Vector3 = global_position - anchor.global_position

	if to_cell.length() < 0.001:
		to_cell = Vector3(1, 0, 0)

	var ideal_position: Vector3 = anchor.global_position + to_cell.normalized() * FLOCK_RADIUS
	var radius_force: Vector3 = (ideal_position - global_position) * RADIUS_STRENGTH
	var separation_force := Vector3.ZERO

	for other in anchor.cells:
		if other == self:
			continue
		var diff: Vector3 = global_position - other.global_position
		var dist: float = diff.length()
		if dist < SEPARATION_RADIUS and dist > 0.001:
			separation_force += diff.normalized() * (SEPARATION_RADIUS - dist) * SEPARATION_STRENGTH

	velocity += (radius_force + separation_force) * delta
	velocity *= DAMPING
	global_position += velocity * delta
