extends Control

# Declare member variables here. Examples:
# var a = 2
# var b = "text"
onready var loading_animated_sprite = $Loading/SpriteContainer/AnimatedSprite

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	SceneManager.setViewport($ViewportContainer/Viewport)
	
	var _error = LevelManager.connect("level_loading_progress", self, "level_loading_progress")
	_error = LevelManager.connect("level_loading_started", self, "level_loading_started")
	_error = LevelManager.connect("level_loaded", self, "level_loaded")
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func level_loading_progress(value):
	$Loading/CenterContainer/VBoxContainer/ProgressBar.value = value

func level_loading_started(value):
	$Backdrop/Tween.interpolate_property($Backdrop, "color", Color(0, 0, 0, 0), Color(0, 0, 0, 1), $Loading/DelayInTimer.wait_time, Tween.TRANS_LINEAR, Tween.EASE_IN)
	$Backdrop/Tween.start()
	$Loading/DelayInTimer.start()
	$Loading/CenterContainer/VBoxContainer/LevelLabel.text = "Level " + str(value) + ": Sunlight Zone "
	
	var animations = loading_animated_sprite.frames.get_animation_names()
	var animation_id = randi() % animations.size()
	var animation_name = animations[animation_id]
	loading_animated_sprite.play(animation_name)
	
func level_loaded():
	$Backdrop/Tween.interpolate_property($Backdrop, "color", Color(0, 0, 0, 1), Color(0, 0, 0, 0), $Loading/DelayOutTimer.wait_time, Tween.TRANS_LINEAR, Tween.EASE_IN)
	$Backdrop/Tween.start()
	$Loading/DelayOutTimer.start()
	get_tree().paused = false
	$Loading/SpriteContainer.hide()
	$Loading/CenterContainer.hide()
	pass

func _on_Loading_DelayInTimer_timeout():
	$Loading.show()
	SceneManager.goto_scene("res://scenes/levels/Level"+ str(LevelManager.current_level) +".tscn")
	
func _on_Loading_DelayOutTimer_timeout():
	$Loading.hide()
	LevelManager.scene_transitioned()
	$Loading/SpriteContainer.show()
	$Loading/CenterContainer.show()

