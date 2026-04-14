extends Node3D

var _mesh_instance: MeshInstance3D

func _ready() -> void:
	_build_preview_light()
	_build_camera()
	_build_strawberry()

func _build_preview_light() -> void:
	var env := Environment.new()
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color.WHITE
	env.ambient_light_energy = 1.0

	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)

func _build_camera() -> void:
	var cam := Camera3D.new()
	cam.position = Vector3(0, 3, 4)
	add_child(cam)
	cam.look_at(Vector3.ZERO, Vector3.UP)

func _build_strawberry() -> void:
	_mesh_instance = MeshInstance3D.new()
	_mesh_instance.mesh = _generate_mesh()
	_mesh_instance.rotation_degrees.y = 180.0
	add_child(_mesh_instance)

func _process(delta: float) -> void:
	_mesh_instance.rotation_degrees.y += 60.0 * delta

func _generate_mesh() -> ArrayMesh:
	var vertices := PackedVector3Array()
	var indices := PackedInt32Array()
	var colors := PackedColorArray()

	var steps := 8
	var radius := 0.6
	var tip := Vector3(0, 1.0, 0)
	var top := Vector3(0, -1.0, 0)

	# Ring vertices — mid red
	for i in range(steps):
		var angle := (float(i) / steps) * TAU
		var x := cos(angle) * radius
		var z := sin(angle) * radius
		vertices.append(Vector3(x, 0.0, z))
		colors.append(Color(0.9, 0.1, 0.1))

	# Tip vertex — dark red
	var tip_index := vertices.size()
	vertices.append(tip)
	colors.append(Color(0.5, 0.0, 0.0))

	# Top vertex — bright red
	var top_index := vertices.size()
	vertices.append(top)
	colors.append(Color(1.0, 0.3, 0.3))

	for i in range(steps):
		var next := (i + 1) % steps
		indices.append(tip_index)
		indices.append(next)
		indices.append(i)

	for i in range(steps):
		var next := (i + 1) % steps
		indices.append(top_index)
		indices.append(i)
		indices.append(next)

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices
	arrays[Mesh.ARRAY_COLOR] = colors

	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

	# Material must have vertex color enabled to show the gradient
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrays)
	mesh.surface_set_material(0, mat)

	return mesh
