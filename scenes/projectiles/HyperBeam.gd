extends Area2D

var numBeams = 1
var damage = 100
var targetNumBeams = 35


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

func destroy():
	pass # hyper beam will be dequeued manually by Player class

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	scale = scale * 2/3
			
	return 


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_VisibilityNotifier2D_screen_exited():
	$CollisionShape.set_deferred("disabled", true)
	
func _on_VisibilityNotifier2D_screen_entered():
	$CollisionShape.set_deferred("disabled", false)


func _on_BeamGeneratorTimer_timeout():
	var beam = $Beams/Beam

	# duplicate beams to disable / enable as they reach the edge of the screen
	var beamDelta = targetNumBeams - numBeams
	
	# generate beams
	if beamDelta > 0:
		var b = beam.duplicate(14)
		var shape = b.get_node("CollisionShape2D")
		var transform = shape.shape
		var extents = transform.extents
		b.position.x += extents.x * numBeams
		$Beams.add_child(b)
		numBeams += 1
	else:
		$BeamGeneratorTimer.autostart = false
		$BeamGeneratorTimer.stop()
