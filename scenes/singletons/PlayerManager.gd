extends Node

#signal rotation_changed

enum Abilities {
	CHARGE_SHOT = 0,
	SHIELD = 1,
	HEAT_SEEKING = 2
}

enum PowerUps {
	BURST = 1,
	BURST_ANGLED = 2,
	HYPER = 3,
}

enum State {
	DEFAULT = 0,
	SHIELD = 1,
	DAMAGED = 2,
	DEAD = 3
}


enum ShieldState {
	INACTIVE = 1,
	ACTIVE = 2,
	PERFECT = 3
}

onready var state = State.DEFAULT setget set_state
signal state_changed

onready var health = 3 setget set_health
signal health_changed 

onready var charge = 0 setget set_charge
signal charge_changed(value)

onready var shield = 100 setget set_shield
signal shield_changed

onready var powerup = null setget set_powerup
signal powerup_changed

onready var abilities = [] setget set_abilities
signal abilities_changed 

onready var position = 0 setget set_position


func set_state(value):
	state = value
	emit_signal("state_changed", value)

func set_health(value):
	health = value
	emit_signal("health_changed", value)
	
func set_charge(value):
	charge = value
	emit_signal("charge_changed", value)
	
func set_shield(value):
	shield = value
	emit_signal("shield_changed", value)

func set_powerup(value):
	powerup = value
	emit_signal("powerup_changed", value)

func set_abilities(value):
	abilities = value
	emit_signal("abilities_changed", value)
	
func set_position(value):
	position = value

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
