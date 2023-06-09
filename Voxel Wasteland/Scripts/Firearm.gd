extends PhysicsEntity


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

export var is_controlled = false # whether the local player currently has positive control over this firearm
var min_cycle_time = 1 # minimum time between rounds fired (in seconds)
enum firing_modes {BOLT, SEMI, THREEBURST, AUTO}
export (PackedScene) var projectile_scene # the scene to spawn when firing

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func transfer_control():
	pass #TODO: transfer control to/from player

#TODO: figure out how to properly parent guns when they're being controlled by the local player
func _physics_process(delta):
	if (is_controlled):
		is_physics_active = false
		if (Input.is_action_just_pressed("lmb")):
			print('hi!!!')
		pass
