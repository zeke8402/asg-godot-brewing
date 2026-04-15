extends Node3D

func _ready() -> void:
	_build_light()
	_build_landmarks()
	_build_player()

func _build_light() -> void:
	var light := OmniLight3D.new()
	light.position = Vector3(0, 5, 0)
	light.omni_range = 50.0
	add_child(light)

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

func _build_player() -> void:
	var player := CharacterBody3D.new()
	player.name = "Player"
	player.set_script(load("res://Player/anchor.gd"))
	add_child(player)
