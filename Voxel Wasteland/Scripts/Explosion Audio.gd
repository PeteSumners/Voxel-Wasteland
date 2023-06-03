extends AudioStreamPlayer3D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	connect("finished", self, "_on_finished")
	play()

func _on_finished(): # remove self from scene tree when finished playing
	queue_free()
