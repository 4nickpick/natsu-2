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
	
	var level_data = parse.result
	for vector in level_data["level"]["path"]:
		path.push_back(Vector2(vector["x"], vector["y"]))
		
	for dialogues in level_data["level"]["dialogues"]:
		var spawn_trigger = Vector2(dialogues["spawn_trigger"]["x"], dialogues["spawn_trigger"]["y"])
		
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
		
		
	for enemy_data in level_data["level"]["enemies"]:
		var spawn_trigger = Vector2(enemy_data["spawn_trigger"]["x"], enemy_data["spawn_trigger"]["y"])
		
		if !triggers.has(spawn_trigger):
			triggers[spawn_trigger] = []
		
		var enemyHeader = EnemyInstanceHeader.new()
		enemyHeader.group = enemy_data["group"]
		enemyHeader.end_path_behavior = enemy_data["end_path_behavior"]
		
		for enemy_path in enemy_data["path"]:
			var enemyPathBehavior = EnemyInstancePathBehavior.new()
			enemyPathBehavior.patrol_point = Vector2(enemy_path["x"], enemy_path["y"])
			enemyPathBehavior.speed = enemy_path["speed"]
			enemyPathBehavior.projectile_speed = enemy_path["projectile_speed"]
			enemyPathBehavior.firing_angle = enemy_path["firing_angle"]
			enemyPathBehavior.firing_rate = enemy_path["firing_rate"]
			enemyHeader.path.push_back(enemyPathBehavior)
			
		triggers[spawn_trigger].push_back(enemyHeader)
		
	# prep game generation
	trigger_keys = triggers.keys()
	trigger_keys.sort()
	
	return



# Called every frame. 'delta' is the elapsed time since0 the previous frame.
func _process(delta):
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit() 
	
	if Input.is_action_just_pressed("debug_restart"):
		get_tree().change_scene("res://scenes/levels/Level1.tscn") 
		
	move_along_level_path(delta)
	
	process_triggers(delta)
	
	$CanvasLayer/HUD.show_message($Camera2D.position)
	
	
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
	$Camera2D/Enemies/YSort.add_child(enemy)
	var y = enemy.get_parent()
	
	enemy.position = instance_header.path[0].patrol_point
	enemy.path = instance_header.path
#	enemy.speed = instance_header.speed 
#	enemy.projectile_speed = instance_header.projectile_speed
#	enemy.firing_rate = instance_header.firing_rate
#	enemy.firing_angle = instance_header.firing_angle 
	enemy.group = instance_header.group
	
func initiate_dialogue_from_header(header):
	var dialogue = $CanvasLayer/HUD.show_message(header.dialogues[0].speech)
	
