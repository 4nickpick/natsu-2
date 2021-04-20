extends KinematicBody2D

signal died

var maxSpeed = 400
var speed = maxSpeed

var velocity = Vector2()

# health
onready var health = 4 setget set_health

# shield
onready var shield = 100 setget set_shield
var shieldDepletionRate = 50
var shieldRestorationRate = 50
var state = PlayerManager.State.DEFAULT
var shieldState = null

# charge shot
onready var charge = 0 setget set_charge
var chargeBuildRate = 100
var chargeMultiplier = 1
signal charge_changed(value)

# heat seeking
var heatSeekingIndex = 0

# active shot
var currentBullet = null # bullet before its released
var bullets = []

# abilities
onready var abilities = [
	PlayerManager.Abilities.SHIELD,
	PlayerManager.Abilities.CHARGE_SHOT,
	PlayerManager.Abilities.HEAT_SEEKING
] setget set_abilities

onready var powerup = null setget set_powerup

enum CollisionMaskLayers {
	PLAYER = 0,
	ENEMIES = 1, 
	PROJECTILES_PLAYER = 2,
	PROJECTILES_ENEMY = 3,
	BOUNDARIES = 4
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
		if abilities.find(PlayerManager.Abilities.CHARGE_SHOT):
			build_charge(delta)
		
	if abilities.find(PlayerManager.Abilities.SHIELD) > -1:
		if Input.is_action_pressed("player_action2"):
			$AnimatedSprite.animation = "intimidate"
			if Input.is_action_just_pressed("player_action2"):
				setShieldState(PlayerManager.ShieldState.PERFECT)
			elif $Shield/PerfectDetectionTimer.is_stopped() and $Shield/PerfectCooldownTimer.is_stopped():
				setShieldState(PlayerManager.ShieldState.ACTIVE)
				
		elif $Shield/PerfectDetectionTimer.is_stopped() and $Shield/PerfectCooldownTimer.is_stopped():
			setShieldState(PlayerManager.ShieldState.INACTIVE)
			state = PlayerManager.State.DEFAULT
		
		if Input.is_action_just_released("player_action2"):
			$AnimatedSprite.animation = "default"
			
	
	if abilities.find(PlayerManager.Abilities.HEAT_SEEKING) > -1 and currentBullet:
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
	if powerup == PlayerManager.PowerUps.HYPER: # there's no point in shooting at this point
		return
	currentBullet = Echo.instance()
	currentBullet.set_origin("player")
	currentBullet.global_position = $ProjectileSpawner.global_position
	currentBullet.passiveVelocity = Vector2(0, 0)
	currentBullet.activeVelocity = Vector2(1, 0)
	owner.add_child(currentBullet)		
	
func update_current_bullet():
	if powerup == PlayerManager.PowerUps.HYPER:
		return
			
	if abilities.find(PlayerManager.Abilities.CHARGE_SHOT) > -1 and currentBullet:
		if charge > 0:
			chargeMultiplier = (charge / 100.0) + 1 
			currentBullet.scale = Vector2(chargeMultiplier, chargeMultiplier) 
			
		if not currentBullet.active or currentBullet.is_missile: 
			currentBullet.global_position = $ProjectileSpawner.global_position
	
	
func shoot():
	if powerup == PlayerManager.PowerUps.HYPER:
		pass
		
	if abilities.find(PlayerManager.Abilities.CHARGE_SHOT) > -1 and currentBullet:
		if charge == 100:
			currentBullet.invincible = true
			currentBullet.activeVelocity *= 1.4
			
		currentBullet.damage *= chargeMultiplier	
		self.charge = 0
		chargeMultiplier = 1
		emit_signal("charge_changed", charge)
		
	if abilities.find(PlayerManager.Abilities.HEAT_SEEKING) > -1:
		heatSeekingIndex = 0
	
	# release the bullet	
	if currentBullet: 
		currentBullet.active = true
	
		if !currentBullet.heat_seeking:
			if powerup == PlayerManager.PowerUps.BURST or powerup == PlayerManager.PowerUps.BURST_ANGLED:
				var currentBulletUp = currentBullet.copy()
				currentBulletUp.global_position.y = currentBullet.global_position.y - 30
				if powerup == PlayerManager.PowerUps.BURST_ANGLED:
					currentBulletUp.activeVelocity = currentBulletUp.activeVelocity.rotated(-.25)
				owner.add_child(currentBulletUp)
				bullets.push_back(currentBulletUp)
				
				var currentBulletDown = currentBullet.copy()
				currentBulletDown.global_position.y = currentBullet.global_position.y + 30
				if powerup == PlayerManager.PowerUps.BURST_ANGLED:
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
	var newShield = shield
	if Input.is_action_pressed("player_action2") or !$Shield/PerfectDetectionTimer.is_stopped():
		newShield = shield - shieldDepletionRate * delta 
	else:
		if $Shield/RechargeDelayTimer.is_stopped():
			newShield = shield + shieldRestorationRate * delta
		
	newShield = clamp(newShield, 0, 100)
	
	if shield != newShield:
		self.shield = newShield
		
	if shield <= 0:
		setShieldState((PlayerManager.ShieldState.INACTIVE))
		
		
func build_charge(delta):
	if Input.is_action_pressed("player_action1"):
		self.charge += chargeBuildRate * delta 
	else:
		self.charge = 0
		
	self.charge = clamp(charge, 0, 100)
	
	if abilities.find(PlayerManager.Abilities.HEAT_SEEKING) > -1:
		if charge > 10 and currentBullet: 
			var enemies = get_tree().get_nodes_in_group("enemies")
			enemies = filter_dead_enemies(enemies)
			if enemies.size() > 0:
				enemies.sort_custom(self, "sort_enemies")
				currentBullet.set_heat_seeking(enemies[0])
		
func construct_hyper_beam():
	$AnimatedSprite.animation = "intimidate"
	if powerup == PlayerManager.PowerUps.HYPER:
		var h = Hyper.instance()
		h.position = $ProjectileSpawner.position
		add_child(h)
		
func deconstruct_hyper_beam():
	var h = get_node_or_null("HyperBeam")
	if h != null:
		$AnimatedSprite.animation = "default"
		h.queue_free()
	
# Called when the node enters the scene tree for the first time.
func _ready():
	PlayerManager.health = health
	PlayerManager.charge = charge
	PlayerManager.shield = shield 
	PlayerManager.abilities = abilities
	PlayerManager.powerup = powerup
	
	
	setShieldState(PlayerManager.ShieldState.INACTIVE)
	add_to_group("player")
	
	construct_hyper_beam()
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):	
	get_input(delta)
	
	if abilities.find(PlayerManager.Abilities.SHIELD) > -1:
		adjust_shield_charge(delta)
	
func _physics_process(delta):
	var collision = move_and_slide(velocity)			
	PlayerManager.position = position
	update_current_bullet()
		
func take_damage(damage):
	var is_vulnerable = state == PlayerManager.State.DEFAULT
	if is_vulnerable: 
		health = health - damage
		
		if health > 0:
			$HitCooldownTimer.start()	
			state = PlayerManager.State.DAMAGED
			$HitBoxes/Area2D/CollisionShape2D.set_deferred("disabled", true)
			set_collision_mask_bit(1, false)
			set_collision_mask_bit(3, false)
			$AnimatedSprite.modulate = Color.red
			$AnimatedSprite.play("hit")
			deconstruct_hyper_beam()
			
			# interrupt charge shot
			if currentBullet != null:
				currentBullet.queue_free()
				currentBullet = null
				
			self.charge = 0
			chargeMultiplier = 1
			heatSeekingIndex = 0
		
	return is_vulnerable
	
	
func setShieldState(newShieldState):
	if shieldState == newShieldState:
		return 
		
	if newShieldState == PlayerManager.ShieldState.ACTIVE and shieldState == PlayerManager.ShieldState.INACTIVE and shield == 0:
		return 
	
	shieldState = newShieldState
#	emit_signal("shield_state_changed")
		
	match shieldState:
		PlayerManager.ShieldState.INACTIVE:
			state = PlayerManager.State.DEFAULT
			$Shield/PerfectDetectionTimer.stop()
			$Shield/ActiveHitBox/CollisionShape2D.set_deferred("disabled", true)
			$Shield/PerfectHitBox/CollisionShape2D.set_deferred("disabled", true)
			$Shield/ActiveHitBox/Sprite.visible = false
			$Shield/PerfectHitBox/Sprite.visible = false
			$AnimatedSprite.animation = "default"
			if $Shield/RechargeDelayTimer.is_stopped():
				$Shield/RechargeDelayTimer.start()
		PlayerManager.ShieldState.ACTIVE:
			state = PlayerManager.State.SHIELD
			$Shield/ActiveHitBox/CollisionShape2D.set_deferred("disabled", false)
			$Shield/PerfectHitBox/CollisionShape2D.set_deferred("disabled", true)
			$Shield/ActiveHitBox/Sprite.visible = true
			$Shield/PerfectHitBox/Sprite.visible = false
			$AnimatedSprite.animation = "intimidate"
		PlayerManager.ShieldState.PERFECT:
			state = PlayerManager.State.SHIELD
			$Shield/PerfectDetectionTimer.start()
			$Shield/ActiveHitBox/CollisionShape2D.set_deferred("disabled", false)
			$Shield/PerfectHitBox/CollisionShape2D.set_deferred("disabled", false)
			$Shield/ActiveHitBox/Sprite.visible = true	
			$Shield/PerfectHitBox/Sprite.visible = false
			$AnimatedSprite.animation = "intimidate"
			
func set_health(value):
	health = value
	PlayerManager.health = value
	
func set_shield(value):
	shield = value
	PlayerManager.shield = value
	
func set_charge(value):
	charge = value
	PlayerManager.charge = value
	
func set_abilities(value):
	abilities = value
	PlayerManager.abilities = value
	
func set_powerup(value):
	powerup = value
	PlayerManager.powerup = value
	
func kill():
		emit_signal("died")
		destroy()
	
	
func destroy():
	queue_free()
	
	
func _on_HitCooldownTimer_timeout():	
	state = PlayerManager.State.DEFAULT
	$AnimatedSprite.modulate = Color.white
	$AnimatedSprite.play("default")
	$HitBoxes/Area2D/CollisionShape2D.set_deferred("disabled", false)
	set_collision_mask_bit(1, true)
	set_collision_mask_bit(3, true)
	
	
func _on_Area2D_area_entered(area):
	if area.is_in_group("enemy_projectiles"):
		if take_damage(area.damage):
			area.destroy()
	
	elif area.is_in_group("powerups"):
		if $PowerupTimer.is_stopped():
			self.powerup = PlayerManager.PowerUps.BURST if area.type == 1 else PlayerManager.PowerUps.HYPER 
			
			if powerup == PlayerManager.PowerUps.HYPER:
				construct_hyper_beam()
				
			$PowerupTimer.start()
			emit_signal("powerup_changed")
			area.destroy()
	elif area.is_in_group("enemies"):
		if area.health > 0:
			take_damage(1)
			area.kill()		
		

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
		
		self.shield -= 40
		emit_signal("shield_changed")
		

func _on_PerfectDetectionTimer_timeout():
	if Input.is_action_pressed("player_action2"):
		setShieldState(PlayerManager.ShieldState.ACTIVE)
	else:
		setShieldState(PlayerManager.ShieldState.INACTIVE)


func _on_PerfectCooldownTimer_timeout():
	$Shield/PerfectHitBox/Sprite.visible = false
	if Input.is_action_pressed("player_action2"):
		setShieldState(PlayerManager.ShieldState.ACTIVE)
	else:
		setShieldState(PlayerManager.ShieldState.INACTIVE)
		

func _on_PowerupTimer_timeout():
	powerup = null
	deconstruct_hyper_beam()
	emit_signal("powerup_changed")
