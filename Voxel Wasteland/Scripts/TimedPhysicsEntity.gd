extends PhysicsEntity
class_name TimedPhysicsEntity

export var life_time = 3000 # life time in ms
var start_time = INF
var countdown_started = false
export var start_countdown_immediately = true # whether to start the countdown to deletion as soon as this TimedPhysicsEntity is created

# Called when the node enters the scene tree for the first time.
func _ready():
	if (start_countdown_immediately):
		start_countdown()

func start_countdown():
	if countdown_started: return # don't do anything if the countdown's already begun
	start_time = Time.get_ticks_msec()
	countdown_started = true

func _physics_process(delta):
	if start_time + life_time <= Time.get_ticks_msec():
			queue_free()
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
