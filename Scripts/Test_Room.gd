extends Node


# Called when the node enters the scene tree for the first time.
func _ready():
	if !Relayconnect.IS_HOST:
		return
	var i = 0
	for puppet_master in get_tree().get_nodes_in_group("in_game"):
		var player = GameManager.spawn_object("res://Scenes/FireKnight/Fire_Knight.tscn",Vector2(280 + (i *10),300),0,puppet_master.name)
		var network_node = player.get_node("NetworkVarSync")
		network_node.owner_id = puppet_master.network_node.owner_id
		i += 2



