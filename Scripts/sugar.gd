extends Node3D

var radius: float = 1.0
var drift: Vector3 # random direction to drift in
var rotation_speed: Vector3
var _feed_indicator: MeshInstance3D
var _being_eaten: bool = false:
	set(value):
		_being_eaten = value
		if _feed_indicator:
			_feed_indicator.visible = value

var _label: Label3D
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
	
func _build_feed_indicator() -> void:
	_feed_indicator = MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.9
	torus.outer_radius = 1.0
	_feed_indicator.mesh = torus
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.5, 0.0, 0.6)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_feed_indicator.material_override = mat
	_feed_indicator.visible = false
	_feed_indicator.top_level = true
	add_child(_feed_indicator)
	
func _build_label() -> void:
	_label = Label3D.new()
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.no_depth_test = true
	_label.font_size = 64
	_label.modulate = Color(1.0, 1.0, 1.0)
	_label.outline_size = 8
	_label.outline_modulate = Color(0.9, 0.4, 0.6)
	_label.position.y = 0.5
	_update_label()
	add_child(_label)

func _update_label() -> void:
	if _label:
		_label.text = "%d/%d" % [units, total_units]
		
func _update_feed_indicator() -> void:
	if _feed_indicator:
		var torus := _feed_indicator.mesh as TorusMesh
		if torus:
			torus.inner_radius = scale.x * 0.9
			torus.outer_radius = scale.x * 1.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	rotation_speed = Vector3(
		randf_range(-0.5, 0.5),
		randf_range(-0.5, 0.5),
		randf_range(-0.5, 0.5)
	)
	
	units = randi_range(10, 1000)
	total_units = units
	_update_scale()
	drift = Vector3(
		randf_range(-1.0, 1.0),
		0.0,
		randf_range(-1.0, 1.0)
	).normalized() * 0.5
	add_to_group("food")
	_build_mesh()
	_build_feed_indicator()
	_update_feed_indicator()
	_build_label()
	
func _update_scale() -> void:
	var s: float = float(units) / 100.0
	scale = Vector3(s, s, s)
	radius = s
	_update_feed_indicator()

func _process(delta: float) -> void:
	var body := get_child(0) as CharacterBody3D
	if body:
		body.global_position = position
		body.move_and_collide(drift * delta / scale.x)
		position = body.global_position
		position.y = 0.0
		
	rotation += rotation_speed * delta
	_update_label()
	
	if _feed_indicator:
		_feed_indicator.global_position = global_position
		_feed_indicator.global_position.y = 0.0
		_feed_indicator.rotation = Vector3.ZERO
	
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
