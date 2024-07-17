extends Control
@export var start_game_button:TextureButton
@export var local_broadcast:RichTextLabel
@export var player_1 : Control
@export var player_2 : Control

var puppet_master_sync_id_1 : set = p1_changed
var puppet_master_sync_id_2 : set = p2_changed

# Called when the node enters the scene tree for the first time.
func _ready():
	if !Relayconnect.IS_LOCAL_HOST:
		local_broadcast.queue_free()
	
	if Relayconnect.IS_HOST:
		Relayconnect.game_started_rpc.rpc_id(0,false)	
		for puppet_master in get_tree().get_nodes_in_group("in_game"):
			puppet_master.remove_from_group("in_game")
			_spawn_lobby_player(puppet_master)
	
	GameManager.SpawnPuppetSignal.connect(_spawn_lobby_player)
	GameManager.spawn_puppet_masters()
	
func _process(delta):
	release_focus()
	var in_game = get_tree().get_nodes_in_group("in_game")
	var have_selected_character = 0
	for puppet_master : Puppet_Master in in_game:
		if puppet_master.character_selected != "":
			have_selected_character+= 1
			
	if have_selected_character > 1 && Relayconnect.IS_HOST:
		start_game_button.disabled = false
	else:
		start_game_button.disabled = true

		 
func _spawn_lobby_player(puppet_master : Puppet_Master):
	
	puppet_master_in_game.rpc_id(Relayconnect.HOST_ID,puppet_master.name)
	

func remove_lobby_player(player_num : int):
	_remove_lobby_playerRPC.rpc_id(Relayconnect.HOST_ID,player_num)
	
@rpc("call_local","any_peer","reliable")
func _remove_lobby_playerRPC(player_num : int):
	match player_num:
		1:
			puppet_master_sync_id_1 = null
		2:
			puppet_master_sync_id_2 = null
	
@rpc("any_peer","call_local","reliable")
func puppet_master_in_game(puppet_master_sync_id):

	if puppet_master_sync_id_1 == puppet_master_sync_id or puppet_master_sync_id_2 == puppet_master_sync_id:
		return
	
	var in_game = get_tree().get_nodes_in_group("in_game")
	if in_game.size() >= 2:
		return
	
	var puppet_master : Puppet_Master
	for node in get_tree().get_nodes_in_group("puppet_masters"):
		if node.name == puppet_master_sync_id:
			puppet_master = node
			break
	
	if puppet_master.is_in_group("in_game"):
		return		
	
	puppet_master.add_to_group("in_game")
	if puppet_master_sync_id_1 == null:
		puppet_master_sync_id_1 = puppet_master.name
		return
		
	if puppet_master_sync_id_2== null:
		puppet_master_sync_id_2 = puppet_master.name

		
func p1_changed(new_p1_sync_id):
	puppet_master_sync_id_1 = new_p1_sync_id
	if puppet_master_sync_id_1 == null:
		player_1.puppet_master = null
		return
	var puppet_master : Puppet_Master
	for node in get_tree().get_nodes_in_group("puppet_masters"):
		if node.name == puppet_master_sync_id_1:
			puppet_master = node
			break
	player_1.puppet_master = puppet_master
	puppet_master.player_number = 1
	
func p2_changed(new_p2_sync_id):
	puppet_master_sync_id_2 = new_p2_sync_id
	if puppet_master_sync_id_2 == null:
		player_2.puppet_master = null
		return
		
	var puppet_master : Puppet_Master
	for node in get_tree().get_nodes_in_group("puppet_masters"):
		if node.name == puppet_master_sync_id_2:
			puppet_master = node
			break
			
	player_2.puppet_master = puppet_master
	puppet_master.player_number = 2


func _on_leave_button_button_down():
	Relayconnect.leave_command.rpc_id(0)
	pass # Replace with function body.


func _on_start_button_button_down():
	Relayconnect.game_started_rpc.rpc_id(0,true)
	Relayconnect.call_rpc_room(GameManager.change_scene_rpc,["res://Scenes/Test_Room.tscn",false])
	pass # Replace with function body.
