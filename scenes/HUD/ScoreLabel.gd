extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass
	
func start():
	$TweenRise.interpolate_property(self, "position:y", null, position.y - 20, 1, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	$TweenRise.start()

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_TweenRise_tween_completed(_object, _key):
	queue_free()
