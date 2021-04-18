extends Control

var health = 0 setget update_health
var score = 0 setget update_score
var shield = 0 setget update_shield
var charge = 0 setget update_charge
var powerup = 0 setget update_powerup
var abilities = 0 setget update_abilities
var count = 0 setget update_enemy_count
var message = "" setget show_message

onready var scoreUI = $HUDContainer/HeaderContainer/Score
onready var fpsUI = $HUDContainer/HeaderContainer/FPS
onready var countUI = $HUDContainer/HeaderContainer/Count
onready var messageUI = $HUDContainer/FooterContainer/Message


func update_score(score):
	scoreUI.text = "Score: " + str(score) 
	
func update_fps():
	fpsUI.text = "FPS: " + str(Engine.get_frames_per_second())
	 
func update_enemy_count(enemy_count):
	$HUDContainer/HeaderContainer/Count.text = "Count: " + str(enemy_count) 
	 
func update_health(health):
	$HUDContainer/HeaderContainer/Health.text = "Health: " + str(health) 
	
func update_charge(charge):
#	$HUDContainer/HeaderContainer/Health.text = "Health: " + str(health) 
	pass
	
func update_powerup(powerup):
#	$HUDContainer/HeaderContainer/Health.text = "Health: " + str(health) 
	pass
	
func update_abilities(abilities):
#	$HUDContainer/HeaderContainer/Health.text = "Health: " + str(health) 
	pass
	
func update_shield(shield):
#	$HUDContainer/HeaderContainer/Health.text = "Health: " + str(health) 
	pass
	
func show_message(message):
	$HUDContainer/FooterContainer/Message.text = str(message)

# Called when the node enters the scene tree for the first time.
func _ready():
	self.health = PlayerManager.health
	self.shield = PlayerManager.shield
	self.charge = PlayerManager.charge
	self.powerup = PlayerManager.powerup
	self.abilities = PlayerManager.abilities


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	update_fps()
