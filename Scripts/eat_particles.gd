extends GPUParticles3D

func _ready() -> void:
	amount = 16
	lifetime = 0.5
	explosiveness = 0.0
	randomness = 1.0
	emitting = false
	
	var mat := ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	mat.emission_sphere_radius = 0.5
	mat.direction = Vector3(0, 1, 0)
	mat.spread = 180.0
	mat.initial_velocity_min = 0.5
	mat.initial_velocity_max = 2.0
	mat.gravity = Vector3(0, -1, 0)
	mat.scale_min = 0.05
	mat.scale_max = 0.1
	mat.color = Color(1.0, 1.0, 1.0, 0.8)
	process_material = mat
	
	var quad := QuadMesh.new()
	quad.size = Vector2(0.1, 0.1)
	var quad_mat := StandardMaterial3D.new()
	quad_mat.albedo_color = Color(1, 1, 1, 0.8)
	quad_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	quad_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	quad_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	quad.surface_set_material(0, quad_mat)
	draw_pass_1 = quad

func set_scale_radius(s: float) -> void:
	var mat := process_material as ParticleProcessMaterial
	if mat:
		mat.emission_sphere_radius = s * 0.5
		mat.initial_velocity_max = s * 2.0
