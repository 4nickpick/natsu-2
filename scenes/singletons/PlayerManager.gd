extends Node

enum Abilities {
	CHARGE_SHOT = 0,
	SHIELD = 1,
	HEAT_SEEKING = 2,
#	MISSILE = 4 # splash
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

var state = State.DEFAULT
var health = 3
var charge = 0
var shield = 100
var powerup = null 
var abilities = []

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
