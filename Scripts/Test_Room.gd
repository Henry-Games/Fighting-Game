extends Node
var charcters = {
	"fire_knight":"res://Scenes/FireKnight/Fire_Knight.tscn"
}
@export var winner_label:RichTextLabel
var game_finished = false
# Called when the node enters the scene tree for the first time.
func _ready():
	MUSIC_MANAGER.change_music("res://Assets/Sounds/battle.mp3")
	if !Relayconnect.IS_HOST:
		return
	var i = 0
	for puppet_master : Puppet_Master in get_tree().get_nodes_in_group("in_game"):
		var player = GameManager.spawn_object(charcters[puppet_master.character_selected],Vector2(400 + (i *300),300),0,puppet_master.name,puppet_master.network_node.owner_id)
		var network_node = player.get_node("NetworkVarSync")
		i += 1

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
		await get_tree().create_timer(1).timeout
	Relayconnect.call_rpc_room(GameManager.change_scene_rpc,["res://Scenes/MultiplayerLobby/Multiplayer_Lobby.tscn",false])
	

