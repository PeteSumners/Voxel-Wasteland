extends PhysicsEntity
class_name ItemUser
#use 'T' to throw items. 'Q' drops them. 'E' cycles between them
#use 'R' to repair/reload items
export var item_throw_impulse = 20 # SI units: kg*m/s
onready var item_hold_node = find_node("Item Hold Node") # node to hold items in
onready var item_release_node = find_node("Item Release Node") # node to start items from when they're released back into the world

export var max_items = 10 # max number of items this ItemUser can carry
var items = []

# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	
	pass # Replace with function body.

# picks up an item if possible
# assume item is, in fact, an Item
func try_pickup_item(item):
	if (items.size() >= max_items): # can only hold up to max_items items
		return
	
	item.pickup(self)
	
	print(items)

# use an item
# TODO: change_momentum instead of directly setting grenade speed
func use_item(item_index = 0):
	if (items.size() <= 0): # can't use an item if you don't have any items!
		return
	
	#item.use()
	var item = items[item_index]
	item.use() # let the item handle its own use cases
	items.remove(item_index)
	print(items)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
