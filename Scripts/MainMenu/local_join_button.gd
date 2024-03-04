extends Control

var ip 
var room_code

# Called when the node enters the scene tree for the first time.
func _ready():
	$RichTextLabel.text = room_code
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_join_button_button_down():
	Relayconnect.local_join(ip,room_code)
	pass # Replace with function body.


func _on_timer_timeout():
	queue_free()
	pass # Replace with function body.
