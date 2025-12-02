@tool 
extends EditorPlugin

#func _enter_tree():
	#add_autoload_singleton("PMDUtilsAutoload", "res://addons/pmd-utils/pmd_utils_autoload.gd")

#func _exit_tree():
	#remove_autoload_singleton("PMDUtilsAutoload")
