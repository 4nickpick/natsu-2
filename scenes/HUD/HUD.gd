extends Control

onready var scoreUI = $HUDContainer/HeaderContainer/Score
onready var fpsUI = $HUDContainer/HeaderContainer/FPS
onready var countUI = $HUDContainer/HeaderContainer/Count
onready var messageUI = $HUDContainer/FooterContainer/Message


func update_score(value):
	scoreUI.text = "Score: " + str(value) 
	
func update_fps():
	fpsUI.text = "FPS: " + str(Engine.get_frames_per_second())
	 
func update_enemy_count(value):
	$HUDContainer/HeaderContainer/Count.text = "Count: " + str(value) 
	 
func update_health(value):
	$HUDContainer/HeaderContainer/Health.text = "Health: " + str(value) 
	
func update_charge(value):
	$HUDContainer/HeaderContainer/Count.text = "Charge: " + "%.2f" % value
	pass
	
func update_powerup(value):
#	$HUDContainer/HeaderContainer/Health.text = "Health: " + str(health) 
	pass
	
func update_abilities(value):
#	$HUDContainer/HeaderContainer/Health.text = "Health: " + str(health) 
	pass
	
func update_shield(value):
#	$HUDContainer/HeaderContainer/Health.text = "Health: " + str(health) 
	pass
	
func show_message(message):
	$HUDContainer/FooterContainer/Message.text = str(message)

# Called when the node enters the scene tree for the first time.
func _ready():	
	PlayerManager.connect("health_changed", self, "update_health")
	PlayerManager.connect("shield_changed", self, "update_shield")
	PlayerManager.connect("charge_changed", self, "update_charge")
	PlayerManager.connect("powerup_changed", self, "update_powerup")
	PlayerManager.connect("abilities_changed", self, "update_abilities")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	update_fps()
