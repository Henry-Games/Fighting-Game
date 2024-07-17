extends Node2D

@onready var button_sound = $Sounds/Button_sound


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_button_pressed():
	button_sound.play();
	await get_tree().create_timer(0.2).timeout
	GameManager.change_scene_rpc("res://Scenes/MainMenu/MainMenu.tscn", true)
	print("Play")
	pass


func _on_button_2_pressed():
	# Add the change_scene_rpc("") function when ready to make options page.
	
	button_sound.play();
	await get_tree().create_timer(0.2).timeout
	print("Options")
	pass


func _on_button_3_pressed():
	button_sound.play();
	await get_tree().create_timer(0.2).timeout
	get_tree().quit()
	print("Exit")
	pass
