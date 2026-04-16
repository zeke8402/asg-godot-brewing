extends Node3D

var velocity := Vector3.ZERO
var acceleration := Vector3.ZERO
var time_out_of_borders: float = 0.0

@export var maxVelocity: float = 5.0
@export var maxAcceleration: float = 10.0
@export var rotationOffset: float = PI/2

# Yeast reproduction stats
@export var amountToReplicate: float = 10
@export var maxReplications: float = 25

# Yeast lifespan
@export var lifespan: float = 120.0
var age: float = 0.0

# Boids + Zekes arrays for drifting toward objects
var neighbors := []
var neighborsDistances := []
var food_targets := []
var foodDistances := []

enum State { FLOCKING, EATING }
var state: State = State.FLOCKING

var eat_timer: float = 0.0 # How long before food units are gained.
var current_food: Node3D = null:
	set(value) :
		if is_instance_valid(current_food):
			current_food.stop_eating()
		current_food = value
var food_consumed: int = 0
var replications: int = 0

var burst_timer: float = 0.0

func _ready() -> void:
	_build_mesh()

func _build_mesh() -> void:
	var body := CharacterBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 2
	body.motion_mode = CharacterBody3D.MOTION_MODE_FLOATING

	var collision := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.3
	collision.shape = shape
	body.add_child(collision)

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
	
func _process(delta: float) -> void:
	age += delta
	if age >= lifespan:
		_die()
	if state == State.EATING:
		_process_eating(delta)
		
func _process_eating(delta: float) -> void:
	if burst_timer > 0.0:
		burst_timer -= delta
		global_position += velocity * delta
		global_position.y = 0.0
		return
		
	if not is_instance_valid(current_food):
		state = State.FLOCKING
		current_food = null
		eat_timer = 0.0
		return

	var direction := (current_food.global_position - global_position).normalized()
	direction.y = 0.0
	
	var body := get_child(0) as CharacterBody3D
	if body:
		body.global_position = global_position
		body.move_and_collide(direction * 2.0 * delta)
		global_position = body.global_position
		global_position.y = 0.0

	eat_timer += delta
	
	if eat_timer >= 1.0:
		eat_timer = 0.0
		food_consumed += current_food.eat()
		_process_lifecycle()
		
func _process_lifecycle() -> void:
	if food_consumed >= amountToReplicate:
		food_consumed = 0
		replications += 1
		if replications >= maxReplications:
			_die()
		else:
			_replicate()

func _replicate() -> void:
	var flock := get_parent()
	if flock and flock.has_method("spawn_cell_at"):
		var current_dir := velocity.normalized()
		if current_dir.length() < 0.001:
			current_dir = Vector3(randf_range(-1.0, 1.0), 0.0, randf_range(-1.0, 1.0)).normalized()
		velocity = -current_dir * flock.replicateBurstStrength
		flock.spawn_cell_at(global_position, current_dir)

func _die() -> void:
	var flock := get_parent()
	if flock and flock.has_method("remove_cell"):
		flock.remove_cell(self)
	queue_free()

func reset() -> void:
	state = State.FLOCKING
	if is_instance_valid(current_food):
		current_food.stop_eating()
	current_food = null
	eat_timer = 0.0
	velocity = Vector3.ZERO
