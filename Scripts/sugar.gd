extends Node3D

var radius: float = 1.0
var drift: Vector3 # random direction to drift in
var _being_eaten: bool = false
var _label: Label3D

var units: int = 0
var total_units: int = 0

func _build_mesh() -> void:
	var body := CharacterBody3D.new()
	body.collision_layer = 2
	body.collision_mask = 2

	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.0, 0.5, 1.0)
	collision.shape = shape
	body.add_child(collision)

	var mesh_instance := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(1.0, 0.5, 1.0)
	mesh_instance.mesh = box
	body.add_child(mesh_instance)

	add_child(body)
	
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

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
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
	_build_label()
	
func _update_scale() -> void:
	var s: float = float(units) / 100.0
	scale = Vector3(s, s, s)
	radius = s

func _process(delta: float) -> void:
	var body := get_child(0) as CharacterBody3D
	if body:
		body.global_position = position
		body.move_and_collide(drift * delta / scale.x)
		position = body.global_position
		position.y = 0.0
		
	_update_label()
	
func eat() -> int:
	if units <= 0:
		return 0
	units -= 1
	if units % 10 == 0:
		_update_scale()
	if units <= 0:
		queue_free()
	return 1
	
