extends Area2D

export var health = 4
export var point_value = 100

const ScoreLabel = preload("res://scenes/HUD/ScoreLabel.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.
	
	
func kill():	
	set_collision_layer_bit(1, false)
	health = 0
	
	$CollisionShape2D.set_deferred("disabled", true)
		
	$AnimatedSprite.self_modulate = Color(127, 0, 0, 127)
	$AnimatedSprite.play("dead")	
	var timer = Timer.new()
	timer.connect("timeout", self, "_on_timer_timeout")
	timer.wait_time = 1
	timer.one_shot = true
	add_child(timer)
	timer.start()
	
	PlayerManager.score += point_value
	var scoreLabel = ScoreLabel.instance()
	get_tree().get_root().add_child(scoreLabel)
	scoreLabel.position = get_parent().get_parent().position
	scoreLabel.get_node("Label").text = "+" + str(point_value)
	scoreLabel.start()


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _on_timer_timeout():
	$AnimatedSprite.visible = false
