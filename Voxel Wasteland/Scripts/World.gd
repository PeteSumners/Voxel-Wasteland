extends Node
class_name VoxelWorld
# TODO: edit world: save chunks/voxels for later

# world size in chunks

export (PackedScene) var voxel_chunk_scene
export var world_width = 2
var world_seed = 0
signal generated_world_seed
signal update_registry
signal explosion
signal build

var entity_registry = []

# TODO: only render chunks in front of player (chunk center is +z relative to player's head).

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	world_seed = randi()
	generate_world()

# TODO: explosion damage
func _on_explosion(global_position, radius, explosion_momentum):
	emit_signal("explosion", global_position, radius, explosion_momentum)

func _on_build(global_position):
	emit_signal("build", global_position)
	print("trying to build at " + str(global_position))

# signal for registering entities in the world
func register_entity(entity, render_dst, make_chunks_visible):
	entity_registry.append([entity, render_dst, make_chunks_visible])
	connect("explosion", entity, "_on_explosion")
	emit_signal("update_registry", entity_registry)

func unregister_entity(entity):
	for e in entity_registry:
		if (e[0] == entity):
			entity_registry.erase(e)

func generate_world():
	for i in range(0, world_width):
		for j in range(0, world_width):
			var voxel_chunk = voxel_chunk_scene.instance()
			voxel_chunk.transform.origin = VoxelChunk.chunk_width * Vector3(i, 0, j)
			connect("generated_world_seed", voxel_chunk, "_on_generated_world_seed")
			connect("update_registry", voxel_chunk, "update_registry")
			connect("explosion", voxel_chunk, "_on_explosion")
			connect("build", voxel_chunk, "_on_build")
			add_child(voxel_chunk)
	emit_signal("generated_world_seed", world_seed)
	emit_signal("update_registry", entity_registry)

func _physics_process(delta):
	# TODO: 
	# get horizontal distance from player, spawn/despawn chunks based on that. 
	# Then save voxel data for each chunk into permanent memory (hard drive: not RAM). 
	pass
