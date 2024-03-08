class_name Network_Var_Sync
extends Node2D
signal DestroyingOnPurposeSignal
var parent
# Instance file path for replication of this node on connecting clients
@export var instance_file_path : String

# Reliable sync vars, only update on variable change and will always go through
# slower, but reliable
@export var reliable_sync_vars = {} 
# Unreliable, packets may be lost in transit, sends these packets every frame
@export var unreliable_sync_vars = {}
# These variables are reliably synced but will only sync data from the Host
@export var always_server_sync_vars = {}

# Object SyncID, The name of the object is also the ObjectSyncID if spawned by GameManager
@export var sync_id = "" : set = onSyncIdChange
func onSyncIdChange(new_sync_id):
	sync_id = new_sync_id
	#If this is not going to be controlled by antoher player and you are not the host then get data from the host
	
	

var multiplayer_id
# Decides whether to be synced by the local player or the host
@export var is_local_authority = false
# is this owned by the local computer
@export var is_local_player = false
# id of owner 0 if host is owner
@export var owner_id = 0 : set  = onOwnerIdChange
func onOwnerIdChange(new_id):
	remove_from_group(str(owner_id))
	owner_id = new_id
	add_to_group(str(owner_id))
	# Check if new owner is local player
	if owner_id == multiplayer_id:
		is_local_player = true
	else:
		is_local_player = false
	
	

		

# Locally stores refrences to all nodes to be synced
var node_array : Array[Node]

# This is the dictionries that are converted for use and sending, instead of node paths they have,
# the index of the node in the node_array
var reliable_vars_to_sync : Dictionary
var unreliable_vars_to_sync : Dictionary
var always_server_vars_to_sync : Dictionary # Currently Unused

# Stores the prior values for the objects so we are not node.getting every single value every frame
var prior_value_dictionary_reliable : Dictionary
var prior_value_dictionary_unreliable : Dictionary
var prior_value_dictionary_server : Dictionary # Currently Unused
# Called when the node enters the scene tree for the first time.
func _ready():
	reliable_sync_vars["."] = ["owner_id"]
	parent = get_parent()
	# Setup Node Array : add node to node array, if it already exists dont add node to node array,
	# then in the respective points where the node paths would be put the index of the corresponding node 
	# in the node array
	var i = 0;
	for key in reliable_sync_vars:
		node_array.append(get_node(key))
		reliable_vars_to_sync[i] = reliable_sync_vars[key]
		i += 1
	
	for key in unreliable_sync_vars:
		var find = node_array.find(get_node(key))
		if find != -1:
			unreliable_vars_to_sync[find] = unreliable_sync_vars[key]
		else:
			node_array.append(get_node(key))
			unreliable_vars_to_sync[i] = unreliable_sync_vars[key]
			i+=1
	
	for key in always_server_sync_vars:
		var find = node_array.find(get_node(key))
		if find != -1:
			always_server_vars_to_sync[find] = always_server_sync_vars[key]
		else:
			node_array.append(get_node(key))
			always_server_vars_to_sync[i] = always_server_sync_vars[key]
			i+=1
	
	# Setup Prior value dictionaries to compare to in _process
	prior_value_dictionary_reliable = {}
	for key in reliable_vars_to_sync:
		prior_value_dictionary_reliable[key] = {}
		for variable in reliable_vars_to_sync[key]:
			prior_value_dictionary_reliable[key][variable] = node_array[key].get(variable)
	
	prior_value_dictionary_unreliable = {}
	for key in unreliable_vars_to_sync:
		prior_value_dictionary_unreliable[key] = {}
		for variable in unreliable_vars_to_sync[key]:
			prior_value_dictionary_unreliable[key][variable] = node_array[key].get(variable)
		
	prior_value_dictionary_server = {}
	for key in always_server_vars_to_sync:
		prior_value_dictionary_server[key] = {}
		for variable in always_server_vars_to_sync[key]:
			prior_value_dictionary_server[key][variable] = node_array[key].get(variable)
	
	#If not host or local authority then ask for sync data from host
	if !Relayconnect.IS_HOST and !is_local_authority:
		on_spawn_sync.rpc_id(Relayconnect.HOST_ID)
	
	#If this is local authority and not the local player then get data from owning player
	if is_local_authority and !is_local_player:
		on_spawn_sync.rpc_id(owner_id)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	#If host check for changes in always server sync variables then send those changes
	if Relayconnect.IS_HOST:
		var new_dictionary_server = {}
		var something_different_server = false
		for key in always_server_vars_to_sync:
			new_dictionary_server[key] = {}
			for variable in always_server_vars_to_sync[key]:
				var new_value = node_array[key].get(variable)
				if prior_value_dictionary_server[key][variable] != new_value:
					new_dictionary_server[key][variable] = new_value
					prior_value_dictionary_server[key][variable] = new_value
					something_different_server = true
		
		if something_different_server:
			Relayconnect.call_rpc_room(reliable_sync,[new_dictionary_server],false)
	
	if !Relayconnect.IS_HOST and !is_local_authority:
		return
	
	if !is_local_player and is_local_authority:
		return
		
	# If local computer is owner of this node it is in charge of checking changed reliable variables
	var new_dictionary_reliable := {}
	var something_different_reliable := false
	
	
	for key in reliable_vars_to_sync:
		new_dictionary_reliable[key] = {}
		for variable in reliable_vars_to_sync[key]:
			var new_value = node_array[key].get(variable)
			if prior_value_dictionary_reliable[key][variable] != new_value:
				prior_value_dictionary_reliable[key][variable] = new_value
				new_dictionary_reliable[key][variable] = new_value
				something_different_reliable = true
				
	# If local computer is owner of this node it is in charge of sending unreliable packets to other connected players
	for key in unreliable_vars_to_sync:
		for variable in unreliable_vars_to_sync[key]:
			var new_value = node_array[key].get(variable)
			prior_value_dictionary_unreliable[key][variable] = new_value

	if something_different_reliable:
		Relayconnect.call_rpc_room(reliable_sync,[new_dictionary_reliable],false)
	
	
	Relayconnect.call_rpc_room(unreliable_sync,[prior_value_dictionary_unreliable],false)
	

# Initial sync when player joins
@rpc("any_peer","call_remote","reliable")
func on_spawn_sync():
	
	var sender_id = multiplayer.get_remote_sender_id()
	if sender_id == 0:
		sender_id = multiplayer.get_unique_id()
	
	reliable_sync.rpc_id(sender_id,prior_value_dictionary_reliable)
	reliable_sync.rpc_id(sender_id,prior_value_dictionary_server)
	unreliable_sync.rpc_id(sender_id,prior_value_dictionary_unreliable)
	
# RPC functions for sending and receiving the sync data
@rpc("any_peer","call_remote","reliable")
func reliable_sync(sync_dict : Dictionary):
	print(sync_dict)
	for key in sync_dict:
		for variable in sync_dict[key]:
			var node = node_array[key]
			if node.get(variable) != sync_dict[key][variable]:
				node.set(variable,sync_dict[key][variable])


@rpc("any_peer","call_remote","unreliable_ordered")
func unreliable_sync(sync_dict : Dictionary):
	for key in sync_dict:
		for variable in sync_dict[key]:
			var node := node_array[key] as Node2D
			match variable:
				"global_position":
					if node.get(variable).distance_to(sync_dict[key][variable]) > 50:
						node.set(variable,sync_dict[key][variable])
				_:
					if node.get(variable) != sync_dict[key][variable]:
						node.set(variable,sync_dict[key][variable])

# sends a signal when destroyed through this method, use to avoid unintentially running code on _exit_tree
func Destroy_Networked():
	Relayconnect.call_rpc_room(Destroy_RPC,[])
	
@rpc("any_peer","call_local","reliable")
func Destroy_RPC():
	DestroyingOnPurposeSignal.emit()
	get_parent().queue_free()

