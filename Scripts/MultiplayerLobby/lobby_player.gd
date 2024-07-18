extends Control


# TO SET IN EDITOR
@export var name_line_edit : LineEdit
@export var alphabet_grid : FlowContainer
@export var disconnect_button : BaseButton
@export var type_here_label : RichTextLabel
@export var p1_or_p2 : int
@export var player_colour : Color
@export var outline : NinePatchRect
var mobile = false
var controller := false
var controller_id := 0


# puppet master that controls the instance
var puppet_master: set = onPuppetMasterChange
var is_removed = false
var prior_button : Button 
@export var selected_button : BaseButton : set = onSelectedButtonChanged

var selected_character = "" : set = onSelectedCharacterChanged;
@onready var multiplayer_lobby = get_parent().get_parent()
func _ready():
	
	$NetworkVarSync.multiplayer_id = multiplayer.get_unique_id()
	name_line_edit.placeholder_text = "Player %s" % p1_or_p2
	
	outline.self_modulate = player_colour
	selected_button = selected_button
	pass
	
func _process(delta):
	if is_instance_valid(puppet_master):
		var device_text = "Keyboard"
		if puppet_master.mobile:
			device_text = "Mobile"
		elif puppet_master.controller:
			device_text = "Controller"
		
		if !puppet_master.network_node.is_local_player:
			for child in alphabet_grid.get_children():
				child.visible = false
		
			disconnect_button.visible = false
			type_here_label.text = "REMOTE PLAYER - %s" %device_text
			name_line_edit.editable = false
		else:
			type_here_label.text = "LOCAL PLAYER - %s" %device_text	
	if !Relayconnect.IS_HOST:
		return
	if !is_instance_valid(puppet_master) and !is_removed:
		puppet_master = null
		multiplayer_lobby.remove_lobby_player(p1_or_p2)
		is_removed = true
		

func onPuppetMasterChange(new_puppet_master):
	print(new_puppet_master)
	if is_instance_valid(puppet_master):
		puppet_master.CharacterSelectedChangedSignal.disconnect(onSelectedCharacterChanged)
		puppet_master.remove_from_group("in_game")
		puppet_master.remove_from_group("p1")
		puppet_master.remove_from_group("p2")

	puppet_master = new_puppet_master
	
	
	if puppet_master == null:
		selected_character = ""
		for child in alphabet_grid.get_children():
			child.visible = false
		
		type_here_label.text = "NO PLAYER"
		name_line_edit.editable = false
		name_line_edit.text = ""
		return
	
	
	is_removed = false
	puppet_master.CharacterSelectedChangedSignal.connect(onSelectedCharacterChanged)
	selected_character = puppet_master.character_selected
	controller_id = puppet_master.device_id
	controller = puppet_master.controller
	mobile = puppet_master.mobile
	name_line_edit.text = puppet_master.player_name
	name_line_edit.text_changed.emit(name_line_edit.text)
	
	
	$NetworkVarSync.owner_id = puppet_master.network_node.owner_id
	
	
	var device_text = "Keyboard"
	if mobile:
		device_text = "Mobile"
	elif controller:
		device_text = "Controller"
		
	# If not owned by the local computer then disable text input
	if !puppet_master.network_node.is_local_player:
		for child in alphabet_grid.get_children():
			child.visible = false
	
		disconnect_button.visible = false
		type_here_label.text = "REMOTE PLAYER - %s" %device_text
		name_line_edit.editable = false
		return
	
	type_here_label.text = "LOCAL PLAYER - %s" %device_text
	# If local player setup keybaord
	if controller:
		for child in alphabet_grid.get_children():
			child.visible = true
	else:
		for child in alphabet_grid.get_children():
			child.visible = false
	
	if mobile:
		outline.visible = false
		disconnect_button.visible = false
	else:
		outline.visible = true
		disconnect_button.visible = true

	name_line_edit.editable = true


	
	
	
func _input(event):
	# If controller owned then take input move location in the virtual keybaord
	# have to set the focus neighbours in editor
	if !$NetworkVarSync.is_local_player or puppet_master == null:
		return
		
	if controller and event.device == controller_id:
		match event.get_class():
			"InputEventJoypadButton":
				if event.pressed:
					match event.button_index:
						JOY_BUTTON_DPAD_DOWN:
							move_button(SIDE_BOTTOM)
						JOY_BUTTON_DPAD_UP:
							move_button(SIDE_TOP)
						JOY_BUTTON_DPAD_LEFT:
							move_button(SIDE_LEFT)
						JOY_BUTTON_DPAD_RIGHT:
							move_button(SIDE_RIGHT)
						JOY_BUTTON_A:
							buttonPressed()
						JOY_BUTTON_B:
							if !name_line_edit.text.is_empty():
								name_line_edit.text = name_line_edit.text.left(name_line_edit.text.length() - 1)
								name_line_edit.text_changed.emit(name_line_edit.text)
	elif event.device == controller_id:
		
		match event.get_class():
			"InputEventKey":
				var key = OS.get_keycode_string(event.keycode)
				print(key)
				if event.echo:
					return
				if !event.pressed:
					return
				match event.keycode:
					KEY_DOWN:
						move_button(SIDE_BOTTOM)
					KEY_UP:
						move_button(SIDE_TOP)
					KEY_LEFT:
						move_button(SIDE_LEFT)
					KEY_RIGHT:
						move_button(SIDE_RIGHT)
					KEY_ENTER:
						buttonPressed()

										
	
func move_button(direction_enum):
	var button_to_check = selected_button.find_valid_focus_neighbor(direction_enum)
	
	if button_to_check == null:
		return
	
	if (button_to_check.get_parent().get_parent().name == "Player1" and p1_or_p2 == 2) or\
	(button_to_check.get_parent().get_parent().name == "Player2" and p1_or_p2 == 1):
		return
		
	if not (button_to_check is BaseButton):
		return
	
	selected_button = button_to_check
	
func buttonPressed():
	if selected_button.visible == false or selected_button.disabled == true:
		return
	match selected_button.name:
		"A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R",\
		"S","T","U","V","W","X","Y","Z":
			name_line_edit.text += selected_button.text
			name_line_edit.text_changed.emit(name_line_edit.text)
		"BACK":
			name_line_edit.text = name_line_edit.text.left(name_line_edit.text.length() - 1)
			name_line_edit.text_changed.emit(name_line_edit.text)
		"fire_knight":
			for node : Puppet_Master in get_tree().get_nodes_in_group("puppet_masters"):
				if node.network_node.is_local_player and node.player_number \
				and node.device_id == controller_id and node.controller == controller :
					node.character_selected = "fire_knight"
		_:
			selected_button.button_down.emit()

			
func onSelectedButtonChanged(new_button):
	if !(new_button is BaseButton):
		return
	if selected_button != null:
		selected_button.remove_child(outline)
	
	selected_button = new_button
	selected_button.add_child(outline)
	outline.global_position = selected_button.global_position
	outline.size = selected_button.size


func onSelectedCharacterChanged(new_character_name):
	selected_character = new_character_name
	if selected_character == "fire_knight":
		$SelectedCharacter.texture = load("res://Assets/fire_knight/FireKnightSelection.png")
	else:
		$SelectedCharacter.texture = load("res://Assets/fire_knight/NoSelected.png")
	
func _on_line_edit_text_changed(new_text : String):
	print(new_text.strip_edges().is_empty())
	if new_text.strip_edges().is_empty():
		puppet_master.player_name = "Player %s" % p1_or_p2
	else:
		puppet_master.player_name = new_text


func _on_disconnect_button_button_down():
	await get_tree().create_timer(0.1).timeout
	multiplayer_lobby.remove_lobby_player(p1_or_p2)

	
			
