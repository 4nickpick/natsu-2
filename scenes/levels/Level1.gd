extends Node2D

export (int) var levelNumber = 1
const Enemy = preload("res://scenes/actors/Enemy.tscn")
const BigEnemy = preload("res://scenes/actors/BigEnemy.tscn")
const Golem = preload("res://scenes/actors/Golem.tscn")
const Boss = preload("res://scenes/actors/Boss.tscn")
const Obstacle1 = preload("res://scenes/actors/Obstacle.tscn")
const Obstacle2 = preload("res://scenes/actors/Obstacle2.tscn")

# camera management
var path: PoolVector2Array
export (int) var current_path_index = 0  # checkpoints

var speed = 80
var velocity = Vector2(1, 0)

var triggers: Dictionary 
var trigger_keys: Array

var time_start = 0 
var time_now = 0 


# Called when the node enters the scene tree for the first time.
func _ready():
				
	# load level objects from json  
	var file = File.new()
	file.open("res://data/level" + str(levelNumber) + ".json", File.READ)
	var text = file.get_as_text()
	file.close()
	
	var parse = JSON.parse(text)
	if parse.error != OK:
		return
	
	var level_data = parse.result["level"]
	
	speed = level_data["speed"]
	for vector in level_data["path"]:
		path.push_back(Vector2(
			vector["x"] * speed, 
			vector["y"] * speed
		))
		
	for dialogues in level_data["dialogues"]:
		var spawn_trigger = Vector2(
			dialogues["spawn_trigger"]["x"] * speed, 
			dialogues["spawn_trigger"]["y"] * speed
		)
		
		if !triggers.has(spawn_trigger):
			triggers[spawn_trigger] = []
			
		var dialogueHeader = DialogueHeader.new()
		dialogueHeader.dialogues = []
		for dialogue_data in dialogues["dialogue"]:
			var dialogue = DialogueLine.new()
			dialogue.speaker = dialogue_data["speaker"]
			dialogue.speech = dialogue_data["speech"]
			dialogueHeader.dialogues.push_back(dialogue)
		triggers[spawn_trigger].push_back(dialogueHeader)
		
	for obstacle in level_data["obstacles"]:
		var spawn_trigger = Vector2(
			obstacle["spawn_trigger"]["x"] * speed, 
			obstacle["spawn_trigger"]["y"] * speed
		)
		
		if !triggers.has(spawn_trigger):
			triggers[spawn_trigger] = []
			
		var header = ObstacleInstanceHeader.new()
		header.type = obstacle["type"]
		header.flipped = obstacle["flipped"]
		triggers[spawn_trigger].push_back(header)
		
	for enemy_data in level_data["enemies"]:
		if !enemy_data["enabled"]:
			continue
			
		var spawn_trigger = Vector2(
			enemy_data["spawn_trigger"]["x"] * speed, 
			enemy_data["spawn_trigger"]["y"] * speed
		)
		
		if !triggers.has(spawn_trigger):
			triggers[spawn_trigger] = []
		
		var enemyHeader = EnemyInstanceHeader.new()
		enemyHeader.type = enemy_data["type"]
		enemyHeader.group = enemy_data["group"]
		enemyHeader.end_path_behavior = enemy_data["end_path_behavior"]
		
		for enemy_path in enemy_data["path"]:
			var enemyPathBehavior = EnemyInstancePathBehavior.new()
			enemyPathBehavior.patrol_point = Vector2(
				enemy_path["x"] * speed, 
				enemy_path["y"] * speed
			)
			enemyPathBehavior.speed = enemy_path["speed"]
			enemyPathBehavior.projectile_speed = enemy_path["projectile_speed"]
			enemyPathBehavior.firing_angle = enemy_path["firing_angle"]
			enemyPathBehavior.firing_rate = enemy_path["firing_rate"]
			enemyPathBehavior.firing_type = enemy_path["firing_type"]
			enemyHeader.path.push_back(enemyPathBehavior)
			
		triggers[spawn_trigger].push_back(enemyHeader)
		
	var bossTrigger = path[path.size()-1]
	var bossHeader = BossInstanceHeader.new()
	bossHeader.type = level_data["boss"]["type"]
	triggers[bossTrigger] = []
	triggers[bossTrigger].push_back(bossHeader)
	
	# prep game generation
	trigger_keys = triggers.keys()
	trigger_keys.sort()
	
	time_start = OS.get_unix_time()
	
	return

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):		
	move_along_level_path(delta)
	process_triggers()
	
	# debug
#	time_now = OS.get_unix_time()
#	var time_elapsed = time_now - time_start
#	$CanvasLayer.show_message(str(time_elapsed / 60) + "m " + str(time_elapsed % 60) + "s" )
#	$CanvasLayer/HUD.show_message($Camera2D.position)

	
func move_along_level_path(delta):
	if not path:
		return 
	
	var target = path[current_path_index]
	var distance = $Camera2D.position.distance_to(target)
	
	# we've reached our target position 
	if distance < 1:
		
		# are we at the end of our patrol?
		var next_path_index = current_path_index + 1
		if next_path_index > path.size() - 1:
			return

		current_path_index = next_path_index
		target = path[current_path_index]
	
	var maxMovementDistance = speed * delta
	var movementDistance = min(position.distance_to(target), maxMovementDistance)
	var tempSpeed = movementDistance / delta if delta > 0 else 0.1
	
	velocity = (target - position).normalized() * tempSpeed * delta
	$Camera2D.position += velocity
	
	
func process_triggers():
	if trigger_keys.size() == 0:
		return 
		
	if PlayerManager.health <= 0:
		return
		
	var next_trigger = trigger_keys[0]
		
	if $Camera2D.position.x > next_trigger.x - 1:
		trigger_keys.pop_front() # we're processing this now
		var triggers_up = triggers[next_trigger]
		
		for trigger in triggers_up:
			if trigger is EnemyInstanceHeader:
				spawn_enemy_from_instance_header(trigger)
			if trigger is BossInstanceHeader:
				spawn_boss_from_instance_header(trigger)
			if trigger is ObstacleInstanceHeader:
				spawn_obstacle_from_instance_header(trigger)
			elif trigger is DialogueHeader:
				initiate_dialogue_from_header(trigger)
				
	
	return
	
func spawn_enemy_from_instance_header(instance_header):
	var enemy = null
	match instance_header.type:
		"Eyeball":
			enemy = Enemy.instance()
		"BigRobot":
			enemy = BigEnemy.instance()
		"Golem":
			enemy = Golem.instance()
	
	enemy.path = instance_header.path
	enemy.group = instance_header.group
	enemy.end_path_behavior = instance_header.end_path_behavior
	$Camera2D/Enemies/YSort.add_child(enemy)
	
	
func spawn_boss_from_instance_header(instance_header):
	var enemy = null
	match instance_header.type:
		"KingCrab":
			enemy = Boss.instance()
	$Camera2D/Enemies/YSort.add_child(enemy)
	
func spawn_obstacle_from_instance_header(instance_header):
	var obstacle = null
	if instance_header.type == 1:
		obstacle = Obstacle1.instance()
		obstacle.position = Vector2(2500, 400)
		if instance_header.flipped:
			obstacle.position.y = 400
			obstacle.scale = Vector2(1, -1)
	else:
		obstacle = Obstacle2.instance()
		obstacle.position = Vector2(2500, 510)
		if instance_header.flipped:
			obstacle.position.y = 300
			obstacle.scale = Vector2(1, -1)
			
	obstacle.velocity = Vector2(-speed, 0)
			
	$Camera2D/Enemies/YSort.add_child(obstacle)
	
func initiate_dialogue_from_header(header):
	var _dialogue = $CanvasLayer.show_message(header.dialogues[0].speech)
	pass

