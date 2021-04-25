extends "res://scenes/actors/Enemy.gd"

var phases 

# Called when the node enters the scene tree for the first time.
func _ready():
	position = Vector2(1100, 500)
	velocity = Vector2(0, 0)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
func kill():
	.kill()
	PlayerManager.level_complete()
	pass
