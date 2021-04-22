extends Node

var viewport
var current_scene = null


# Called when the node enters the scene tree for the first time.
func _ready():
	pass
	
func setViewport(_viewport):
	viewport = _viewport
	current_scene = viewport.get_child(viewport.get_child_count()-1)

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
	# It is now safe to remove the current scene
	if current_scene != null:
		current_scene.free()

	# Load the new scene.
	var s = ResourceLoader.load(path)

	# Instance the new scene.
	current_scene = s.instance()

	# Add it to the active scene, as child of root.
	if viewport != null:
		viewport.add_child(current_scene)

	# Optionally, to make it compatible with the SceneTree.change_scene() API.
#	get_tree().set_current_scene(current_scene)
