extends KinematicBody2D

signal shield_state_changed
signal charge_changed
signal shield_changed
signal health_changed
signal died

var speed = 400
var velocity = Vector2()
var health = 5

# shield
var shield = 100
var shieldDepletionRate = 50
var shieldRestorationRate = 50
var state = State.DEFAULT
var shieldState = ShieldState.INACTIVE

# charge shot
var charge = 0
var chargeBuildRate = 100

var currentBullet = null # bullet before its released

var abilities = [
	Abilities.SHIELD,
#	Abilities.CHARGE_SHOT,
	Abilities.HEAT_SEEKING
]

var powerup = null 

enum Abilities {
	CHARGE_SHOT = 0,
	SHIELD = 1,
	HEAT_SEEKING = 2,
	BURST = 3,
	HYPER = 4,
	MISSILE = 5
}

enum PowerUps {
	FastProjectiles = 0,
	PowerProjectiles = 1,
	PermaShield = 2
}

enum State {
	DEFAULT = 0,
	SHIELD = 1,
	DAMAGED = 2,
	DEAD = 3
}

enum CollisionMaskLayers {
	PLAYER = 0,
	ENEMIES = 1, 
	PROJECTILES_PLAYER = 2,
	PROJECTILES_ENEMY = 3,
	BOUNDARIES = 4
}

enum ShieldState {
	INACTIVE = 1,
	ACTIVE = 2,
	PERFECT = 3
}

const Echo = preload("res://scenes/projectiles/Echo.tscn")

func get_input(delta):
	velocity = Vector2()
	if Input.is_action_pressed("player_right"):
		velocity.x += 1
	if Input.is_action_pressed("player_left"):
		velocity.x -= 1
	if Input.is_action_pressed("player_down"):
		velocity.y += 2
	if Input.is_action_pressed("player_up"):
		velocity.y -= 2
	velocity = velocity.normalized() * speed
	
	if Input.is_action_just_pressed("player_action1"):
		if $ProjectileSpawner/CooldownTimer.is_stopped() and currentBullet == null:
			construct_current_bullet()
				
	if Input.is_action_just_released("player_action1"):
		if $ProjectileSpawner/CooldownTimer.is_stopped():
			$ProjectileSpawner/CooldownTimer.start()
			shoot()
	elif Input.is_action_pressed("player_action1"):
		if abilities.find(Abilities.CHARGE_SHOT):
			if $ProjectileSpawner/CooldownTimer.is_stopped():
				build_charge(delta)
		
	if abilities.find(Abilities.SHIELD) > -1:
		if Input.is_action_pressed("player_action2"):
			if Input.is_action_just_pressed("player_action2"):
				setShieldState(ShieldState.PERFECT)
			elif $Shield/PerfectDetectionTimer.is_stopped() and $Shield/PerfectCooldownTimer.is_stopped():
				setShieldState(ShieldState.ACTIVE)
				
		elif shieldState != ShieldState.INACTIVE and $Shield/PerfectDetectionTimer.is_stopped() and $Shield/PerfectCooldownTimer.is_stopped():
			setShieldState(ShieldState.INACTIVE)
			state = State.DEFAULT
	
	
func construct_current_bullet():
	currentBullet = Echo.instance()
	currentBullet.set_origin("player")
#	currentBullet.position = Vector2($ProjectileSpawner/, $ProjectileSpawner.transform.y)
	currentBullet.passiveVelocity = Vector2(0, 0)
	currentBullet.activeVelocity = Vector2(1, 0)
	add_child(currentBullet)
	
func update_current_bullet():
	if abilities.find(Abilities.CHARGE_SHOT) > -1:
		if charge > 0:
			var multiplier = (charge / 100.0) + 1 
			currentBullet.damage *= multiplier
			currentBullet.scale *= multiplier 
	
	
func shoot():
	if abilities.find(Abilities.CHARGE_SHOT) > -1:
		if charge == 100:
			currentBullet.invincible = true
			currentBullet.velocity *= 1.4
			
		charge = 0
		emit_signal("charge_changed")
	
#	if abilities.find(Abilities.HEAT_SEEKING):
		# find default target
#		currentBullet.set_heat_seeking(null)
		
	# release the bullet	
	remove_child(currentBullet)
	owner.add_child(currentBullet)
	currentBullet.global_position = $ProjectileSpawner.global_position
	
#	currentBullet = null
		
		
func adjust_shield_charge(delta):
	var shieldCurrent = shield
	if Input.is_action_pressed("player_action2") or !$Shield/PerfectDetectionTimer.is_stopped():
		shield = shield - shieldDepletionRate * delta 
	else:
		if $Shield/RechargeDelayTimer.is_stopped():
			shield = shield + shieldRestorationRate * delta
		
	shield = clamp(shield, 0, 100)
	
	if shield != shieldCurrent:
		emit_signal("shield_changed")
		
	if shield <= 0:
		setShieldState((ShieldState.INACTIVE))
		
		
func build_charge(delta):
	var startingCharge = charge
	if Input.is_action_pressed("player_action1"):
		charge += chargeBuildRate * delta 
	else:
		charge = 0
		
	charge = clamp(charge, 0, 100)
	
	if charge != startingCharge:
		emit_signal("charge_changed")
	
# Called when the node enters the scene tree for the first time.
func _ready():
	setShieldState(ShieldState.INACTIVE)
	emit_signal("health_changed")
	add_to_group("player")
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):	
	get_input(delta)
	
	if abilities.find(Abilities.SHIELD) > -1:
		adjust_shield_charge(delta)
	
func _physics_process(delta):
	var collision = move_and_collide(velocity * delta)
	
	if collision:
		if collision.collider.is_in_group("enemies"):
			take_damage(1)
			collision.collider.kill()		
			
	update_current_bullet()
		
func take_damage(damage):
	var is_vulnerable = state == State.DEFAULT
	if is_vulnerable: 
		health -= damage
		emit_signal("health_changed")
		
		$HitCooldownTimer.start()	
		state = State.DAMAGED
		$HitBoxes/Area2D/CollisionShape2D.disabled = true
		$AnimatedSprite.modulate = Color.red
		$AnimatedSprite.play("hit")
		
		if health <= 0:
			kill()
		
	return is_vulnerable
	
	
func setShieldState(newShieldstate):
	shieldState = newShieldstate
	emit_signal("shield_state_changed")
		
	match shieldState:
		ShieldState.INACTIVE:
			state = State.DEFAULT
			$Shield/PerfectDetectionTimer.stop()
			$Shield/ActiveHitBox/CollisionShape2D.disabled = true
			$Shield/PerfectHitBox/CollisionShape2D.disabled = true
			$Shield/ActiveHitBox/Sprite.visible = false
			$Shield/PerfectHitBox/Sprite.visible = false
			$AnimatedSprite.animation = "default"
			if $Shield/RechargeDelayTimer.is_stopped():
				$Shield/RechargeDelayTimer.start()
		ShieldState.ACTIVE:
			state = State.SHIELD
			$Shield/ActiveHitBox/CollisionShape2D.disabled = false
			$Shield/PerfectHitBox/CollisionShape2D.disabled = true
			$Shield/ActiveHitBox/Sprite.visible = true
			$Shield/PerfectHitBox/Sprite.visible = false
			$AnimatedSprite.animation = "intimidate"
		ShieldState.PERFECT:
			state = State.SHIELD
			$Shield/PerfectDetectionTimer.start()
			$Shield/ActiveHitBox/CollisionShape2D.disabled = false
			$Shield/PerfectHitBox/CollisionShape2D.disabled = false
			$Shield/ActiveHitBox/Sprite.visible = true	
			$Shield/PerfectHitBox/Sprite.visible = false
			$AnimatedSprite.animation = "intimidate"
	
func kill():
		emit_signal("died")
		destroy()
	
	
func destroy():
	queue_free()
	
	
func _on_HitCooldownTimer_timeout():	
	state = State.DEFAULT
	$AnimatedSprite.modulate = Color.white
	$AnimatedSprite.play("default")
	$HitBoxes/Area2D/CollisionShape2D.disabled = false
	
	
func _on_Area2D_area_entered(area):
	if area.is_in_group("enemy_projectiles"):
		if take_damage(area.damage):
			area.destroy()
		

func _on_ActiveHitBox_area_entered(area):
	if area.is_in_group("enemy_projectiles"):
		area.destroy()
	pass # Replace with function body.


func _on_PerfectHitBox_area_entered(area):
	if area.is_in_group("enemy_projectiles"):
		$Shield/PerfectHitBox/Sprite.visible = true
		$Shield/PerfectCooldownTimer.start()
		$Shield/PerfectDetectionTimer.stop()
		area.reflect("player")
		
		shield -= 40
		emit_signal("shield_changed")
		

func _on_PerfectDetectionTimer_timeout():
	if Input.is_action_pressed("player_action2"):
		setShieldState(ShieldState.ACTIVE)
	else:
		setShieldState(ShieldState.INACTIVE)


func _on_PerfectCooldownTimer_timeout():
	$Shield/PerfectHitBox/Sprite.visible = false
	if Input.is_action_pressed("player_action2"):
		setShieldState(ShieldState.ACTIVE)
	else:
		setShieldState(ShieldState.INACTIVE)
	
