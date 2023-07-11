extends Item


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

const jetpack_force = 30 # force in N (kg*m/s^2)

# Called when the node enters the scene tree for the first time.
func _physics_process(delta):
	if (triggered):
		if (item_user != null):
			var forward_dir = item_user.item_release_node.global_transform.basis.z
			forward_dir = Vector3(forward_dir.x, abs(forward_dir.y), forward_dir.z).normalized()
			var jetpack_dir = (forward_dir + Vector3.UP).normalized()
			item_user.change_momentum(jetpack_dir * jetpack_force * delta)


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
