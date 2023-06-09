extends Entity
class_name PhysicsEntity

const gravity = 9.8 # gravitational acceleration in m/s^2
export var drag = .2 # (m/s^2) / (m/s)
export var floor_friction = 20 # m/s^2
export var wall_friction = 20

signal collided

var is_physics_active = true # whether this PhysicsEntity should do physics processing

# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	if (not is_physics_active):
		return
		
	velocity -= velocity * drag * delta # apply drag
	velocity = move_and_slide(velocity, Vector3.UP) # do the actual movement
	#move_and_collide(velocity * delta)
	if (get_slide_count() > 0): emit_signal("collided")
	
	# friction calculations
	if (is_on_ceiling() or is_on_floor()):
		if (velocity.length_squared() > .1): # don't move horizontally if only moving by a very little
			velocity -= velocity.normalized() * floor_friction * delta
		else:
			velocity = Vector3.ZERO
	
	velocity.y -= gravity * delta # apply gravity
	
	if (is_on_wall()):
		velocity -= velocity.normalized() * wall_friction * delta

func _on_explosion(global_position, radius, speed):
	if (not is_inside_tree()): return # don't do anything if already out of the scene tree
	var sqr_dst = global_translation.distance_squared_to(global_position)
	if (sqr_dst <= radius*radius):
		var direction
		if sqr_dst <= .5: 
			direction = Vector3.UP # always have a direction to explode in
		else:
			direction = global_translation - global_position
		velocity = direction.normalized() * speed
