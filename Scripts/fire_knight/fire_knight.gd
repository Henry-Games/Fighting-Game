extends CharacterBody2D

const SPEED = 250.0
const JUMP_VELOCITY = -250.0
@onready var animation = $AnimationPlayer
@onready var sprite_2d = $Sprite2D

var damage = 10;
var health = 100;
# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var state
var state_machine

var was_in_air = false
func _ready():

	state_machine = State_Machine.new()
	change_state("idle")

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta

	move_and_slide()

func change_state(new_state_name):
	if state != null:
		state.exit()
		state.queue_free()
	# Add New State
	state = state_machine.get_state(new_state_name).new()
	state.setup("change_state", self)
	state.name = new_state_name
	add_child(state)

func _on_animation_player_animation_finished(anim_name):
	#print("ANIM FINISHED " + anim_name)
	change_state("idle")


func _on_attack_hit_body_entered(body):
	if !$NetworkVarSync.is_local_player:
		return
	
	if body.get_class() == "CharacterBody2D" and body != self:
		body.TakeDamage(damage, 10)
		

func TakeDamage(damage : int, knockback:float):
	Relayconnect.call_rpc_room(TakeDamageRPC,[damage,0]);
	
@rpc("any_peer","call_local","reliable")
func TakeDamageRPC(damage : int, knockback: float):
	health -= damage
	print("Health : " + str(health) )
