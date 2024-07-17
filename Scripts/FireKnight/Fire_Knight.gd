extends CharacterBody2D

const SPEED = 250.0
const JUMP_VELOCITY = -250.0


@export var name_label : RichTextLabel

var mobile_controls = preload("res://Scenes/FireKnight/Mobile_Controls.tscn")

var damage = 10
var knockback = 2
var max_health = 100
var health = 100

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var state
var state_machine

var was_in_air = false
var selected_health_bar
var selected_name_label
@onready var puppet_master :Puppet_Master= get_parent()
@onready var animation = $AnimationPlayer
@onready var sprite_2d = $Sprite2D
@onready var p1_health_bar = $Node/Control/HealthBar1
@onready var p2_health_bar = $Node/Control/HealthBar2
@onready var p1_name_label = $Node/Control/P1Name
@onready var p2_name_label = $Node/Control/P2Name

func _ready():
	match puppet_master.player_number:
		1:
			p2_health_bar.visible = false
			selected_health_bar = p1_health_bar
			p2_name_label.visible = false
			selected_name_label = p1_name_label
		2:
			p1_health_bar.visible = false
			selected_health_bar = p2_health_bar
			p1_name_label.visible = false
			selected_name_label = p2_name_label
	
	selected_name_label.text = puppet_master.player_name
	add_to_group("alive")
	if puppet_master.network_node.is_local_player and puppet_master.mobile:
		var instance = mobile_controls.instantiate()
		add_child(instance)
	
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
	if anim_name == "death":
		return
	
	change_state("idle")



func _on_attack_hit_body_entered(body):
	if !$NetworkVarSync.is_local_player:
		return
	
	if body.get_class() == "CharacterBody2D" and body != self:
		var direction = sign(scale.y)
		body.TakeDamage(damage, knockback,direction)

func TakeDamage(damage : int, knockback:float,direction : int):

	Relayconnect.call_rpc_room(TakeDamageRPC,[damage,knockback,direction]);


@rpc("any_peer","call_local","reliable")
func TakeDamageRPC(damage : int, knockback: float, direction : int):
	
	if state.name == "defend":
		change_state("attack3")
		return
	health -= damage
	velocity.x += (direction * knockback) * 100
	if health <= 0:
		change_state("death")
	else:
		change_state("hit")
		
	scale.y = -(sign(direction) * 1.5)
	if sign(direction) == 1:
		global_rotation_degrees = 180
	else:
		global_rotation_degrees = 0
	
	selected_health_bar.medium_damage_anim()
	selected_health_bar.change_health_bar(health*100/max_health)

func forcedPositionSync():
	# FOR synchronosity on each state change reliably update player position
	if $NetworkVarSync.is_local_player:
		var node_array_pos = $NetworkVarSync.node_array.find(self)
		Relayconnect.call_rpc_room($NetworkVarSync.reliable_sync,[{node_array_pos:{"global_position":global_position}}],false)

