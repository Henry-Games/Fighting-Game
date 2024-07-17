extends Control

@onready var anim_player :AnimationPlayer= $AnimationPlayer 
@onready var heart :TextureProgressBar= $Heart
@onready var health_bar :TextureProgressBar= $HealthBar
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func change_health_bar(percentage ):
	print(percentage)
	health_bar.value = percentage
	heart.value = percentage

func medium_damage_anim():
	anim_player.stop(true)
	anim_player.play("medium_damage")
