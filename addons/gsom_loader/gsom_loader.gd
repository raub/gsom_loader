@tool
extends EditorPlugin


func _enable_plugin() -> void:
	add_autoload_singleton("GsomLoader", "./gsom_loader_autoload.gd")


func _disable_plugin() -> void:
	remove_autoload_singleton("GsomLoader")
