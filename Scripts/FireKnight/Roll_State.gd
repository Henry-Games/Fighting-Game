extends State
class_name Roll_State
var player
var is_left

# Called when the node enters the scene tree for the first time.
func _ready():
	#print("Enter Roll State")
	player = get_parent()
	
	player.animation.play("roll",-1,1.5)
	if player.scale.y < 0:
		is_left = -1
	else:
		is_left = 1
		
	player.velocity.x = 350 * is_left

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	pass

func exit():
	pass
	#print("Exit Roll State")
