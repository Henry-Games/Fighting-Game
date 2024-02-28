extends State
class_name Air_Attack_State
var player

# Called when the node enters the scene tree for the first time.
func _ready():
	#print("Enter Air Attack State")
	player = get_parent()
	
	player.animation.play("air_attack", -1, 1.25)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	player.velocity.y = 5
	player.velocity.x = move_toward(player.velocity.x, 0, 15)
	
	if player.is_on_floor():
		player.change_state("idle")

func exit():
	player.was_in_air = true
	#print("Exit Air Attack State")
