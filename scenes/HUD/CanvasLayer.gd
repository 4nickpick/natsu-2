extends CanvasLayer

onready var scoreUI = $HUD/UI/Score
onready var healthUI = $HUD/UI/Health
onready var fpsUI = $HUD/UI/FPS
onready var countUI = $HUD/UI/Count
onready var chargeUI = $HUD/UI/ChargeProgress
onready var shieldUI = $HUD/UI/ShieldProgress
#onready var messageUI = $HUD/HUDContainer/FooterContainer/Message


func update_score(value):
	scoreUI.text = "Score: " + str(value) 
	
func update_fps():
	fpsUI.text = "FPS: " + str(Engine.get_frames_per_second())
	 
func update_enemy_count(value):
	countUI.text = "Count: " + str(value) 
	 
func update_health(value):
	healthUI.text = "Health: " + str(value) 
	
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
#	$HUD/HUDContainer/FooterContainer/Message.text = str(message)
	pass

# Called when the node enters the scene tree for the first time.
func _ready():	
	PlayerManager.connect("health_changed", self, "update_health")
	PlayerManager.connect("shield_changed", self, "update_shield")
	PlayerManager.connect("charge_changed", self, "update_charge")
	PlayerManager.connect("powerup_changed", self, "update_powerup")
	PlayerManager.connect("abilities_changed", self, "update_abilities")
#	PlayerManager.connect("rotation_changed", self, "update_rotation")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	update_fps()
	
func _input(event):
	if event.is_action_pressed("ui_cancel"):
		if get_tree().paused == false:
			get_tree().paused = true
			$PauseMenu.show()
		else:
			$PauseMenu.hide()
			get_tree().paused = false


func _on_UnpauseButton_pressed():
	$PauseMenu.hide()
	get_tree().paused = false

func _on_RestartLevelButton_pressed():
	$PauseMenu.hide()
	get_tree().paused = false
	SceneManager.goto_scene("res://scenes/levels/Level1.tscn") 

func _on_QuitButton_pressed():
	$PauseMenu.hide()
	get_tree().paused = false
	SceneManager.goto_scene("res://scenes/Main.tscn") 

	
