extends CanvasLayer


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

func update_score(score):
	$HUDContainer/HeaderContainer/Score.text = "Score: " + str(score) 
	
func update_fps(fps):
	$HUDContainer/HeaderContainer/FPS.text = "FPS: " + str(fps)
	 
func update_enemy_count(enemy_count):
	$HUDContainer/HeaderContainer/Count.text = "Count: " + str(enemy_count) 
	 
func update_health(health):
	$HUDContainer/HeaderContainer/Health.text = "Health: " + str(health) 
	
func show_message(message, spelled = true):
	$HUDContainer/FooterContainer/Message.text = str(message)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _on_FPSTimer_timeout():
	update_fps(Engine.get_frames_per_second())
