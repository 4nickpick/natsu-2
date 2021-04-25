extends Node

var best_score = 0 
const filepath = "user://best_score.data"

func _ready():
	load_best_score()
	pass
	
func load_best_score():
	var file = File.new()
	if not file.file_exists(filepath): 
		return 0 
	
	file.open(filepath, File.READ)
	best_score = file.get_var()
	file.close()
	
	return best_score
	
func save_best_score():
	var file = File.new()
	file.open(filepath, File.WRITE)
	file.store_var(best_score)
	file.close()
	
func set_best_score(value):
	best_score = value
	save_best_score()
	pass
