extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_StartButton_pressed():
	SceneManager.goto_scene("res://scenes/levels/Level1.tscn")


func _on_SettingsButton_pressed():
#	SceneManager.goto_scene("res://scenes/Settings.tscn")
	pass


func _on_QuitButton_pressed():
	get_tree().quit()