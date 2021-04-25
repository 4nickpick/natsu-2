extends CanvasLayer

onready var scoreUI = $HUD/UI/Score
onready var fpsUI = $HUD/UI/FPS
onready var countUI = $HUD/UI/Count
onready var chargeUI = $HUD/UI/ChargeProgress
onready var shieldUI = $HUD/UI/ShieldProgress
onready var healthUI = $HUD/UI/HealthProgress
#onready var messageUI = $HUD/HUDContainer/FooterContainer/Message

func pause_menu_show():
	$PauseMenu.show()
	$Backdrop.color = Color(0, 0, 0, .5)
	
func pause_menu_hide():
	$PauseMenu.hide()
	$Backdrop.color = Color(0, 0, 0, 0)
	
func game_over_menu_show():
	$Backdrop/Tween.interpolate_property($Backdrop, "color", Color(0, 0, 0, 0), Color(0, 0, 0, .5), 3, Tween.TRANS_LINEAR, Tween.EASE_IN)
	$Backdrop/Tween.start()
	$GameOverMenu/DelayTimer.start()
	
func game_over_menu_hide():
	$GameOverMenu.hide()
	$Backdrop.color = Color(0, 0, 0, 0)
	
func level_complete_menu_show():
	$Backdrop/Tween.interpolate_property($Backdrop, "color", Color(0, 0, 0, 0), Color(0, 0, 0, .5), 3, Tween.TRANS_LINEAR, Tween.EASE_IN)
	$Backdrop/Tween.start()
	$VictoryMenu/DelayTimer.start()
	
func level_complete_menu_hide():
	$GameOverMenu.hide()
	$Backdrop.color = Color(0, 0, 0, 0)
	
	
func update_score(value):
	scoreUI.text = "Score: " + str(value) 
	
func update_fps():
	fpsUI.text = "FPS: " + str(Engine.get_frames_per_second())
	 
func update_enemy_count(value):
	countUI.text = "Count: " + str(value) 
	 
func update_health(value):
	healthUI.value = value
	
func update_gameover(value):
	$Backdrop.color = Color(0, 0, 0, .5)
	$GameOverMenu.show()
	
func update_charge(value):
	chargeUI.value = value
	
func update_rotation(value):
#	$HUD/HUDContainer/FooterContainer/Count.text = str(value)
	pass
	
func update_powerup(value):
#	$HUDContainer/FooterContainer/Health.text = "Health: " + str(health) 
	pass
	
func update_abilities(value):
#	$HUDContainer/FooterContainer/Health.text = "Health: " + str(health) 
	pass
	
func update_shield(value):
	shieldUI.value = value
	pass
	
func show_message(message):
	$HUD/UI/Message.text = str(message)
	pass

# Called when the node enters the scene tree for the first time.
func _ready():	
	PlayerManager.connect("score_changed", self, "update_score")
	PlayerManager.connect("health_changed", self, "update_health")
	PlayerManager.connect("shield_changed", self, "update_shield")
	PlayerManager.connect("charge_changed", self, "update_charge")
	PlayerManager.connect("powerup_changed", self, "update_powerup")
	PlayerManager.connect("abilities_changed", self, "update_abilities")
	PlayerManager.connect("died", self, "game_over_menu_show")
	PlayerManager.connect("level_complete", self, "level_complete_menu_show")
#	PlayerManager.connect("rotation_changed", self, "update_rotation")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	update_fps()
	
func _input(event):
	if PlayerManager.health > 0:
		if event.is_action_pressed("ui_cancel"):
			if get_tree().paused == false:
				get_tree().paused = true
				pause_menu_show()
			else:
				pause_menu_hide()
				get_tree().paused = false


func _on_UnpauseButton_pressed():
	pause_menu_hide()
	get_tree().paused = false

func _on_RestartLevelButton_pressed():
	pause_menu_hide()
	game_over_menu_hide()
	get_tree().paused = false
	SceneManager.goto_scene("res://scenes/levels/Level1.tscn") 

func _on_QuitButton_pressed():
	pause_menu_hide()
	game_over_menu_hide()
	get_tree().paused = false
	SceneManager.goto_scene("res://scenes/Main.tscn") 



func _on_Tween_tween_completed(object, key):
	pass


func _on_GameOverMenu_DelayTimer_timeout():
	$GameOverMenu.show()


func _on_VictoryMenu_DelayTimer_timeout():
	$VictoryMenu.show()
