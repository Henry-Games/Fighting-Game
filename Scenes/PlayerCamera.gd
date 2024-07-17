extends Camera2D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var players_alive = get_tree().get_nodes_in_group("alive")
	if players_alive.size() == 0:
		return
	var position_sum :Vector2= Vector2.ZERO;
	var furthest_left_player :Node2D= players_alive[0]
	var furthest_right_player :Node2D= players_alive[0]
	for player:Node2D in players_alive:
		position_sum += player.global_position
		if player.global_position.x > furthest_right_player.global_position.x:
			furthest_right_player = player
		
		if player.global_position.x < furthest_left_player.global_position.x:
			furthest_left_player = player
		
	var targetPos = position_sum / players_alive.size()
	targetPos.y -= 50
	self.global_position = global_position.lerp(targetPos,delta)


	var distance_between_players = furthest_left_player.global_position.distance_to(\
	furthest_right_player.global_position)
	
	
	var zoom_x = get_viewport_rect().size.x/(distance_between_players + 100)
	zoom_x = clamp(zoom_x,0.5,4)
	zoom = Vector2(zoom_x,zoom_x)
	

	pass
