extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_button_pressed():
	get_tree().change_scene_to_file("MainMenu.tscn")
	print("Play")
	pass


func _on_button_2_pressed():
	# get.tree().change_scene_to_file()
	print("Options")
	pass


func _on_button_3_pressed():
	get_tree().quit()
	print("Exit")
	pass
