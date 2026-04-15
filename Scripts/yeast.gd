extends Node3D

var velocity := Vector3.ZERO
var acceleration := Vector3.ZERO
var time_out_of_borders: float = 0.0

@export var maxVelocity: float = 5.0
@export var maxAcceleration: float = 10.0
@export var rotationOffset: float = PI/2


var neighbors := []
var neighborsDistances := []

func _ready() -> void:
	_build_mesh()

func _build_mesh() -> void:
	var body := CharacterBody3D.new()
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
	
