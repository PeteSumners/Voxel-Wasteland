extends PhysicsEntity
class_name TimedPhysicsEntity

export var countdown_time = 3000 # life time in ms
var start_time = INF
var timed_out = false # whether this TimedPhysicsEntity has called timeout() since start_countdown().

func start_countdown():
	start_time = Time.get_ticks_msec()
	timed_out = false

# checks time and calls timeout() if necessary
func check_time():
	if (timed_out): # no need to call timeout twice
		return
	
	if start_time + countdown_time <= Time.get_ticks_msec():
			timeout()

func _physics_process(delta):
	check_time()

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func timeout():
	timed_out = true
	pass
