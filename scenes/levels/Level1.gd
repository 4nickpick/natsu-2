extends Node2D

# Called when the node enters the scene tree for the first time.
func _ready():
# load enemy list from json 

#	



# Called every frame. 'delta' is the elapsed time since0 the previous frame.
func _process(_delta):
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit() 
	
	if Input.is_action_just_pressed("debug_restart"):
		get_tree().change_scene("res://scenes/levels/Level1.tscn") 
