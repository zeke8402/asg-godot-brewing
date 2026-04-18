extends Node3D

var radius: float = 1.0
var drift: Vector3 # random direction to drift in
var rotation_speed: Vector3
var _being_eaten: bool = false:
	set(value):
		_being_eaten = value
var _label: Label
var _label_canvas: CanvasLayer
var units: int = 0
var total_units: int = 0
var _eating_count: int = 0:
	set(value):
		_eating_count = value
		_being_eaten = _eating_count > 0

func _build_mesh() -> void:
	var body := CharacterBody3D.new()
	body.collision_layer = 2
	body.collision_mask = 2

	var collision := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 1.0
	collision.shape = shape
	body.add_child(collision)

	var mesh_instance := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(1.0, 0.5, 1.0)
	mesh_instance.mesh = box
	body.add_child(mesh_instance)

	add_child(body)
	
func _build_label() -> void:
	_label_canvas = CanvasLayer.new()
	_label_canvas.layer = 15
	add_child(_label_canvas)
	
	_label = Label.new()
	_label.add_theme_color_override("font_color", Color(1.0, 0.7, 0.8))
	_label.add_theme_font_size_override("font_size", 64)
	_label.visible = false
	_label_canvas.add_child(_label)

func _update_label() -> void:
	if _label:
		_label.text = "%d/%d" % [units, total_units]
		_label.visible = units < total_units

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	rotation_speed = Vector3(
		randf_range(-0.08, 0.08),
		randf_range(-0.08, 0.08),
		randf_range(-0.08, 0.08),
	)
	
	units = randi_range(10, 100)
	total_units = units
	_update_scale()
	drift = Vector3(
		randf_range(-1.0, 1.0),
		0.0,
		randf_range(-1.0, 1.0)
	).normalized() * 0.5
	add_to_group("food")
	_build_mesh()
	_build_label()
	
func _update_scale() -> void:
	var s: float = max(float(units) / 20.0, 0.01)
	scale = Vector3(s, s, s)
	radius = s

func _process(delta: float) -> void:
	if not is_instance_valid(self):
		return
	var body := get_child(0) as CharacterBody3D
	if body:
		body.global_position = position
		body.move_and_collide(drift * delta / scale.x)
		position = body.global_position
		position.y = 0.0
		
	rotation += rotation_speed * delta
	if _label and _label.visible:
		var camera := get_viewport().get_camera_3d()
		if camera:
			var screen_pos := camera.unproject_position(global_position)
			_label.position = screen_pos - Vector2(_label.size.x / 2.0, _label.size.y / 2.0)
	_update_label()
	
func eat() -> int:
	if units <= 0:
		return 0
	units -= 1
	_being_eaten = true
	if units % 10 == 0:
		_update_scale()
	if units <= 0:
		queue_free()
	return 1
	
func increment_eaters() -> void:
	_eating_count += 1
	
	
func stop_eating() -> void:
	_eating_count -= 1
