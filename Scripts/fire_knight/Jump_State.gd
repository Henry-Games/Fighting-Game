extends State
class_name Jump_State
var player
var puppet_master
# Called when the node enters the scene tree for the first time.
func _ready():
	#print("Enter Jump State")
	player = get_parent()
	puppet_master = player.get_parent()
	puppet_master.AttackSignal.connect(onAttack)

	# Handle initial Animation
	player.animation.play("jump_up")
	
	# Handle Jump.
	player.velocity.y = player.JUMP_VELOCITY

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	if player.is_on_floor():
		player.change_state("idle")

		
# Air Attack
func onAttack():
	if player.velocity.y < 0:
		player.change_state("air_attack")

func exit():
	player.was_in_air = true
	#print("Exit Jump State")
