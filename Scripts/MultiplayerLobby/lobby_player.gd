extends Control

@export var lineEdit : LineEdit
@export var alphabet_grid : FlowContainer
@export var colour_grid : FlowContainer
@export var disconnect_button : Button
@export var TYPE_HERE_LABEL : RichTextLabel
@export var controller := false
var controller_id := 0

var puppet_master
var lobby_grid_pos
@export var prior_button : Button 
@export var selected_button : Button : set = onSelectedButtonChanged

var prior_selected_container = Vector2.ZERO
func _ready():
	add_to_group("lobby_players")
	puppet_master = get_parent()
	controller_id = puppet_master.device_id
	controller = puppet_master.controller
	lineEdit.text = puppet_master.player_name
	$NetworkVarSync.owner_id = puppet_master.network_node.owner_id
	$NetworkVarSync.DestroyingOnPurpose.connect(_on_purposeful_destroy)
	puppet_master.add_to_group("in_game")
	
	if !controller:
		for child in alphabet_grid.get_children():
			child.queue_free()
		for child in colour_grid.get_children():
			child.disabled = false
			child.button_mask = MOUSE_BUTTON_MASK_LEFT
		
		disconnect_button.disabled = false
		disconnect_button.button_mask = MOUSE_BUTTON_MASK_LEFT
		TYPE_HERE_LABEL.text = "TYPE HERE ^ ^ ^"
	
	if !puppet_master.network_node.is_local_player:
		for child in alphabet_grid.get_children():
			child.queue_free()
		
		for child in colour_grid.get_children():
			child.queue_free()
		
		disconnect_button.queue_free()
		TYPE_HERE_LABEL.text = "REMOTE PLAYER"
		lineEdit.editable = false
		set_process_input(false)


func _input(event):
	if controller and event.device == controller_id:
		match event.get_class():
			"InputEventJoypadButton":
				if event.pressed:
					match event.button_index:
						JOY_BUTTON_DPAD_DOWN:
							if selected_button.get_focus_neighbor(SIDE_BOTTOM):
								selected_button = selected_button.find_valid_focus_neighbor(SIDE_BOTTOM)
						JOY_BUTTON_DPAD_UP:
							if selected_button.get_focus_neighbor(SIDE_TOP):
								selected_button = selected_button.find_valid_focus_neighbor(SIDE_TOP)
						JOY_BUTTON_DPAD_LEFT:
							if selected_button.get_focus_neighbor(SIDE_LEFT):
								selected_button = selected_button.find_valid_focus_neighbor(SIDE_LEFT)
						JOY_BUTTON_DPAD_RIGHT:
							if selected_button.get_focus_neighbor(SIDE_RIGHT):
								selected_button = selected_button.find_valid_focus_neighbor(SIDE_RIGHT)
						JOY_BUTTON_A:
							buttonPressed()
						JOY_BUTTON_B:
							lineEdit.text = lineEdit.text.left(lineEdit.text.length() - 1)
							lineEdit.text_changed.emit(lineEdit.text)
				
	
func buttonPressed():
	match selected_button.text:
		"A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R",\
		"S","T","U","V","W","X","Y","Z":
			lineEdit.text += selected_button.text
			lineEdit.text_changed.emit(lineEdit.text)
		"BACK":
			lineEdit.text = lineEdit.text.left(lineEdit.text.length() - 1)
			lineEdit.text_changed.emit(lineEdit.text)
		_:

			selected_button.button_down.emit()
			
func onSelectedButtonChanged(new_button):
	if controller:
		prior_button.disabled = true	
		new_button.disabled = false
		
	selected_button = new_button
	prior_button = new_button

	
func _on_line_edit_text_changed(new_text):
	puppet_master.player_name = new_text


func _on_disconnect_button_button_down():
	$NetworkVarSync.Destroy_Networked()
	pass # Replace with function body.

func _on_purposeful_destroy():
	puppet_master.remove_from_group("in_game")
			
