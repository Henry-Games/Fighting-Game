extends State
class_name Death_State
var player
var is_left

# Called when the node enters the scene tree for the first time.
func _ready():
	#print("Enter Roll State")
	player = get_parent()
	
	player.animation.play("death",-1,1.5)
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	player.velocity.x = move_toward(player.velocity.x, 0, 25)
	pass

func exit():
	pass
	#print("Exit Roll State")
