extends RichTextLabel


# Called when the node enters the scene tree for the first time.
func _ready():
	text = "[center]ROOM CODE : %s" %[Relayconnect.ROOM_CODE]
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
