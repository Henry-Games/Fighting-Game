extends Node2D

signal DestroyingOnPurpose
var parent
var positions_to_interpolate = {}
@export var instance_file_path : String
@export var reliable_sync_vars = {} 
@export var unreliable_sync_vars = {}
@export var always_server_sync_vars = {}
@export var sync_id = "" : set = onSyncIdChange
func onSyncIdChange(new_sync_id):
	sync_id = new_sync_id
	if !Relayconnect.IS_HOST and !is_local_authority:
		on_spawn_sync.rpc_id(Relayconnect.HOST_ID)
	
	
		
@export var is_local_authority = false
@export var is_local_player = false
@export var owner_id = 0 : set  = onOwnerIdChange
func onOwnerIdChange(new_id):
	remove_from_group(str(owner_id))
	print(owner_id)
	owner_id = new_id
	add_to_group(str(owner_id))
	print(owner_id)
	print("OWNER_ID CHANGE")
	if owner_id == multiplayer.get_unique_id():
		is_local_player = true
	else:
		is_local_player = false
		
	if is_local_authority and !is_local_player:
		on_spawn_sync.rpc_id(owner_id)
		


var node_array : Array[Node]
var reliable_vars_to_sync : Dictionary
var unreliable_vars_to_sync : Dictionary
var always_server_vars_to_sync : Dictionary

var prior_value_dictionary_reliable : Dictionary
var prior_value_dictionary_unreliable : Dictionary
var prior_value_dictionary_server : Dictionary
# Called when the node enters the scene tree for the first time.
func _ready():
	parent = get_parent()
	reliable_sync_vars["."] = ["owner_id"]
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
		
	if is_local_player:
		set_process(false)
		return	
			
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
	
		
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
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
			print(new_dictionary_server)
			Relayconnect.call_rpc_room(reliable_sync,[new_dictionary_server],false)
	
	if !Relayconnect.IS_HOST and !is_local_authority:
		return
	
	if !is_local_player and is_local_authority:
		return
	
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
	
	for key in unreliable_vars_to_sync:
		for variable in unreliable_vars_to_sync[key]:
			var new_value = node_array[key].get(variable)
			prior_value_dictionary_unreliable[key][variable] = new_value

	if something_different_reliable:
		Relayconnect.call_rpc_room(reliable_sync,[new_dictionary_reliable],false)
	
	Relayconnect.call_rpc_room(unreliable_sync,[prior_value_dictionary_unreliable],false)
	

		
@rpc("any_peer","call_remote","reliable")
func on_spawn_sync():
	
	var sender_id = multiplayer.get_remote_sender_id()
	if sender_id == 0:
		print("SHOULD NOT BE HERE")
		sender_id = multiplayer.get_unique_id()
	
	reliable_sync.rpc_id(sender_id,prior_value_dictionary_reliable)
	reliable_sync.rpc_id(sender_id,prior_value_dictionary_server)
	unreliable_sync.rpc_id(sender_id,prior_value_dictionary_unreliable)
	

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


func Destroy_Networked():
	Relayconnect.call_rpc_room(Destroy_RPC,[])
	
@rpc("any_peer","call_local","reliable")
func Destroy_RPC():
	DestroyingOnPurpose.emit()
	get_parent().queue_free()

