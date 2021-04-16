extends Area2D

var speed = 50
var powerupType = 1


# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	powerupType = randi() % 3 + 1
	
	if powerupType == 1:
		modulate = Color.red
		
	if powerupType == 2:
		modulate = Color.green
		


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	position.x -= speed * delta
	
func destroy():
	queue_free()
