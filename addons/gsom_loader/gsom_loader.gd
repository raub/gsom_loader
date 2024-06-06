@tool
extends EditorPlugin


func _enter_tree() -> void:
	add_autoload_singleton("GsomLoader", "./gsom_loader_autoload.gd")


func _exit_tree() -> void:
	remove_autoload_singleton("GsomLoader")
