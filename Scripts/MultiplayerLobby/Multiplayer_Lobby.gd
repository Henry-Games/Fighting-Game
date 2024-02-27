extends Node2D
@export var StartGameButton:Button
# Called when the node enters the scene tree for the first time.
func _ready():
	
	GameManager.spawn_puppet_masters()
	GameManager.SPAWN_PUPPET_SIGNAL.connect(spawn_lobby_player)
	if Relayconnect.IS_HOST:
		Relayconnect.game_started_rpc.rpc_id(0,false)	
		for puppet_master in get_tree().get_nodes_in_group("in_game"):
			spawn_lobby_player(puppet_master)
		
	
func spawn_lobby_player(puppet_master):
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
			var player = GameManager.spawn_object("res://Scenes/MultiplayerLobby/lobby_player.tscn",Vector2(x_pos,y_pos),0,puppet_master.name)
			player.lobby_grid_pos = Vector2(x_raw,y_raw)
		
		i+=1

	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if !Relayconnect.IS_HOST:
		set_process(false)
	
	if get_tree().get_nodes_in_group("lobby_players").size() >= 1:
		StartGameButton.disabled = false
	else:
		StartGameButton.disabled = true
		


func _on_start_game_button_down():
	Relayconnect.game_started_rpc.rpc_id(0,true)
	Relayconnect.call_rpc_room(GameManager.change_scene_rpc,["res://Scenes/main.tscn",false])



func _on_leave_button_down():
	Relayconnect.leave_command.rpc_id(0)

