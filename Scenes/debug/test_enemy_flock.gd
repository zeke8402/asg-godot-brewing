extends Node3D

@onready var _flock: Node3D = $Flock

@export var cameraZoomPerCell: float = 0.5
@export var cameraZoomSpeed: float = 0.05

var _time_label: Label
var _yeast_label: Label

func _ready() -> void:
	_build_camera()
	_build_light()
	_build_background()
	_build_food()

func _build_background() -> void:
	var plane := MeshInstance3D.new()
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(500, 500)
	plane.mesh = mesh
	
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://Shaders/must.gdshader")
	plane.material_override = mat
	plane.position.y = -0.1
	add_child(plane)

func _build_camera() -> void:
	var cam := Camera3D.new()
	cam.position = Vector3(0, 15, 0)
	add_child(cam)
	cam.look_at(Vector3.ZERO, Vector3.FORWARD)

func _build_light() -> void:
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45, 45, 0)
	sun.light_energy = 1.2
	sun.shadow_enabled = true
	add_child(sun)
	
	var env_node := WorldEnvironment.new()
	var env := Environment.new()
	
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.1, 0.15, 0.2)
	
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.6, 0.7, 0.8)
	env.ambient_light_energy = 0.8
	
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	env.glow_intensity = 0.3
	
	env_node.environment = env
	add_child(env_node)
	
func _build_food() -> void:
	_spawn_food_at(Vector3(20, 0, 0))
	
	for i in range(50):
		var pos := Vector3(
			randf_range(-100.0, 100.0),
			0.0,
			randf_range(-100.0, 100.0)
		)
		_spawn_food_at(pos)

func _spawn_food_at(pos: Vector3) -> void:
	var sugar := preload("res://Scenes/sugar.tscn").instantiate()
	sugar.position = pos
	sugar.scale = Vector3(10, 10, 10)
	sugar.radius = 10.0
	add_child(sugar)

func _add_action(action: String, key: Key, axis: JoyAxis, axis_value: float) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)

	var key_event := InputEventKey.new()
	key_event.keycode = key
	InputMap.action_add_event(action, key_event)

	var axis_event := InputEventJoypadMotion.new()
	axis_event.axis = axis
	axis_event.axis_value = axis_value
	InputMap.action_add_event(action, axis_event)

func _process(_delta: float) -> void:
	if _flock:
		var camera := get_viewport().get_camera_3d()
		camera.global_position.x = _flock.global_position.x
		camera.global_position.z = _flock.global_position.z
		
		var cell_count: int = _flock._cells.size()
		var target_y: float = clamp(sqrt(float(cell_count)) * cameraZoomPerCell, 15.0, 150.0)
		camera.global_position.y = lerp(camera.global_position.y, target_y, cameraZoomSpeed)
