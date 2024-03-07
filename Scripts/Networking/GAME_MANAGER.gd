extends Node2D

var host_started = false

#Objects to sync dictionary, mainly to make sure network ids dont double up
var objects_to_sync = {}
# Stores current scene for replication on player join
var current_scene
# Store all current controller puppet masters : TODO replace with groups instead
var controller_puppet_masters = {}
# Characters for ObjectSyncIDs add more if needed
var CHARS = "1234567890";

# Called by puppet masters when they want to create a puppet
signal SPAWN_PUPPET_SIGNAL(puppet_master)

# Creates unique code for Object Synchroinizing
func create_unique_object_code():
	var id = ""
	for n in 7:
		var random_number =  randi_range(0,CHARS.length() -1)
		var random_char = CHARS[random_number]
		id+=random_char
		
	if objects_to_sync.has(id):
		return create_unique_object_code()
	
	return id

func _ready():
	# Add/Remove puppetmasters when a controller Connects/Disconnects
	Input.joy_connection_changed.connect(on_joy_connection_changed)

#region Puppet Master Spawning/Destruction
func spawn_puppet_masters():
	# If a puppet master for the local player exists already do not make another
	if get_tree().get_nodes_in_group(str(multiplayer.get_unique_id())).size() >= 1:
		return
		
	#Setup Keyboard Player
	var puppet_master_keyboard_touch = spawn_object("res://Scenes/Networking/Puppet_Master.tscn",Vector2.ZERO,0,"",multiplayer.get_unique_id())
	puppet_master_keyboard_touch.controller = false;
	if OS.get_name() == "Android" or OS.get_name() == "iOS":
		puppet_master_keyboard_touch.mobile = true
	puppet_master_keyboard_touch._network_ready.rpc_id(Relayconnect.HOST_ID)
		
	#Setup puppet masters for controllers currently connected
	for controller_id in Input.get_connected_joypads():
		add_controller_puppet_master(controller_id)

func add_controller_puppet_master(new_device_id):
	var puppet_master_controller = spawn_object("res://Scenes/Networking/Puppet_Master.tscn",Vector2.ZERO,0,"",multiplayer.get_unique_id())
	
	
	puppet_master_controller.controller = true
	puppet_master_controller.device_id = new_device_id
	controller_puppet_masters[new_device_id] = puppet_master_controller

func remove_controller_puppet_master(device_id):
	Relayconnect.call_rpc_room(controller_puppet_masters[device_id].DestroySelf,[])
	controller_puppet_masters.erase(device_id)
	
func on_joy_connection_changed(device_id : int,connected : bool):
	if !host_started:
		return
	if connected:
		add_controller_puppet_master(device_id)
	else:
		remove_controller_puppet_master(device_id)


#endregion

#region Synchronised Object Spawning
# have local and remote functions for spawning seperate as RPCs ,even when called locally, do not return
# the object spawned, makes it harder to spawn an object and initialize its value.
func spawn_object(object_path : String,pos : Vector2,rot : float,parent_id : String = "",owner_id : int = 0):
	var object_id = create_unique_object_code()
	var object_to_spawn = load(object_path) as PackedScene
	var object_instance = object_to_spawn.instantiate() 
	object_instance.global_position = pos
	object_instance.rotation_degrees = rot
	object_instance.name = object_id
	objects_to_sync[object_id] = object_instance
	
	var networked_sync_node = object_instance.get_node("NetworkVarSync")
	networked_sync_node.multiplayer_id = multiplayer.get_unique_id()
	networked_sync_node.sync_id = object_id
	networked_sync_node.owner_id = owner_id
	
	if parent_id != "":
		objects_to_sync[parent_id].add_child(object_instance)
	else:
		add_child(object_instance)
		
	Relayconnect.call_rpc_room(spawn_object_rpc,[object_path,pos,rot,object_id,parent_id,owner_id],false)
	return object_instance

@rpc("any_peer","call_local","reliable")
func spawn_object_rpc(object_path : String,pos : Vector2,rot : float,object_id : String,parent_id : String = "",owner_id : int = 0):
	var object_to_spawn = load(object_path) as PackedScene
	var object_instance = object_to_spawn.instantiate() 
	
	
	
	object_instance.global_position = pos
	object_instance.rotation_degrees = rot
	object_instance.name = object_id
	objects_to_sync[object_id] = object_instance
	
	var networked_sync_node = object_instance.get_node("NetworkVarSync")
	networked_sync_node.multiplayer_id = multiplayer.get_unique_id()
	networked_sync_node.sync_id = object_id
	networked_sync_node.owner_id = owner_id
	
	if parent_id != "":
		objects_to_sync[parent_id].add_child(object_instance)
	else:
		add_child(object_instance)
		
#endregion

# Custom Change scene function which -
# - Synchronises the changing of the scene at runtime
# - Stores the scene node path for people joining after game start
# -	Potentially keep or destroy puppetmasters if puppetmater info is needed in the next scene
@rpc("any_peer","call_local","reliable")
func change_scene_rpc(scene_path : String, destroy_puppet_masters : bool):
	
	if!destroy_puppet_masters:
		# Destroy children of puppet master
		for puppet_master in get_tree().get_nodes_in_group("puppet_masters"):
			for child in puppet_master.get_children():
				if child.name != "NetworkVarSync":
					child.queue_free()
		# destroy everything under GameManager other than the puppetmasters
		for child in GameManager.get_children():
			if !child.is_in_group("puppet_masters"):
				child.queue_free()
	else:
		# Destroy everything but the auto load
		for child in GameManager.get_children():
			child.queue_free()
	
	# Change Scene
	get_tree().change_scene_to_file(scene_path)
	#Store scene node path for replication
	current_scene = scene_path


# Get tree structure for all children of Game Manager for replication on newly joined client
func sync_game_data(target_player):
	var dict_to_send = Recursive_child(self)
	sync_game_data_rpc.rpc_id(target_player,dict_to_send,current_scene)
	pass

# Build children of GameManager based on received data from host
@rpc("any_peer","call_remote","reliable")
func sync_game_data_rpc(game_data : Dictionary,scene_path : String):
	change_scene_rpc(scene_path,false)
	recursive_build_scene(game_data,self)
	pass

# Helper function to get all nodes and their require information into a dictionary for sending
func Recursive_child(node):
	var dict = {}
	for child in node.get_children():
		var network_node = child.get_node_or_null("NetworkVarSync")
		if !network_node:
			continue
		dict[network_node.sync_id] = {
			"node_path":network_node.instance_file_path,
			"sync_id":network_node.sync_id,
			"owner_id":network_node.owner_id,
			"children":Recursive_child(child),
		}
	return dict

# builds scene based on dictinary tree structure
func recursive_build_scene(node_dictionary,parent_node):
	for node in node_dictionary:
		# Create child
		var node_info = node_dictionary[node]
		var object_to_spawn = load(node_info.node_path)
		var object_instance = object_to_spawn.instantiate()

		
		# Update values
		var network_node = object_instance.get_node("NetworkVarSync")
		object_instance.name = node_info.sync_id
		network_node.sync_id = node_info.sync_id
		network_node.owner_id = node_info.owner_id
		
		parent_node.add_child(object_instance)
		objects_to_sync[node_info.sync_id] = object_instance
		
		# If the node has children, build those children
		recursive_build_scene(node_info.children,object_instance)
