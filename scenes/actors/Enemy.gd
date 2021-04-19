extends Area2D

export (int) var health = 2
export (float) var speed = 150
export (float) var projectile_speed = 1000
export (float) var firing_rate = .1
export var firing_angle = 0
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
export (PatrolType) var end_path_behavior = PatrolType.DEQUEUE

const Echo = preload("res://scenes/projectiles/Echo.tscn")
const Powerup = preload("res://scenes/powerups/Powerup.tscn")
	
func shoot():
	var b = Echo.instance()
	b.set_origin("enemies")
	get_parent().add_child(b)
	b.global_position = $ProjectileSpawner.global_position
	if str(firing_angle) == "player":
		firing_angle = 0
	b.activeVelocity = Vector2(-1, 0).rotated(deg2rad(firing_angle))
	b.speed = projectile_speed
	b.active = true
		

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	if path:
		position = path[0].patrol_point
	else:
		velocity = Vector2.LEFT
		
	$ProjectileSpawner/CooldownTimer.wait_time = firing_rate
		
	velocity = velocity.normalized()
	pass # Replace with function body.
	
func _process(_delta):
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
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
			if  patrol_iterator > 0 and nextPatrolIndex > path.size()-1 or patrol_iterator < 0 and nextPatrolIndex < 0:
				match end_path_behavior:
					PatrolType.DEQUEUE:
						destroy()
						return
					PatrolType.PATROL_LOOP:
						nextPatrolIndex = 0
					PatrolType.PATROL_BACK:
						patrol_iterator *= -1
						nextPatrolIndex = patrol_index + patrol_iterator

			patrol_index = nextPatrolIndex
			target = path[nextPatrolIndex].patrol_point
			speed = path[nextPatrolIndex].speed
			firing_rate = path[nextPatrolIndex].firing_rate
			firing_angle = path[nextPatrolIndex].firing_angle
			$ProjectileSpawner/CooldownTimer.wait_time = firing_rate
			$ProjectileSpawner/CooldownTimer.stop()
			$ProjectileSpawner/CooldownTimer.start()
		
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
	
	return true
	
func kill():
	set_collision_layer_bit(1, false)
	path = null
	health = 0
	velocity = Vector2.ZERO
	$HitBoxes/Area2D/CollisionShape2D.disabled = true
	$AnimatedSprite.modulate = Color(127, 0, 0, 127)
	$AnimatedSprite.play("dead")	

func _on_AnimatedSprite_animation_finished():
	if $AnimatedSprite.animation == "dead":
		if path:
			var powerupNode = get_node(path)
			if powerupNode:
				powerupNode.visible = true
				powerupNode.global_position = global_position
				get_parent().add_child(powerupNode)
		
		destroy()

func _on_CooldownTimer_timeout():
	shoot()
	pass


func _on_Area2D_area_entered(area):
	if area.is_in_group("player_projectiles"):
		if take_damage(area.damage):
			area.destroy()
		
		
