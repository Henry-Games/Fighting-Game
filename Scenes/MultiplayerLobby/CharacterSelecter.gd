extends Control


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_fire_knight_select_button_down():
	for node : Puppet_Master in get_tree().get_nodes_in_group("puppet_masters"):
		if node.network_node.is_local_player and node.player_number\
		and node.controller == false:
			node.character_selected = "fire_knight"

