extends KinematicBody2D

var health = 2
var speed = 150
var velocity = Vector2(-1, 0)

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
	velocity = velocity.normalized() * speed
	pass # Replace with function body.
	
func _process(_delta):
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	move_and_collide(velocity * delta)
			
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
	health = 0
	velocity = Vector2.ZERO
	$HitBoxes/Area2D/CollisionShape2D.disabled = true
	$AnimatedSprite.modulate = Color(127, 0, 0, 127)
	$AnimatedSprite.play("dead")	

func _on_AnimatedSprite_animation_finished():
	if $AnimatedSprite.animation == "dead":
		
		var powerup = Powerup.instance()
		powerup.global_position = global_position
		get_parent().add_child(powerup)
		
		destroy()
		
			
			


func _on_CooldownTimer_timeout():
#	shoot()
	pass


func _on_Area2D_area_entered(area):
	if area.is_in_group("player_projectiles"):
		if take_damage(area.damage):
			area.destroy()
		
