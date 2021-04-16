extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var rotation_speed = 2

var scale_speed = .6
var scale_down = false
var scale_max = 1.125
var scale_min = .875


# Called when the node enters the scene tree for the first time.
func _ready():
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	rotation += rotation_speed * delta 
	
	if scale_down:
		scale.x -= scale_speed * delta
		scale.y -= scale_speed * delta
		if scale.x < scale_min: 
			scale_down = false
	else:
		scale.x += scale_speed * delta
		scale.y += scale_speed * delta
		if scale.x > scale_max: 
			scale_down = true
		
	
	
