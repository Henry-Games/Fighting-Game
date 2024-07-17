extends Node

var target_pos = null;
var target_node = null;
var t = 0;
# Called when the node enters the scene tree for the first time.
func start_timer():
	
	# Do some action
	await get_tree().create_timer(0.1).timeout # waits for 1 second
	clear()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if target_pos != null and target_node != null:
		t+=delta * 5;
		target_node.global_position = target_node.global_position.lerp(target_pos, t)

func clear():
	target_pos = null
	target_node = null;
	
	t=0;
