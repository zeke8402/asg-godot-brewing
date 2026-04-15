extends CharacterBody3D

const SPEED = 25.0
const CELL_COUNT = 100
const FLOCK_RADIUS = 2.0

var cells: Array[Node3D] = []

func _ready() -> void:
	_build_reticle()
	_spawn_cells()

func _build_reticle() -> void:
	var label := Label3D.new()
	label.text = "X"
	label.font_size = 64
	label.modulate = Color(0.0, 1.0, 0.8)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	add_child(label)
	
func _spawn_cells() -> void:
	for i in range(CELL_COUNT):
		var cell: Node3D = preload("res://Player/cell.gd").new()
		cell.anchor = self
		get_parent().add_child(cell)
		cells.append(cell)
		var angle: float = (float(i) / float(CELL_COUNT)) * TAU
		cell.global_position = Vector3(
			global_position.x + cos(angle) * FLOCK_RADIUS,
			global_position.y,
			global_position.z + sin(angle) * FLOCK_RADIUS
		)

func _physics_process(delta: float) -> void:
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")

	if input_dir.length() > 1.0:
		input_dir = input_dir.normalized()

	position.x += input_dir.x * SPEED * delta
	position.z += input_dir.y * SPEED * delta
	
	_update_cells(delta)

func _update_cells(delta: float) -> void:
	for cell in cells:
		cell.update(delta)
