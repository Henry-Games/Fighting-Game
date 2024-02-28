extends State
class_name Defend_State
var player

# Called when the node enters the scene tree for the first time.
func _ready():
	#print("Enter Defend State")
	player = get_parent()
	player.animation.play("defend")
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	player.velocity.x = move_toward(player.velocity.x, 0, 15)

func exit():
	pass
	#print("Exit Defend State")
