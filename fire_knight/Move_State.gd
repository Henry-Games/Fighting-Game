extends State
class_name Move_State
var player

# Called when the node enters the scene tree for the first time.
func _ready():
	print("Enter Move State")
	player = get_parent()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	# Animations
	if player.is_on_floor():
		player.animation.play("move", -1, 0.6)
	
	# Get the input direction and handle the movement/deceleration.
	var direction = Input.get_axis("Left", "Right")
	if not direction:
		player.change_state("idle")
	else:
		var is_left = player.velocity.x < 0
		player.sprite_2d.flip_h = is_left
		player.velocity.x = direction * player.SPEED
	
	if Input.is_action_just_pressed("Jump") and player.is_on_floor():
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
	print("Exit Move State")
