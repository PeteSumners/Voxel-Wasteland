extends PhysicsEntity

# TODO: cylindrical collider so that players can turn without being pushed from voxels,
# functionality for automatically walking over single-voxel-high steps,
# air strafing (slow velocity changes in midair)

# todo: functionality for drones (with 2d displays in the 3d world), mechs, paragliders, tanks, other vehicles

signal build

export (PackedScene) var grenade_scene

# to keep the player in bounds
export var minX = 1
export var maxX = 511
export var minZ = 1
export var maxZ = 511

# movement stuff
export var jump_speed = 5 # m/s
export var walk_speed = 5 # m/s
export var jetpack_up_force = 20
export var jetpack_side_force = 3
var jetpack_active = false


onready var left_hip = $"Body/Legs/Hips/Left Hip"
onready var right_hip = $"Body/Legs/Hips/Right Hip"
onready var voxel_placeholder = $'Voxel'
var animation_time = 0 # current animation time
export var walk_frequency = .25 # leg cycles per unit distance
export var max_leg_rot = 60 # max rotation of legs in walk cycle

onready var head = $Head
onready var camera = $Head/Camera
export var mouse_sensitivity = 0.3
var camera_x_rotation = 0
var horizontal_input_direction = Vector3.ZERO




# grenade throw speed in m/s
export var grenade_throw_speed = 24

const build_dst = 5

# whether the player has a jetpack
export var has_jetpack = false

func _input(event):
	if event is InputEventMouseMotion:
		rotate_y(deg2rad(-event.relative.x * mouse_sensitivity))
		
		var x_delta = -event.relative.y * mouse_sensitivity
		camera_x_rotation = camera.rotation_degrees.x
		if (camera_x_rotation + x_delta > -90 && camera_x_rotation + x_delta < 90):
			camera_x_rotation += x_delta
			camera.rotate_x(deg2rad(x_delta))

# move the player with a jetpack
func jetpack_move(delta):
	if (not has_jetpack): return
	
	if is_on_floor():
		jetpack_active = false
	else:
		if Input.is_action_just_pressed("jump"):
			jetpack_active = true

	if jetpack_active:
		# TODO: play sound
		if Input.is_action_pressed("jump"):
			# TODO: increase/decrease jetpack sound volume based on whether "jump" is pressed or not
			velocity.y += jetpack_up_force * delta
		velocity += horizontal_input_direction * jetpack_side_force * delta

func animate_legs(delta):
	var horizontal_speed = Vector3(velocity.x, 0, velocity.z).length()
	if (is_on_floor()):
		animation_time = animation_time + delta*horizontal_speed
	var rot_factor = sin(2*PI*animation_time*walk_frequency)
	var rotation = 0
	if (horizontal_input_direction == Vector3.ZERO):
		animation_time = 0
	else:
		rotation = rot_factor*max_leg_rot
	right_hip.rotation_degrees.x = rotation
	left_hip.rotation_degrees.x = -rotation
	
# update the (global) horizontal direction the player should move in based on input
func update_horizontal_input_direction():
	horizontal_input_direction = Vector3.ZERO
	var basis = get_global_transform().basis
	
	if Input.is_action_pressed("right"):
		horizontal_input_direction += basis.x
	if Input.is_action_pressed("left"):
		horizontal_input_direction -= basis.x
	if Input.is_action_pressed("backward"):
		horizontal_input_direction += basis.z
	if Input.is_action_pressed("forward"):
		horizontal_input_direction -= basis.z
	
	horizontal_input_direction = horizontal_input_direction.normalized()

func _physics_process(delta):
	update_horizontal_input_direction()
	animate_legs(delta)
	jetpack_move(delta)
	
	# TODO: refactor all this code into a bunch of little methods
	# allow for player to collide with their own rockets/grenades? NAH.
	# definitely allow for certain rockets to collide with and push other players far, far across the map. Actually, no. Just do insta-explosions on contact. 
	
	
	if (Input.is_action_just_pressed("rmb")):
		var grenade = grenade_scene.instance() as Explosive
		world.add_child(grenade)
		grenade.global_translation = camera.global_translation
		grenade.velocity = velocity - (camera.global_transform.basis.z.normalized() * grenade_throw_speed)
		grenade.look_at(grenade.global_translation + camera.global_transform.basis.z, camera.global_transform.basis.y)
	
	# ground movement code
	
	# TODO: compensate for explosions with no ground movement input (I think velocity.y is being overwritten here after explosion events)
	if is_on_floor():
		# only allow player to control walk speed if the player is moving slower than walk_speed
		var horizontal_velocity = Vector3(velocity.x, 0, velocity.z)
		if (horizontal_velocity.length_squared() < (walk_speed * walk_speed)):
			velocity.x = horizontal_input_direction.x * walk_speed
			velocity.z = horizontal_input_direction.z * walk_speed
		
		if Input.is_action_just_pressed("jump"):
			velocity.y += jump_speed
	
	# TODO: interpolate air movement based on drag and jetpack force
	# interpolate ground movement based on ground acceleration
	
	# bound checks
	var pos = transform.origin
	if (pos.x < minX):
		if (velocity.x < 0):
			velocity.x = 0
		transform.origin.x = minX
	if (pos.x > maxX):
		if (velocity.x > 0):
			velocity.x = 0
		transform.origin.x = maxX
	if (pos.z < minZ):
		if (velocity.z < 0):
			velocity.z = 0
		transform.origin.z = minZ
	if (pos.z > maxZ):
		if (velocity.z > 0):
			velocity.z = 0
		transform.origin.z = maxZ
	
	#velocity = move_and_slide(velocity, Vector3.UP)
	
	# raycasting for building/breaking blocks
	if (Input.is_action_just_pressed("build")):
		build_voxel()

# build a voxel in the world
func build_voxel():
	var space_state = get_world().direct_space_state
	
	# use global coordinates, not local to node
	# transform.basis.z * 20 is 20m in the transform's forward direction
	var global_origin = camera.global_transform.origin
	var global_dir = -camera.global_transform.basis.z.normalized()
	var result = space_state.intersect_ray(global_origin, global_origin+(global_dir * build_dst))
	if (result.size() != 0):
		var distance=global_origin.distance_to(result.position)
		var voxel_pos = result.position - (global_dir*.01) # global_dir*.01 to keep voxel outside of other voxels
		voxel_pos = Vector3(int(voxel_pos.x), int(voxel_pos.y), int(voxel_pos.z)) # snap voxel to integer coordinates
		print("build block " + str(distance) + " m away")
		voxel_placeholder.global_translation = voxel_pos
		voxel_placeholder.global_rotation = Vector3.ZERO
		print(voxel_placeholder.global_translation)
		emit_signal("build", voxel_pos)
	else:
		print("didn't build anything...")

# Called when the node enters the scene tree for the first time.
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	camera.far = render_dst
	connect("build", world, "_on_build") # make the world build when the player builds


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
