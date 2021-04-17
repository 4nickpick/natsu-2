extends Area2D

var speed = 50
export var type = 1


# Called when the node enters the scene tree for the first time.
func _ready():
	
	if type == 1:
		modulate = Color.white
	
	if type == 2:
		modulate = Color.red
		
	if type == 3:
		modulate = Color.green
		


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	position.x -= speed * delta
	
func destroy():
	queue_free()
