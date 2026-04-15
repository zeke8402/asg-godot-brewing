extends Node3D

@onready var _flock: Node3D = $Flock
var _time_label: Label

func _ready() -> void:
	_setup_input_map()
	_build_background()
	_build_camera()
	_build_hud()
	_build_light()
	_build_landmarks()
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

func _build_landmarks() -> void:
	var positions = [
		Vector3(3, 0, 0),
		Vector3(-3, 0, 0),
		Vector3(0, 0, 3),
		Vector3(0, 0, -3),
		Vector3(5, 0, 5),
	]

	for pos in positions:
		var mesh_instance := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.3
		sphere.height = 0.6
		mesh_instance.mesh = sphere

		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.8, 0.1, 0.1)
		mesh_instance.material_override = mat

		mesh_instance.position = pos
		add_child(mesh_instance)

func _build_food() -> void:
	var strawberry := preload("res://Scenes/strawberry.tscn").instantiate()
	strawberry.position = Vector3(20, 0, 0)
	strawberry.scale = Vector3(10, 10, 10)
	add_child(strawberry)

func _setup_input_map() -> void:
	_add_action("move_up",    KEY_W,  JOY_AXIS_LEFT_Y, -1)
	_add_action("move_down",  KEY_S,  JOY_AXIS_LEFT_Y,  1)
	_add_action("move_left",  KEY_A,  JOY_AXIS_LEFT_X, -1)
	_add_action("move_right", KEY_D,  JOY_AXIS_LEFT_X,  1)

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

func _build_hud() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)

	_time_label = Label.new()
	_time_label.position = Vector2(10, -10)
	_time_label.anchor_bottom = 1.0
	_time_label.anchor_top = 1.0
	_time_label.grow_vertical = Control.GROW_DIRECTION_BEGIN
	canvas.add_child(_time_label)

func _process(_delta: float) -> void:
	_time_label.text = "%.2f" % (Time.get_ticks_msec() / 1000.0)
	if _flock:
		get_viewport().get_camera_3d().global_position.x = _flock.global_position.x
		get_viewport().get_camera_3d().global_position.z = _flock.global_position.z
