extends Node

var BestScore = preload("res://scripts/UserScore.gd").new()
var hi_scores = 0

enum LevelState {
	LOADING = 1,
	RUNNING = 2,
	COMPLETE = 3
}
var level_state = LevelState.LOADING 

var current_level = 0

signal level_loading_started(level)
signal level_loaded(level)

signal level_complete
signal level_loading_progress(progress)

signal level_started

func load_level(level):
	current_level = level
	emit_signal("level_loading_started", current_level)

func level_loading_progress(progress):
	level_state = LevelState.LOADING
	emit_signal("level_loading_progress", progress)
	
func level_loaded():
	level_state = LevelState.RUNNING
	get_tree().paused = true
	emit_signal("level_loaded")

func level_complete():
	level_state = LevelState.COMPLETE
	emit_signal("level_complete")
	
	if PlayerManager.score > hi_scores:
		BestScore.set_best_score(PlayerManager.score)
	
	
func scene_transitioned():
	emit_signal("level_started")
	
# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	var _error = SceneManager.connect("loading_completed", self, "level_loaded")
	_error = SceneManager.connect("loading_progress", self, "level_loading_progress")
	hi_scores = BestScore.load_best_score()
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
