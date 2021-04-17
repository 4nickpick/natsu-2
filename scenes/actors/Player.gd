extends KinematicBody2D

signal shield_state_changed
signal charge_changed
signal shield_changed
signal health_changed
signal powerup_changed
signal died

var speed = 400
var velocity = Vector2()
var health = 5

# shield
var shield = 100
var shieldDepletionRate = 50
var shieldRestorationRate = 50
var state = State.DEFAULT
var shieldState = null

# charge shot
var charge = 0
var chargeBuildRate = 100
var chargeMultiplier = 1

# heat seeking
var heatSeekingIndex = 0

var currentBullet = null # bullet before its released
var bullets = []

var abilities = [
	Abilities.SHIELD,
	Abilities.CHARGE_SHOT,
	Abilities.HEAT_SEEKING
]

var powerup = null

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
const Hyper = preload("res://scenes/projectiles/HyperBeam.tscn")

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
		construct_current_bullet()
				
	if Input.is_action_just_released("player_action1"):
		shoot()
	elif Input.is_action_pressed("player_action1"):
		if abilities.find(Abilities.CHARGE_SHOT):
			build_charge(delta)
		
	if abilities.find(Abilities.SHIELD) > -1:
		if Input.is_action_pressed("player_action2"):
			$AnimatedSprite.animation = "intimidate"
			if Input.is_action_just_pressed("player_action2"):
				setShieldState(ShieldState.PERFECT)
			elif $Shield/PerfectDetectionTimer.is_stopped() and $Shield/PerfectCooldownTimer.is_stopped():
				setShieldState(ShieldState.ACTIVE)
				
		elif $Shield/PerfectDetectionTimer.is_stopped() and $Shield/PerfectCooldownTimer.is_stopped():
			setShieldState(ShieldState.INACTIVE)
			state = State.DEFAULT
		
		if Input.is_action_just_released("player_action2"):
			$AnimatedSprite.animation = "default"
			
	
	if abilities.find(Abilities.HEAT_SEEKING) > -1 and currentBullet:
		var startingHeatSeekingIndex = heatSeekingIndex
		var enemies = get_tree().get_nodes_in_group("enemies")
		enemies = filter_dead_enemies(enemies)
		
		enemies.sort_custom(self, "sort_enemies")
		if currentBullet.heat_seeking:
			if enemies.size() > 0: 
				if(Input.is_action_just_released("player_reticle_control_wheel_up")
						or Input.is_action_just_pressed("player_reticle_control_up")):
					heatSeekingIndex += 1
					if heatSeekingIndex > enemies.size() - 1:
						heatSeekingIndex = 0
					
				if(Input.is_action_just_released("player_reticle_control_wheel_down")
						or Input.is_action_just_pressed("player_reticle_control_down")):
					heatSeekingIndex -= 1
					if heatSeekingIndex < 0:
						heatSeekingIndex = enemies.size() - 1
				
				if heatSeekingIndex != startingHeatSeekingIndex:
					currentBullet.set_heat_seeking(enemies[heatSeekingIndex])
			else:
				currentBullet.set_heat_seeking(null)
	
func construct_current_bullet():
	if powerup == PowerUps.HYPER: # there's no point in shooting at this point
		return
	currentBullet = Echo.instance()
	currentBullet.set_origin("player")
	currentBullet.global_position = $ProjectileSpawner.global_position
	currentBullet.passiveVelocity = Vector2(0, 0)
	currentBullet.activeVelocity = Vector2(1, 0)
	owner.add_child(currentBullet)		
	
func update_current_bullet():
	if powerup == PowerUps.HYPER:
		return
			
	if abilities.find(Abilities.CHARGE_SHOT) > -1 and currentBullet:
		if charge > 0:
			chargeMultiplier = (charge / 100.0) + 1 
			currentBullet.scale = Vector2(chargeMultiplier, chargeMultiplier) 
			
		if not currentBullet.active or currentBullet.is_missile: 
			currentBullet.global_position = $ProjectileSpawner.global_position
	
	
func shoot():
	if powerup == PowerUps.HYPER:
		pass
		
	if abilities.find(Abilities.CHARGE_SHOT) > -1 and currentBullet:
		if charge == 100:
			currentBullet.invincible = true
			currentBullet.activeVelocity *= 1.4
			
		currentBullet.damage *= chargeMultiplier	
		charge = 0
		chargeMultiplier = 1
		emit_signal("charge_changed")
		
	if abilities.find(Abilities.HEAT_SEEKING) > -1:
		heatSeekingIndex = 0
	
	# release the bullet	
	if currentBullet: 
		currentBullet.active = true
	
		if !currentBullet.heat_seeking:
			if powerup == PowerUps.BURST or powerup == PowerUps.BURST_ANGLED:
				var currentBulletUp = currentBullet.copy()
				currentBulletUp.global_position.y = currentBullet.global_position.y - 30
				if powerup == PowerUps.BURST_ANGLED:
					currentBulletUp.activeVelocity = currentBulletUp.activeVelocity.rotated(-.25)
				owner.add_child(currentBulletUp)
				bullets.push_back(currentBulletUp)
				
				var currentBulletDown = currentBullet.copy()
				currentBulletDown.global_position.y = currentBullet.global_position.y + 30
				if powerup == PowerUps.BURST_ANGLED:
					currentBulletDown.activeVelocity = currentBulletDown.activeVelocity.rotated(.25)
				owner.add_child(currentBulletDown)
				bullets.push_back(currentBulletDown)
			
		bullets.push_back(currentBullet) 
		currentBullet = null
		
		
func sort_enemies(a, b):
	if a.global_position.x <= global_position.x and b.global_position.x > global_position.x:
		return false
		
	if a.global_position.x > global_position.x and b.global_position.x <= global_position.x:
		return true
		
	if(a.global_position.x < b.global_position.x):
		return true
		
	return false
	
func filter_dead_enemies(list: Array):
	var filtered: Array = []
	for element in list:
		if element.health > 0 and element.position.x > 40:
			filtered.append(element)
			
	return filtered 
	
		
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
	
	if abilities.find(Abilities.HEAT_SEEKING) > -1:
		if charge > 10 and currentBullet: 
			var enemies = get_tree().get_nodes_in_group("enemies")
			enemies = filter_dead_enemies(enemies)
			if enemies.size() > 0:
				enemies.sort_custom(self, "sort_enemies")
				currentBullet.set_heat_seeking(enemies[0])
	
	if charge != startingCharge:
		emit_signal("charge_changed")
		
func construct_hyper_beam():
	$AnimatedSprite.animation = "intimidate"
	if powerup == PowerUps.HYPER:
		var h = Hyper.instance()
		h.position = $ProjectileSpawner.position
		add_child(h)
		
func deconstruct_hyper_beam():
	var h = get_node("HyperBeam")
	if h:
		$AnimatedSprite.animation = "default"
		h.queue_free()
	
# Called when the node enters the scene tree for the first time.
func _ready():
	setShieldState(ShieldState.INACTIVE)
	emit_signal("health_changed")
	add_to_group("player")
	
	construct_hyper_beam()
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):	
	get_input(delta)
	
	if abilities.find(Abilities.SHIELD) > -1:
		adjust_shield_charge(delta)
	
func _physics_process(delta):
	var collision = move_and_collide(velocity * delta)
	
	if collision:
		if collision.collider.is_in_group("enemies"):
			if collision.collider.health > 0:
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
		set_collision_mask_bit(1, false)
		set_collision_mask_bit(3, false)
		$AnimatedSprite.modulate = Color.red
		$AnimatedSprite.play("hit")
		deconstruct_hyper_beam()
		
		# interrupt charge shot
		if currentBullet != null:
			currentBullet.queue_free()
			currentBullet = null
			
		charge = 0
		chargeMultiplier = 1
		heatSeekingIndex = 0
		
		if health <= 0:
			kill()
		
	return is_vulnerable
	
	
func setShieldState(newShieldState):
	if shieldState == newShieldState:
		return 
		
	if newShieldState == ShieldState.ACTIVE and shieldState == ShieldState.INACTIVE and shield == 0:
		return 
	
	shieldState = newShieldState
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
	set_collision_mask_bit(1, true)
	set_collision_mask_bit(3, true)
	
	
func _on_Area2D_area_entered(area):
	if area.is_in_group("enemy_projectiles"):
		if take_damage(area.damage):
			area.destroy()
	
	elif area.is_in_group("powerups"):
		if $PowerupTimer.is_stopped():
			powerup = PowerUps.BURST if area.type == 1 else PowerUps.HYPER 
			
			if powerup == PowerUps.HYPER:
				construct_hyper_beam()
				
			$PowerupTimer.start()
			emit_signal("powerup_changed")
			area.destroy()
		

func _on_ActiveHitBox_area_entered(area):
	if area.is_in_group("enemy_projectiles"):
		area.destroy()
	pass # Replace with function baody.


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
		

func _on_PowerupTimer_timeout():
	powerup = null
	deconstruct_hyper_beam()
	emit_signal("powerup_changed")
