extends KinematicBody2D

var health = 2
var speed = 150
var velocity = Vector2(0, 0) #Vector2(-1, 0) 

export (NodePath) var path 
export (NodePath) var powerup 
var patrol_points
var patrol_index = 0
var patrol_type 


const Echo = preload("res://scenes/projectiles/Echo.tscn")
const Powerup = preload("res://scenes/powerups/Powerup.tscn")
	
func shoot():
	var b = Echo.instance()
	b.set_origin("enemies")
	get_parent().add_child(b)
	b.global_position = $ProjectileSpawner.global_position
	b.activeVelocity = Vector2(-1, 0)
	b.speed = 1000
	b.active = true
		

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	if path:
		patrol_points = get_node(path).curve.get_baked_points()
		position = patrol_points[0]
	else:
		velocity = Vector2.LEFT
		
	velocity = velocity.normalized() * speed
	pass # Replace with function body.
	
func _process(_delta):
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	
	if !path or health == 0:
		move_and_collide(velocity * delta)
	else:
		var target = patrol_points[patrol_index]
		var distance = position.distance_to(target)
		if distance < 1:
			patrol_index = wrapi(patrol_index + 1, 0, patrol_points.size())
			target = patrol_points[patrol_index]
		
		var maxMovementDistance = speed * delta
		var movementDistance = min(distance, maxMovementDistance)
		var tempSpeed = movementDistance / delta 
		
		velocity = (target - position).normalized() * tempSpeed
		var collision = move_and_collide(velocity * delta)
			
	if position.x < 0 - speed: # enemy should be well outside visible range at this point 
		destroy()

func destroy():
	queue_free()
	
func take_damage(damage):
	health -= damage
	if health <= 0:
		kill()
	
	return true
	
func kill():
	set_collision_layer_bit(1, false)
	health = 0
	velocity = Vector2.ZERO
	$HitBoxes/Area2D/CollisionShape2D.disabled = true
	$AnimatedSprite.modulate = Color(127, 0, 0, 127)
	$AnimatedSprite.play("dead")	

func _on_AnimatedSprite_animation_finished():
	if $AnimatedSprite.animation == "dead":
		
		var powerupNode = get_node(path)
		if powerupNode:
			powerupNode.visible = true
			powerupNode.global_position = global_position
			get_parent().add_child(powerupNode)
		
		destroy()

func _on_CooldownTimer_timeout():
#	shoot()
	pass


func _on_Area2D_area_entered(area):
	if area.is_in_group("player_projectiles"):
		if take_damage(area.damage):
			area.destroy()
		
