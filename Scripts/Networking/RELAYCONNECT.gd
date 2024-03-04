extends Node2D

### ALL CODE PERTAINING TO RELAY CONNECTION
signal JOIN_SUCCESS
signal JOIN_FAIL(error_message)
signal HOST_SUCCESS
signal HOST_FAIL(error_message)
signal ON_RELAY_SERVER_CONNECT()
signal ON_RELAY_SERVER_FAIL()
signal ON_RELAY_SERVER_DISCONNECT()

signal NETWORK_TICK(unix_time)
var connected = false
var network_ticking_started := false
@export var typed_room_code= ""
var ROOM_DATA := {}
var ROOM_CODE : String
var IS_HOST := false;
var HOST_ID := 0;
var CHARS := "ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890";

var IS_LOCAL_HOST = false
var joining_local_host = false
var local_relay_server_pid = -1
var typed_local_address = ""
	
# Called when the node enters the scene tree for the first time.
func _ready():
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connected_fail)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

# Starts connecting to relay server, could be any - Local or Remote
func connect_to_relay_server(ip : String):
	var relay_connect = ENetMultiplayerPeer.new()
	var error = relay_connect.create_client(ip,25566)
	if error:
		return(error)
		
	multiplayer.multiplayer_peer = relay_connect
	
# When connected to relay server register player to the database and emit connection signal
func _on_connected_to_server():
	_resgister_player.rpc_id(0)
	connected = true
	ON_RELAY_SERVER_CONNECT.emit()
	
	# Instantly join selected local room if joining through local broadcast
	if joining_local_host:
		join()
	joining_local_host = false
	
#Register player command
@rpc("any_peer","call_remote","reliable")
func _resgister_player():
	pass

func _on_connected_fail():
	connected = false
	ON_RELAY_SERVER_FAIL.emit()
	
	joining_local_host = false

# if relay server disconncets Return to main menu and reset important values to default
func _on_server_disconnected():
	connected = false
	
	GameManager.change_scene_rpc("res://Scenes/MainMenu/MainMenu.tscn",true)
	ROOM_DATA = {}
	ROOM_CODE = ""
	IS_HOST = false
	HOST_ID = 0
	joining_local_host = false
	
# Host Using remote relay server
func host():
	if multiplayer.multiplayer_peer.CONNECTION_CONNECTED:
		host_rpc.rpc_id(0)

# Join room using remote relay server
func join():
	if multiplayer.multiplayer_peer.CONNECTION_CONNECTED:
		join_rpc.rpc_id(0,typed_room_code)
#Dummy for cmd being sent to server
@rpc("any_peer","call_remote","reliable")
func host_rpc():
	pass
#receives host success from relay server
@rpc("authority","call_remote","reliable")
func host_success_rpc(room_code : String,room_info : Dictionary):
	ROOM_DATA = room_info
	HOST_ID = ROOM_DATA.host_id
	ROOM_CODE = ROOM_DATA.room_code
	IS_HOST = true
	HOST_SUCCESS.emit()
#receives host fail from relay server
@rpc("authority","call_remote","reliable")
func host_fail_rpc(room_code : String, error_message : String):
	HOST_FAIL.emit(error_message)

#Dummy for cmd being sent to server
@rpc("any_peer","call_remote","reliable")	
func join_rpc(room_code : String):
	pass

#Receives join succes from relay server, this is received by all players when any player joins
@rpc("authority","call_remote","reliable")
func join_success_rpc(room_info : Dictionary,player_joined_id):
	# if we are the people joining then send join success
	if player_joined_id == multiplayer.get_unique_id():
		ROOM_DATA = room_info
		HOST_ID = ROOM_DATA.host_id
		ROOM_CODE = ROOM_DATA.room_code
		IS_HOST = false
		JOIN_SUCCESS.emit()
	#The host sends current game data for synchronization
	if IS_HOST:
		GameManager.sync_game_data(player_joined_id)
	pass

# Join Failed received from server only by player that is trying to join
@rpc("authority","call_remote","reliable")
func join_fail_rpc(room_code : String, error_message : String):
	JOIN_FAIL.emit(error_message)
	print(error_message)
	pass

# Leave Command
@rpc("any_peer","call_remote","reliable")
func leave_command():
	pass

# Kick command
@rpc("any_peer","call_remote","reliable")
func remove_player_command(player_to_remove):
	pass

# When a player disconnects from the room
@rpc("authority","call_remote","reliable")
func player_disconnect_room(player_disconnecting_id):
	#if we are the player disconnecting/being kicked then go back to main_menu
	if player_disconnecting_id == multiplayer.get_unique_id():
		room_closed()
	# on all other computers remove everything related to leaving player
	else:
		for child in GameManager.get_children():
			var network_node = child.get_node("NetworkVarSync")
			if network_node.owner_id == player_disconnecting_id:
				GameManager.objects_to_sync.erase(network_node.sync_id)
				child.queue_free()

# Resets your game to default and sends to main menu
@rpc("authority","call_remote","reliable")
func room_closed():
	# if was locally hosting destroy the relay server running
	var relay_server = get_node("/root/RelayServer")
	if relay_server:
		relay_server.queue_free()
		
	ROOM_DATA = {}
	GameManager.objects_to_sync = {}
	# Get rid of all network syncronised objects under GameManager
	for child in GameManager.get_children():
		child.queue_free()
	IS_HOST = false
	HOST_ID = 0
	get_tree().change_scene_to_file("res://Scenes/MainMenu/MainMenu.tscn")


# Receive Room Data from relay server (as in room code and current players and their ids)
@rpc("authority","reliable")
func sync_room_data_rpc(room_data : Dictionary):
	ROOM_DATA = room_data
	HOST_ID = ROOM_DATA.host_id

@rpc("any_peer","reliable")
func game_started_rpc(started : bool):
	pass

# When local hosting create relay server and connect to self
func local_host():
	IS_LOCAL_HOST = true
	var object_to_spawn = load("res://Scenes/Networking/RelayServer.tscn") as PackedScene
	var object_instance = object_to_spawn.instantiate() 
	get_tree().root.add_child(object_instance)
	connect_to_relay_server("127.0.0.1")


func local_join(ip,room_code):
	# connect to the local player
	connect_to_relay_server(ip)
	# set roomcode to join when connection succeds
	typed_room_code = room_code
	joining_local_host = true
	
# CALL RPC ROOM -  Calls rpc functions on the entire joined lobby - Currently only up to 
func call_rpc_room(rpc_function : Callable, args : Array, call_self : bool = true):
	if !ROOM_DATA.has("players") or multiplayer.multiplayer_peer.get_connection_status() != 2:
		return
	
	for player_id in ROOM_DATA.players:
		if player_id == multiplayer.multiplayer_peer.get_unique_id() and !call_self:
			continue
			
		match args.size():
			0:
				rpc_function.rpc_id(player_id)
			1:
				rpc_function.rpc_id(player_id,args[0])
			2:
				rpc_function.rpc_id(player_id,args[0],args[1])
			3:
				rpc_function.rpc_id(player_id,args[0],args[1],args[2])
			4:
				rpc_function.rpc_id(player_id,args[0],args[1],args[2],args[3])
			5:
				rpc_function.rpc_id(player_id,args[0],args[1],args[2],args[3],args[4])
			6:
				rpc_function.rpc_id(player_id,args[0],args[1],args[2],args[3],args[4],args[5])


	

