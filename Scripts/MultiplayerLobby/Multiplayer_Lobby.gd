extends Node2D
@export var start_game_button:Button
@export var local_broadcast:RichTextLabel
# Called when the node enters the scene tree for the first time.
func _ready():
	if !Relayconnect.IS_LOCAL_HOST:
		local_broadcast.queue_free()
	
	if Relayconnect.IS_HOST:
		Relayconnect.game_started_rpc.rpc_id(0,false)	
		for puppet_master in get_tree().get_nodes_in_group("in_game"):
			_spawn_lobby_player(puppet_master)
	
	GameManager.SpawnPuppetSignal.connect(_spawn_lobby_player)
	GameManager.spawn_puppet_masters()
	

func _spawn_lobby_player(puppet_master : Puppet_Master):
	spawn_lobby_player_cmd.rpc_id(Relayconnect.HOST_ID,puppet_master.network_node.sync_id)
		
@rpc("any_peer","call_local","reliable")
func spawn_lobby_player_cmd(puppet_master_sync_id):
	var puppet_master : Puppet_Master
	for node in get_tree().get_nodes_in_group("puppet_masters"):
		if node.name == puppet_master_sync_id:
			puppet_master = node
	
	var found_pos = false
	var i = 0

	while !found_pos:
		var x_raw = i % 4
		var y_raw = floor(i / 4) 
		var over_lapped = false
		for lobby_player in get_tree().get_nodes_in_group("lobby_players"):
			
			if lobby_player.lobby_grid_pos == Vector2(x_raw,y_raw):
				over_lapped = true
				break
				
		if !over_lapped:
			var x_pos = x_raw * 250
			var y_pos = y_raw * 300
			found_pos = true
			var player = GameManager.spawn_object("res://Scenes/MultiplayerLobby/Lobby_Player.tscn",Vector2(x_pos,y_pos),0,puppet_master.name)
			player.lobby_grid_pos = Vector2(x_raw,y_raw)
		i+=1

	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if !Relayconnect.IS_HOST:
		set_process(false)
	
	if get_tree().get_nodes_in_group("lobby_players").size() >= 1:
		start_game_button.disabled = false
	else:
		start_game_button.disabled = true
		


func _on_start_game_button_down():
	Relayconnect.game_started_rpc.rpc_id(0,true)
	Relayconnect.call_rpc_room(GameManager.change_scene_rpc,["res://Scenes/Test_Room.tscn",false])



func _on_leave_button_down():
	Relayconnect.leave_command.rpc_id(0)

