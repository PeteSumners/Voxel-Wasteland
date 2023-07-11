extends Item
class_name Explosive

# TODO: bouncy explosive (doesn't delete itself until 2-3 explosions)
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
	#explode() # can't just explode every time this item gets re-parented (duplicated/deleted)
	pass

func _on_collision(): # explode when a triggered explosive hits something
	if (triggered):
		explode()

func timeout(): # don't allow item pickup on timeout if triggered
	if (not triggered):
		.timeout()

func use(item_index):
	throw(item_index).trigger() # throw AND trigger the explosive

func explode():
	spawn_explosion_sound()
	emit_signal("explosion", Vector3(global_translation.x, global_translation.y, global_translation.z), explosion_radius, explosion_speed)
	queue_free()

func spawn_explosion_sound():
	var explosion_audio = explosion_audio_scene.instance()
	world.add_child(explosion_audio)
	explosion_audio.global_translation = global_translation
	
