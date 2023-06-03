extends Explosive

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

#export var speed = 0
export var acceleration = 50 # acceleration in m/s^2

# Called when the node enters the scene tree for the first time.
func _ready():
	#velocity = global_transform.basis.z * speed
	pass


func _physics_process(delta):
	velocity += acceleration * global_transform.basis.z * delta

func _on_collision():
	queue_free()
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

