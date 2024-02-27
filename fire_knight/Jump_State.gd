extends State
class_name Jump_State
var player

# Called when the node enters the scene tree for the first time.
func _ready():
	print("Enter Jump State")
	player = get_parent()
	
	# Handle initial Animation
	player.animation.play("jump_up")
	
	# Handle Jump.
	player.velocity.y = player.JUMP_VELOCITY

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	
	if player.is_on_floor():
		player.change_state("idle")

# Next attack in combo
func _input(event):
	if event.is_action_pressed("Attack") and player.velocity.y < 0:
		player.change_state("air_attack")

func exit():
	player.was_in_air = true
	print("Exit Jump State")
