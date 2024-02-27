extends Node
class_name State

var change_state
var persistent_state

func setup(change_state, persistent_state):
	self.change_state = change_state
	self.persistent_state = persistent_state
	
func exit():
	pass
