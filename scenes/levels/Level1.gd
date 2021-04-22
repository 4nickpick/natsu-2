extends Node2D

export (int) var levelNumber = 1
const Enemy = preload("res://scenes/actors/Enemy.tscn")

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
		
	# prep game generation
	trigger_keys = triggers.keys()
	trigger_keys.sort()
	
	time_start = OS.get_unix_time()
	
	return

# Called every frame. 'delta' is the elapsed time since0 the previous frame.
func _process(delta):		
	move_along_level_path(delta)
	process_triggers(delta)
	
	# debug
	time_now = OS.get_unix_time()
	var time_elapsed = time_now - time_start
#	$CanvasLayer.show_message(str(time_elapsed / 60) + "m " + str(time_elapsed % 60) + "s" )
#	$CanvasLayer/HUD.show_message($Camera2D.position)
	
	
func move_along_level_path(delta):
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
	
	
func process_triggers(delta):
	if trigger_keys.size() == 0:
		return 
		
	var next_trigger = trigger_keys[0]
		
	if $Camera2D.position.x > next_trigger.x:
		trigger_keys.pop_front() # we're processing this now
		var triggers_up = triggers[next_trigger]
		
		for trigger in triggers_up:
			if trigger is EnemyInstanceHeader:
				spawn_enemy_from_instance_header(trigger)
			elif trigger is DialogueHeader:
				initiate_dialogue_from_header(trigger)
				
	
	return
	
func spawn_enemy_from_instance_header(instance_header):
	var enemy = Enemy.instance()
	enemy.path = instance_header.path
	enemy.group = instance_header.group
	enemy.end_path_behavior = instance_header.end_path_behavior
	$Camera2D/Enemies/YSort.add_child(enemy)
	
	
func initiate_dialogue_from_header(header):
#	var dialogue = $CanvasLayer/HUD.show_message(header.dialogues[0].speech)
	pass

