extends State
class_name Move_State
var player
var puppet_master
# Called when the node enters the scene tree for the first time.
func _ready():
	#print("Enter Move State")
	
	player = get_parent()
	puppet_master = player.get_parent()
	puppet_master.JumpSignal.connect(onJump)
	puppet_master.AttackSignal.connect(onAttack)
	puppet_master.SpecialSignal.connect(onSpecialAttack)
	puppet_master.RollSignal.connect(onRoll)
	puppet_master.DefendSignal.connect(onDefend)
	
	player.animation.play("move", -1, 0.8)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	# Get the input direction and handle the movement/deceleration.
	var direction = puppet_master.MoveAxis.x
	if not direction:
		player.change_state("idle")
	else:
		#var is_left = player.velocity.x < 0
		#player.sprite_2d.flip_h = is_left

		player.scale.y = sign(puppet_master.MoveAxis.x) * 1.5
		if sign(puppet_master.MoveAxis.x) == -1:
			player.global_rotation_degrees = 180
		else:
			player.global_rotation_degrees = 0
			
		player.velocity.x = direction * player.SPEED

	
func onJump():
	if player.is_on_floor():
		player.change_state("jump")

func onAttack():
	if puppet_master.MoveAxis.y > 0:
		player.change_state("attack2")
	elif puppet_master.MoveAxis.y < 0:
		player.change_state("attack3")
	else:
		player.change_state("attack1")

func onSpecialAttack():
	player.change_state("sp_attack")

func onRoll():
	player.change_state("roll")

func onDefend():
	player.change_state("defend")

func exit():
	pass
	#print("Exit Move State")
