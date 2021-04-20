extends Area2D 

const Reticle = preload("res://scenes/projectiles/Reticle.tscn")

var speed = 150
var max_speed = 800
var rotation_speed = 0
var cooldown = .1
var damage = 2

 # projectiles start out as non-moving for charge shots
var passiveVelocity = Vector2(-1, 0)

# active velocity indicates the projectile's velocity once released from charge
# can be modified while the projectile is charging 
var activeVelocity = Vector2(1, 0) 

var active = false

var reticle = null

var last_position = null
var distance_traveled = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	activeVelocity = activeVelocity.normalized() 
	last_position = position
		
	$Tween.interpolate_property(self, "speed", null, max_speed, 1, Tween.TRANS_QUAD, Tween.EASE_IN)
	$Tween.start()
	
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	rotation += rotation_speed * delta
	if active: 
		position += activeVelocity * speed * delta

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):		
	if speed == max_speed:
		set_off_explosion()
	pass
	
func set_off_explosion():
	$Tween.stop(self, "speed")
	speed = 0
	$AnimatedSprite.visible = false
	$CollisionShape2D.set_deferred("disabled", true)
	$Explosion.set_deferred("visible", true)
	$Explosion/CollisionShape2D.set_deferred("disabled", false)
	$Explosion/Timer.start()

func set_origin(origin):
	if origin == "player":
		set_collision_layer(4) #player_projectiles
		set_collision_mask(10) #enemies + enemy_projectiles
		
		$Explosion.set_collision_layer_bit(2, true)
		$Explosion.set_collision_mask_bit(1, true)
		$Explosion.set_collision_mask_bit(3, true)
		
		if is_in_group("enemy_projectiles"):
			remove_from_group("enemy_projectiles")
			$Explosion.remove_from_group("enemy_projectiles")
			
		add_to_group("player_projectiles")
		$Explosion.add_to_group("player_projectiles")
		
		rotation = deg2rad(180)
	elif origin == "enemies":
		set_collision_layer(8) #enemy_projectiles
		set_collision_mask(1) #player
		
		$Explosion.set_collision_layer_bit(3, true)
		$Explosion.set_collision_mask_bit(0, true)
		
		if is_in_group("player_projectiles"):
			remove_from_group("player_projectiles")
			$Explosion.remove_from_group("player_projectiles")
			
		add_to_group("enemy_projectiles")
		$Explosion.add_to_group("enemy_projectiles")
		
	
func reflect(origin):
	set_origin(origin)
	activeVelocity = -1 * activeVelocity 
	damage *= 2
	
	
func copy():
	var copied = duplicate(8)
	copied.active = true
	return copied
	
func destroy():
	if not $Explosion.visible:
		set_off_explosion()
		return
	
	if $Explosion/Timer.is_stopped(): 
		queue_free()		
		
	
func _on_VisibilityEnabler2D_screen_exited():
	pass

func _on_Timer_timeout():
	destroy()
