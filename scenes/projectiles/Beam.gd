extends Area2D

var damage = 100
# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func destroy():
	pass # enemy collision doesn't destroy hyper beams


func _on_VisibilityNotifier2D_screen_entered():
	$CollisionShape2D.set_deferred("disabled", false)


func _on_VisibilityNotifier2D_screen_exited():
	$CollisionShape2D.set_deferred("disabled", true)
