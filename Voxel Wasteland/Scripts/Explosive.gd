extends TimedPhysicsEntity
class_name Explosive

# have two timers for all explosives: one to blow it up after it hits something, and one to destroy it after a certain time

signal explosion
export var explosion_radius = 3
export var explosion_speed = 15 # debris/player speed change when the explosion goes off

export (PackedScene) var explosion_audio_scene

# Called when the node enters the scene tree for the first time.
func _ready():
	connect("explosion", world, "_on_explosion")
	connect("collided", self, "_on_collision")

func _exit_tree():
	explode()

func _on_collision(): # try to start the explosive's timer when it hits something
	start_countdown()

func explode():
	spawn_explosion_sound()
	emit_signal("explosion", Vector3(global_translation.x, global_translation.y, global_translation.z), explosion_radius, explosion_speed)

func spawn_explosion_sound():
	var explosion_audio = explosion_audio_scene.instance()
	world.add_child(explosion_audio)
	explosion_audio.global_translation = global_translation