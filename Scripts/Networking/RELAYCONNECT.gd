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

## Supplementary functions	
# Called when the node enters the scene tree for the first time.
func _ready():
	var relay_connect = ENetMultiplayerPeer.new()
	var error = relay_connect.create_client("127.0.0.1",25566)
	if error:
		return(error)
		
	multiplayer.multiplayer_peer = relay_connect
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connected_fail)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	NetworkTicker()
	

	
		
func NetworkTicker():
	var unix_time_with_ms = Time.get_unix_time_from_system() * 1000 
	var formattedTime = floorf(unix_time_with_ms/200) * 200
	NETWORK_TICK.emit(formattedTime)
	await get_tree().create_timer(0.2).timeout
	NetworkTicker()
	
func _on_connected_to_server():
	_resgister_player.rpc_id(0)
	connected = true
	ON_RELAY_SERVER_CONNECT.emit()

func _on_connected_fail():
	connected = false
	ON_RELAY_SERVER_FAIL.emit()

func _on_server_disconnected():
	connected = false
	GameManager.change_scene_rpc("res://SCENES/MainMenu/MainMenu.tscn",true)
	ROOM_DATA = {}
	ROOM_CODE = ""
	IS_HOST = false
	HOST_ID = 0
	
func host():
	if multiplayer.multiplayer_peer.CONNECTION_CONNECTED:
		host_rpc.rpc_id(0)

func join():
	if multiplayer.multiplayer_peer.CONNECTION_CONNECTED:
		join_rpc.rpc_id(0,typed_room_code)

@rpc("any_peer","call_remote","reliable")
func host_rpc():
	pass

@rpc("authority","call_remote","reliable")
func host_success_rpc(room_code : String,room_info : Dictionary):
	ROOM_DATA = room_info
	HOST_ID = ROOM_DATA.host_id
	ROOM_CODE = ROOM_DATA.room_code
	IS_HOST = true
	HOST_SUCCESS.emit()
	
@rpc("authority","call_remote","reliable")
func host_fail_rpc(room_code : String, error_message : String):
	HOST_FAIL.emit(error_message)

@rpc("any_peer","call_remote","reliable")	
func join_rpc(room_code : String):
	pass

@rpc("authority","call_remote","reliable")
func join_success_rpc(room_info : Dictionary,player_joined_id):
	if player_joined_id == multiplayer.get_unique_id():
		ROOM_DATA = room_info
		HOST_ID = ROOM_DATA.host_id
		ROOM_CODE = ROOM_DATA.room_code
		IS_HOST = false
		JOIN_SUCCESS.emit()
	
	if IS_HOST:
		GameManager.sync_game_data(player_joined_id)
	pass

@rpc("authority","call_remote","reliable")
func join_fail_rpc(room_code : String, error_message : String):
	JOIN_FAIL.emit(error_message)
	print(error_message)
	pass

@rpc("any_peer","call_remote","reliable")
func leave_command():
	pass
		
@rpc("any_peer","call_remote","reliable")
func remove_player_command(player_to_remove):
	pass

@rpc("authority","call_remote","reliable")
func player_disconnect_room(player_disconnecting_id):
	if player_disconnecting_id == multiplayer.get_unique_id():
		room_closed()
	else:
		for child in GameManager.get_children():
			var network_node = child.get_node("NetworkVarSync")
			if network_node.owner_id == player_disconnecting_id:
				GameManager.objects_to_sync.erase(network_node.sync_id)
				child.queue_free()

@rpc("authority","call_remote","reliable")
func room_closed():
	ROOM_DATA = {}
	GameManager.objects_to_sync = {}
	for child in GameManager.get_children():
		child.queue_free()
	IS_HOST = false
	HOST_ID = 0
	get_tree().change_scene_to_file("res://SCENES/MainMenu/MainMenu.tscn")

@rpc("any_peer","call_remote","reliable")
func _resgister_player():
	pass

@rpc("authority","reliable")
func sync_room_data_rpc(room_data : Dictionary):
	ROOM_DATA = room_data
	HOST_ID = ROOM_DATA.host_id
	print(ROOM_DATA)

@rpc("any_peer","reliable")
func game_started_rpc(started : bool):
	pass

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



