extends Node3D

func _ready() -> void:
	_build_mesh()

func _build_mesh() -> void:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = _generate_mesh()
	add_child(mesh_instance)

func _generate_mesh() -> ArrayMesh:
	var vertices := PackedVector3Array()
	var indices := PackedInt32Array()
	var colors := PackedColorArray()

	var steps := 8
	var radius := 0.6
	var tip := Vector3(0, -1.0, 0)
	var top := Vector3(0,  1.0, 0)

	for i in range(steps):
		var angle := (float(i) / steps) * TAU
		var x := cos(angle) * radius
		var z := sin(angle) * radius
		vertices.append(Vector3(x, 0.0, z))
		colors.append(Color(0.9, 0.1, 0.1))

	var tip_index := vertices.size()
	vertices.append(tip)
	colors.append(Color(0.5, 0.0, 0.0))

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

	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mesh.surface_set_material(0, mat)

	return mesh
