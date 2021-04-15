extends Node

var eyeball = preload("res://scenes/actors/Enemy.tscn")
var score = 0
var fps = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit() 
	
	if Input.is_action_just_pressed("debug_restart"):
		get_tree().change_scene("res://scenes/levels/Level1.tscn") 
	
	$HUD.update_score(score)
	$HUD.update_enemy_count(get_tree().get_nodes_in_group("player_projectiles").size())
#	$HUD.update_enemy_count(get_tree().get_nodes_in_group("enemies").size())
	
	

func _on_EnemySpawner_timeout():	
	var centerPosition = $EnemySpawner/CollisionShape2D.global_position + $EnemySpawner.global_position
	var size = $EnemySpawner/CollisionShape2D.shape.extents
	
	var position = Vector2(
		(randi() % int(size.x)) - (size.x/2) + centerPosition.x,
		(randi() % int(size.y)) - (size.y/2) + centerPosition.y
	)
	
	var enemy = eyeball.instance()
	enemy.global_position = position
	add_child(enemy)
	enemy.add_to_group("enemies")
	pass

func _on_Player_died():
	$HUD.update_health($Player.health)
	$HUD.show_message("GAME OVER")

func _on_Player_health_changed():
	$HUD.update_health($Player.health)


func _on_Player_shield_state_changed():
#	$HUD.update_enemy_count(str($Player.shieldState) + ": " + "%.2f" % $Player.shield)
	pass


func _on_Player_shield_changed():
#	$HUD.update_enemy_count(str($Player.shieldState) + ": " + "%.2f" % $Player.shield)
	pass

func _on_Player_charge_changed():
	$HUD.update_enemy_count("%.2f" % $Player.charge)
