extends Area2D

const Echo = preload("res://scenes/projectiles/Echo.tscn")
const Bomb = preload("res://scenes/projectiles/Bomb.tscn")
const Powerup = preload("res://scenes/powerups/Powerup.tscn")
const ScoreLabel = preload("res://scenes/HUD/ScoreLabel.tscn")
const EnemyBody = preload("res://scenes/actors/EnemyBody.gd")

export (int) var health = 2
export (float) var speed = 150
export (float) var point_value = 100
export (float) var projectile_speed = 1000
export (float) var firing_rate = .1
export var firing_angle = 0
export var firing_spray = 1
export var body_rotating = false
export var body_rotating_speed: float = .5
export (int) var group = null
var velocity = Vector2(0, 0) #Vector2(-1, 0) 

export (PoolVector2Array) var path
export (NodePath) var powerup

var patrol_index = 0
var patrol_iterator = 1 # direction to iterate over patrol_points

enum PatrolType {
	DEQUEUE = 1,
	PATROL_LOOP = 2,
	PATROL_BACK = 3
}
var end_path_behavior: int = 1

# enemy stunned
export var stunnable: bool = true
var stunned: bool = false
export var freezable: bool = true
var frozen: bool = false

# burst 
onready var cooldownTimer = $ProjectileSpawner/CooldownTimer
var firing_type = null
var maxBurst: int = 3
var burstRemaining: int = 0
	
func shoot():
	if health <= 0:
		return
		
	if PlayerManager.health <= 0:
		return
		
	_create_bullet(0)
	
	if firing_spray > 1:
		firing_angle = 360 / firing_spray
		for i in range(firing_spray):
			if i == 0:
				continue
			_create_bullet(i * firing_angle)
		
func _create_bullet(rotation_offset):
	var b = Echo.instance()
	b.set_origin("enemies")
	get_parent().add_child(b)
	b.global_position = $ProjectileSpawner.global_position
	b.activeVelocity = Vector2(-1, 0).rotated(rotation + deg2rad(rotation_offset))
	b.speed = projectile_speed
	b.active = true
	
func bomb():
	if health <= 0:
		return
		
	var b = Bomb.instance()
	b.set_origin("enemies")
	get_parent().add_child(b)
	b.global_position = $ProjectileSpawner.global_position
	b.activeVelocity = Vector2(-1, 0).rotated(deg2rad(-45))
	b.speed = projectile_speed
	b.active = true
		

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize() 
	var _error = PlayerManager.connect("lives_changed", self, "set_exit_route")
	add_to_group("enemies")
	
	if path:
		position = path[0].patrol_point
		firing_rate = path[0].firing_rate
		firing_angle = path[0].firing_angle
		firing_type = path[0].firing_type
	else:
		velocity = Vector2.LEFT
	
	if firing_rate > 0:
		$ProjectileSpawner/CooldownTimer.wait_time = firing_rate
		$ProjectileSpawner/CooldownTimer.start()
		
	velocity = velocity.normalized()
	pass # Replace with function body.
	
func _process(delta):
	var rotation_val = 0
	if body_rotating:
		rotation_val = rotation + (body_rotating_speed * delta)
	elif $BurstCooldownTimer.is_stopped():
		if str(firing_angle) == "player":
			rotation_val = (position - PlayerManager.position).angle()
		else:
			rotation_val = deg2rad(firing_angle)
			
	rotation = rotation_val			
#			PlayerManager.emit_signal("rotation_changed", str(rad2deg(rotation_val)) + "H: " + str($AnimatedSprite.flip_h) + "V: " + str($AnimatedSprite.flip_v) )

	$AnimatedSprite.flip_v = Helpers.is_between_inclusive(rotation_degrees, -180, -91) or \
		Helpers.is_between_inclusive(rotation_degrees, 91, 180)
	pass
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	if stunned:
		return
			
	if !path:
		position += (velocity * speed * delta)
		
		if position.x < 0 - speed: # enemy should be well outside visible range at this point 
			destroy()
	else:
		var target = path[patrol_index].patrol_point
		var distance = position.distance_to(target)
		
		# we've reached our target position 
		if distance < 1:
			
			# are we at the end of our patrol?
			var nextPatrolIndex = patrol_index + patrol_iterator
			if  patrol_iterator > 0 and nextPatrolIndex >= path.size() or patrol_iterator < 0 and nextPatrolIndex < 0:
				match end_path_behavior:
					1:
						destroy()
						return
					2:
						nextPatrolIndex = 0
					3:
						patrol_iterator *= -1
						nextPatrolIndex = patrol_index + patrol_iterator*2

			patrol_index = nextPatrolIndex
			target = path[nextPatrolIndex].patrol_point
			speed = path[nextPatrolIndex].speed
			firing_rate = path[nextPatrolIndex].firing_rate
			firing_angle = path[nextPatrolIndex].firing_angle
#			if firing_rate > 0:
#				$ProjectileSpawner/CooldownTimer.wait_time = firing_rate
#				$ProjectileSpawner/CooldownTimer.autostart = true
#				$ProjectileSpawner/CooldownTimer.start()
		
		var maxMovementDistance = speed * delta
		var movementDistance = min(position.distance_to(target), maxMovementDistance)
		var tempSpeed = movementDistance / delta 
		
		velocity = (target - position).normalized() * tempSpeed * delta
		position += velocity

func destroy():
	queue_free()
	
func take_damage(damage):
	health -= damage
	
	if health <= 0:
		kill()
	
	if stunnable: 
		set_stunned()	
	
	return true
	
func body_take_damage(body, damage):
	body.health -= damage
	
	if body.health <= 0:
		PlayerManager.add_score(body.point_value)
		body.kill()
		
		var bodies = $HitBoxes.get_children()
		var totalHealthRemaining = 0
		for body in bodies:
			totalHealthRemaining += clamp(body.health, 0, 9999)
			
		if totalHealthRemaining <= 0:
			kill()			
	
	if stunnable: 
		set_stunned()	
	
	return true
	
func set_stunned():
	stunned = true
	pass
	
func kill():
	set_collision_layer_bit(1, false)
	path = null
	health = 0
	velocity = Vector2.ZERO
	
	var hitboxes = $HitBoxes.get_children()
	for hitbox in hitboxes:
		hitbox.get_node("CollisionShape2D").set_deferred("disabled", true)
		
	$AnimatedSprite.modulate = Color(127, 0, 0, 127)
	$AnimatedSprite.play("dead")	
	
	PlayerManager.score += point_value
	var scoreLabel = ScoreLabel.instance()
	get_tree().get_root().add_child(scoreLabel)
	scoreLabel.position = position	
	scoreLabel.get_node("Label").text = "+" + str(point_value)
	scoreLabel.start()

func set_exit_route():
	if $VisibilityNotifier2D.visible: 
		set_deferred("path", null)
		
		var leave = randi() % 2
		if leave == 1:
			# wander about on screen
			var new_path = []
			for _i in range(3):
				var enemyPathBehavior = EnemyInstancePathBehavior.new()
				enemyPathBehavior.patrol_point = Vector2((randi() % 1280), (randi() % 600))
				enemyPathBehavior.speed = randi() % 300				
				enemyPathBehavior.firing_angle = randi() % 360				
				enemyPathBehavior.firing_type = null				
				new_path.push_back(enemyPathBehavior);
				
			set_deferred("path", new_path)
			set_deferred("patrol_index", 0)
			set_deferred("patrol_iterator", 1)
		else:
			set_deferred("velocity", Vector2.DOWN.rotated(randi() % 360))
			set_deferred("speed", randi() % 300)
			# leave the screen

func _on_AnimatedSprite_animation_finished():
	if $AnimatedSprite.animation == "dead":
		if powerup:
			var powerupNode = get_node(powerup)
			if powerupNode:
				powerupNode.visible = true
				powerupNode.global_position = global_position
				get_parent().add_child(powerupNode)
		
		destroy()

func _on_CooldownTimer_timeout():
	if firing_type == "burst":
		shoot()
		burstRemaining = maxBurst - 1
		$BurstCooldownTimer.start()
	else:
		shoot()
	pass


func _on_BurstCooldownTimer_timeout():
	if burstRemaining > 0:
		shoot()
		burstRemaining -= 1
		$BurstCooldownTimer.start()


func _on_Area2D_area_entered(area):
	if area.is_in_group("player_projectiles"):
		if take_damage(area.damage):
			area.destroy()		
			
			
func _on_Body_area_entered(area, body_name):
	if area.is_in_group("player_projectiles"):
		var targetBody = $HitBoxes.get_node_or_null(body_name)
		if !targetBody:
			return
			
		body_take_damage(targetBody, area.damage)

		
func _on_HitCooldownTimer_timeout():
	pass # Replace with function body.

func _on_Core_area_entered(area):
	if area.is_in_group("player_projectiles"):
		area.destroy()	#core is invincible
