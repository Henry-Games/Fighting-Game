extends State
class_name Idle_State
var player

# Called when the node enters the scene tree for the first time.
func _ready():
	print("Enter Idle State")
	player = get_parent()
	
	# Animations
	if player.was_in_air:
		player.animation.play("jump_land")
		player.was_in_air = false
	else:
		player.animation.play("idle")
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	player.velocity.x = move_toward(player.velocity.x, 0, 25)
	
	if Input.is_action_pressed("Left") or Input.is_action_pressed("Right"):
		var direction = Input.get_axis("Left", "Right")
		if direction and player.is_on_floor():
			player.change_state("move")	
	elif Input.is_action_just_pressed("Jump"):
		player.change_state("jump")
	elif Input.is_action_just_pressed("Attack"):
		if Input.is_action_pressed("Up"):
			player.change_state("attack2")
		elif Input.is_action_pressed("Down"):
			player.change_state("attack3")
		else:
			player.change_state("attack1")
	elif Input.is_action_just_pressed("SpAttack"):
		player.change_state("sp_attack")
	elif Input.is_action_just_pressed("Roll"):
		player.change_state("roll")
	elif Input.is_action_just_pressed("Defend"):
		player.change_state("defend")

func exit():
	print("Exit Idle State")
