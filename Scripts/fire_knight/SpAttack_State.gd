extends State
class_name SpAttack_State
var player

# Called when the node enters the scene tree for the first time.
func _ready():
	#print("Enter SpAttack State")
	player = get_parent()
	
	player.animation.play("sp_attack", -1, 1.25)
	player.audio_
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	player.velocity.x = move_toward(player.velocity.x, 0, 15)

func exit():
	pass
	#print("Exit SpAttack State")
