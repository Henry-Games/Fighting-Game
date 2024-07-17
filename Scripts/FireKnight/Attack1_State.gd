extends State
class_name Attack1_State
var player

# Called when the node enters the scene tree for the first time.
func _ready():
	#print("Enter Attack1 State")
	player = get_parent()
	player.forcedPositionSync()
	player.damage = 10
	player.knockback = 2
	player.animation.play("attack1", -1, 1.25)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	player.velocity.x = move_toward(player.velocity.x, 0, 15)

func exit():
	pass
	#print("Exit Attack1 State")
