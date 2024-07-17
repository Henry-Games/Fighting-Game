extends State
class_name Idle_State
var player
var puppet_master
# Called when the node enters the scene tree for the first time.
func _ready():
	#print("Enter Idle State")
	player = get_parent()
	player.forcedPositionSync()
	puppet_master = player.get_parent()
	puppet_master.JumpSignal.connect(onJump)
	puppet_master.AttackSignal.connect(onAttack)
	puppet_master.SpecialSignal.connect(onSpecialAttack)
	puppet_master.RollSignal.connect(onRoll)
	puppet_master.DefendSignal.connect(onDefend)
	# Animations
	if player.was_in_air:
		player.animation.play("jump_land")
		player.was_in_air = false
	else:

		player.animation.play("idle")
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	player.velocity.x = move_toward(player.velocity.x, 0, 25)
		
	if !puppet_master.MoveAxis.is_zero_approx():

		var direction = puppet_master.MoveAxis.x
		if direction and player.is_on_floor():
			player.change_state("move")	

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
	#print("Exit Idle State")
