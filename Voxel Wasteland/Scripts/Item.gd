extends TimedPhysicsEntity
class_name Item

# TODO:
# droppable items
# throwable items (x amt of force in a certain direction) with different item masses
# main use (lmb), alt use (rmb)
# ex: main use grenade would pull the pin, main release grenade would cook it, and alt use would throw it
# ex: alt use gun would aim down sights, alt release would reset to hipfire, main use would pull trigger, main release would release trigger
# ex: main use knife would use it, alt use knife would throw it
# ex: main use magazine would reload it with bullets, alt use would throw it (so other players can have it!)
# ex: 'Z' to drop items (firearms, for example) 
# ex: main use body armor to repair it, alt use to put it on
# ex: main use jetpack to repair (refuel) it, alt use to put it on
# ex: main use helmet to repair it, alt use to put it on
# picking up/catching items: use 'F' in the general direction of an item to pick up/catch it. Be careful! Active grenades can blow up in your hand, so throw them back quickly! 
# some items (active rockets, bullets, flying knives) can't be picked up
# cycling through items: 'Q' (switch between items of the same type, like different grenades) and 'E' (switch item types, from grenades to armor, from armor to guns, etd)
# reload with 'R'
# stopping power (if a player gets hit with an item of x mass going at y speed, change player's momentum by x*y)
# (players have mass, too. Add that to your physics calculations.) 

var item_user = null
onready var camera = get_viewport().get_camera()
signal item_pickup

var can_pickup = false # whether this item can currently be picked up
var triggered = false

# Called when the node enters the scene tree for the first time.
func _ready():
	can_pickup = false
	start_countdown()
	#print('being held: ' + str(item_user != null))
	#print('last release: ' + str(last_release))
	#connect("item_pickup", player, "try_pickup_item", [self]) # make player try to pick up this item when the player collides with it
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	look_at(camera.global_translation, Vector3.UP)
#	pass

func timeout():
	can_pickup = true

func _on_Area_body_entered(body):
	if (not can_pickup): # don't try picking up this item until it can be picked up again
		return
		
	if ((item_user == null) and (body.is_in_group("ItemUsers"))):
		body.try_pickup_item(self)
	pass # Replace with function body.

# picks up this item with item_user
func pickup(item_user):
	if (not can_pickup):
		print("Why are you trying to pick up an item that can't be picked up?")
		return

	var picked_up_item = self.duplicate()
	picked_up_item.item_user = item_user # set item_user so that the picked_up_item knows how to act later
	
	
	# pick up the duplicate item
	item_user.items.append(picked_up_item)
	item_user.item_hold_node.add_child(picked_up_item)
	picked_up_item.transform.origin = Vector3.ZERO
	picked_up_item.is_physics_active = false
	
	queue_free()
	
# trigger's this item's behavior
func trigger():
	triggered = true
	
func use():
	var used_item = self.duplicate()
	used_item.item_user = null
	used_item.trigger() # actually USE (trigger) the item now in the world
	
	world.add_child(used_item)
	used_item.global_translation = item_user.item_release_node.global_translation
	used_item.velocity = velocity # start item at same base velocity
	used_item.change_momentum(-item_user.item_release_node.global_transform.basis.z.normalized() * item_user.item_throw_impulse) # throw the grenade
	
	queue_free() # remove one's self from the equation
	
