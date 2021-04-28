extends CanvasLayer

onready var scoreUI = $HUD/UI/Score
onready var fpsUI = $HUD/UI/FPS
onready var countUI = $HUD/UI/Count
onready var livesUI = $HUD/UI/Lives
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
	$VictoryMenu/CenterContainer/VBoxContainer/LabelScore.text = "Score: " + str(PlayerManager.score)
	$VictoryMenu/CenterContainer/VBoxContainer/LabelHiScore.text = "Hi Score: " + str(PlayerManager.score)
	$VictoryMenu/CenterContainer/VBoxContainer/LabelRank.text = "Rank: C"
	$VictoryMenu/DelayTimer.start()
	
func level_complete_menu_hide():
	$VictoryMenu.hide()
	$Backdrop.color = Color(0, 0, 0, 0)

func level_start():
	$GameOverMenu/CenterContainer/VBoxContainer/RestartLevelButton.visible = true
	$VictoryMenu/DelayTimer.start()
	
func level_start_hide():
	$GameOverMenu.hide()
	$Backdrop.color = Color(0, 0, 0, 0)
	
func update_score(value):
	scoreUI.text = "Score: " + str(value) 
	
func update_lives(value):
	livesUI.text = "Lives: " + str(value) 
	if value <= 0:
		$GameOverMenu/CenterContainer/VBoxContainer/RestartLevelButton.visible = false
		
	game_over_menu_show()
	
func update_fps():
	fpsUI.text = "FPS: " + str(Engine.get_frames_per_second())
	 
func update_enemy_count(value):
	countUI.text = "Count: " + str(value) 
	 
func update_health(value):
	healthUI.value = value
#
#func update_gameover(value):
#	$Backdrop.color = Color(0, 0, 0, .5)
#	$GameOverMenu.show()
	
func update_charge(value):
	chargeUI.value = value
#
#func update_rotation(value):
##	$HUD/HUDContainer/FooterContainer/Count.text = str(value)
#	pass

func update_powerup(value):
	var labelText = "None"
	match value:
		PlayerManager.PowerUps.NONE:
			labelText = "None"
		PlayerManager.PowerUps.HYPER:
			labelText = "Hyper Beam"
		PlayerManager.PowerUps.BOMB:
			labelText = "Bomb"
		PlayerManager.PowerUps.BURST:
			labelText = "Burst"
		PlayerManager.PowerUps.BURST_ANGLED:
			labelText = "Burst v2"	
				
	countUI.text = "Powerup: " + labelText 
	pass

#func update_abilities(value):
##	$HUDContainer/FooterContainer/Health.text = "Health: " + str(health) 
#	pass
	
func update_shield(value):
	shieldUI.value = value
	pass
	
func show_message(message):
	$HUD/UI/Message.text = str(message)
	pass
	
func show_splash():
	$LevelStartDisplay/CenterContainer/VBoxContainer/LevelNameLabel.text = "LEVEL 1"
	$LevelStartDisplay/CenterContainer/VBoxContainer/LevelNumberLabel.text = "THE SUNLIGHT ZONE"
	$LevelStartDisplay/CenterContainer/VBoxContainer/HBoxContainer/Label.text = "x " + str(PlayerManager.lives)
	$LevelStartDisplay.show()
	$LevelStartDisplay/DelayTimer.start()
	pass


# Called when the node enters the scene tree for the first time.
func _ready():	
	var _error = PlayerManager.connect("score_changed", self, "update_score")
	_error = PlayerManager.connect("health_changed", self, "update_health")
	_error = PlayerManager.connect("shield_changed", self, "update_shield")
	_error = PlayerManager.connect("charge_changed", self, "update_charge")
	_error = PlayerManager.connect("lives_changed", self, "update_lives")
	_error = PlayerManager.connect("died", self, "game_over_menu_show")
	_error = PlayerManager.connect("powerup_changed", self, "update_powerup")
#	_error = PlayerManager.connect("abilities_changed", self, "update_abilities")
#	PlayerManager.connect("rotation_changed", self, "update_rotation")
	
	_error = LevelManager.connect("level_started", self, "show_splash")
	_error = LevelManager.connect("level_complete", self, "level_complete_menu_show")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	update_fps()
	
func _input(event):
	if PlayerManager.health > 0 and LevelManager.level_state == LevelManager.LevelState.RUNNING:
		if event.is_action_pressed("ui_cancel"):
			if get_tree().paused == false:
				get_tree().paused = true
				pause_menu_show()
			else:
				pause_menu_hide()
				get_tree().paused = false

func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_FOCUS_OUT:
		if PlayerManager.health > 0 and LevelManager.level_state == LevelManager.LevelState.RUNNING:
			if get_tree().paused == false:
				get_tree().paused = true
				pause_menu_show()

func _on_UnpauseButton_pressed():
	pause_menu_hide()
	get_tree().paused = false

func _on_RestartLevelButton_pressed():
	pause_menu_hide()
	game_over_menu_hide()
	level_complete_menu_hide()
	LevelManager.load_level(LevelManager.current_level)
	#unpause level later to avoid enemies from moving while new level loads

func _on_QuitButton_pressed():
	pause_menu_hide()
	game_over_menu_hide()
	level_complete_menu_hide()
	SceneManager.goto_scene("res://scenes/Main.tscn") 
	get_tree().paused = false

func _on_GameOverMenu_DelayTimer_timeout():
	$GameOverMenu.show()


func _on_VictoryMenu_DelayTimer_timeout():
	$VictoryMenu.show()

func _on_LevelStartDisplay_DelayTimer_timeout():
	$LevelStartDisplay.hide()
