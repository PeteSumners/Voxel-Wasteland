extends StaticBody
class_name VoxelChunk

# TODO: refactor VoxelChunk code into VoxelGrid code (so that space ships and other vehicles (and weapon designs) can use VoxelGrid code)
# also, draw bounds on vehicle VoxelGrids so that players know how far they can build

# this chunk's horizontal bounding box
onready var bounds = Rect2(Vector2(global_translation.x, global_translation.z), Vector2.ONE*chunk_width)

enum VoxelType {
	EMPTY, GRASS, BEDROCK
}

#TODO: on-the-fly textures/array of voxels so I don't have to make a bunch of packed scenes
export (PackedScene) var grass_block_scene
export (PackedScene) var grass_block_entity_scene

export (PackedScene) var bedrock_block_scene

# array of arrays
# indicates entities for which voxel chunks are rendered. 
# includes an int for render distance 
# and a bool that determines whether chunks should be made visible for the entity
var render_entities = []

var voxels = []
const chunk_width = 8 # chunk size, in voxels
const chunk_height = 8
var generation_height = 5
var world_seed
#var min_render_dst = 16 # minimum (circle) render distance in meters
var max_render_dst = 48 # maximum (directional) render distance in meters

var chunk_generated = false # whether the chunk has been generated before
var rendered_since_last_update = false # whether the chunk has been rendered since it was last updated
var chunk_clear = true

var renderable # whether the chunk should be rendered for collisions
const entity_update_time = 1000 # time between entity updates (in milliseconds)
var last_entity_update_time = -INF
var time_offset # chunk entity update time offset in ms.
const time_offset_between_chunks = 10 # time between chunk updates from one chunk to the next, in ms
const loop_width = 16 # width of an update loop in chunks. used to calculate time_offset

# uses bounds to determine if this chunk is within two times taxicab distance (mathematical limit on spherical explosions) from pos
func chunk_within_dst_of_pos(var global_pos, var dst):
	var pos_2d = get_horizontal_pos(global_pos)
	var bounds_to_check = Rect2(pos_2d - (Vector2.ONE*dst), Vector2.ONE*dst*2)
	return bounds.intersects(bounds_to_check, true)

# returns the horizontal - (x, z): not y - position of global_pos
func get_horizontal_pos(var global_pos):
	return Vector2(global_pos.x, global_pos.z)

# returns whether this chunk contains a given position
func chunk_contains_position(var global_pos):
	return bounds.has_point(get_horizontal_pos(global_pos))

func _on_generated_world_seed (world_seed):
	self.world_seed = world_seed
	#generate_chunk()
	#render_chunk()

# I'm gonna make this chunk...DISAPPEAR!
func clear_chunk():
	for child in get_children():
		child.queue_free()
	rendered_since_last_update = false
	chunk_clear = true

# TODO: optimize this by checking if the chunk has been updated before re-rendering. 
# (don't render if there's been no change since the last render)
func should_render_chunk():
	return (not rendered_since_last_update) and renderable

func should_generate_chunk():
	return not chunk_generated

func should_clear_chunk():
	return (not chunk_clear) and (not renderable)

func update_registry(registry):
	render_entities = registry

# Called when the node enters the scene tree for the first time.
func _ready():
	var chunk_x = int(global_translation.x / chunk_width)
	var chunk_z = int(global_translation.z / chunk_width)
	time_offset = (chunk_z % loop_width)
	time_offset += chunk_x * loop_width
	time_offset *= time_offset_between_chunks
	pass

# update position/rotation info in relation to the player
func update_entity_data():
	if (last_entity_update_time + entity_update_time > Time.get_ticks_msec() + time_offset):
		return
	
	renderable = false
	visible = false
	
	for data in render_entities:
		var entity = data[0]
		var render_dst = data[1]
		var make_visible = data[2]
		
		# don't bother rendering if we don't need to
		if (not chunk_within_dst_of_pos(entity.global_translation, render_dst)):
			continue
		
		var chunk_center = bounds.get_center()
		var entity_pos = Vector2(entity.global_translation.x, entity.global_translation.z)
		var squared_entity_dst = chunk_center.distance_squared_to(entity_pos) # entity's distance from this chunk
		#var in_front_of_player = player.to_local(chunk_center).z < 0 # whether the player is facing this chunk
		var within_render_dst = (squared_entity_dst <= (render_dst * render_dst))
		renderable = renderable or within_render_dst
		visible = visible or (make_visible and within_render_dst)
	last_entity_update_time = Time.get_ticks_msec()
	
func _process(delta):
	update_entity_data()
	
	if (should_generate_chunk()): # if haven't generated the chunk yet
		generate_chunk()
	if (should_render_chunk()): # if within render distance and haven't rendered since last update
		render_chunk()
	if (should_clear_chunk()): # if not within render distance and haven't cleared yet
		clear_chunk()
		
# generate new voxel data for the chunk
func generate_chunk():
	if (world_seed == null):
		return
	
	#configure noise
	var noise = OpenSimplexNoise.new()
	noise.seed = world_seed
	noise.octaves = 1
	noise.period = 20.0
	
	# make the voxel data
	voxels.resize(chunk_width)
	for i in range(0, chunk_width):
		voxels[i] = []
		voxels[i].resize(chunk_height)
		for j in range(0, chunk_height):
			voxels[i][j] = []
			voxels[i][j].resize(chunk_width)
			for k in range(0, chunk_width):
				# put bedrock on the bottom of each chunk
				if j == 0:
					update_voxel(i, j, k, VoxelType.BEDROCK)
					continue
				
				var world_coordinates = to_global(Vector3(i, j, k))
				var noiseValue = (noise.get_noise_3d(world_coordinates.x, world_coordinates.y, world_coordinates.z)+1)/2*generation_height
				
				if (noiseValue >= j):
					update_voxel(i, j, k, VoxelType.GRASS)
				else:
					update_voxel(i, j, k, VoxelType.EMPTY)
	
	# the chunk is generated!
	chunk_generated = true

# render the chunk with its current voxel data
func render_chunk():
	if (not chunk_generated):
		return
	
	# clear all children (all voxel instances)
	clear_chunk()
		
	for i in range(0, voxels.size()):
		for j in range(0, voxels[i].size()):
			for k in range(0, voxels[i][j].size()):
				
				var voxel = voxels[i][j][k]
				if (voxel == VoxelType.EMPTY):
					continue
				
				# check for exposure (is on an edge or next to an empty voxel)
				var is_exposed = \
				(i == 0) or (i == voxels.size()-1) or \
				(j == 0) or (j == voxels[i].size()-1) or \
				(k == 0) or (k == voxels[i][j].size()-1)
				
				
				if (i > 0): is_exposed = is_exposed or (voxels[i-1][j][k] == VoxelType.EMPTY)
				if (i < voxels.size()-1): is_exposed = is_exposed or (voxels[i+1][j][k] == VoxelType.EMPTY)
				
				if (j > 0): is_exposed = is_exposed or (voxels[i][j-1][k] == VoxelType.EMPTY)
				if (j < voxels[i].size()-1): is_exposed = is_exposed or (voxels[i][j+1][k] == VoxelType.EMPTY)
				
				if (k > 0): is_exposed = is_exposed or (voxels[i][j][k-1] == VoxelType.EMPTY)
				if (k < voxels[i][j].size()-1): is_exposed = is_exposed or (voxels[i][j][k+1] == VoxelType.EMPTY)
				
				# only display voxels if they're exposed to the outside world
				if (is_exposed):
					var voxel_instance
					match voxel:
						VoxelType.GRASS:
							voxel_instance = grass_block_scene.instance()
						VoxelType.BEDROCK:
							voxel_instance = bedrock_block_scene.instance()
						VoxelType.EMPTY:
							print("That shouldn't have happened. Check VoxelChunk.gd.")
							pass
					
					voxel_instance.transform.origin = Vector3(i, j, k)
					add_child(voxel_instance)
	
	rendered_since_last_update = true
	chunk_clear = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _on_explosion(explosion_global_pos, explosion_radius, explosion_speed):
	# don't do anything if this chunk isn't being exploded
	if not chunk_within_dst_of_pos(explosion_global_pos, explosion_radius):
		return
	
	# TODO: don't loop over every voxel (account for position in radius in the loop bounds)
	# , and skip voxels that are empty
	
	var explosion_local_pos = to_local(explosion_global_pos)
	var start_x = max(0, floor(explosion_local_pos.x - explosion_radius))
	var end_x = min(voxels.size(), ceil(explosion_local_pos.x + explosion_radius))
	var start_y = max(0, floor(explosion_local_pos.y - explosion_radius))
	var end_y = min(voxels[0].size(), ceil(explosion_local_pos.y + explosion_radius))
	var start_z = max(0, floor(explosion_local_pos.z - explosion_radius))
	var end_z = min(voxels[0][0].size(), ceil(explosion_local_pos.z + explosion_radius))
	
	var voxel_entities_to_spawn = []
	for i in range(start_x, end_x):
		for j in range(start_y, end_y):
			for k in range(start_z, end_z):
				var voxel = get_voxel(i, j, k)
				if (voxel == VoxelType.EMPTY or voxel == VoxelType.BEDROCK): # don't try to explode air or bedrock
					continue
				var voxel_pos = Vector3(i, j, k) + (Vector3.ONE * .5) # (center of voxel at i, j, k)
				if (explosion_local_pos.distance_to(voxel_pos) <= explosion_radius):
					voxel_entities_to_spawn.append([voxel, i, j, k])
					remove_voxel_from_chunk(i, j, k)
	
	if (visible):
		render_explosion(explosion_local_pos, explosion_radius, explosion_speed, voxel_entities_to_spawn)
	
func _on_build(global_pos):
	if not chunk_contains_position(global_pos): # don't build anything if there's nothing to build
		return
	print("building! chunk is at" + str(bounds.position))
	update_voxel_at_global_pos(global_pos, VoxelType.BEDROCK)
	
func render_explosion(var explosion_local_pos, var explosion_radius, var explosion_speed, var voxel_entities_to_spawn):
	render_chunk()
	
	# spawn entities for lost voxels
	for e in voxel_entities_to_spawn:
		var entity = null
		match e[0]:
			VoxelType.GRASS:
				entity = grass_block_entity_scene.instance()
			VoxelType.BEDROCK: # don't explode bedrock
				continue
			VoxelType.EMPTY:
				continue
		if entity != null:
			entity.translation = Vector3(e[1], e[2], e[3])
			var entity_center = entity.translation + (Vector3.ONE * .5)
			var start_dir = (entity_center - explosion_local_pos).normalized() # inconsistent horizontal velocity
			start_dir.y = max(1, abs(start_dir.y)) # semi-consistent y velocity
			start_dir = start_dir.normalized()
			entity.velocity = start_dir * explosion_speed * randf()
			add_child(entity)

func remove_voxel_from_chunk(i, j, k):
	update_voxel(i, j, k, VoxelType.EMPTY)

# updates voxel given a global position
func update_voxel_at_global_pos(global_pos, voxel_type):
	var local_pos = to_local(global_pos)
	var i = int(local_pos.x)
	var j = int(local_pos.y)
	var k = int(local_pos.z)
	update_voxel(i, j, k, voxel_type)

# updates the voxel at (i,j,k) (local voxel array coordinates) to be voxel_type. Automatically triggers a chunk render update!
func update_voxel(i, j, k, voxel_type):
	# do NOT build outside the voxel chunk
	if (i >= voxels.size() or j >= voxels[0].size() or k >= voxels[0][0].size()): return
	voxels[i][j][k] = voxel_type
	rendered_since_last_update = false
	
func get_voxel(i, j, k):
	return voxels[i][j][k]
