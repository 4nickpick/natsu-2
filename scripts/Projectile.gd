extends Area2D 

const Reticle = preload("res://scenes/projectiles/Reticle.tscn")

var speed = 800
var rotation_speed = 25
var cooldown = .1
var damage = 1
var is_missile = false

 # projectiles start out as non-moving for charge shots
var passiveVelocity = Vector2(0, 0)

# active velocity indicates the projectile's velocity once released from charge
# can be modified while the projectile is charging 
var activeVelocity = Vector2(1, 0) 

var active = false

var invincible = false # is projectile destroyed on collision?

var heat_seeking = false # alter direction to target nearest enemies
var heat_seeking_target = null #heat_seeking target
var reticle = null

# Called when the node enters the scene tree for the first time.
func _ready():
	activeVelocity = activeVelocity.normalized() 
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	rotation += rotation_speed * delta
	if active: 
		position += activeVelocity * speed * delta

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	if heat_seeking:
		update_heat_seeking(delta)
	
	pass
	
func set_heat_seeking(target):
	heat_seeking = target != null
	heat_seeking_target = target
	
	if reticle != null:
		reticle.queue_free()
		
	if target != null:
		reticle = Reticle.instance()
		get_parent().add_child(reticle)
		reticle.global_position = target.global_position

func update_heat_seeking(delta):
	if active and reticle != null:
		reticle.queue_free()
		
	if heat_seeking_target == null and reticle != null:
		reticle.queue_free()
	
	if reticle != null and heat_seeking_target != null:
		reticle.global_position = heat_seeking_target.global_position
		
	if active and heat_seeking_target != null and heat_seeking_target.health > 0:
		var vectorToTarget = heat_seeking_target.global_position - global_position 
		activeVelocity = vectorToTarget.normalized() * speed * delta * 4 # x4 cause it feels sluggish otherwise
	

func set_origin(origin):
	if origin == "player":
		set_collision_layer(4) #player_projectiles
		set_collision_mask(2) #enemies
		
		if is_in_group("enemy_projectiles"):
			remove_from_group("enemy_projectiles")
			
		add_to_group("player_projectiles")
	elif origin == "enemies":
		set_collision_layer(8) #enemy_projectiles
		set_collision_mask(1) #player
		
		if is_in_group("player_projectiles"):
			remove_from_group("player_projectiles")
			
		add_to_group("enemy_projectiles")
		
	
func reflect(origin):
	set_origin(origin)
	activeVelocity = -1 * activeVelocity 
	damage *= 2
	
	
func copy():
	var copied = duplicate(8)
	copied.active = true
	return copied
	
func destroy():
	if not invincible or not $VisibilityEnabler2D.is_on_screen():
		queue_free()
		
		if reticle != null:
			reticle.queue_free()
	
func _on_VisibilityEnabler2D_screen_exited():
	destroy()
