extends Node3D

@onready var _flock: Node3D = $Flock

@export var cameraZoomPerCell: float = 0.5
@export var cameraZoomSpeed: float = 0.05

var _time_label: Label
var _yeast_label: Label

var _enemy_flocks: Array[Node3D] = []
var _enemy_label: Label

func _ready() -> void:
	_build_background()
	_build_camera()
	_build_hud()
	_build_water_overlay()
	_build_light()
	_build_food()
	_build_enemies()
	
func _build_enemies() -> void:
	for i in range(3):
		var flock := preload("res://Scenes/enemy_flock.tscn").instantiate()
		flock.position = Vector3(
			randf_range(-80.0, 80.0),
			0.0,
			randf_range(-80.0, 80.0)
		)
		add_child(flock)
		_enemy_flocks.append(flock)

func _build_background() -> void:
	var plane := MeshInstance3D.new()
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(500, 500)
	plane.mesh = mesh
	
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://Shaders/must.gdshader")
	plane.material_override = mat
	plane.position.y = -5
	add_child(plane)
	
func _build_water_overlay() -> void:
	var canvas := CanvasLayer.new()
	canvas.layer = 1
	add_child(canvas)
	
	var rect := ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://Shaders/water_overlay.gdshader")
	rect.material = mat
	canvas.add_child(rect)

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

func _build_hud() -> void:
	var canvas := CanvasLayer.new()
	canvas.layer = 10
	add_child(canvas)
	
	_time_label = Label.new()
	_time_label.anchor_left = 1.0
	_time_label.anchor_right = 1.0
	_time_label.anchor_top = 0.0
	_time_label.anchor_bottom = 0.0
	_time_label.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_time_label.position = Vector2(-10, 10)
	canvas.add_child(_time_label)
	
	_yeast_label = Label.new()
	_yeast_label.anchor_left = 0.5
	_yeast_label.anchor_right = 0.5
	_yeast_label.anchor_top = 0.0
	_yeast_label.anchor_bottom = 0.0
	_yeast_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_yeast_label.position = Vector2(0, 10)
	canvas.add_child(_yeast_label)
	
	_enemy_label = Label.new()
	_enemy_label.anchor_left = 0.5
	_enemy_label.anchor_right = 0.5
	_enemy_label.anchor_top = 0.0
	_enemy_label.anchor_bottom = 0.0
	_enemy_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_enemy_label.position = Vector2(0, 30)
	canvas.add_child(_enemy_label)

func _process(_delta: float) -> void:
	_time_label.text = "%.2f" % (Time.get_ticks_msec() / 1000.0)
	_yeast_label.text = "Yeast: %d" % _flock._cells.size()
		
	var total_enemy_cells: int = 0
	# Reactivate to quickly test win screen
	'''
	if _enemy_flocks.size() <= 0:
		var win_screen := preload("res://Scenes/win_screen.tscn").instantiate()
		add_child(win_screen)
		win_screen.call_deferred("setup", 0,0,0)
	'''

		
	for flock in _enemy_flocks:
		total_enemy_cells += flock._cells.size()
		_enemy_label.text = "Enemy cells: %d" % total_enemy_cells
		
	if total_enemy_cells == 0 and _enemy_flocks.size() > 0:
		_show_win_screen()
		
	if _flock:
		var camera := get_viewport().get_camera_3d()
		camera.global_position.x = _flock.global_position.x
		camera.global_position.z = _flock.global_position.z
		
		var cell_count: int = _flock._cells.size()
		var target_y: float = clamp(sqrt(float(cell_count)) * cameraZoomPerCell, 7.0, 50.0)
		camera.global_position.y = lerp(camera.global_position.y, target_y, cameraZoomSpeed)
		
func _show_win_screen() -> void:
	var elapsed: float = Time.get_ticks_msec() / 1000.0
	var score: int = _flock._cells.size() * 1000 - int(elapsed)
	
	var win_screen := preload("res://Scenes/win_screen.tscn").instantiate()
	add_child(win_screen)
	win_screen.setup(score, elapsed, _flock._cells.size())
