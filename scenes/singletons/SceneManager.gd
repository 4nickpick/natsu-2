extends Node

var viewport
var loading

var loader
var wait_frames
var time_max = 100
var current_scene = null
var resource_path

signal loading_progress(progress)
signal loading_completed

# Called when the node enters the scene tree for the first time.
func _ready():
	pass
	
func getViewport():
	return viewport
	
func setViewport(value):
	viewport = value
	current_scene = viewport.get_child(viewport.get_child_count()-1)
	
func setLoading(value):
	loading = value

# This function will usually be called from a signal callback,
# or some other function in the current scene.
# Deleting the current scene at this point is
# a bad idea, because it may still be executing code.
# This will result in a crash or unexpected behavior.

# The solution is to defer the load to a later time, when
# we can be sure that no code from the current scene is running:
func goto_scene(path):	
	call_deferred("_deferred_goto_scene", path)


func _deferred_goto_scene(path):
	
	resource_path = path 
	
	# Load the new scene.
	loader = ResourceLoader.load_interactive(resource_path)
	if loader == null:
		return 
	
	set_process(true)
	
	# It is now safe to remove the current scene
	if current_scene != null:
		current_scene.free()

	wait_frames = 3 
	
	
func _process(_time):
	if loader == null:
		set_process(false)
		return
	
	if wait_frames > 0:
		wait_frames -= 1
		return
	
	var t = OS.get_ticks_msec()
	while OS.get_ticks_msec() < t + time_max:
		var resp = loader.poll()
		
		if resp == ERR_FILE_EOF:
			var resource = loader.get_resource()
			loader = null
			_set_new_scene(resource)
			break
		elif resp == OK:
			_update_progress()
		else:
			return
		
			
func _set_new_scene(scene_resource):
	
	# Instance the new scene.
	current_scene = scene_resource.instance()

	# Add it to the active scene, as child of root.
	if viewport != null:
		viewport.add_child(current_scene)
		
	emit_signal("loading_completed")

	# Optionally, to make it compatible with the SceneTree.change_scene() API.
#	get_tree().set_current_scene(current_scene)

func _update_progress():
	var progress = float(loader.get_stage()) / loader.get_stage_count()
	emit_signal("loading_progress", progress)
