extends Node
var charcters = {
	"fire_knight":"res://Scenes/FireKnight/Fire_Knight.tscn"
}
@export var winner_label:RichTextLabel
var game_finished = false
# Called when the node enters the scene tree for the first time.
func _ready():
	MUSIC_MANAGER.change_music("res://Assets/Sounds/battle.mp3")
	Relayconnect.RoomClosedSignal.connect(onRoomClosed)
	$AnimationPlayer.play("FadeFromBlack")
	if !Relayconnect.IS_HOST:
		return
	var i = 0
	for puppet_master : Puppet_Master in get_tree().get_nodes_in_group("in_game"):
		
		i += 1
		
	var p1 : Puppet_Master = get_tree().get_first_node_in_group("p1")
	var p2 : Puppet_Master = get_tree().get_first_node_in_group("p2")
	var player1 = GameManager.spawn_object(charcters[p1.character_selected],Vector2(400,300),0,p1.name,p1.network_node.owner_id)
	var player2 = GameManager.spawn_object(charcters[p1.character_selected],Vector2(700,300),0,p2.name,p2.network_node.owner_id)
	player2.scale.y = -1 * 1.5
	player2.global_rotation_degrees = 180
func _process(delta):
	if !Relayconnect.IS_HOST:
		return
		
	var alive_players = get_tree().get_nodes_in_group("alive")
	if alive_players.size() == 1 and !game_finished:
		var puppet_master : Puppet_Master = alive_players[0].get_parent() 
		winner_label.text = "[center]WINNER : %s[center]" % puppet_master.player_name
		game_finished = true
		lobby_timer()

func lobby_timer():
	await get_tree().create_timer(5).timeout
	for i in range(0,5):
		winner_label.text = "[center]RETURNING TO LOBBY IN %s[center]" %[5 - i]
		if 5-i == 1:
			Relayconnect.call_rpc_room(LeaveToLobby,[])
		await get_tree().create_timer(1).timeout
		
		
	
	
@rpc("any_peer","call_local","reliable")
func LeaveToLobby():
	$AnimationPlayer.play("FadeToBlack")
	$ExitToLobbyTimer.start()
	
func _on_exit_to_lobby_timer_timeout():
	Relayconnect.call_rpc_room(GameManager.change_scene_rpc,["res://Scenes/MultiplayerLobby/Multiplayer_Lobby.tscn",false])
	
func onRoomClosed():
	$AnimationPlayer.play("FadeToBlack")
	$ExitToMainMenuTimer.start()
	
func _on_exit_to_main_menu_timer_timeout():
	GameManager.change_scene_rpc("res://Scenes/MainMenu/Main_Menu.tscn",true)
	pass # Replace with function body.






