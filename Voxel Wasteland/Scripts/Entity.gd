extends KinematicBody
class_name Entity

signal register_entity
signal unregister_entity

export var should_register = true # whether this entity should register for signals to/from the world
export var render_dst = 32 # how far the entity should make chunks render
export var make_chunks_visible = false # whether the entity should make chunks visible when it moves around
onready var world = get_node("/root/Main/World")

var velocity = Vector3.ZERO # current velocity

# Called when the node enters the scene tree for the first time.
func _ready():
	# don't do anything if you shouldn't register with the world
	if (not should_register): return
		
	connect("register_entity", world, "register_entity") # make world call its register_entity() method when entity's register_entity signal is emitted
	connect("unregister_entity", world, "unregister_entity")
	emit_signal("register_entity", self, render_dst, make_chunks_visible) # register the entity with the world

func _exit_tree():
	if (not should_register): return
	emit_signal("unregister_entity", self)
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

# handle explosion
#func _on_explosion(global_position, radius, speed):
	#print(str(self) + ' is an entity handling an explosion!')
	#emit_signal("explosion", global_position, radius, speed)
