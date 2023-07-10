extends PhysicsEntity
class_name TimedPhysicsEntity

export var countdown_time = 3000 # life time in ms
var start_time = INF

func start_countdown():
	start_time = Time.get_ticks_msec()

func _physics_process(delta):
	if start_time + countdown_time <= Time.get_ticks_msec():
			timeout()

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func timeout():
	pass
